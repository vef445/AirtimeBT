//
//  PolarView.swift
//  Airtime BT
//
//  Created by Guillaume Vigneron on 26/06/2025.
//  Copyright © 2025 Guillaume Vigneron. All rights reserved.
//

import SwiftUI
import DGCharts

/// A read-only chart plotting Vertical Speed vs Horizontal Speed
struct PolarView: UIViewRepresentable {

    @EnvironmentObject var main: MainProcessor

    func makeUIView(context: Context) -> CombinedChartView {
        let chartView = CombinedChartView()
        
        chartView.backgroundColor = UIColor.systemBackground

        // Disable all user interaction
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

        // Add X axis title label ABOVE the chart
                let xAxisLabel = UILabel()
                xAxisLabel.text = "Horizontal Speed"
                xAxisLabel.font = UIFont.systemFont(ofSize: 12)
                xAxisLabel.textAlignment = .center
                xAxisLabel.textColor = .label
                xAxisLabel.translatesAutoresizingMaskIntoConstraints = false
                chartView.addSubview(xAxisLabel)

                // Constraints for X axis label: center horizontally, place just above chart
                NSLayoutConstraint.activate([
                    xAxisLabel.centerXAnchor.constraint(equalTo: chartView.centerXAnchor),
                    xAxisLabel.bottomAnchor.constraint(equalTo: chartView.topAnchor, constant: 34)
                ])

                // Add Y axis title label (rotated)
                let yAxisLabel = UILabel()
                yAxisLabel.text = "Vertical Speed"
                yAxisLabel.font = UIFont.systemFont(ofSize: 12)
                yAxisLabel.textColor = .label
                yAxisLabel.textAlignment = .center
                yAxisLabel.translatesAutoresizingMaskIntoConstraints = false
                yAxisLabel.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
                chartView.addSubview(yAxisLabel)

                // Constraints for Y axis label: center vertically, place to left of chart
                NSLayoutConstraint.activate([
                    yAxisLabel.centerYAnchor.constraint(equalTo: chartView.centerYAnchor),
                    yAxisLabel.leadingAnchor.constraint(equalTo: chartView.leadingAnchor, constant: 0)
                ])

        return chartView
    }



    func updateUIView(_ chartView: CombinedChartView, context: Context) {
        let track = main.chartViewProcessor.track
        let useImperial = main.useImperialUnits

        let visibleMinX = main.chartViewProcessor.lineChartView.lowestVisibleX
        let visibleMaxX = main.chartViewProcessor.lineChartView.highestVisibleX

        let filteredPoints = track.trackData.filter { point in
            point.secondsFromStart >= visibleMinX && point.secondsFromStart <= visibleMaxX
        }

        guard !filteredPoints.isEmpty else {
            chartView.data = nil
            return
        }

        // Main line entries
        let lineEntries: [ChartDataEntry] = filteredPoints.map { point in
            let hSpeed = useImperial ? point.horizontalSpeed.metersPerSecondToMPH : point.horizontalSpeed.metersPerSecondToKMH
            let vSpeed = useImperial ? point.velD.metersPerSecondToMPH : point.velD.metersPerSecondToKMH
            return ChartDataEntry(x: hSpeed, y: vSpeed)
        }

        let lineDataSet = LineChartDataSet(entries: lineEntries, label: "")
        lineDataSet.colors = [NSUIColor.purple]
        lineDataSet.drawCirclesEnabled = false
        lineDataSet.drawValuesEnabled = false
        lineDataSet.lineWidth = 1.0
        lineDataSet.axisDependency = .left

        // Marker dataset - single point scatter
        var markerEntries: [ChartDataEntry] = []
        if let selectedPoint = main.highlightedPoint.point {
            let hSpeed = useImperial ? selectedPoint.horizontalSpeed.metersPerSecondToMPH : selectedPoint.horizontalSpeed.metersPerSecondToKMH
            let vSpeed = useImperial ? selectedPoint.velD.metersPerSecondToMPH : selectedPoint.velD.metersPerSecondToKMH
            markerEntries.append(ChartDataEntry(x: hSpeed, y: vSpeed))
        }

        let markerDataSet = ScatterChartDataSet(entries: markerEntries, label: "")
        markerDataSet.setColor(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? .white : .black
        })
        markerDataSet.setScatterShape(.circle)
        markerDataSet.scatterShapeSize = 10
        markerDataSet.drawValuesEnabled = false

        // Combine both datasets into the chart data
        let combinedData = CombinedChartData()
        combinedData.lineData = LineChartData(dataSet: lineDataSet)
        combinedData.scatterData = ScatterChartData(dataSet: markerDataSet)

        chartView.data = combinedData

        chartView.xAxis.valueFormatter = DefaultAxisValueFormatter(decimals: 0)
        chartView.leftAxis.valueFormatter = DefaultAxisValueFormatter(decimals: 0)

        if let selectedPoint = main.highlightedPoint.point, !markerEntries.isEmpty {
            let hSpeed = useImperial ? selectedPoint.horizontalSpeed.metersPerSecondToMPH : selectedPoint.horizontalSpeed.metersPerSecondToKMH
            let vSpeed = useImperial ? selectedPoint.velD.metersPerSecondToMPH : selectedPoint.velD.metersPerSecondToKMH

            let dataSetIndex = 1  // scatter dataset
            let dataIndex = 0     // only one entry

            let highlight = Highlight(x: hSpeed, y: vSpeed, dataSetIndex: dataSetIndex, dataIndex: dataIndex)
            chartView.highlightValue(highlight, callDelegate: false)

            // No custom marker, so just clear any existing marker
            chartView.marker = nil
        } else {
            chartView.marker = nil
            chartView.highlightValue(nil)
        }

        chartView.setNeedsDisplay()
    }
}
