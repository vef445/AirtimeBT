//
//  UnitsManager.swift
//  Airtime BT
//
//  Created by Guillaume Vigneron on 04/07/2025.
//  Copyright © 2025 Guillaume Vigneron. All rights reserved.
//

import Foundation
import CoreLocation

enum DataType {
    case speed
    case altitude
    case temperature
    case distance
}

class UnitsManager {
    
    static func retrieveUserUnit(
        for dataType: DataType,
        preference: MainProcessor.UnitPreference,
        customAltitudeUnit: UnitLength? = nil,
        customSpeedUnit: UnitSpeed? = nil,
        customDistanceUnit: UnitLength? = nil
    ) -> String {
        switch dataType {
        case .speed:
            if preference == .mix, let customSpeed = customSpeedUnit {
                if customSpeed == .kilometersPerHour { return "km/h" }
                else if customSpeed == .milesPerHour { return "mph" }
                else { return "km/h" }
            } else {
                switch preference {
                case .metric: return "km/h"
                case .imperial: return "mph"
                case .mix: return "mph"
                }
            }
        case .altitude:
            if preference == .mix, let customAlt = customAltitudeUnit {
                if customAlt == .meters { return "m" }
                else if customAlt == .feet { return "ft" }
                else { return "m" }
            } else {
                switch preference {
                case .metric: return "m"
                case .imperial: return "ft"
                case .mix: return "ft"
                }
            }
        case .temperature:
            switch preference {
            case .metric: return "°C"
            case .imperial: return "°F"
            case .mix: return "°C"
            }
        case .distance:
            if preference == .mix, let customDist = customDistanceUnit {
                if customDist == .meters { return "m" }
                else if customDist == .feet { return "ft" }
                else { return "m" }
            } else {
                switch preference {
                case .metric: return "m"
                case .imperial: return "ft"
                case .mix: return "m"
                }
            }
        }
    }
    
    static func conversionFactor(
        for dataType: DataType,
        preference: MainProcessor.UnitPreference,
        customAltitudeUnit: UnitLength? = nil,
        customSpeedUnit: UnitSpeed? = nil,
        customDistanceUnit: UnitLength? = nil
    ) -> Double {
        switch dataType {
        case .speed:
            if preference == .mix, let customSpeed = customSpeedUnit {
                if customSpeed == .kilometersPerHour { return 1.0 }
                else if customSpeed == .milesPerHour { return 0.621371 }
                else { return 1.0 }
            } else {
                switch preference {
                case .metric: return 1.0
                case .imperial: return 0.621371
                case .mix: return 0.621371
                }
            }
        case .altitude:
            if preference == .mix, let customAlt = customAltitudeUnit {
                if customAlt == .meters { return 1.0 }
                else if customAlt == .feet { return 3.28084 }
                else { return 1.0 }
            } else {
                switch preference {
                case .metric: return 1.0
                case .imperial: return 3.28084
                case .mix: return 3.28084
                }
            }
        case .temperature:
            return 1.0
        case .distance:
            if preference == .mix, let customDist = customDistanceUnit {
                if customDist == .meters { return 1.0 }
                else if customDist == .feet { return 3.28084 }
                else { return 1.0 }
            } else {
                switch preference {
                case .metric: return 1.0
                case .imperial: return 3.28084
                case .mix: return 1.0
                }
            }
        }
    }
    
    // MARK: - Conversion functions for actual values
    
    /// Converts speed from m/s to user preferred units.
    static func convertedSpeed(
        fromMS metersPerSecond: Double,
        preference: MainProcessor.UnitPreference,
        customSpeedUnit: UnitSpeed? = nil
    ) -> Double {
        if preference == .mix, let customSpeed = customSpeedUnit {
            if customSpeed == .kilometersPerHour {
                return metersPerSecond * 3.6
            } else if customSpeed == .milesPerHour {
                return metersPerSecond * 2.23694
            } else {
                return metersPerSecond * 3.6
            }
        } else {
            switch preference {
            case .metric:
                return metersPerSecond * 3.6
            case .imperial, .mix:
                return metersPerSecond * 2.23694
            }
        }
    }
    
    /// Converts altitude from meters to user preferred units.
    static func convertedAltitude(
        fromMeters meters: Double,
        preference: MainProcessor.UnitPreference,
        customAltitudeUnit: UnitLength? = nil
    ) -> Double {
        if preference == .mix, let customAlt = customAltitudeUnit {
            if customAlt == .meters {
                return meters
            } else if customAlt == .feet {
                return meters * 3.28084
            } else {
                return meters
            }
        } else {
            switch preference {
            case .metric:
                return meters
            case .imperial, .mix:
                return meters * 3.28084
            }
        }
    }
    
    /// Converts distance from meters to user preferred units.
    static func convertedDistance(
        fromMeters meters: Double,
        preference: MainProcessor.UnitPreference,
        customDistanceUnit: UnitLength? = nil
    ) -> Double {
        if preference == .mix, let customDist = customDistanceUnit {
            if customDist == .meters {
                return meters
            } else if customDist == .feet {
                return meters * 3.28084
            } else {
                return meters
            }
        } else {
            switch preference {
            case .metric:
                return meters
            case .imperial, .mix:
                return meters * 3.28084
            }
        }
    }
    
    /// Converts temperature from Celsius to user preferred units.
    /// Assumes input in Celsius.
    static func convertedTemperature(
        fromCelsius celsius: Double,
        preference: MainProcessor.UnitPreference
    ) -> Double {
        switch preference {
        case .metric, .mix:
            return celsius
        case .imperial:
            return (celsius * 9/5) + 32
        }
    }
}
