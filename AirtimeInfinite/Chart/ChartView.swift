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
        if let data = view.data,
           let firstEntry = data.dataSets.first?.entryForIndex(0) {
            view.xAxis.axisMinimum = firstEntry.x
        }

        // Remove all existing limit lines before re-adding
        view.xAxis.removeAllLimitLines()

        /*
        // Add Swoop Start limit line
        if let swoopStartIndex = main.track.calculateSwoopStartIndex(in: main.track.trackData),
           swoopStartIndex >= 0,
           swoopStartIndex < main.track.trackData.count {
            let swoopStartPoint = main.track.trackData[swoopStartIndex]
            let swoopStartX = swoopStartPoint.secondsFromStart

            let limitLine = ChartLimitLine(limit: swoopStartX, label: "Swoop Start")
            limitLine.lineColor = .systemRed
            limitLine.lineWidth = 2
            limitLine.lineDashLengths = [4, 2]
            limitLine.labelPosition = .rightBottom
            limitLine.valueFont = .systemFont(ofSize: 10)

            view.xAxis.addLimitLine(limitLine)
        }
         */

        // ✅ Re-add Measurement marker (your blue line)
        if main.selectedMeasurePoint.isActive,
               let measureX = main.selectedMeasurePoint.point?.secondsFromStart {
                let measureLine = ChartLimitLine(limit: measureX, label: "")
                measureLine.lineColor = .systemBlue
                measureLine.lineWidth = 2
                view.xAxis.addLimitLine(measureLine)
            }

        // Restore highlight if needed
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
        var previousX: Double? = nil

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
            guard let chart = chartView as? BarLineChartViewBase else { return }

            let visibleMinX = chart.lowestVisibleX
            let visibleMaxX = chart.highestVisibleX
            let visibleRange = visibleMinX...visibleMaxX
            
            // Update visible range in main processor, so polar chart updates too
            DispatchQueue.main.async {
                self.parent.main.updateVisibleRange(visibleRange)
                self.parent.main.isDragging = false
            }

            // Existing map update logic:
            let trackCoordinates = parent.main.track.getTrackCoordinatesFromSecondsBounds(
                firstIndex: visibleMinX,
                lastIndex: visibleMaxX
            )

            if !trackCoordinates.isEmpty {
                parent.main.mapViewProcessor.setMapRegion(trackCoordinates: trackCoordinates)
            }
        }
        
        public func chartViewDidEndZooming(_ chartView: ChartViewBase, scaleX: CGFloat, scaleY: CGFloat) {
            guard let chart = chartView as? BarLineChartViewBase else { return }

            let visibleMinX = chart.lowestVisibleX
            let visibleMaxX = chart.highestVisibleX
            let visibleRange = visibleMinX...visibleMaxX

            DispatchQueue.main.async {
                self.parent.main.updateVisibleRange(visibleRange)
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
        if let data = chartView.data,
           let firstEntry = data.dataSets.first?.entryForIndex(0) {
            chartView.xAxis.axisMinimum = firstEntry.x
        }

        main.chartViewProcessor.updateAutoScaleAxis()
    }
}
