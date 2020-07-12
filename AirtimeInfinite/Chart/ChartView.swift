//
//  ChartView.swift
//  AirtimeInfinite
//
//  Created by Jordan Gould on 6/18/20.
//  Copyright © 2020 Jordan Gould. All rights reserved.
//

import SwiftUI
import Charts

/// View representing the actual chart object
struct ChartView: UIViewRepresentable {
    
    @EnvironmentObject var main: MainProcessor
    
    func makeUIView(context: Context) -> LineChartView {
        main.chartViewProcessor.lineChartView.delegate = context.coordinator
        prepareChart()
        return main.chartViewProcessor.lineChartView
    }

    func updateUIView(_ view: LineChartView, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, ChartViewDelegate {
        var parent: ChartView

        init(_ parent: ChartView) {
            self.parent = parent
        }
        
        /// Update the datapoint on the map and data view when user touches 
        public func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
            parent.main.highlightedPoint.setPointFromSecondsProperty(seconds: entry.x)
            if let hPoint = parent.main.highlightedPoint.point {
                parent.main.mapViewProcessor.addSelectedDataPoint(dataPoint: hPoint)
                /// If measuring, update highlight
                if let mPoint = parent.main.selectedMeasurePoint.point {
                    if parent.main.selectedMeasurePoint.isActive {
                        parent.main.mapViewProcessor.addMeasurementOverlay(
                            startMeasure: hPoint.secondsFromStart,
                            endMeasure: mPoint.secondsFromStart)
                    }
                }
            }
        }
        
        /// Match the region visible in the map to the visible chart area
        public func chartViewDidEndPanning(_ chartView: ChartViewBase) {
            /// Converted to provide x bounds vars, will always be a subclass of BarLineChartViewBase
            let chart = chartView as! BarLineChartViewBase
            let track = parent.main.track
            let trackCoordinates = track.getTrackCoordinatesFromSecondsBounds(firstIndex: chart.lowestVisibleX, lastIndex: chart.highestVisibleX)
            if !trackCoordinates.isEmpty{
                parent.main.mapViewProcessor.setMapRegion(trackCoordinates: trackCoordinates)
            }
        }
    }
    
    // Future Todo: Show side profile of flight path for BASE?
    /// Initialize the preferred chart settings (e.g. Description, axis settings, etc.)
    func prepareChart() {
        let chartView = main.chartViewProcessor.lineChartView
        chartView.noDataText = "Press + to load a track."
        chartView.noDataFont = NSUIFont.systemFont(ofSize: 20)
        chartView.rightAxis.enabled = true
        chartView.xAxis.enabled = true
        chartView.xAxis.drawGridLinesEnabled = false
        chartView.xAxis.drawLabelsEnabled = false
        chartView.xAxis.drawAxisLineEnabled = false
        chartView.leftAxis.drawGridLinesEnabled = false
        chartView.xAxis.labelPosition = XAxis.LabelPosition.bottom
        chartView.legend.enabled = false
        
        main.chartViewProcessor.updateAutoScaleAxis()
    }
}
