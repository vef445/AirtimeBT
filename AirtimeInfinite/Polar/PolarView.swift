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
        // Replace useImperial boolean with unitPreference
        let unitPreference = main.unitPreference  // assuming you have this on main

        let lowestVisibleX = main.chartViewProcessor.lineChartView.lowestVisibleX
        let highestVisibleX = main.chartViewProcessor.lineChartView.highestVisibleX

        guard lowestVisibleX.isFinite, highestVisibleX.isFinite, lowestVisibleX < highestVisibleX else {
            return
        }

        let visibleRange = lowestVisibleX...highestVisibleX

        // Pass unitPreference instead of useImperial boolean
        main.polarViewProcessor.loadTrack(
            track: track,
            visibleRange: visibleRange,
            unitPreference: unitPreference,
            highlightedPoint: main.highlightedPoint.point
        )
    }

}
