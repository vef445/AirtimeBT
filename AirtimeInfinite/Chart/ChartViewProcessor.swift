//
//  ChartViewProcessor.swift
//  AirtimeInfinite
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
    
    /// 
    var track: Track = Track()
    
    let flightMetrics = [FlightMetric.alt,
                         FlightMetric.hVel,
                         FlightMetric.vVel,
                         FlightMetric.tVel,
                         FlightMetric.dive,
                         FlightMetric.glide,
                         FlightMetric.hDist]

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
        
        chartableMetrics.first(where: { $0.attributes == .alt })?.valueList =
            track.trackData.map { MainProcessor.instance.useImperialUnits ? $0.altitude.metersToFeet : $0.altitude }
        
        chartableMetrics.first(where: { $0.attributes == .hVel })?.valueList =
            track.trackData.map { MainProcessor.instance.useImperialUnits ?
                $0.horizontalSpeed.metersPerSecondToMPH : $0.horizontalSpeed.metersPerSecondToKMH}
        
        chartableMetrics.first(where: { $0.attributes == .vVel })?.valueList =
            track.trackData.map { MainProcessor.instance.useImperialUnits ?
                $0.velD.metersPerSecondToMPH : $0.velD.metersPerSecondToKMH }
        
        chartableMetrics.first(where: { $0.attributes == .tVel })?.valueList =
            track.trackData.map { MainProcessor.instance.useImperialUnits ?
            $0.totalSpeed.metersPerSecondToMPH : $0.totalSpeed.metersPerSecondToKMH}
        
        chartableMetrics.first(where: { $0.attributes == .dive })?.valueList =
            track.trackData.map { $0.diveAngle }
        
        chartableMetrics.first(where: { $0.attributes == .glide })?.valueList =
            track.trackData.map { $0.glideRatio }
        
        chartableMetrics.first(where: { $0.attributes == .hDist })?.valueList =
            track.trackData.map { MainProcessor.instance.useImperialUnits ? $0.distance2D.metersToFeet : $0.distance2D }
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
        
        for i in 0..<track.xRange.count {
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
}
