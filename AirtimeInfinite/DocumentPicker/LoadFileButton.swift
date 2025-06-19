//
//  LoadFileButton.swift
//  AirtimeInfinite
//
//  Created by Jordan Gould on 6/18/20.
//  Copyright © 2020 Jordan Gould. All rights reserved.
//

import SwiftUI
import FlySightCore
import Combine


/// Styling for the unified load button
struct LoadButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
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

// MARK: - Unified Button

/// Single button that opens either Bluetooth or File Picker based on settings
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
                CustomModalViewCombined(isPresented: $isShowingModal, bluetoothManager: main.bluetoothManager)
                    .environmentObject(main)
            } else {
                TrackFilePickerView(isPresented: $isShowingModal)
                    .environmentObject(main)
            }
        }
        .alert(isPresented: $main.trackLoadError) {
            Alert(
                title: Text("File Error"),
                message: Text("Could not load track file"),
                dismissButton: .default(Text("Ok"))
            )
        }
    }
}

struct CustomModalViewCombined: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var main: MainProcessor

    @ObservedObject var bluetoothManager: FlySightCore.BluetoothManager

    @State private var selectedPeripheralID: UUID? = nil
    @State private var isShowingConnectingAlert = false
    @State private var dotsCount = 1

    // Timer to update dots count every 0.5 seconds
    private let dotsTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    // Timer to refresh directory every 1 second while connecting
    @State private var refreshTimer: Timer.TimerPublisher?

    // Used to hold Combine cancellables for timers
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Device Picker Section with placeholder text
                HStack {
                    Picker("Select Device", selection: $selectedPeripheralID) {
                        Text("Select your FlySight").tag(UUID?.none) // Placeholder

                        ForEach(main.bluetoothManager.peripheralInfos) { peripheralInfo in
                            devicePickerLabel(for: peripheralInfo)
                                .tag(Optional(peripheralInfo.id)) // use Optional(...) to match UUID?
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.horizontal)

                    // Connect / Disconnect Button next to picker
                    if main.bluetoothManager.connectedPeripheral != nil {
                        Button("Disconnect") {
                            disconnect()
                        }
                        .foregroundColor(.red)
                        .padding(.trailing)
                    } else if selectedPeripheralID != nil {
                        Button("Connect") {
                            connect()
                        }
                        .foregroundColor(.blue)
                        .padding(.trailing)
                    }
                }

                Divider()

                // Files Section
                FileExplorerView(bluetoothManager: main.bluetoothManager, isPresented: $isPresented)
                    .environmentObject(main)
            }
            .navigationTitle("Bluetooth Utility")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .onAppear {
                selectedPeripheralID = main.bluetoothManager.connectedPeripheral?.id
            }
            // Overlay "Connecting..." popup with animated dots and Cancel button
            .overlay {
                if isShowingConnectingAlert {
                    VStack(spacing: 20) {
                        Text("Connecting" + String(repeating: ".", count: dotsCount))
                            .font(.headline)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(radius: 10)
                            // Update dotsCount every 0.5 seconds
                            .onReceive(dotsTimer) { _ in
                                dotsCount = dotsCount % 3 + 1
                            }

                        Button(action: {
                            cancelConnecting()
                        }) {
                            Text("Cancel")
                                    .foregroundColor(.red)
                                    .font(.body)
                                    //.padding(8)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.4))
                    .edgesIgnoringSafeArea(.all)
                }
            }
            .onReceive(main.bluetoothManager.$directoryEntries) { entries in
                // When directory entries are loaded, hide connecting alert and stop refresh timer
                if isShowingConnectingAlert && !entries.isEmpty {
                    stopRefreshing()
                }
            }
            .padding()
        }
    }
    
    @ViewBuilder
    func devicePickerLabel(for peripheralInfo: FlySightCore.PeripheralInfo) -> some View {
        HStack {
            Text(peripheralInfo.name)
            if peripheralInfo.isPairingMode {
                Image(systemName: "dot.circle.fill")
                    .foregroundColor(.green)
            }
        }
    }



    // MARK: - Helper Functions

    private func connect() {
        if let newID = selectedPeripheralID,
           let peripheralInfo = main.bluetoothManager.peripheralInfos.first(where: { $0.id == newID }) {
            // Show connecting popup
            isShowingConnectingAlert = true

            main.bluetoothManager.connect(to: peripheralInfo.peripheral)
            main.bluetoothManager.connectedPeripheral = peripheralInfo

            // Start refresh timer to load directory every second
            refreshTimer = Timer.publish(every: 1, on: .main, in: .common)
            refreshTimer?.autoconnect()
                .sink { _ in
                    main.bluetoothManager.loadDirectoryEntries()
                }
                .store(in: &cancellables)
        }
    }

    private func disconnect() {
        if let connectedPeripheral = main.bluetoothManager.connectedPeripheral {
            main.bluetoothManager.disconnect(from: connectedPeripheral.peripheral)
            main.bluetoothManager.connectedPeripheral = nil
            selectedPeripheralID = nil
        }
        stopRefreshing()
        isShowingConnectingAlert = false
    }

    private func cancelConnecting() {
        // Cancel refresh timer, disconnect device, hide overlay, reset selected device
        disconnect()
    }

    private func stopRefreshing() {
        isShowingConnectingAlert = false
        refreshTimer = nil
        cancellables.removeAll()
    }
}

