//
//  ChartViewProcessor.swift
//  AirtimeBT
//
//  Created by Jordan Gould on 6/18/20.
//  Copyright © 2020 Jordan Gould. All rights reserved.
//

import SwiftUI
import DGCharts

/// Data handler for the Chart view
class ChartViewProcessor: ObservableObject {
    
    /// Primary view object from the Charts library
    var lineChartView: LineChartView
    
    /// Track if the view is cut
    var isCut: Bool {
        return originalTrack != nil
    }

    
    ///
    var track: Track = Track()
    
    /// Keeps a backup of the full track in case user cuts to a zoomed range
    private var originalTrack: Track? = nil
    
    let flightMetrics = [FlightMetric.alt,
                         FlightMetric.hVel,
                         FlightMetric.vVel,
                         FlightMetric.tVel,
                         FlightMetric.dive,
                         FlightMetric.glide,
                         FlightMetric.hDist,
                         FlightMetric.accelVertical,
                         FlightMetric.accelParallel,
                         FlightMetric.accelPerp,
                         FlightMetric.accelTotal]
    
    @Published var isCutPublished: Bool = false
    @Published var autoCutTrackOption: MainProcessor.AutoCutTrackOption = .jump
    @Published var chartableMetrics: [ChartableMetric] = []
    @Published var autoScaleEnabled: Bool {
        didSet {
            UserDefaults.standard.set(autoScaleEnabled, forKey: "autoScaleEnabled")
        }
    }
    
    init() {
        if UserDefaults.standard.object(forKey: "autoScaleEnabled") != nil {
            self.autoScaleEnabled = UserDefaults.standard.bool(forKey: "autoScaleEnabled")
        } else {
            self.autoScaleEnabled = true
        }
        lineChartView = LineChartView()
        initChartableMetrics()
    }
    
    /**
     Processes and displays user-selected track data to the chart
     
     - Parameters:
        - track: Object containing all track data
     */
    func loadTrack(track: Track){
        
        self.track = track
        self.loadChartableMetrics()
        
        var dataSets: [LineChartDataSet] = []
        
        // If nothing selected to display, default to first available (likely altitude)
        if chartableMetrics.filter({ $0.isSelected}).count == 0 {
            self.chartableMetrics[0].isSelected = true
        }
        
        /// Only load data selected by the user
        for data in self.chartableMetrics {
            if data.isSelected{
                let dataSet = buildDataSetForNumericProperty(
                    propertyData: data.valueList,
                    label: data.attributes.title)
                dataSet.setColor(data.attributes.color)
                if data.attributes.rightAxis {
                    dataSet.axisDependency = .right
                } else {
                    dataSet.axisDependency = .left
                }
                dataSets.append(dataSet)
            }
        }
        
        let data = LineChartData(dataSets: dataSets)
        
        lineChartView.data = data
        
    }
    
    /// Refresh the currently loaded track
    func reloadTrack() {
        if !track.trackData.isEmpty {
            loadTrack(track: self.track)
        }
    }
    
    /// Clear highlights and resize to default screen
    func resetChart() {
        
        lineChartView.highlightValues([])
        lineChartView.fitScreen()
        lineChartView.notifyDataSetChanged()
    }
    
    /// Generate chartable metrics from base FlightMetrics
    func initChartableMetrics() {
        for metric in flightMetrics{
            chartableMetrics.append(ChartableMetric(attributes: metric))
        }
    }
    
