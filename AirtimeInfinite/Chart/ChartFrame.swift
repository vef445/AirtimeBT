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
    
    @State private var pinSelection = false
    @State private var showChart = false
    
    let support_url = "https://github.com/vef445/AirtimeBT"
    
    var body: some View {
        ZStack {
            if showChart {
                ChartView()
            } else {
                Color.clear
            }
            HStack {
                Spacer()
                VStack{
                    
                    /// Link to docs button
                    Button(action: {
                        let urlComponents = URLComponents (string: self.support_url)!
                        UIApplication.shared.open (urlComponents.url!)
                    }) {
                        Image(systemName: "questionmark.circle")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 25)
                    
                    /// Chart Settings button
                    Button(action: {
                        self.showingMetricSelectionMenu = true
                    }) {
                        Image(systemName: "gear")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 10)
                    
                    /// Selected measurement point button
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
                            .foregroundColor(self.pinSelection ? .blue : .gray)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 10)
                    
                    Spacer()
                }
            }
        }
        .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showChart = true
                    }
                }
            }
        }
