//
//  ContentView.swift
//  AirtimeInfinite
//
//  Created by Jordan Gould on 6/18/20.
//  Copyright © 2020 Jordan Gould. All rights reserved.
//

import SwiftUI

/// Primary view displaying all data visualiztion views
struct ContentView: View {
    
    @State var isShowingPicker = false
    @State var showingMetricSelectionMenu = false
    @State var orientation = UIDevice.current.orientation
    
    @EnvironmentObject var main: MainProcessor
    
    /// More screen space available, can reduce stat size
    let isPad = UIDevice.current.userInterfaceIdiom == .pad
    
    var body: some View {
        
        GeometryReader { geo in
            ZStack {
                /// Fade background when chart menu is open
                Color.gray
                    .opacity((self.showingMetricSelectionMenu || self.main.isLoading) ? 0.5 : 0.0)
                    .edgesIgnoringSafeArea(.all)
                    .animation(.linear, value: showingMetricSelectionMenu || main.isLoading)
                
                ///
                LoadingView(isShowing: self.$main.isLoading){
                    /// Main stack
                    ZStack {
                        if geo.size.height > geo.size.width {
                            /// Vertical main view
                            VStack {
                                DataPointView(isMultiRow: !self.isPad,
                                              showAcceleration: self.main.showAcceleration)
                                    .padding(.horizontal, 10)
                                    .padding(.top, 5)
                                    .padding(.bottom, 10)
                                    /// If we're on an iPad, size metric display for a single row while vertical
                                    .frame(height: self.isPad ? 45 : 90)
                                VPart(top: {
                                    ChartFrame(showingMetricSelectionMenu: self.$showingMetricSelectionMenu)
                                }) {
                                    MapView()
                                }.edgesIgnoringSafeArea(.bottom)
                            }
                        } else {
                            /// Horizontal main view
                            VStack {
                                DataPointView(isMultiRow: false,
                                              showAcceleration: self.main.showAcceleration)
                                    .padding(.horizontal, 10)
                                    .padding(.top, 5)
                                    .frame(height: 45)
                                HPart(left: {
                                    ChartFrame(showingMetricSelectionMenu: self.$showingMetricSelectionMenu)
                                }) {
                                    MapView()
                                }.edgesIgnoringSafeArea(.trailing)
                                    .edgesIgnoringSafeArea(.bottom)
                            }
                        }
                        /// Load file  button
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                VStack(spacing: 2) {
                                    UnifiedLoadButton()                                    
                                }
                            }
                        }

                        
                        /// Chart data selection menu
                        ChartSettingsView(showingMetricSelectionMenu: self.$showingMetricSelectionMenu)
                            .environmentObject(self.main)
                            .background(Color(.secondarySystemBackground))
                            .edgesIgnoringSafeArea(.all)
                            .cornerRadius(20)
                            .shadow(radius: 20)
                            .frame(width: 300, height: 300, alignment: .center)
                            .padding()
                            .offset(x: 0, y: self.showingMetricSelectionMenu ? 0 : 1000)
                            .animation(.linear, value: self.showingMetricSelectionMenu)
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
