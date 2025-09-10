import SwiftUI
import Combine
import AppKit

struct MetronomeView: View {
    @StateObject private var viewModel = MetronomeViewModel()
    @State private var showAnalysis: Bool = true
    @State private var didZoomForAnalysis: Bool = false
    @State private var previousWindowFrame: NSRect? = nil

    var body: some View {
        VStack(spacing: 18) {
            Text("Metronome")
                .font(.title)
                .fontWeight(.semibold)
                .accessibilityIdentifier("title")

            HStack(alignment: .center, spacing: 10) {
                Label("Input", systemImage: "mic")
                    .labelStyle(.titleAndIcon)
                Picker("Input", selection: Binding(
                    get: { viewModel.selectedInputDeviceId ?? "" },
                    set: { viewModel.selectedInputDeviceId = $0.isEmpty ? nil : $0 }
                )) {
                    ForEach(viewModel.inputDevices) { dev in
                        Text(dev.name)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .tag(dev.id)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 220, alignment: .leading)

                Button {
                    viewModel.refreshDevices()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }

                // Live input level meter (dBFS)
                HStack(spacing: 6) {
                    Text("Level")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.gray.opacity(0.2))
                        let db = viewModel.inputLevelDb
                        let norm: CGFloat = {
                            // Map -80dB..0dB -> 0..1
                            let clamped = min(0, max(-80, db.isNaN ? -80 : db))
                            return CGFloat((clamped + 80) / 80)
                        }()
                        Capsule().fill(db.isNaN ? Color.clear : (db > -20 ? Color.red : db > -40 ? Color.orange : Color.green))
                            .frame(width: 80 * norm)
                    }
                    .frame(width: 80, height: 8)
                }
            }

            HStack(spacing: 12) {
                Text("BPM: \(viewModel.bpm)")
                    .font(.headline)
                    .accessibilityIdentifier("bpmLabel")
                Slider(value: Binding(
                    get: { Double(viewModel.bpm) },
                    set: { viewModel.bpm = Int($0); viewModel.storePreferences(); if viewModel.isRunning { viewModel.schedule() } }
                ), in: 20...300, step: 1)
                .accessibilityIdentifier("bpmSlider")
                .controlSize(.small)
                .frame(width: 160)

                Button {
                    let next = max(20, min(300, viewModel.bpm - 1))
                    viewModel.bpm = next
                    viewModel.storePreferences()
                    if viewModel.isRunning { viewModel.schedule() }
                } label: {
                    Image(systemName: "minus")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityIdentifier("bpmMinusButton")

                Button {
                    let next = max(20, min(300, viewModel.bpm + 1))
                    viewModel.bpm = next
                    viewModel.storePreferences()
                    if viewModel.isRunning { viewModel.schedule() }
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityIdentifier("bpmPlusButton")
            }

            // Onset sensitivity threshold
            HStack(spacing: 8) {
                Text("Min Level")
                Slider(value: Binding(
                    get: { viewModel.onsetMinDb },
                    set: { viewModel.onsetMinDb = $0 }
                ), in: (-80)...(-10), step: 1)
                .controlSize(.small)
                .frame(width: 160)
                Text(String(format: "%.0f dB", viewModel.onsetMinDb))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Rhythm")
                    .font(.headline)
                ScrollView {
                    Picker("Rhythm", selection: Binding(
                        get: { viewModel.pattern },
                        set: { viewModel.pattern = $0; viewModel.storePreferences(); if viewModel.isRunning { viewModel.schedule() } }
                    )) {
                        Text("Quarter").tag(Pattern.quarter)
                        Text("Eighth").tag(Pattern.eighth)
                        Text("8th Triplets").tag(Pattern.eighthTriplet)
                        Text("Sixteenth").tag(Pattern.sixteenth)
                        Text("16th Triplets").tag(Pattern.sixteenthTriplet)
                    }
                    .pickerStyle(.radioGroup)
                    .accessibilityIdentifier("patternPicker")
                }
                .frame(height: 120)
            }

            HStack(spacing: 12) {
                Button(viewModel.isRunning ? "Stop" : "Start") {
                    if viewModel.isRunning { viewModel.stop() } else { viewModel.start() }
                }
                .keyboardShortcut(.space, modifiers: [])
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityIdentifier("startStopButton")

                Button(viewModel.isPreRoll || viewModel.isRecording ? "Stop Recording" : "Record 15s") { viewModel.record15s() }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .accessibilityIdentifier("recordButton")

                if viewModel.isPreRoll {
                    Text("Starting in: \(viewModel.preRollSeconds)s")
                        .monospacedDigit()
                        .foregroundStyle(.orange)
                        .accessibilityIdentifier("prerollCountdown")
                }

                if viewModel.isRecording {
                    Text("Recording: \(viewModel.remainingSeconds)s")
                        .monospacedDigit()
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("recordCountdown")
                }
            }
            
            // Inline analysis panel behind a disclosure
            if let s = viewModel.analysisSeries, !viewModel.isRecording {
                Divider()
                DisclosureGroup("Show Analysis", isExpanded: $showAnalysis) {
                    VStack(alignment: .leading, spacing: 12) {
                        AnalysisGraphView(series: s)
                        HStack {
                            Spacer()
                            Button("Clear") { viewModel.analysisSeries = nil }
                                .keyboardShortcut(.escape, modifiers: [])
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
        .padding(24)
        .frame(minWidth: 520, minHeight: 360)
        .onReceive(viewModel.$analysisSeries) { series in
            showAnalysis = true
            if series != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    guard let win = NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first(where: { $0.isVisible }) else { return }
                    if previousWindowFrame == nil { previousWindowFrame = win.frame }
                    let target = win.screen?.visibleFrame ?? NSScreen.main?.visibleFrame
                    if let target {
                        win.setFrame(target, display: true, animate: true)
                        didZoomForAnalysis = true
                    }
                }
            } else if didZoomForAnalysis {
                DispatchQueue.main.async {
                    guard let win = NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first(where: { $0.isVisible }) else { return }
                    if let prev = previousWindowFrame {
                        win.setFrame(prev, display: true, animate: true)
                    }
                    previousWindowFrame = nil
                    didZoomForAnalysis = false
                }
            }
        }
    }
}

#Preview {
    MetronomeView()
}


