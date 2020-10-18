//
//  Cityrepository.swift
//  Weather
//
//  Created by Александр Кравченков on 18.10.2020.
//

import Foundation
import NodeKit

struct CityCacheFirstRepository {

    private let cache: CityCacheService
    private let cityNetwork: CityService
    private let weatherNetwork: DetailedWeatherService

    init(cache: CityCacheService, cityNetwork: CityService, weatherNetwork: DetailedWeatherService) {
        self.cache = cache
        self.cityNetwork = cityNetwork
        self.weatherNetwork = weatherNetwork
    }
}

// MARK: - CityRepository

extension CityCacheFirstRepository: CityRepository {

    /// Возвращает все города, которые пользователь сохранил себе для просмотра
    /// Сначала читает данные из кеша
    ///     - Если получил ошибку - просто пробрасывает ее на верх и заканчивает работу
    ///
    /// После получения городов прокидывает их выше (это был кеш)
    /// Затем берет все города у которых протух кеш и перезапрашивает их из сети
    /// После этого обновляет кеш
    /// Затем мерджит обновленные данные и данные прочитанные ранее из кеша
    /// И пробрасывает новую пачку данных выше
    func getAllSaved() -> CacheContext<[CityDetailedEntity]> {
        let result = CacheContext<[CityDetailedEntity]>()

        self.cache.getAll().onCompleted { items in
            let expiredItems = items.filter { $0.isExpired }

            // Если не нашлось ни одного итема, у которого протух кеш то есть isEmpty == true
            // это значит, что кеш не протухший, а значит isExpired == false ==> isExpired = !isEmpty
            result.emitCache(items.map { $0.value }, isExpired: !expiredItems.isEmpty)

            // если есть итемы  у которых протух кеш, то идем дальше
            // если у всех кеш свежий, то просто выходим
            guard !expiredItems.isEmpty else { return }

            // перезапрашиваем из сети те итемы, у которых протух кеш
            result.emitStartLoading()
            self.cityNetwork.getCitiesDetailedWeather(by: expiredItems.map { $0.value.cityId })
                .dispatchOn(.global())  // потенциально тяжелая операция, нечего грузить главный поток
                .onCompleted { cities in
                    // Передадим слушаетлю всю пачку моделей
                    // Для этого нужно взять старые модели и заменить в них те которые протухли на свежие
                    let newItems = items.compactMap { item -> CityDetailedEntity? in
                        guard item.isExpired else { return item.value }

                        return cities.first(where: { $0.cityId == item.value.cityId })
                    }

                    result.emit(data: newItems)

                    // Сохраняем то что пришло
                    _ = self.cache.save(cites: cities)
                }.onError { err in
                    result.emit(error: err)
                }
        }.onError { err in
            print("ERR; While reading cache in \(#function) : \(err)")
            result.emit(error: err)
        }

        return result.dispatch(on: .main)
    }

    /// Запрашивает город по имени
    /// Работает только с сетью
    ///
    /// Подробнее смотри `CityNetworkService` и его реализации
    func getCityBy(name: String) -> Observer<CityDetailedEntity> {
        return self.cityNetwork.getCityDetailedWeather(by: name)
    }

    /// Сохраняет город в кеш
    /// С сетью не работает
    ///
    /// Подробнее смотри `CityCacheService` и его реализацию
    func save(city: CityDetailedEntity) -> Observer<Void> {
        return self.cache.save(cites: [city])
    }

    func getCityDetails(by id: Int, coords: CoordEntity) -> CacheContext<CityDetailedEntity> {

        let result = CacheContext<CityDetailedEntity>()

        // читаем из кеша информацию о городе
        self.cache.get(by: id).onCompleted { item in
            // если прочли из кеша сначала проверяем - есть ли там информация о погоде
            guard let weather = item.weather else {
                // если погоды нет, то ее надо запросить, а потом сохранить
                self.reloadDetailedWeather(item: item, context: result)
                return
            }

            // если информация о погоде есть, то пробрасываем модель выше
            var city = item.city.value
            city.detailedWeather = weather.value

            // протух кеш или нет зависит от:
            //  - протух ли кеш города
            //  - протух ли кеш погоды
            let isExpired = item.city.isExpired && weather.isExpired
            result.emitCache(city, isExpired: isExpired)

            guard isExpired else {
                return
            }

            // если кеш все таки протух, тогда надо его обновить
            self.detailedCacheIsLoadedButExpired(context: result,
                                                 cityCache: item.city,
                                                 weatherCache: weather,
                                                 coords: coords)
        }.onError { err in
            print("ERR; While reading cache in \(#function) : \(err)")
            // если не получилось прочесть из кеша, то идем в сеть
            self.loadDetailedInfo(cityId: id, coords: coords, context: result)
        }
        return result
    }

}

