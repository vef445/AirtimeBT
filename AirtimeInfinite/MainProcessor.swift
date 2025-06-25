//
//  MainProcessor.swift
//  AirtimeBT
//
//  Created by Jordan Gould on 6/18/20.
//  Copyright © 2020 Jordan Gould. All rights reserved.
//

import Combine
import SwiftUI
import FlySightCore

/// Primary data handler/processor
class MainProcessor: ObservableObject {
    
    private(set) var trackURL: URL? = nil
    
    static let instance = MainProcessor()
    
    let bluetoothManager = FlySightCore.BluetoothManager()
    
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
    
    @Published var showAcceleration: Bool {
        didSet {
            UserDefaults.standard.set(showAcceleration, forKey: "showAcceleration")
        }
    }
    
    @Published var useBluetooth: Bool {
        didSet {
            UserDefaults.standard.set(useBluetooth, forKey: "useBluetooth")
        }
    }
    
    var anyCancellableHighlight: AnyCancellable? = nil
    var anyCancellableMeasure: AnyCancellable? = nil
    var anyCancellableChart: AnyCancellable? = nil

    /// Tracks the last connected Bluetooth peripheral UUID
    var lastConnectedPeripheralID: UUID? {
        get {
            if let idString = UserDefaults.standard.string(forKey: "LastPeripheralID") {
                return UUID(uuidString: idString)
            }
            return nil
        }
        set {
            if let newValue = newValue {
                UserDefaults.standard.set(newValue.uuidString, forKey: "LastPeripheralID")
            }
        }
    }

    /// Indicates whether a track file is loaded
    var trackLoaded: Bool {
        return !track.trackData.isEmpty
    }

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
        
        if UserDefaults.standard.object(forKey: "showAcceleration") != nil {
            self.showAcceleration = UserDefaults.standard.bool(forKey: "showAcceleration")
        } else {
            self.showAcceleration = false
        }
        
        if UserDefaults.standard.object(forKey: "useBluetooth") != nil {
            self.useBluetooth = UserDefaults.standard.bool(forKey: "useBluetooth")
        } else {
            self.useBluetooth = false
        }
        
        /// Allow for nested observable selection objects
        anyCancellableHighlight = highlightedPoint.objectWillChange.sink { (_) in
            self.objectWillChange.send()
        }
        anyCancellableMeasure = selectedMeasurePoint.objectWillChange.sink { (_) in
            self.objectWillChange.send()
        }
        anyCancellableChart = chartViewProcessor.objectWillChange.sink { (_) in
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
                if trackURL.startAccessingSecurityScopedResource() {
                    defer { trackURL.stopAccessingSecurityScopedResource() }
                    try self.track.importURL(url: trackURL)
                } else if trackURL.isFileURL {
                    // Possibly Bluetooth file, try to import directly
                    try self.track.importURL(url: trackURL)
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
                self.trackURL = trackURL
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
