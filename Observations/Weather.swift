//
//  Weather.swift
//  Vind
//
//  Created by Jens Utbult on 2016-01-05.
//  Copyright © 2016 Jens Utbult. All rights reserved.
//

import Foundation
import CoreLocation

enum WeatherProvider {
    case SMHI
    case Sjofartsverket
}

struct Weather : CustomStringConvertible {
    let locationName: String
    let coordinate: CLLocationCoordinate2D?
    let stationHeight: Double?
    let date: NSDate
    let provider:WeatherProvider
    
    let windSpeed: Double?
    let windGusts: Double?
    let windDirection: Double?
    let seaLevel: Double?
    
    let temperature: Double?
    let humidity: Double?
    let pressure: Double?
    
    var description : String {
        var result = "\(locationName) (\(provider)) \(date)\n"
        if let coordinate = coordinate { result += "coordinate: \(coordinate.latitude):\(coordinate.longitude)\n" }
        if let stationHeight = stationHeight { result += "stationHeight: \(stationHeight)m\n" }
        if let windSpeed = windSpeed { result += "windSpeed: \(windSpeed)m/s\n" }
        if let windGusts = windGusts { result += "windGusts: \(windGusts)m/s\n" }
        if let windDirection = windDirection { result += "windDirection: \(windDirection * 180.0 / M_PI)°\n" }
        if let seaLevel = seaLevel { result += "seaLevel: \(seaLevel)m\n" }
        if let temperature = temperature { result += "temperature: \(temperature)C\n" }
        if let humidity = humidity { result += "humidity: \(humidity)\n" }
        if let pressure = pressure { result += "pressure: \(pressure)\n" }
        return result
    }
}
