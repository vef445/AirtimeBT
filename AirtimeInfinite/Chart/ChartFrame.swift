//
//  ChartFrame.swift
//  AirtimeBT
//
//  Created by Jordan Gould on 6/18/20.
//  Copyright © 2020 Jordan Gould. All rights reserved.
//

import SwiftUI

/// View containing all Chart content
struct ChartFrame: View {
    
    @EnvironmentObject var main: MainProcessor
    @Binding var showingMetricSelectionMenu: Bool
    @Binding var showChartToolbar: Bool
    @Binding var buttonsVisible: Bool
    @Binding var showPolarView: Bool
    
    @State private var pinSelection = false
    @State private var showChart = false

    
    
    let support_url = "https://github.com/vef445/AirtimeBT"
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if showChart {
                    ChartView()
                } else {
                    Color.clear
                }
                
                        Spacer()

                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        // Your six buttons here...
                        Button(action: {
                            let urlComponents = URLComponents(string: self.support_url)!
                            UIApplication.shared.open(urlComponents.url!)
                        }) {
                            Image(systemName: "questionmark.circle")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.primary)
                        }

                        Button(action: {
                            self.showingMetricSelectionMenu = true
                        }) {
                            Image(systemName: "gear")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.primary)
                        }

                        Button(action: {
                            self.pinSelection.toggle()
                            self.main.selectedMeasurePoint.isActive = self.pinSelection
                            if self.pinSelection {
                                self.main.selectedMeasurePoint.point = self.main.highlightedPoint.point
                                if let selectedMeasurePosition = self.main.selectedMeasurePoint.point?.secondsFromStart {
                                    self.main.chartViewProcessor.addVerticalLimitLine(location: selectedMeasurePosition)
                                }
                            } else {
                                self.main.chartViewProcessor.clearVerticalLines()
                                self.main.mapViewProcessor.removeMeasurementOverlay()
                            }
                        }) {
                            Image("ruler")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(self.pinSelection ? .blue : .primary)
                        }

                        Button(action: {
                            main.chartViewProcessor.cutToVisibleRange()
                        }) {
                            Image(systemName: "scissors")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 30, height: 30)
                                .foregroundColor(main.chartViewProcessor.isCut ? .blue : .primary)
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
                    
                    Button(action: {
                        showPolarView.toggle()
                    }) {
                        Image(systemName: showPolarView ? "map" : "chart.xyaxis.line")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 30)
                            .foregroundColor(.primary)
                    }
                    .accessibilityLabel("Toggle chart/map view")
                }
                    .padding()
                        .background(Color.gray.opacity(0.4))
                        .clipShape(Capsule())
                        .padding(.top, 25)
                        .padding(.trailing, 20)
                        .frame(maxWidth: .infinity, alignment: .trailing) // Keep aligned right
                        .offset(x: buttonsVisible ? 0 : 120) // Slide off by approx button width + padding
                        .animation(.easeInOut(duration: 0.8), value: buttonsVisible)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showChart = true
                    buttonsVisible = showChartToolbar
                }
            }
              
            .onChange(of: showChartToolbar) { newValue in
                buttonsVisible = newValue // slide in/out based on toolbar state
            }
        }
    }
}