// MARK: - Helpers

private extension CityCacheFirstRepository {

    /// Перезагружает детальную информацию о погоде из сети
    /// Эмитит закешированный город с погодой выше
    /// Если город протух - обновляет город и эмитит обновленный результат
    /// Затем обновляет кеш
    func reloadDetailedWeather(item: CityCacheResponse, context: CacheContext<CityDetailedEntity>) {
        self.weatherNetwork
            .getDetailedWeather(by: item.city.value.coords)
            .onCompleted { value in
                var city = item.city.value
                city.detailedWeather = value
                context.emitCache(city, isExpired: item.city.isExpired)

                // если кеш города не протух, то больше делать нам нечего - выходим
                guard item.city.isExpired else { return }

                // если протух - перезапрашиваем город
                self.cityNetwork
                    .getCitiesDetailedWeather(by: item.city.value.cityId)
                    .onCompleted { city in
                        var mutable = city
                        mutable.detailedWeather = value
                        // кидаем выше новую обновленную модель
                        context.emit(data: mutable)
                        // и сохраняем ее в кеш
                        self.cache.save(cites: [mutable]).onError { err in
                            print("ERR; While writing cache in \(#function) : \(err)")
                        }
                    }
            }.onError { err in
                // если не прочли детальную погоду, то у нас ошибка и мы ничего не можем с этим сделать
                context.emit(error: err)
            }
    }

    /// Загружает детальную информацию о городе и погоде из сети
    /// Пробрасывает ее выше
    /// А затем сохраняет в кеш
    func loadDetailedInfo(cityId: Int, coords: CoordEntity, context: CacheContext<CityDetailedEntity>) {
        context.emitStartLoading()
        self.cityNetwork
            .getCitiesDetailedWeather(by: cityId) // запрашиваем город
            .combine(self.weatherNetwork.getDetailedWeather(by: coords)) // и сразу параллельно запрашиваем детальную информацию о погоде
            .onCompleted { args in
                var (city, weather) = args
                city.detailedWeather = weather
                context.emit(data: city)
                // и если получили из сети что-то, то сохраняем в кеш
                self.cache
                    .save(cites: [city])
                    .combine(self.cache.save(detailedWeather: weather, for: city))
                    .onError { err in
                        print("ERR; While writing cache in \(#function) : \(err)")
                    }
            }.onError { err in
                context.emit(error: err)
            }
    }

    /// Проверяет какой конкретно кеш протух
    /// Если протухли оба кеша - вызывает `reloadDetailedWeather`
    /// Если протух только один из - идет в сеть, пробрасывает реультат выше
    /// Затем обновляет кеш
    func detailedCacheIsLoadedButExpired(context: CacheContext<CityDetailedEntity>,
                                         cityCache: CachedModel<CityDetailedEntity>,
                                         weatherCache: CachedModel<DetailedWeatherEntity>,
                                         coords: CoordEntity) {

        switch (cityCache.isExpired, weatherCache.isExpired) {
        case (true, true):
            // если протухло оба кеша, тогда вызываем метод который использовали для обновления погоды
            // так как он обновляет и город и погоду
            let cache = CityCacheResponse(city: cityCache, weather: weatherCache)
            self.reloadDetailedWeather(item: cache, context: context)
        case (true, false):
            // протух только город
            self.cityNetwork
                .getCitiesDetailedWeather(by: cityCache.value.cityId)
                .onCompleted { newCity in
                    // берем город из сети а затем сохраняем в кеш
                    var mutable = newCity
                    mutable.detailedWeather = weatherCache.value
                    context.emit(data: mutable)
                    self.cache.save(cites: [newCity]).onError { err in
                        print("ERR; While writing cache in \(#function) : \(err)")
                    }
                }.onError { err in
                    // попытались взять из сети - получили ошибку
                    // ну ниче страшного - кеш-то мы отправили
                    context.emit(error: err)
                }
        case (false, true):
            // протухла только погода
            self.weatherNetwork
                .getDetailedWeather(by: coords)
                .onCompleted { newWeather in
                    // получили погоду из сети, пробросили выше
                    var city = cityCache.value
                    city.detailedWeather = newWeather
                    context.emit(data: city)
                    // и сохранили в кеш
                    self.cache.save(detailedWeather: newWeather, for: city).onError { err in
                        print("ERR; While writing cache in \(#function) : \(err)")
                    }
                }.onError { err in
                    // попытались взять из сети - получили ошибку
                    // ну ниче страшного - кеш-то мы отправили
                    context.emit(error: err)
                }
        case (false, false):
            // нереальный случай в этом участке кода, но раз надо, так надо
            return
        }
    }
}
