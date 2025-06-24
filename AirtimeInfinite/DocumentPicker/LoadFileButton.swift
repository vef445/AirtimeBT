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
        HStack {
            Image(systemName: "plus")
                .font(.system(size: 20))
        }
        .padding()
        .foregroundColor(.black)
        .background(Color.gray)
        .cornerRadius(10)
        .frame(minWidth: 60, maxWidth: 60, minHeight: 60, maxHeight: 60)
    }
}

struct UnifiedLoadButton: View {
    @State private var isShowingModal = false
    @EnvironmentObject var main: MainProcessor

    var body: some View {
        Button(action: {
            isShowingModal.toggle()
        }) {
            Text("+")
                .font(Font.system(size: 28, design: .default))
        }
        .padding()
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

struct BaseModalWrapper<Content: View>: View {
    let content: () -> Content
    var body: some View {
        ZStack {
            content()
        }
    }
}
