//
//  ContentView.swift
//  AirtimeBT
//
//  Created by Jordan Gould on 6/18/20.
//  Copyright © 2020 Jordan Gould. All rights reserved.
//

import SwiftUI

/// Primary view displaying all data visualiztion views
import SwiftUI

/// Primary view displaying all data visualiztion views
struct ContentView: View {
    
    @State private var showChartToolbar = true
    @State var isShowingPicker = false
    @State var showingMetricSelectionMenu = false
    @State var orientation = UIDevice.current.orientation
    @State private var buttonsVisible = true
    @State private var showUnits = false
    @State private var showValues = true

    
    @EnvironmentObject var main: MainProcessor
    
    let isPad = UIDevice.current.userInterfaceIdiom == .pad
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomTrailing) {
                /// Dim background when needed
                Color.gray
                    .opacity((self.showingMetricSelectionMenu || self.main.isLoading) ? 0.5 : 0.0)
                    .edgesIgnoringSafeArea(.all)
                    .animation(.linear, value: showingMetricSelectionMenu || main.isLoading)
                
                LoadingView(isShowing: self.$main.isLoading) {
                    ZStack {
                        if geo.size.height > geo.size.width {
                            // Portrait
                            VStack {
                                DataPointView(showValues: $showValues,
                                              isMultiRow: !isPad,
                                              showAcceleration: main.showAcceleration)
                                    .padding(.horizontal, 10)
                                    .padding(.top, 5)
                                    .frame(height: isPad ? 45 : 90)
                                    .gesture(
                                        DragGesture(minimumDistance: 0)
                                            .onChanged { _ in
                                                showUnits = true
                                            }
                                            .onEnded { _ in
                                                showUnits = false
                                            }
                                    )
                                
                                VPart(top: {
                                    ChartFrame(
                                        showingMetricSelectionMenu: $showingMetricSelectionMenu,
                                        showChartToolbar: $showChartToolbar,
                                        buttonsVisible: $buttonsVisible
                                    )

                                }) {
                                    MapView()
                                }
                                .edgesIgnoringSafeArea(.bottom)
                            }
                        } else {
                            // Landscape
                            VStack {
                                DataPointView(showValues: $showValues,
                                              isMultiRow: false,
                                              showAcceleration: main.showAcceleration)
                                    .padding(.horizontal, 4)
                                    .frame(height: 45)
                                
                                HPart(left: {
                                    ChartFrame(
                                        showingMetricSelectionMenu: $showingMetricSelectionMenu,
                                        showChartToolbar: $showChartToolbar,
                                        buttonsVisible: $buttonsVisible
                                    )
                                }) {
                                    MapView()
                                }
                                .edgesIgnoringSafeArea(.trailing)
                                .edgesIgnoringSafeArea(.bottom)
                            }
                        }
                        
                        // Chart settings menu
                        ChartSettingsView(showingMetricSelectionMenu: $showingMetricSelectionMenu)
                            .environmentObject(main)
                            .background(Color(.secondarySystemBackground))
                            .edgesIgnoringSafeArea(.all)
                            .cornerRadius(20)
                            .shadow(radius: 20)
                            .frame(width: 300, height: 300)
                            .padding()
                            .offset(y: showingMetricSelectionMenu ? 0 : 1000)
                            .animation(.linear, value: showingMetricSelectionMenu)
                    }
                }
                
                /// 👇 Load & Menu Button
                UnifiedLoadButtonGroup(showChartToolbar: self.$showChartToolbar)
                    .environmentObject(main)
                    .padding(.trailing, geo.size.width > geo.size.height ? 0 : 20) // smaller gap in landscape, bigger in portrait
                    .padding(.bottom, 12)
                    .ignoresSafeArea(.container, edges: geo.size.width > geo.size.height ? .trailing : [])
            }
            .onChange(of: main.trackLoadedSuccessfully) { loaded in
                if loaded {
                    showChartToolbar = false
                    DispatchQueue.main.async {
                        main.trackLoadedSuccessfully = false
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(MainProcessor())
    }
}