    /// Load data from the track into the chartable metric
    func loadChartableMetrics() {
        let preference = MainProcessor.instance.unitPreference

        // Altitude (meters native)
        let altFactor = UnitsManager.conversionFactor(for: .altitude, preference: preference)
        chartableMetrics.first(where: { $0.attributes == .alt })?.valueList =
            track.trackData.map { $0.altitude * altFactor }

        // Horizontal velocity (convert m/s to user unit)
        chartableMetrics.first(where: { $0.attributes == .hVel })?.valueList =
            track.trackData.map {
                UnitsManager.convertedSpeed(fromMS: $0.horizontalSpeed, preference: preference)
            }

        // Vertical velocity (convert m/s to user unit)
        chartableMetrics.first(where: { $0.attributes == .vVel })?.valueList =
            track.trackData.map {
                UnitsManager.convertedSpeed(fromMS: $0.velD, preference: preference)
            }

        // Total velocity (convert m/s to user unit)
        chartableMetrics.first(where: { $0.attributes == .tVel })?.valueList =
            track.trackData.map {
                UnitsManager.convertedSpeed(fromMS: $0.totalSpeed, preference: preference)
            }
        
        // Dive angle (unitless), but clipped at landing time
            if let diveMetric = chartableMetrics.first(where: { $0.attributes == .dive }) {
                diveMetric.valueList = track.trackData
                    .filter { dp in
                        if let landingTime = track.landingTime {
                            return dp.secondsFromStart <= landingTime
                        }
                        return true
                    }
                    .map { dp in
                        dp.diveAngle
                    }
            }
        
        // Glide ratio (unitless), but clipped at landing time
            if let diveMetric = chartableMetrics.first(where: { $0.attributes == .glide }) {
                diveMetric.valueList = track.trackData
                    .filter { dp in
                        if let landingTime = track.landingTime {
                            return dp.secondsFromStart <= landingTime
                        }
                        return true
                    }
                    .map { dp in
                        dp.glideRatio
                    }
            }

        // Dive angle and glide ratio - unitless, no conversion. Not used if we filter out value after landing as done above
/*        chartableMetrics.first(where: { $0.attributes == .dive })?.valueList =
            track.trackData.map { $0.diveAngle }
        chartableMetrics.first(where: { $0.attributes == .glide })?.valueList =
            track.trackData.map { $0.glideRatio }
*/
        // Distance (meters native)
        let distFactor = UnitsManager.conversionFactor(for: .distance, preference: preference)
        chartableMetrics.first(where: { $0.attributes == .hDist })?.valueList =
            track.trackData.map { $0.distance2D * distFactor }

        // Accelerations (meters native)
        chartableMetrics.first(where: { $0.attributes == .accelVertical })?.valueList =
            track.trackData.map { $0.accelVert * altFactor }
        chartableMetrics.first(where: { $0.attributes == .accelParallel })?.valueList =
            track.trackData.map { $0.accelParallel * altFactor }
        chartableMetrics.first(where: { $0.attributes == .accelPerp })?.valueList =
            track.trackData.map { $0.accelPerp * altFactor }
        chartableMetrics.first(where: { $0.attributes == .accelTotal })?.valueList =
            track.trackData.map { $0.accelTotal * altFactor }
    }

    
    /**
     Builds a LineChartDataSet for a given set of y-axis data using the track object
     
     - Parameters:
        - propertyData: Array of y-values
        - label: Name of the data
     
     - Returns: LineChartDataSet
     */
    func buildDataSetForNumericProperty(propertyData: [Double], label: String) -> LineChartDataSet {
            var values: [ChartDataEntry] = []
            
        let count = min(track.xRange.count, propertyData.count)
        for i in 0..<count {
            values.append(ChartDataEntry(x: Double(track.xRange[i]), y: Double(propertyData[i])))
        }

        
        let dataSet = LineChartDataSet(entries: values, label: label)
        
        dataSet.drawCirclesEnabled = false
        dataSet.drawValuesEnabled = false
        
        /// Only allow vertical mouseover line
        dataSet.drawHorizontalHighlightIndicatorEnabled = false
        dataSet.highlightColor = .systemRed
        
        return dataSet
    }
    
    /**
    Allows the user to toggle autoscaling of the y-axis
    
    - Parameters:
       - enabled:will y-axis autoscale?
    */
    func updateAutoScaleAxis() {
        if autoScaleEnabled {
            lineChartView.leftAxis.labelPosition = .insideChart
            lineChartView.rightAxis.labelPosition = .insideChart
        } else {
            lineChartView.leftAxis.labelPosition = .outsideChart
            lineChartView.rightAxis.labelPosition = .outsideChart
        }
        lineChartView.autoScaleMinMaxEnabled = autoScaleEnabled
    }
    