struct ConnectView: View {
    @ObservedObject var bluetoothManager: FlySightCore.BluetoothManager

    var body: some View {
        HStack(spacing: 10) {
            Picker("Select Device", selection: Binding(
                get: {
                    bluetoothManager.connectedPeripheral?.id ?? UUID()
                },
                set: { newID in
                    if bluetoothManager.connectedPeripheral?.id == newID {
                        bluetoothManager.disconnect(from: bluetoothManager.connectedPeripheral!.peripheral)
                        bluetoothManager.connectedPeripheral = nil
                    } else if let peripheralInfo = bluetoothManager.peripheralInfos.first(where: { $0.id == newID }) {
                        bluetoothManager.connect(to: peripheralInfo.peripheral)
                        bluetoothManager.connectedPeripheral = peripheralInfo
                    }
                }
            )) {
                Text("Select Device").tag(UUID())
                ForEach(bluetoothManager.peripheralInfos) { peripheralInfo in
                    Text(peripheralInfo.name).tag(peripheralInfo.id)
                }
            }
            .pickerStyle(MenuPickerStyle())
            
            if let connectedPeripheral = bluetoothManager.connectedPeripheral {
                Button("Disconnect") {
                    bluetoothManager.disconnect(from: connectedPeripheral.peripheral)
                    bluetoothManager.connectedPeripheral = nil
                }
                .foregroundColor(.red)
            } else {
                Button("Connect") {
                    if let selectedID = bluetoothManager.peripheralInfos.first?.id,
                       let peripheralInfo = bluetoothManager.peripheralInfos.first(where: { $0.id == selectedID }) {
                        bluetoothManager.connect(to: peripheralInfo.peripheral)
                        bluetoothManager.connectedPeripheral = peripheralInfo
                    }
                }
                .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
    }
}

struct FileExplorerView: View {
    @ObservedObject var bluetoothManager: FlySightCore.BluetoothManager
    @EnvironmentObject var main: MainProcessor
    
    @Binding var isPresented: Bool

    @State private var isDownloading = false
    @State private var isUploading = false
    @State private var showFileImporter = false
    @State private var selectedFileURL: URL?

    @State private var animateText = false

    var body: some View {
        VStack(spacing: 0) {
            // Only show top bar when file list is available
            if !bluetoothManager.directoryEntries.isEmpty {
                HStack {
                    Button(action: {
                        bluetoothManager.goUpOneDirectoryLevel()
                    }) {
                        Image(systemName: "arrow.backward")
                            .font(.title2)
                    }
                    .disabled(bluetoothManager.currentPath.count == 0)

                    Spacer()

                    GeometryReader { geo in
                        ScrollingText(text: "Select your TRACK.CSV file", containerWidth: geo.size.width)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                    }
                    .frame(height: 20)

                    Spacer()

                    Button(action: {
                        bluetoothManager.loadDirectoryEntries()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 8)
            }

            List {
                ForEach(bluetoothManager.directoryEntries.filter { !$0.isHidden }) { entry in
                    Button(action: {
                        if entry.isFolder {
                            bluetoothManager.changeDirectory(to: entry.name)
                        } else {
                            downloadFile(entry)
                        }
                    }) {
                        HStack {
                            Image(systemName: entry.isFolder ? "folder.fill" : "doc")
                            VStack(alignment: .leading) {
                                Text(entry.name)
                                    .font(.headline)
                                    .foregroundColor(entry.isFolder ? .blue : .primary)
                                if !entry.isFolder {
                                    Text("\(entry.size.fileSize())")
                                        .font(.caption)
                                }
                            }
                            Spacer()
                            Text(entry.formattedDate)
                                .font(.caption)
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.data],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    selectedFileURL = url
                }
            case .failure(let error):
                print("Failed to select file: \(error.localizedDescription)")
            }
        }
        .overlay(
            Group {
                if isDownloading {
                    DownloadProgressView(isShowing: $isDownloading, progress: $bluetoothManager.downloadProgress, cancelAction: cancelDownload)
                        .padding()
                }
                if isUploading {
                    // your uploading UI here if needed
                }
            }
        )
    }

    private func downloadFile(_ entry: FlySightCore.DirectoryEntry) {
        isDownloading = true
        let fullPath = (bluetoothManager.currentPath + [entry.name]).joined(separator: "/")
        bluetoothManager.downloadFile(named: fullPath) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    saveFile(data: data, name: entry.name)
                case .failure(let error):
                    print("Failed to download file: \(error.localizedDescription)")
                }
                isDownloading = false
            }
        }
    }

    private func saveFile(data: Data, name: String) {
        let fileManager = FileManager.default
        if let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = documentDirectory.appendingPathComponent(name)
            do {
                try data.write(to: fileURL)
                main.loadTrack(trackURL: fileURL)
                print("File saved to \(fileURL.path)")
                isPresented = false
            } catch {
                print("Failed to save file: \(error.localizedDescription)")
            }
        }
    }

    private func cancelDownload() {
        bluetoothManager.cancelDownload()
        isDownloading = false
    }

    private func cancelUpload() {
        bluetoothManager.cancelUpload()
    }
}

struct DownloadProgressView: View {
    @Binding var isShowing: Bool
    @Binding var progress: Float
    var cancelAction: () -> Void
    
