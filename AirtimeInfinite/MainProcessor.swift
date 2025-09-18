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
    var polarViewProcessor: PolarViewProcessor
    
    var track: Track

    // Custom units when unitPreference == .mix
    var customAltitudeUnit: UnitLength = .meters
    var customSpeedUnit: UnitSpeed = .kilometersPerHour
    var customDistanceUnit: UnitLength = .meters

    @Published var highlightedPoint: UserDataPointSelection
    @Published var selectedMeasurePoint: MeasurementPointSelection
    @Published var trackLoadedSuccessfully = false
    
    @Published var trackLoadError = false
    @Published var isLoading = false
    
    @Published var autoCutTrackOption: AutoCutTrackOption = .jump {
        didSet {
            UserDefaults.standard.set(autoCutTrackOption.rawValue, forKey: "autoCutTrackOption")
        }
    }
    @Published var unitPreference: UnitPreference {
        didSet {
            UserDefaults.standard.set(unitPreference.rawValue, forKey: "unitPreference")
        }
    }

    
    @Published var isDragging = false
    
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
    
    enum AutoCutTrackOption: String, CaseIterable, Identifiable {
        case never = "Never"
        case jump = "Jump"
        case swoop = "Swoop"
        
        var id: String { self.rawValue }
    }
    enum UnitPreference: String, CaseIterable, Identifiable {
        case metric = "Metric"
        case imperial = "Imperial"
        case mix = "Mix"
        
        var id: String { self.rawValue }
    }
    
    var anyCancellableHighlight: AnyCancellable? = nil
    var anyCancellableMeasure: AnyCancellable? = nil
    var anyCancellableChart: AnyCancellable? = nil
    var anyCancellableChartOption: AnyCancellable? = nil

    
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
    
    init() {
        // Step 1: Get the autoCutTrackOption value from UserDefaults *before* initializing properties
        let savedOption: AutoCutTrackOption
        if let saved = UserDefaults.standard.string(forKey: "autoCutTrackOption"),
           let option = AutoCutTrackOption(rawValue: saved) {
            savedOption = option
        } else {
            savedOption = .jump
        }
        if let savedPreference = UserDefaults.standard.string(forKey: "unitPreference"),
           let pref = UnitPreference(rawValue: savedPreference) {
            self.unitPreference = pref
        } else {
            self.unitPreference = .metric
        }
        
        // Step 2: Initialize all properties that do not require 'self'
        self.autoCutTrackOption = savedOption
        self.showAcceleration = UserDefaults.standard.bool(forKey: "showAcceleration")
        self.useBluetooth = UserDefaults.standard.bool(forKey: "useBluetooth")
        
        self.highlightedPoint = UserDataPointSelection()
        self.selectedMeasurePoint = MeasurementPointSelection()
        
        self.mapViewProcessor = MapViewProcessor()
        self.chartViewProcessor = ChartViewProcessor()
        self.polarViewProcessor = PolarViewProcessor()
        
        self.track = Track()
        
        // Step 3: Now safely use self
        self.chartViewProcessor.autoCutTrackOption = savedOption
        
        // Step 4: Setup cancellables
        self.anyCancellableHighlight = highlightedPoint.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
        self.anyCancellableMeasure = selectedMeasurePoint.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
        self.anyCancellableChart = chartViewProcessor.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
        self.anyCancellableChartOption = $autoCutTrackOption.sink { [weak self] newOption in
            self?.chartViewProcessor.autoCutTrackOption = newOption
        }
    }


    
    // TODO: Reset Data View on reload, prevent issues with stale views
    /**
     Load a track file into all data views
     
     - Parameters:
     - trackURL: File path to be loaded
     */
    func loadTrack(trackURL: URL) async {
        track.resetGroundElevationCache()
        await MainActor.run {
            self.isLoading = true
        }

        do {
            if trackURL.startAccessingSecurityScopedResource() {
                defer { trackURL.stopAccessingSecurityScopedResource() }
                try await self.track.importURL(url: trackURL)
            } else if trackURL.isFileURL {
                try await self.track.importURL(url: trackURL)
            } else {
                await MainActor.run {
                    self.trackLoadError = true
                    self.isLoading = false
                }
                return
            }
        } catch {
            await MainActor.run {
                self.trackLoadError = true
                self.isLoading = false
            }
            return
        }

        await MainActor.run {
            self.trackURL = trackURL
            
            // Reset zoom lock status
            self.chartViewProcessor.isCutPublished = false

            // Update processors
            self.chartViewProcessor.loadTrack(track: self.track)
            self.chartViewProcessor.resetChart()

            self.mapViewProcessor.clearMap()
            self.mapViewProcessor.loadTrack(track: self.track)

            let fullRange = 0.0...(self.track.trackData.last?.secondsFromStart ?? 0.0)
            self.polarViewProcessor.loadTrack(
                track: self.track,
                visibleRange: fullRange,
                unitPreference: self.unitPreference,
                highlightedPoint: self.highlightedPoint.point
            )

            if let exitPoint = self.track.exitDataPointInFilteredData() {
                self.highlightedPoint.point = exitPoint
            } else {
                print("Warning: exit point index out of range in filtered data")
                // Handle fallback here, if needed
            }

            self.isLoading = false
            self.trackLoadedSuccessfully = true
        }

    }
    
    ///Manage custom units
    func setCustomUnits(altitude: UnitLength, speed: UnitSpeed, distance: UnitLength) {
        // Save the custom units locally
        self.customAltitudeUnit = altitude
        self.customSpeedUnit = speed
        self.customDistanceUnit = distance

        // If unitPreference is mix, update internal units used for display/conversion accordingly
        if self.unitPreference == .mix {
            // For example, update units used in chart display or data conversion
            // You could add methods or properties here that use these units
            // This depends on how your rest of MainProcessor works
        }
        
        // Reload track or views to reflect new unit settings
        self.fullyReloadTrack()
    }

    
    /// Reloads the currently loaded track file completely
    func fullyReloadTrack() {
        guard let url = self.trackURL else {
            print("No trackURL available to reload track")
            return
        }
        
        Task {
            await self.loadTrack(trackURL: url)
        }
    }
    /*
    //Update the weather annotations
    func updateWeatherAnnotations(with weatherAnnotations: [WeatherAnnotation]) {
        let existingAnnotations = mapView.annotations.compactMap { $0 as? WeatherAnnotation }
        mapView.removeAnnotations(existingAnnotations)
        mapView.addAnnotations(weatherAnnotations)
    }
*/
    
    /// Call this whenever the visible X range changes (e.g. on zoom or pan)
    func updateVisibleRange(_ range: ClosedRange<Double>) {
        polarViewProcessor.loadTrack(track: self.track,
                                     visibleRange: range,
                                     unitPreference: self.unitPreference,
                                     highlightedPoint: self.highlightedPoint.point)
    }

    
    /// Calculates the fastest average speed over 3 seconds within the performance window
    func fastest3sSpeedInPerformanceWindow() async -> (
        startTime: Int,
        maxAvgDescentSpeedkmh: Double,
        maxAvgDescentSpeedmph: Double,
        performanceWindowStartAltitude: Double,
        performanceWindowEndAltitude: Double
    )? {
        guard let result = await SpeedAnalysis.fastestAverageDescentSpeedInPerformanceWindow(data: track.trackData) else {
            return nil
        }
        return (
            startTime: result.startTime,
            maxAvgDescentSpeedkmh: result.maxAvgDescentSpeedkmh,
            maxAvgDescentSpeedmph: result.maxAvgDescentSpeedmph,
            performanceWindowStartAltitude: result.performanceWindowStartAltitude,
            performanceWindowEndAltitude: result.performanceWindowEndAltitude
        )
    }
    

}


