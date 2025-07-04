//
//  PolarViewProcessor.swift
//  Airtime BT
//
//  Created by Guillaume Vigneron on 27/06/2025.
//  Copyright © 2025 Guillaume Vigneron. All rights reserved.
//

import DGCharts
import UIKit

class PolarViewProcessor {

    let chartView: CombinedChartView

    init() {
        chartView = CombinedChartView()

        chartView.backgroundColor = UIColor.systemBackground

        // Disable all gestures
        chartView.pinchZoomEnabled = false
        chartView.doubleTapToZoomEnabled = false
        chartView.dragEnabled = false
        chartView.scaleXEnabled = false
        chartView.scaleYEnabled = false
        chartView.highlightPerTapEnabled = false
        chartView.highlightPerDragEnabled = false
        chartView.legend.enabled = false
        chartView.rightAxis.enabled = false

        // Axis styling
        chartView.xAxis.drawLabelsEnabled = true
        chartView.xAxis.labelPosition = .top
        chartView.xAxis.drawGridLinesEnabled = true
        chartView.leftAxis.drawGridLinesEnabled = true
        chartView.leftAxis.labelFont = .systemFont(ofSize: 12)
        chartView.leftAxis.inverted = true
        chartView.xAxis.labelFont = .systemFont(ofSize: 12)
        chartView.xAxis.granularityEnabled = true
        chartView.xAxis.granularity = 1.0

        chartView.noDataText = "No data in current time range."
        chartView.noDataFont = .systemFont(ofSize: 16)
        chartView.clipDataToContentEnabled = false

        // X axis title label ABOVE the chart
        let xAxisLabel = UILabel()
        xAxisLabel.text = "Horizontal Speed"
        xAxisLabel.font = UIFont.systemFont(ofSize: 12)
        xAxisLabel.textAlignment = .center
        xAxisLabel.textColor = .label
        xAxisLabel.translatesAutoresizingMaskIntoConstraints = false
        chartView.addSubview(xAxisLabel)

        NSLayoutConstraint.activate([
            xAxisLabel.centerXAnchor.constraint(equalTo: chartView.centerXAnchor),
            xAxisLabel.bottomAnchor.constraint(equalTo: chartView.topAnchor, constant: 34)
        ])

        // Y axis title label (rotated)
        let yAxisLabel = UILabel()
        yAxisLabel.text = "Vertical Speed"
        yAxisLabel.font = UIFont.systemFont(ofSize: 12)
        yAxisLabel.textColor = .label
        yAxisLabel.textAlignment = .center
        yAxisLabel.translatesAutoresizingMaskIntoConstraints = false
        yAxisLabel.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
        chartView.addSubview(yAxisLabel)

        NSLayoutConstraint.activate([
            yAxisLabel.centerYAnchor.constraint(equalTo: chartView.centerYAnchor),
            yAxisLabel.leadingAnchor.constraint(equalTo: chartView.leadingAnchor)
        ])
    }

    func loadTrack(track: Track, visibleRange: ClosedRange<Double>, unitPreference: MainProcessor.UnitPreference, highlightedPoint: DataPoint?) {
            let filteredPoints = track.trackData.filter {
                $0.secondsFromStart >= visibleRange.lowerBound && $0.secondsFromStart <= visibleRange.upperBound
            }

            guard !filteredPoints.isEmpty else {
                chartView.data = nil
                return
            }

            let lineEntries = filteredPoints.map { point -> ChartDataEntry in
                let hSpeed = UnitsManager.convertedSpeed(fromMS: point.horizontalSpeed, preference: unitPreference)
                let vSpeed = UnitsManager.convertedSpeed(fromMS: point.velD, preference: unitPreference)
                return ChartDataEntry(x: hSpeed, y: vSpeed)
            }

            let lineDataSet = LineChartDataSet(entries: lineEntries, label: "")
            lineDataSet.colors = [NSUIColor.purple]
            lineDataSet.drawCirclesEnabled = false
            lineDataSet.drawValuesEnabled = false
            lineDataSet.lineWidth = 1.0
            lineDataSet.axisDependency = .left

            var markerEntries: [ChartDataEntry] = []
            if let selectedPoint = highlightedPoint {
                let hSpeed = UnitsManager.convertedSpeed(fromMS: selectedPoint.horizontalSpeed, preference: unitPreference)
                let vSpeed = UnitsManager.convertedSpeed(fromMS: selectedPoint.velD, preference: unitPreference)
                markerEntries.append(ChartDataEntry(x: hSpeed, y: vSpeed))
            }

            let markerDataSet = ScatterChartDataSet(entries: markerEntries, label: "")
            markerDataSet.setColor(UIColor { $0.userInterfaceStyle == .dark ? .white : .black })
            markerDataSet.setScatterShape(.circle)
            markerDataSet.scatterShapeSize = 10
            markerDataSet.drawValuesEnabled = false

        // Reference lines (example slopes)
        let maxH = lineEntries.map { $0.x }.max() ?? 100
        let maxV = lineEntries.map { $0.y }.max() ?? 100

        let referenceLines = [
            createClippedReferenceLine(slope: 1.0, intercept: 0, maxX: maxH, maxY: maxV),
            createClippedReferenceLine(slope: 1/3, intercept: 0, maxX: maxH, maxY: maxV),
            createClippedReferenceLine(slope: 0.5, intercept: 0, maxX: maxH, maxY: maxV)
        ]

        let combinedData = CombinedChartData()
        combinedData.lineData = LineChartData(dataSets: [lineDataSet] + referenceLines)
        combinedData.scatterData = ScatterChartData(dataSet: markerDataSet)

        chartView.data = combinedData

        chartView.xAxis.valueFormatter = DefaultAxisValueFormatter(decimals: 0)
        chartView.leftAxis.valueFormatter = DefaultAxisValueFormatter(decimals: 0)

        // Highlight point if available
        if !markerEntries.isEmpty {
            let highlight = Highlight(x: markerEntries[0].x, y: markerEntries[0].y, dataSetIndex: 0)
            chartView.highlightValue(highlight, callDelegate: false)
        } else {
            chartView.highlightValue(nil)
        }

        chartView.setNeedsDisplay()
    }

    private func createClippedReferenceLine(slope: Double, intercept: Double, maxX: Double, maxY: Double) -> LineChartDataSet {
        var points: [ChartDataEntry] = []

        let yAtMaxX = slope * maxX + intercept
        let xAtMaxY = (maxY - intercept) / slope

        if yAtMaxX <= maxY {
            points = [ChartDataEntry(x: 0, y: intercept), ChartDataEntry(x: maxX, y: yAtMaxX)]
        } else if xAtMaxY <= maxX {
            points = [ChartDataEntry(x: 0, y: intercept), ChartDataEntry(x: xAtMaxY, y: maxY)]
        } else {
            points = [ChartDataEntry(x: 0, y: intercept), ChartDataEntry(x: maxX, y: maxY)]
        }

        let dataSet = LineChartDataSet(entries: points, label: "")
        dataSet.colors = [NSUIColor.gray.withAlphaComponent(0.5)]
        dataSet.lineWidth = 1
        dataSet.drawCirclesEnabled = false
        dataSet.drawValuesEnabled = false
        dataSet.lineDashLengths = [4, 2]
        dataSet.axisDependency = .left
        return dataSet
    }
}