    @State private var dashPhase: CGFloat = 0
    
    var body: some View {
        if isShowing {
            VStack(spacing: 24) {
                Text("Downloading...")
                    .font(.headline)
                    .foregroundColor(.white)
                    .shadow(radius: 3)
                
                ZStack {
                    // Background blur circle
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 90, height: 90)
                    
                    // Gray track
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 10)
                        .frame(width: 90, height: 90)
                    
                    // Gradient progress with dash animation
                    Circle()
                        .trim(from: 0, to: CGFloat(progress))
                        .stroke(
                            LinearGradient(
                                colors: [.pink, .purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round, dash: [15, 20], dashPhase: dashPhase)
                        )
                        .rotationEffect(Angle(degrees: -90))
                        .frame(width: 90, height: 90)
                        .animation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false), value: dashPhase)
                        .onAppear {
                            dashPhase = -35
                        }
                    
                    // Percentage text
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 26, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                }
                
                Button(action: cancelAction) {
                    Text("Cancel")
                        .font(.body)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.15))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(radius: 4)
                }
            }
            .padding(40)
            .background(
                Color.black.opacity(0.7)
                    .cornerRadius(25)
                    .shadow(radius: 12)
            )
            .padding()
        }
    }
}

struct ScrollingText: View {
    let text: String
    let containerWidth: CGFloat

    @State private var textWidth: CGFloat = 0
    @State private var offset: CGFloat = 0
    @State private var animationActive = false

    var body: some View {
        Text(text)
            .lineLimit(1)
            .background(GeometryReader { geo -> Color in
                DispatchQueue.main.async {
                    self.textWidth = geo.size.width
                    if textWidth > containerWidth && !animationActive {
                        animationActive = true
                        startAnimation()
                    }
                }
                return Color.clear
            })
            .offset(x: offset)
            .clipped()
            .animation(.linear(duration: 6).repeatForever(autoreverses: false), value: offset)
            .onAppear {
                if textWidth > containerWidth {
                    startAnimation()
                }
            }
    }

    private func startAnimation() {
        // Reset offset to 0 and animate to negative scroll amount
        offset = 0
        let distance = textWidth - containerWidth
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            offset = -distance - 20 // scroll left by textWidth - containerWidth + some padding
        }
    }
}
