//
//  CityDetailedWeatherEntity.swift
//  WeatherDebug
//

import NodeKit

struct CityDetailedWeatherEntity {
    let coords: CoordEntity
    let weather: [CityWeatherConditionsEntity]
    let base: String
    let main: CityMainWeatherInfoEntity
    let wind: CityWindEntity?
    let clouds: CityCloundEntity?
    let rain: CityRainEntity?
    let snow: CitySnowEntity?
    let time: Date
    let systemInfo: CitySystemInfoEntity
    let timezone: Int
    let cityId: String
    let cityName: String
    let cod: String
}

extension CityDetailedWeatherEntity: DTODecodable {

    static func from(dto: CityDetailedWeatherEntry) throws -> CityDetailedWeatherEntity {
        CityDetailedWeatherEntity(coords: try .from(dto: dto.coord),
              weather: try .from(dto: dto.weather),
              base: dto.base,
              main: try .from(dto: dto.main),
              wind: try? .from(dto: dto.wind),
              clouds: try? .from(dto: dto.clouds),
              rain: try? .from(dto: dto.rain),
              snow: try? .from(dto: dto.snow),
              time: Date(timeIntervalSince1970: dto.dt),
              systemInfo: try .from(dto: dto.sys),
              timezone: dto.timezone,
              cityId: dto.id,
              cityName: dto.name,
              cod: dto.cod)
    }
}
