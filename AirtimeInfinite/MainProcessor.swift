//
//  MainProcessor.swift
//  AirtimeInfinite
//
//  Created by Jordan Gould on 6/18/20.
//  Copyright © 2020 Jordan Gould. All rights reserved.
//

import Combine
import SwiftUI

/// Primary data handler/processor
class MainProcessor: ObservableObject {
    
    static let instance = MainProcessor()
    
    var mapViewProcessor: MapViewProcessor
    var chartViewProcessor: ChartViewProcessor
    
    var track: Track
    
    @Published var highlightedPoint: UserDataPointSelection
    @Published var selectedMeasurePoint: MeasurementPointSelection
    
    @Published var trackLoadError = false
    @Published var isLoading = false
    
    @Published var useImperialUnits: Bool {
        didSet {
            UserDefaults.standard.set(useImperialUnits, forKey: "measurementUnits")
        }
    }
    
    var anyCancellableHighlight: AnyCancellable? = nil
    var anyCancellableMeasure: AnyCancellable? = nil

    /// Initialize the main views with no data
    init() {
        highlightedPoint = UserDataPointSelection()
        selectedMeasurePoint = MeasurementPointSelection()
        
        mapViewProcessor = MapViewProcessor()
        chartViewProcessor = ChartViewProcessor()
        
        track = Track()
        
        if UserDefaults.standard.object(forKey: "measurementUnits") != nil {
            self.useImperialUnits = UserDefaults.standard.bool(forKey: "measurementUnits")
        } else {
            self.useImperialUnits = true
        }
        
        /// Allow for nested observable selection objects
        anyCancellableHighlight = highlightedPoint.objectWillChange.sink { (_) in
            self.objectWillChange.send()
        }
        anyCancellableMeasure = selectedMeasurePoint.objectWillChange.sink { (_) in
            self.objectWillChange.send()
        }
    }
    
    // TODO: Reset Data View on reload, prevent issues with stale views
    /**
    Load a track file into all data views
    
    - Parameters:
       - trackURL: File path to be loaded
    */
    func loadTrack(trackURL: URL) {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let fileAccessAllowed = trackURL.startAccessingSecurityScopedResource()
                if fileAccessAllowed {
                    try self.track.importURL(url: trackURL)
                    trackURL.stopAccessingSecurityScopedResource()
                } else {
                    DispatchQueue.main.async {
                        self.trackLoadError = true
                        self.isLoading = false
                    }
                    return
                }
            } catch {
                DispatchQueue.main.async {
                    self.trackLoadError = true
                    self.isLoading = false
                }
                return
            }
            
            DispatchQueue.main.async {
                self.chartViewProcessor.loadTrack(track: self.track)
                self.chartViewProcessor.resetChart()
                
                self.mapViewProcessor.clearMap()
                self.mapViewProcessor.loadTrack(track: self.track)
                
                self.highlightedPoint.point = self.track.trackData[self.track.exitIndex]
                self.isLoading = false
            }
        }
     }
}

