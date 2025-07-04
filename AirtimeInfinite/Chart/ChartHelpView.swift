import SwiftUI

struct ChartHelpView: View {
    
    @Binding var showingHelpMenu: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Help & Documentation")
                        .font(.title)
                        .padding(.top)
                    
                    Text("Welcome to Airtime BT!")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 24) {
                        Text("This app allows you to view, analyse, and share your tracks between two jumps.")
                        
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "gear")
                                .resizable()
                                .frame(width: 20, height: 20)
                            Text("Access settings. Here you can choose: what information to display on the main chart, whether you want to scale automatically the chart, your preferred units, if the track should be cut and what to focus on (whole jump of swoop) and activate the bluetooth connection to your Flysight")
                        }
                        HStack(alignment: .top, spacing: 8) {
                            Image("ruler")
                                .resizable()
                                .frame(width: 20, height: 20)
                            Text("Select a first point on your track, then tap the ruler and select a second point to measure time, distance, altitude, etc between these two points.")
                        }
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lock")
                                .resizable()
                                .frame(width: 20, height: 20)
                            Text("Lock the view on the current zoom level and position so you can swipe again on the chart to display the corresponding data.")
                        }
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                                .resizable()
                                .frame(width: 20, height: 20)
                            Text("Restore full track view after locking on a zoom level and position.")
                        }
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                                .resizable()
                                .frame(width: 20, height: 20)
                            Text("Share or save locally your track.CSV")
                        }
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "line.horizontal.3")
                                .resizable()
                                .frame(width: 20, height: 20)
                            Text("Show/Hide menu")
                        }
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "plus")
                                .resizable()
                                .frame(width: 20, height: 20)
                            Text("Load a new Track.csv, via Bluetooth (Flysight 2 only) or through local file browsing (Flysight 1 and 2)")
                        }
                        HStack(alignment: .top, spacing: 8) {
                            VStack(spacing: 4) {
                                Image(systemName: "map")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                Image(systemName: "speedometer")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                Image(systemName: "chart.xyaxis.line")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                            }
                            Text("Toggle between Map, Speeds polar chat and Speed run analysis views")
                        }
                        
                        Text("For further help and updates, or if you need assistance on how to connect your Flysight (1 or 2) using an Apple adapter, visit the [GitHub page](https://github.com/vef445/AirtimeBT).")
                    }

                    
                }
                .padding()
            }
            
            Button(action: {
                showingHelpMenu = false
            }) {
                Text("Close")
                    .frame(maxWidth: .infinity)
            }
            .padding()
        }
        .frame(
            height: min(UIScreen.main.bounds.height - 100, 500)
        )
    }
}
