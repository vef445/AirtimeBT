//
//  ChartableMetric.swift
//  AirtimeInfinite
//
//  Created by Jordan Gould on 6/18/20.
//  Copyright © 2020 Jordan Gould. All rights reserved.
//

import SwiftUI

/// A chartable/selectable representation of a y-value/FlightMetric (e.g Altitude) and its associated attributes
class ChartableMetric: ObservableObject {
    
    /// Metric to display
    var attributes: FlightMetric
    /// Array of individual  y-values
    var valueList: [Double]
    @Published var isSelected: Bool {
        didSet {
            UserDefaults.standard.set(isSelected, forKey: "isVisible-\(attributes.title)")
        }
    }
    
    /**
     Initializes a new chartable, user selectable y-value
     
    - Parameters:
       - attributes: The FlightMetric enum with the necessary attribute data
    */
    init(attributes: FlightMetric) {
        self.attributes = attributes
        self.valueList = []
        if UserDefaults.standard.object(forKey: "isVisible-\(attributes.title)") != nil {
            self.isSelected = UserDefaults.standard.bool(forKey: "isVisible-\(attributes.title)")
        } else {
            self.isSelected = attributes.defaultVisible
        }
    }

}
