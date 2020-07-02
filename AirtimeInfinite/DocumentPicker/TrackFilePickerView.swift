//
//  DocumentView.swift
//  AirtimeInfinite
//
//  Created by Jordan Gould on 6/18/20.
//  Copyright © 2020 Jordan Gould. All rights reserved.
//

import SwiftUI
import MobileCoreServices

/// Document picker that returns the file URL of a user selected track file
struct TrackFilePickerView: UIViewControllerRepresentable {
    
    @Binding var isPresented: Bool
    
    @EnvironmentObject var main: MainProcessor
    
    func makeUIViewController(
        context: UIViewControllerRepresentableContext<TrackFilePickerView>) ->
        UIViewController {
        /// We are looking for CSVs only
        let documentPicker = UIDocumentPickerViewController(
            documentTypes: [kUTTypeCommaSeparatedText as String], in: .open)
        documentPicker.delegate = context.coordinator
        return documentPicker
    }
    
    func makeCoordinator() -> TrackFilePickerView.Coordinator {
        return Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate, UINavigationControllerDelegate {
        
        var parent: TrackFilePickerView
        init(parent: TrackFilePickerView){
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.main.loadTrack(trackURL: url)
            self.parent.isPresented = false
        }
    }
    
    func updateUIViewController(_ uiViewController: TrackFilePickerView.UIViewControllerType, context: UIViewControllerRepresentableContext<TrackFilePickerView>) {
        
    }
}
