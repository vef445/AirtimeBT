//
//  TrackFileBluetooth.swift
//  AirtimeInfinite
//
//  Created by Guillaume Vigneron on 23/06/2025.
//  Copyright © 2025 Guillaume Vigneron. All rights reserved.
//

import SwiftUI
import FlySightCore
import Combine

// MARK: - Modal View for Bluetooth + File Explorer

struct CustomModalViewCombined: View {
    @Binding var isPresented: Bool
    @ObservedObject var bluetoothManager: FlySightCore.BluetoothManager
    @EnvironmentObject var main: MainProcessor

    @State private var selectedPeripheralID: UUID? = nil
    @State private var isReconnecting = false
    @State private var dotsCount = 1
    @State private var refreshTimer: AnyCancellable?
    @State private var cancellables = Set<AnyCancellable>()
    @State private var isManualConnecting = false

    private let dotsTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                HStack {
                    Picker("Select Device", selection: $selectedPeripheralID) {
                        Text("Select your FlySight").tag(UUID?.none)

                        ForEach(bluetoothManager.peripheralInfos) { peripheral in
                            HStack {
                                Text(peripheral.name)
                                if peripheral.isPairingMode {
                                    Image(systemName: "dot.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }.tag(Optional(peripheral.id))
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.horizontal)

                    if bluetoothManager.connectedPeripheral != nil {
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

                FileExplorerView(bluetoothManager: bluetoothManager, isPresented: $isPresented)
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
                // Load saved peripheral, try reconnect
                if let storedIDString = UserDefaults.standard.string(forKey: "lastConnectedPeripheralID"),
                   let storedUUID = UUID(uuidString: storedIDString) {
                    selectedPeripheralID = storedUUID
                } else {
                    selectedPeripheralID = nil
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    let isConnected = bluetoothManager.connectedPeripheral?.peripheral.state == .connected

                    if isConnected && !bluetoothManager.directoryEntries.isEmpty {
                        return
                    }

                    disconnect()
                    stopRefreshing()

                    if let lastConnectedID = selectedPeripheralID,
                       let peripheralInfo = bluetoothManager.peripheralInfos.first(where: { $0.id == lastConnectedID }) {
                        isReconnecting = true
                        isManualConnecting = false

                        bluetoothManager.connect(to: peripheralInfo.peripheral)
                        bluetoothManager.connectedPeripheral = peripheralInfo
                        startRefreshTimer()
                    }
                }
            }
            .onDisappear {
                stopRefreshing()
            }
            .onReceive(main.bluetoothManager.$directoryEntries) { entries in
                if isReconnecting && !entries.isEmpty {
                    stopRefreshing()
                }
            }
            .overlay {
                if isReconnecting {
                    VStack(spacing: 20) {
                        Text((isManualConnecting ? "Connecting to your FlySight" : "Reconnecting to your FlySight") + String(repeating: ".", count: dotsCount))
                            .font(.headline)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(radius: 10)
                            .onReceive(dotsTimer) { _ in
                                dotsCount = (dotsCount % 3) + 1
                            }

                        Button(action: {
                            cancelReconnecting()
                        }) {
                            Text("Cancel")
                                .foregroundColor(.red)
                                .font(.body)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.4))
                    .edgesIgnoringSafeArea(.all)
                }
            }
            .padding()
        }
    }

    private func connect() {
        if let newID = selectedPeripheralID,
           let peripheral = bluetoothManager.peripheralInfos.first(where: { $0.id == newID }) {
            isReconnecting = true
            isManualConnecting = true

            bluetoothManager.connect(to: peripheral.peripheral)
            bluetoothManager.connectedPeripheral = peripheral

            UserDefaults.standard.set(peripheral.id.uuidString, forKey: "lastConnectedPeripheralID")

            startRefreshTimer()
        }
    }

    private func disconnect() {
        if let peripheral = bluetoothManager.connectedPeripheral?.peripheral {
            bluetoothManager.disconnect(from: peripheral)
            bluetoothManager.connectedPeripheral = nil
        }
        stopRefreshing()
    }

    private func cancelReconnecting() {
        disconnect()
        isReconnecting = false
    }

    private func stopRefreshing() {
        isReconnecting = false
        refreshTimer = nil
        cancellables.removeAll()
    }

    private func startRefreshTimer() {
        refreshTimer?.cancel()

        refreshTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if let peripheral = self.bluetoothManager.connectedPeripheral,
                   peripheral.peripheral.state == .connected {
                    self.bluetoothManager.loadDirectoryEntries()
                }
            }
        refreshTimer?.store(in: &cancellables)
    }
}

// MARK: - File Explorer View

struct FileExplorerView: View {
    @ObservedObject var bluetoothManager: FlySightCore.BluetoothManager
    @EnvironmentObject var main: MainProcessor
    @Binding var isPresented: Bool

    @State private var isDownloading = false

    var body: some View {
        VStack(spacing: 0) {
            if !bluetoothManager.directoryEntries.isEmpty {
                HStack {
                    Button {
                        bluetoothManager.goUpOneDirectoryLevel()
                    } label: {
                        Image(systemName: "arrow.backward")
                            .font(.title2)
                    }
                    .disabled(bluetoothManager.currentPath.isEmpty)

                    Spacer()

                    GeometryReader { geo in
                        ScrollingText(text: "Select your TRACK.CSV file", containerWidth: geo.size.width)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(height: 20)

                    Spacer()

                    Button {
                        bluetoothManager.loadDirectoryEntries()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            List {
                ForEach(bluetoothManager.directoryEntries.filter { !$0.isHidden }) { entry in
                    Button {
                        if entry.isFolder {
                            bluetoothManager.changeDirectory(to: entry.name)
                        } else {
                            downloadFile(entry)
                        }
                    } label: {
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
        .overlay(
            Group {
                if isDownloading {
                    DownloadProgressView(isShowing: $isDownloading,
                                         progress: Binding<Double>(
                                            get: { Double(bluetoothManager.downloadProgress) },
                                            set: { bluetoothManager.downloadProgress = Float($0) }
                                         )) {
                        bluetoothManager.cancelDownload()
                        isDownloading = false
                    }
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
                    print("Download failed: \(error.localizedDescription)")
                }
                isDownloading = false
            }
        }
    }

    private func saveFile(data: Data, name: String) {
        guard let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let fileURL = docDir.appendingPathComponent(name)
        do {
            try data.write(to: fileURL)
            main.loadTrack(trackURL: fileURL)
            isPresented = false
        } catch {
            print("Saving failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Download Progress View

struct DownloadProgressView: View {
    @Binding var isShowing: Bool
    @Binding var progress: Double
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
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 90, height: 90)

                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 10)
                        .frame(width: 90, height: 90)

                    Circle()
                        .trim(from: 0, to: CGFloat(progress))
                        .stroke(
                            LinearGradient(colors: [.pink, .purple, .blue], startPoint: .leading, endPoint: .trailing),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round, dash: [15, 20], dashPhase: dashPhase)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 90, height: 90)
                        .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: dashPhase)
                        .onAppear { dashPhase = -35 }

                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 26, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }

                Button("Cancel", action: cancelAction)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.15))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(radius: 4)
            }
            .padding(40)
            .background(Color.black.opacity(0.7).cornerRadius(25).shadow(radius: 12))
            .padding()
        }
    }
}


// MARK: - Helper Extensions

private extension Float {
    func fileSize() -> String {
        ByteCountFormatter.string(fromByteCount: Int64(self), countStyle: .file)
    }
}

private extension Int {
    func fileSize() -> String {
        ByteCountFormatter.string(fromByteCount: Int64(self), countStyle: .file)
    }
}

private extension FlySightCore.DirectoryEntry {
        var isFolder: Bool {
            attributes.contains("d")
        }
    }

extension FlySightCore.DirectoryEntry {
    var isHidden: Bool {
        name.hasPrefix(".")
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Scrolling Text View for title

struct ScrollingText: View {
    let text: String
    let containerWidth: CGFloat

    @State private var offset: CGFloat = 0
    @State private var textWidth: CGFloat = 0
    @State private var timer: Timer?

    var body: some View {
        Text(text)
            .background(GeometryReader { geo -> Color in
                DispatchQueue.main.async {
                    textWidth = geo.size.width
                    startScrolling()
                }
                return Color.clear
            })
            .offset(x: offset)
            .onDisappear {
                timer?.invalidate()
            }
    }

    private func startScrolling() {
        guard textWidth > containerWidth else { return }

        timer?.invalidate()
        _ = Double(textWidth / 30)

        timer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { _ in
            withAnimation(.linear(duration: 0.03)) {
                offset -= 1
                if offset < -textWidth {
                    offset = containerWidth
                }
            }
        }
    }
}
