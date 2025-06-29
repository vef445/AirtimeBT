//
//  ContentView.swift
//  AirtimeBT
//
//  Created by Jordan Gould on 6/18/20.
//  Copyright © 2020 Jordan Gould. All rights reserved.
//

import SwiftUI
import Combine

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
            ZStack {
                content(for: geo)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 5)
                            .onChanged { _ in
                                main.isDragging = true
                            }
                            .onEnded { _ in
                                main.isDragging = false
                            }
                    )
                
                // Dimming overlay covers everything except settings page
                dimBackground
                    .edgesIgnoringSafeArea(.all)
                    .zIndex(1000)
                
                // Settings page overlay on top of dimming
                metricSelectionOverlay
                    .zIndex(1100)
                
                if geo.size.height > geo.size.width {
                    // Portrait: horizontally center buttons at bottom
                    VStack {
                        Spacer()
                        buttonGroup(geo: geo)
                            .disabled(showingMetricSelectionMenu)
                            .opacity(
                                main.isDragging ? 0.0 :
                                (showingMetricSelectionMenu ? 0.4 : 0.8)
                            )
                            .animation(.easeInOut(duration: 0.25), value: main.isDragging)
                            .padding(.bottom, 20)
                            .zIndex(1200)
                    }
                    .edgesIgnoringSafeArea(.bottom)
                    .frame(width: geo.size.width)
                } else {
                    // Landscape: horizontally center buttons in right viewport,
                    // vertically at bottom with some padding
                    buttonGroup(geo: geo)
                        .disabled(showingMetricSelectionMenu)
                        .opacity(
                            main.isDragging ? 0.0 :
                            (showingMetricSelectionMenu ? 0.4 : 0.8)
                        )
                        .animation(.easeInOut(duration: 0.25), value: main.isDragging)
                        .frame(width: geo.size.width / 2)
                        .position(x: geo.size.width - 100,
                                  y: geo.size.height - 40)
                        .zIndex(1200)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                // Ensure buttons are visible when app becomes active
                    main.isDragging = false
            }
        }
    }

    
    @ViewBuilder
    private func content(for geo: GeometryProxy) -> some View {
        ZStack(alignment: .bottomTrailing) {
            
            LoadingView(isShowing: $main.isLoading) {
                mainContent(for: geo)
            }
        }
        .overlay(floatingToolbar(geo: geo))
        .onPreferenceChange(LeftViewportWidthKey.self) { value in
            if geo.size.width > geo.size.height {
                leftViewportWidth = value
            }
        }
        .onChange(of: showingMetricSelectionMenu) { newValue in
            if newValue {
                showChartToolbar = false
            }
        }
        .onChange(of: main.trackLoadedSuccessfully) { loaded in
            if loaded {
                showChartToolbar = false
                DispatchQueue.main.async { main.trackLoadedSuccessfully = false }
            }
        }
    }
    
    private var dimBackground: some View {
        Color.gray
            .opacity((showingMetricSelectionMenu || main.isLoading) ? 0.5 : 0.0)
            .animation(.linear, value: showingMetricSelectionMenu || main.isLoading)
    }
    
    @ViewBuilder
    private func mainContent(for geo: GeometryProxy) -> some View {
        if geo.size.height > geo.size.width {
            portraitLayout
        } else {
            landscapeLayout
        }
    }
    
    private var portraitLayout: some View {
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
                bottomView
            }
            .edgesIgnoringSafeArea(.bottom)
            .animation(.easeInOut(duration: 0.6), value: bottomViewMode)
        }
    }
    
    private var landscapeLayout: some View {
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
                bottomView
            }
            .edgesIgnoringSafeArea([.trailing, .bottom])
            .animation(.easeInOut(duration: 0.6), value: bottomViewMode)
        }
    }
    
    @ViewBuilder
    private var bottomView: some View {
        switch bottomViewMode {
        case .map:
            MapView()
        case .polar:
            PolarView()
        case .fastestDescent:
            FastestDescentSpeedView()
        }
    }
    
    @ViewBuilder
    private func buttonGroup(geo: GeometryProxy) -> some View {
        UnifiedLoadButtonGroup(
            showChartToolbar: $showChartToolbar,
            bottomViewMode: $bottomViewMode,
            horizontalLayout: true
        )
        .environmentObject(main)
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .background(
            Color(.systemGray6)
                .opacity(0.7)
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
        )
        .frame(maxWidth: 320)
        .frame(maxWidth: .infinity)
        .scaleEffect(0.85)
    }
    
    @ViewBuilder
    private var metricSelectionOverlay: some View {
        if showingMetricSelectionMenu {
            ChartSettingsView(showingMetricSelectionMenu: $showingMetricSelectionMenu)
                .environmentObject(main)
                .frame(width: 300, height: min(UIScreen.main.bounds.height - 100, 650))
                .background(Color(.secondarySystemBackground))
                .cornerRadius(20)
                .shadow(radius: 10)
                .transition(.opacity)
        }
    }
    
    @ViewBuilder
    private func floatingToolbar(geo: GeometryProxy) -> some View {
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
                    : leftViewportWidth + 30,
                y: geo.size.height > geo.size.width
                    ? 80 + 200
                    : (geo.size.height / 2) + 20
            )
            .zIndex(10)
        }
    }
    
    private func burgerButtonAction() {
        if showingMetricSelectionMenu {
            showingMetricSelectionMenu = false
        } else {
            showChartToolbar.toggle()
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
