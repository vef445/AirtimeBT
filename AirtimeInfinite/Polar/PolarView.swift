import SwiftUI
import DGCharts

struct PolarView: UIViewRepresentable {

    @EnvironmentObject var main: MainProcessor

    func makeUIView(context: Context) -> CombinedChartView {
        // Use the processor's existing chartView
        main.polarViewProcessor.chartView
    }

    func updateUIView(_ uiView: CombinedChartView, context: Context) {
        let track = main.chartViewProcessor.track
        let useImperial = main.useImperialUnits

        let lowestVisibleX = main.chartViewProcessor.lineChartView.lowestVisibleX
        let highestVisibleX = main.chartViewProcessor.lineChartView.highestVisibleX

        // Check for NaN or invalid ranges
        guard lowestVisibleX.isFinite, highestVisibleX.isFinite, lowestVisibleX < highestVisibleX else {

            return
        }

        let visibleRange = lowestVisibleX...highestVisibleX

        // Always update polar chart data
        main.polarViewProcessor.loadTrack(track: track, visibleRange: visibleRange, useImperial: useImperial, highlightedPoint: main.highlightedPoint.point)
    }

}
