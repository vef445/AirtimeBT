//
//  UserDataPointSelection.swift
//  AirtimeInfinite
//
//  Created by Jordan Gould on 6/18/20.
//  Copyright © 2020 Jordan Gould. All rights reserved.
//
import SwiftUI

/// Holds and calculates the datapoint representing the data the user has selected via mouseover on the Chart
class UserDataPointSelection: ObservableObject {

    @Published var point: DataPoint?
    
    init(){}
    
    /**
    Given a time in seconds, get the corresponding data point
     
    - Parameters:
     - seconds: Time in seconds from start that user selected
    */
    func setPointFromSecondsProperty(seconds: Double){
        self.point = MainProcessor.instance.track.trackData.first(
            where: { $0.secondsFromStart == seconds })
    }
    
}

/// Holds base point chosen by the user for measurements 
class MeasurementPointSelection: UserDataPointSelection {
    
    @Published var isActive = false
}
