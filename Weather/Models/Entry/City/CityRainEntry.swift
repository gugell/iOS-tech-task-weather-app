//
//  CityRainEntry.swift
//  WeatherDebug
//

import NodeKit

struct CityRainEntry: Codable {

    private enum CodingKeys: String, CodingKey {
        case h1 = "1h"
        case h3 = "3h"
    }

    let h1: Double?
    let h3: Double?
}

extension CityRainEntry: RawMappable {
    typealias Raw = Json
}
