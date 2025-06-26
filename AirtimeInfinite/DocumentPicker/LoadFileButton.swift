//
//  LoadFileButton.swift
//  AirtimeBT
//
//  Created by Jordan Gould on 6/18/20.
//  Updated by Guillaume Vigneron on 6/23/25.
//

import SwiftUI
import FlySightCore

struct LoadButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 60, height: 60) // Ensures label takes full space
            .background(Color.gray.opacity(0.8))
            .foregroundColor(.primary)
            .font(.system(size: 36, weight: .bold)) // Larger and bolder
            .clipShape(Circle())
            .contentShape(Circle()) // Helps with interaction and layout
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct MenuButton: View {
    @Binding var showChartToolbar: Bool
    @State private var isShowingMenu = false

    var body: some View {
        Button(action: {
            // Toggle the toolbar visibility
            showChartToolbar.toggle()
            // Optional: you can also toggle isShowingMenu for other UI
            isShowingMenu.toggle()
        }) {
            Image(systemName: "line.horizontal.3") // Hamburger menu icon
                .font(.system(size: 24, weight: .bold))
        }
        //.padding()
        .buttonStyle(LoadButtonStyle())
    }
}


struct UnifiedLoadButton: View {
    @Binding var showChartToolbar: Bool
    @State private var isShowingModal = false
    @EnvironmentObject var main: MainProcessor

    var body: some View {
        Button(action: {
            isShowingModal.toggle()
        }) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .bold))
        }
        //.padding()
        .buttonStyle(LoadButtonStyle())
        .sheet(isPresented: $isShowingModal) {
            if main.useBluetooth {
                BaseModalWrapper {
                    CustomModalViewCombined(isPresented: $isShowingModal,
                                            bluetoothManager: main.bluetoothManager)
                        .environmentObject(main)
                }
            } else {
                BaseModalWrapper {
                    TrackFilePickerView(isPresented: $isShowingModal)
                        .environmentObject(main)
                }
            }
        }
        .alert(isPresented: $main.trackLoadError) {
            Alert(title: Text("File Error"),
                  message: Text("Could not load track file"),
                  dismissButton: .default(Text("OK")))
        }
    }
}

struct UnifiedLoadButtonGroup: View {
    @Binding var showChartToolbar: Bool

    var body: some View {
        Spacer()
        VStack(spacing: 10) {
            MenuButton(showChartToolbar: $showChartToolbar)
            UnifiedLoadButton(showChartToolbar: $showChartToolbar)
        }
    }
}

struct UnifiedLoadButtonGroup_Previews: PreviewProvider {
    @State static var toolbarVisible = true
    
    static var previews: some View {
        UnifiedLoadButtonGroup(showChartToolbar: $toolbarVisible)
            .environmentObject(MainProcessor())
            .previewLayout(.sizeThatFits)
            .padding()
    }
}


struct BaseModalWrapper<Content: View>: View {
    let content: () -> Content
    var body: some View {
        ZStack {
            content()
        }
    }
}
