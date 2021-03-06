//
//  AddCityPresenter.swift
//  Weather
//

import Foundation

final class AddCityPresenter: AddCityViewOutput, AddCityModuleInput, AddCityModuleOutput {

    // MARK: - AddCityModuleOutput

    var didDismiss: EmptyClosure?
    var didGetCity: Closure<CityDetailedEntity>?

    // MARK: - Properties

    weak var view: AddCityViewInput?

    // MARK: - Private properties

    private let geoService: GeocodingService
    private let cityService: CityService
    private let repo: CityRepository
    private var searchWorkItem: DispatchWorkItem?

    // MARK: - Init

    init(geoService: GeocodingService, cityService: CityService, repo: CityRepository) {
        self.geoService = geoService
        self.cityService = cityService
        self.repo = repo
    }

    // MARK: - AddCityViewOutput

    func didSearch(query: String) {
        guard !query.isEmpty else { return }

        self.searchWorkItem?.cancel()

        let searchWorkItem = DispatchWorkItem { [weak self] in
            self?.search(by: query)
        }

        self.searchWorkItem = searchWorkItem

        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: searchWorkItem)
    }

    func didCancelTap() {
        didDismiss?()
    }

    func didSelect(city: PlacesSuggestionEntity) {
        getCity(by: .init(lon: city.lon, lat: city.lat))
    }
}

// MARK: - Private Methods

private extension AddCityPresenter {
    func search(by query: String) {
        view?.startLoader()
        geoService.getAddressAutocompleteSuggestion(address: query)
            .onCompleted { [weak self] entities in
                if entities.isEmpty {
                    self?.view?.update(citites: [])
                    self?.view?.set(state: .empty(.init(Localized.Empty.request,
                                                        action: Localized.Common.Button.repeat)))
                } else {
                    self?.view?.update(citites: entities)
                    self?.view?.set(state: .normal)
                }
            }.onError { [weak self] error in
                self?.view?.update(citites: [])
                if error.isNetwork {
                    self?.view?.set(state: .error(.init(Localized.Error.noInternetConnection,
                                                       action: Localized.Common.Button.repeat)))
                } else {
                    self?.view?.set(state: .error(.init(Localized.Error.notDefined,
                                                       action: Localized.Common.Button.repeat)))
                }
            }.defer { [weak self] in
                self?.view?.stopLoader()
            }
    }

    func getCity(by coords: CoordEntity) {
        view?.startLoader()
        cityService.getCityBy(coords: coords)
            .onCompleted { [weak self] city in
                self?.repo.save(city: city).defer {
                    self?.didGetCity?(city)
                }
            }.onError { [weak self] error in
                self?.view?.show(error: error)
            }.defer { [weak self] in
                self?.view?.stopLoader()
            }
    }
}
