//
//  ChartButtonsView.swift
//  Airtime BT
//
//  Created by Guillaume Vigneron on 28/06/2025.
//  Copyright © 2025 Guillaume Vigneron. All rights reserved.
//

import SwiftUI

struct ChartButtonsView: View {
    @Binding var buttonsVisible: Bool
    @Binding var showingMetricSelectionMenu: Bool
    @Binding var bottomViewMode: ContentView.BottomViewMode
    @Binding var isLandscape: Bool
    @EnvironmentObject var main: MainProcessor
    
    @State private var pinSelection = false

    
    let support_url = "https://github.com/vef445/AirtimeBT"
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: {
                let urlComponents = URLComponents(string: support_url)!
                UIApplication.shared.open(urlComponents.url!)
            }) {
                Image(systemName: "questionmark.circle")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.primary)
            }
            
            Button(action: {
                showingMetricSelectionMenu = true
                buttonsVisible = false    // Hide the button stack
            }) {
                Image(systemName: "gear")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.primary)
            }

            
            Button(action: {
                pinSelection.toggle()
                main.selectedMeasurePoint.isActive = pinSelection
                if pinSelection {
                    main.selectedMeasurePoint.point = main.highlightedPoint.point
                    if let pos = main.selectedMeasurePoint.point?.secondsFromStart {
                        main.chartViewProcessor.addVerticalLimitLine(location: pos)
                    }
                } else {
                    main.chartViewProcessor.clearVerticalLines()
                    main.mapViewProcessor.removeMeasurementOverlay()
                }
            }) {
                Image("ruler")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(pinSelection ? .blue : .primary)
            }
            
            Button(action: {
                main.chartViewProcessor.cutToVisibleRange()
            }) {
                Image(systemName: "lock")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30)
                    .foregroundColor(main.chartViewProcessor.isCutPublished ? .blue : .primary)
            }
            .accessibilityLabel("Cut to zoomed range")
            
            Button(action: {
                main.chartViewProcessor.restoreOriginalTrack()
            }) {
                Image(systemName: "arrow.clockwise")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30)
                    .foregroundColor(.primary)
            }
            .accessibilityLabel("Restore full chart")
            
            Button(action: {
                main.chartViewProcessor.shareTrack()
            }) {
                Image(systemName: "square.and.arrow.up")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30)
                    .foregroundColor(.primary)
            }
            .disabled(main.chartViewProcessor.track.trackData.isEmpty)
            .accessibilityLabel("Share your track")
            
        }
        .padding()
        .background(Color.gray.opacity(0.6))
        .clipShape(Capsule())
        .padding(.top, 15)
        .padding(.trailing, 20)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .offset(x: buttonsVisible ? 0 : (isLandscape ? -120 : 120))
        .animation(.easeInOut(duration: 0.6), value: buttonsVisible)
    }
}
