//
//  LoadFileButton.swift
//  AirtimeInfinite
//
//  Created by Jordan Gould on 6/18/20.
//  Copyright © 2020 Jordan Gould. All rights reserved.
//

import SwiftUI

/// Round circle styling for the load button
struct LoadButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .frame(width: 70, height: 70)
            .foregroundColor(Color.black)
            .background(Color.gray)
            .clipShape(Circle())
            .shadow(color: Color.black.opacity(0.3),
                    radius: 3,
                    x: 3,
                    y: 3)
            .overlay(
                Circle()
                    .stroke(Color(UIColor.darkGray), lineWidth: 3))
    }
}

/// Button that directs user to a document picker and initiates the track load
struct LoadFileButton: View {
    
    @State var isShowingPicker = false
    
    @EnvironmentObject var main: MainProcessor
    
    var body: some View{
        Button(action: {
            self.isShowingPicker.toggle()
            
        }, label: {
            Text("+")
                .font(Font.system(size: 28, design: .default))
        })
            .padding()
            .buttonStyle(LoadButtonStyle())
            .sheet(isPresented: $isShowingPicker, content: {
                TrackFilePickerView(
                    isPresented: self.$isShowingPicker)
                    .environmentObject(self.main)
            })
            .alert(isPresented: self.$main.trackLoadError) {
                Alert(title: Text("File Error"),
                      message: Text("Could not load track file"),
                      dismissButton: .default(Text("Ok")))
        }
    }
}