    /**
    Adds a vertical line on the chart at selected x position
    
    - Parameters:
       - location:xAxis locaiton of line
       - label: Oprional name of the data
    */
    func addVerticalLimitLine(location: Double, label: String="") {
        let limitLine = ChartLimitLine(limit: location, label: label)
        limitLine.lineWidth = 1
        limitLine.lineColor = .blue
        lineChartView.xAxis.addLimitLine(limitLine)
    }
    
    ///Remove any limit lines on the xAxis
    func clearVerticalLines() {
        lineChartView.xAxis.removeAllLimitLines()
        /// Force refresh
        lineChartView.animate(yAxisDuration: 0.00000001)
    }
    
    func cutToVisibleRange() {
        guard lineChartView.data != nil else { return }

        if originalTrack == nil {
            originalTrack = track.copy()
            isCutPublished = true
        }

        let visibleMinX = lineChartView.lowestVisibleX
        let visibleMaxX = lineChartView.highestVisibleX

        let sourceTrack = originalTrack ?? track

        let filteredTrackData = sourceTrack.trackData.filter { dp in
            dp.secondsFromStart >= visibleMinX && dp.secondsFromStart <= visibleMaxX
        }

        guard !filteredTrackData.isEmpty else { return }

        let cutTrack = Track()
        cutTrack.trackData = filteredTrackData
        cutTrack.xRange = filteredTrackData.map { $0.secondsFromStart }

        self.track = cutTrack
        for i in 0..<chartableMetrics.count {
            chartableMetrics[i].valueList = []
        }
        self.loadChartableMetrics()


        reloadTrack()
        updateAutoScaleAxis()
        lineChartView.notifyDataSetChanged()

        lineChartView.fitScreen()
    }

    func restoreOriginalTrack() {
        guard let original = originalTrack else { return }
        self.track = original
        originalTrack = nil
        reloadTrack()
        updateAutoScaleAxis()
        lineChartView.notifyDataSetChanged()
        isCutPublished = false
    }
    
    func shareTrack() {
        guard let originalURL = MainProcessor.instance.trackURL else { return }

        let tempDir = FileManager.default.temporaryDirectory
        let tempURL = tempDir.appendingPathComponent(originalURL.lastPathComponent)

        print("Original URL: \(originalURL.path)")
        print("Temp URL: \(tempURL.path)")

        do {
            // Remove existing temp file if any
            if FileManager.default.fileExists(atPath: tempURL.path) {
                try FileManager.default.removeItem(at: tempURL)
            }

            // Copy original file to temp directory
            try FileManager.default.copyItem(at: originalURL, to: tempURL)

            // Verify copied file exists
            guard FileManager.default.fileExists(atPath: tempURL.path) else {
                print("Copied file does not exist at temp location.")
                return
            }

            let itemProvider = NSItemProvider(contentsOf: tempURL)!
            itemProvider.registerFileRepresentation(forTypeIdentifier: "public.comma-separated-values-text", fileOptions: [], visibility: .all) { completion in
                completion(tempURL, true, nil)
                return nil
            }

            let activityVC = UIActivityViewController(activityItems: [itemProvider], applicationActivities: nil)
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let root = scene.windows.first?.rootViewController {
                root.present(activityVC, animated: true, completion: nil)
            }
        } catch {
            print("Error preparing file for sharing:", error)
        }
    }

}

/// Extension to add copy method to Track
extension Track {
    func copy() -> Track {
        let newTrack = Track()
        
        // Deep copy the DataPoint array using DataPoint.copy()
        newTrack.trackData = self.trackData.map { $0.copy() }
        
        // Copy other properties (assuming xRange is [Double])
        newTrack.xRange = self.xRange
        
        // Copy any other properties if needed
        
        return newTrack
    }
}
