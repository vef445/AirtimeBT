//
//  Conversions.swift
//  AirtimeBT
//
//  Created by Jordan Gould on 6/18/20.
//  Copyright © 2020 Jordan Gould. All rights reserved.
//

import SwiftUI

extension FloatingPoint {
    var degreesToRadians: Self { self * .pi / 180 }
    var radiansToDegrees: Self { self * 180 / .pi }
}

extension Double {
    var metersToFeet: Self { self * 3.28084 }
    var metersPerSecondToMPH: Self { self * 2.23694 }
    var metersPerSecondToKMH: Self { self * 3.6 }
}
