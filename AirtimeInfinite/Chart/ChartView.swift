//
//  ChartView.swift
//  AirtimeBT
//
//  Created by Jordan Gould on 6/18/20.
//  Copyright © 2020 Jordan Gould. All rights reserved.
//

import SwiftUI
import DGCharts

struct ChartView: UIViewRepresentable {
    
    @EnvironmentObject var main: MainProcessor
    
    func makeUIView(context: Context) -> LineChartView {
        let chartView = main.chartViewProcessor.lineChartView
        chartView.delegate = context.coordinator
        prepareChart()
        // Enable highlight on tap and drag so delegate methods fire properly
        chartView.highlightPerTapEnabled = true
        chartView.highlightPerDragEnabled = true
        return chartView
    }

    func updateUIView(_ view: LineChartView, context: Context) {
        if let highlight = context.coordinator.lastHighlight {
            view.highlightValue(highlight, callDelegate: false)
        }
    }

    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, ChartViewDelegate {
        var parent: ChartView
        var lastHighlight: Highlight? = nil

        init(_ parent: ChartView) {
            self.parent = parent
        }
        
        /// Called when user touches a value
        public func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
            lastHighlight = highlight
            parent.main.highlightedPoint.setPointFromSecondsProperty(seconds: entry.x)
            
            if let hPoint = parent.main.highlightedPoint.point {
                parent.main.mapViewProcessor.addSelectedDataPoint(dataPoint: hPoint)
                
                // Update measurement overlay if active
                if let mPoint = parent.main.selectedMeasurePoint.point,
                   parent.main.selectedMeasurePoint.isActive {
                    parent.main.mapViewProcessor.addMeasurementOverlay(
                        startMeasure: hPoint.secondsFromStart,
                        endMeasure: mPoint.secondsFromStart)
                }
            }
        }
        
        /// Called when touch ends and no value is selected
        public func chartValueNothingSelected(_ chartView: ChartViewBase) {
            // Reapply the last highlight to keep the highlight visible
            if let last = lastHighlight {
                chartView.highlightValue(last)
            }
            // Otherwise do nothing and keep UI stable
        }

        /// Called when panning ends, adjust visible map region and highlight point
        public func chartViewDidEndPanning(_ chartView: ChartViewBase) {
            let chart = chartView as! BarLineChartViewBase
            let seconds = chart.lowestVisibleX

            // Update highlight point on pan end
            //parent.main.highlightedPoint.setPointFromSecondsProperty(seconds: seconds)
            
            let track = parent.main.track
            let trackCoordinates = track.getTrackCoordinatesFromSecondsBounds(
                firstIndex: chart.lowestVisibleX,
                lastIndex: chart.highestVisibleX
            )
            
            if !trackCoordinates.isEmpty {
                parent.main.mapViewProcessor.setMapRegion(trackCoordinates: trackCoordinates)
            }
        }
    }
    
    func prepareChart() {
        let chartView = main.chartViewProcessor.lineChartView
        chartView.noDataText = "Please load a track."
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
