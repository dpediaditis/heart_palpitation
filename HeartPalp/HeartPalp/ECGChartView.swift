//
//  ECGChartView.swift
//  HeartPalp
//
//  Created by Dimitris Pediaditis on 19/4/25.
//

import SwiftUI

struct ECGChartView: View {
    let data: [Double]
    @State private var offset: CGFloat = 0
    @State private var scale: CGFloat = 1.0
    
    // Configure the viewing parameters
    private let sampleRate: Double  // Apple Watch typical ECG sample rate (Hz)
    private let secondsPerDivision: Double = 0.2 // Time scale - each grid division is 0.2 seconds
    private let pointsPerSecond: Double
    private let totalDurationInSeconds: Double
    
    init(data: [Double], sampleRate: Double = 512.0) {
        self.data = data
        self.sampleRate = sampleRate
        self.pointsPerSecond = sampleRate
        self.totalDurationInSeconds = Double(data.count) / sampleRate
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // ECG chart with grid
            GeometryReader { geo in
                ZStack {
                    // Background grid
                    timeGrid(width: geo.size.width, height: geo.size.height)
                    
                    // ECG waveform with scrolling
                    ScrollView(.horizontal, showsIndicators: true) {
                        waveformPath(totalWidth: calculateTotalWidth(viewWidth: geo.size.width),
                                     height: geo.size.height)
                            .background(timeMarkers(totalWidth: calculateTotalWidth(viewWidth: geo.size.width),
                                                   height: geo.size.height))
                    }
                    .frame(height: geo.size.height)
                }
            }
            
            // Zoom controls
            HStack {
                Button(action: { zoomOut() }) {
                    Image(systemName: "minus.magnifyingglass")
                }
                .buttonStyle(.borderless)
                
                Text("Zoom")
                    .font(.caption)
                
                Button(action: { zoomIn() }) {
                    Image(systemName: "plus.magnifyingglass")
                }
                .buttonStyle(.borderless)
                
                Spacer()
                
                if !data.isEmpty {
                    Text(String(format: "%.1f seconds total", totalDurationInSeconds))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 4)
            .padding(.top, 4)
        }
    }
    
    private func calculateTotalWidth(viewWidth: CGFloat) -> CGFloat {
        // Each second takes up this much horizontal space at the current scale
        let pixelsPerSecond = 250.0 * scale
        
        // Calculate total width needed for the entire ECG
        let totalWidth = CGFloat(totalDurationInSeconds) * pixelsPerSecond
        
        // Ensure we return at least the view width
        return max(totalWidth, viewWidth)
    }
    
    private func timeGrid(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            // Horizontal lines
            VStack(spacing: height / 5) {
                ForEach(0..<6, id: \.self) { _ in
                    Divider().background(Color.gray.opacity(0.3))
                }
            }
            
            // Vertical lines - just for the visible area
            HStack(spacing: width / 5) {
                ForEach(0..<6, id: \.self) { _ in
                    Divider().background(Color.gray.opacity(0.3))
                }
            }
        }
    }
    
    private func timeMarkers(totalWidth: CGFloat, height: CGFloat) -> some View {
        let secondWidth = CGFloat(250.0 * scale) // Width of one second at current scale
        
        return ZStack {
            ForEach(0..<Int(totalDurationInSeconds + 1), id: \.self) { second in
                // Position the second marker
                HStack {
                    Spacer()
                        .frame(width: CGFloat(second) * secondWidth)
                    
                    // Vertical time marker line (taller and more visible)
                    Rectangle()
                        .fill(Color.blue.opacity(0.5))
                        .frame(width: 1, height: height * 0.8)
                    
                    Spacer()
                }
                
                // Second number label
                HStack {
                    Spacer()
                        .frame(width: CGFloat(second) * secondWidth)
                    
                    VStack {
                        Spacer()
                        Text("\(second)s")
                            .font(.caption2)
                            .foregroundColor(.blue)
                        Spacer()
                            .frame(height: 4)
                    }
                    
                    Spacer()
                }
            }
        }
        .frame(width: totalWidth)
    }
    
    private func waveformPath(totalWidth: CGFloat, height: CGFloat) -> some View {
        // Handle empty data case
        guard !data.isEmpty else {
            return AnyView(
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: totalWidth, height: height)
            )
        }
        
        // Find data range with some padding
        let maxY = (data.max() ?? 1.0) + 0.1
        let minY = (data.min() ?? -1.0) - 0.1
        let range = max(maxY - minY, 0.5) // Ensure minimum range
        
        return AnyView(
            ZStack {
                // Baseline (0mV line)
                Rectangle()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: totalWidth, height: 1)
                    .position(x: totalWidth/2, y: height/2)
                
                // ECG waveform
                Path { path in
                    let pointSpacing = totalWidth / CGFloat(data.count)
                    
                    for (index, value) in data.enumerated() {
                        // Calculate x position with scaling
                        let x = CGFloat(index) * pointSpacing
                        
                        // Calculate y position (inverted as y increases downward in UI)
                        // Center the signal vertically in the view
                        let normalizedValue = (value - minY) / range
                        let y = height - (normalizedValue * height * 0.6 + height * 0.2)
                        
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(Color.red, lineWidth: 1.5)
            }
            .frame(width: totalWidth, height: height)
        )
    }
    
    private func zoomIn() {
        withAnimation {
            scale = min(scale * 1.5, 10.0) // Limit max zoom
        }
    }
    
    private func zoomOut() {
        withAnimation {
            scale = max(scale / 1.5, 0.5) // Limit min zoom
        }
    }
}


