//
//  ChartFrame.swift
//  AirtimeInfinite
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
    
    var body: some View{
        ZStack {
            ChartView()
            HStack{
                Spacer()
                VStack{
                    
                    /// Unit selection button
                    Button(action: {
                        self.main.useImperialUnits.toggle()
                        self.main.chartViewProcessor.reloadTrack()
                    }) {
                        Image(self.main.useImperialUnits ? "flag" :  "globe")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 35)
                    .padding(.top, 25)
                    
                    /// Data selection button
                    Button(action: {
                        self.showingMetricSelectionMenu = true
                    }) {
                        Image("line-chart")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 35)
                    .padding(.top, 7)
                    
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
                    .padding(.horizontal, 35)
                    .padding(.top, 10)
                    
                    
                    Spacer()
                }
            }
        }
    }
}
