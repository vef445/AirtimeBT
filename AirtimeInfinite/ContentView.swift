//
//  ContentView.swift
//  AirtimeBT
//
//  Created by Jordan Gould on 6/18/20.
//  Copyright © 2020 Jordan Gould. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    
    @State private var showChartToolbar = true
    @State var isShowingPicker = false
    @State var showingMetricSelectionMenu = false
    @State var orientation = UIDevice.current.orientation
    @State private var buttonsVisible = true
    @State private var showUnits = false
    @State private var showValues = true
    @State private var leftViewportWidth: CGFloat = 0
    
    enum BottomViewMode {
        case map
        case polar
        case fastestDescent
    }

    @State private var bottomViewMode: BottomViewMode = .map

    @EnvironmentObject var main: MainProcessor
    
    let isPad = UIDevice.current.userInterfaceIdiom == .pad
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomTrailing) {
                
                // Dim background when needed
                Color.gray
                    .opacity((showingMetricSelectionMenu || main.isLoading) ? 0.5 : 0.0)
                    .edgesIgnoringSafeArea(.all)
                    .animation(.linear, value: showingMetricSelectionMenu || main.isLoading)
                
                LoadingView(isShowing: $main.isLoading) {
                    ZStack {
                        if geo.size.height > geo.size.width {
                            // Portrait
                            VStack(spacing: 0) {
                                DataPointView(showValues: $showValues,
                                              isMultiRow: !isPad,
                                              showAcceleration: main.showAcceleration)
                                    .padding(.horizontal, 10)
                                    .padding(.top, 5)
                                    .frame(height: isPad ? 45 : 90)
                                    .gesture(
                                        DragGesture(minimumDistance: 0)
                                            .onChanged { _ in showUnits = true }
                                            .onEnded { _ in showUnits = false }
                                    )
                                
                                VPart(top: {
                                    ChartFrame(
                                        showingMetricSelectionMenu: $showingMetricSelectionMenu,
                                        showChartToolbar: $showChartToolbar,
                                        buttonsVisible: $buttonsVisible,
                                        bottomViewMode: $bottomViewMode
                                    )
                                }) {
                                    switch bottomViewMode {
                                    case .map:
                                        MapView()
                                    case .polar:
                                        PolarView()
                                    case .fastestDescent:
                                        FastestDescentSpeedView()
                                    }
                                }
                                .edgesIgnoringSafeArea(.bottom)
                                .animation(.easeInOut(duration: 0.6), value: bottomViewMode)
                            }
                        } else {
                            // Landscape
                            VStack(spacing: 0) {
                                DataPointView(showValues: $showValues,
                                              isMultiRow: false,
                                              showAcceleration: main.showAcceleration)
                                    .padding(.horizontal, 4)
                                    .frame(height: 45)
                                
                                HPart(left: {
                                    ChartFrame(
                                        showingMetricSelectionMenu: $showingMetricSelectionMenu,
                                        showChartToolbar: $showChartToolbar,
                                        buttonsVisible: $buttonsVisible,
                                        bottomViewMode: $bottomViewMode
                                    )
                                    .background(
                                        GeometryReader { proxy in
                                            Color.clear.preference(key: LeftViewportWidthKey.self, value: proxy.size.width)
                                        }
                                    )
                                }) {
                                    switch bottomViewMode {
                                    case .map:
                                        MapView()
                                    case .polar:
                                        PolarView()
                                    case .fastestDescent:
                                        FastestDescentSpeedView()
                                    }
                                }
                                .edgesIgnoringSafeArea([.trailing, .bottom])
                                .animation(.easeInOut(duration: 0.6), value: bottomViewMode)
                            }
                        }
                    }
                }
                
                // Your existing load/menu button group
                UnifiedLoadButtonGroup(showChartToolbar: $showChartToolbar)
                    .environmentObject(main)
                    .padding(.trailing, geo.size.width > geo.size.height ? 0 : 20)
                    .padding(.bottom, 12)
                    .ignoresSafeArea(.container, edges: geo.size.width > geo.size.height ? .trailing : [])
            }
            // Floating chart settings menu (7 toggles) remains here if you use it:
            .overlay(
                Group {
                    if showingMetricSelectionMenu {
                        ChartSettingsView(showingMetricSelectionMenu: $showingMetricSelectionMenu)
                            .environmentObject(main)
                            .frame(width: 300, height: min(UIScreen.main.bounds.height - 100, 650))
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(20)
                            .shadow(radius: 10)
                            .transition(.move(edge: .trailing))
                            .zIndex(1000)
                    }
                }
            )
            // NEW: Floating toolbar of 7 action buttons
            .overlay(
                GeometryReader { geo in
                    ChartButtonsView(
                        buttonsVisible: $buttonsVisible,
                        showingMetricSelectionMenu: $showingMetricSelectionMenu,
                        bottomViewMode: $bottomViewMode,
                        isLandscape: .constant(geo.size.width > geo.size.height)
                    )

                    .environmentObject(main)
                    .frame(width: 60)
                    .position(
                        x: geo.size.height > geo.size.width
                            ? geo.size.width - 40
                            : leftViewportWidth + 30, // Use measured left viewport width + offset
                        y: geo.size.height > geo.size.width
                            ? 80 + 200
                            : (geo.size.height / 2) + 20
                    )
                    .zIndex(10)
                }
            )
            // STEP 4: Track left viewport width only in landscape
            .onPreferenceChange(LeftViewportWidthKey.self) { value in
                if geo.size.width > geo.size.height {
                    leftViewportWidth = value
                }
            }
            .onChange(of: main.trackLoadedSuccessfully) { loaded in
                if loaded {
                    showChartToolbar = false
                    DispatchQueue.main.async { main.trackLoadedSuccessfully = false }
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

struct LeftViewportWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
