//
//  ChartFrame.swift
//  AirtimeBT
//
//  Created by Jordan Gould on 6/18/20.
//  Updated to remove embedded button toolbar.
//  © 2020 Jordan Gould. All rights reserved.
//

import SwiftUI

/// View containing the primary chart content (no floating buttons)
struct ChartFrame: View {
    
    @EnvironmentObject var main: MainProcessor
    @Binding var showingMetricSelectionMenu: Bool
    @Binding var showChartToolbar: Bool
    @Binding var buttonsVisible: Bool
    @Binding var bottomViewMode: ContentView.BottomViewMode

    @State private var showChart = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if showChart {
                    ChartView()
                } else {
                    Color.clear
                }
            }
            .onAppear {
                // Delay to allow slide-in animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showChart = true
                    buttonsVisible = showChartToolbar
                }
            }
            .onChange(of: showChartToolbar) { newValue in
                buttonsVisible = newValue
            }
        }
    }
}
