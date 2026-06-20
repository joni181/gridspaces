import AppKit
import GridSpacesCore
import SwiftUI
import Testing
@testable import GridSpacesAgent

@MainActor
@Test func monitorColorsFollowConfiguredOrderAndCycle() {
    let config = GridSpacesConfig(
        grid: [["1"]],
        appearance: Appearance(monitorColors: ["#112233", "#ABCDEF"])
    )
    let viewModel = GridViewModel(config: config)
    viewModel.monitors = [
        MonitorInfo(id: 10, name: "First"),
        MonitorInfo(id: 20, name: "Second"),
        MonitorInfo(id: 30, name: "Third"),
    ]

    #expect(viewModel.monitorColorHex(for: 10) == "#112233")
    #expect(viewModel.monitorColorHex(for: 20) == "#ABCDEF")
    #expect(viewModel.monitorColorHex(for: 30) == "#112233")
}

@MainActor
@Test func monitorColorUsesFirstColorForSingleOrUnknownMonitor() {
    let config = GridSpacesConfig(
        grid: [["1"]],
        appearance: Appearance(monitorColors: ["#123456", "#ABCDEF"])
    )
    let viewModel = GridViewModel(config: config)
    viewModel.monitors = [MonitorInfo(id: 10, name: "Only")]

    #expect(viewModel.monitorColorHex(for: 10) == "#123456")
    #expect(viewModel.monitorColorHex(for: nil) == "#123456")

    viewModel.monitors.append(MonitorInfo(id: 20, name: "Second"))
    #expect(viewModel.monitorColorHex(for: 999) == "#123456")
}

@MainActor
@Test func emptyProgrammaticPaletteFallsBackWithoutCrashing() {
    let config = GridSpacesConfig(
        grid: [["1"]],
        appearance: Appearance(monitorColors: [])
    )
    let viewModel = GridViewModel(config: config)

    #expect(viewModel.monitorColorHex(for: nil) == Appearance.defaults.monitorColors[0])
}

@MainActor
@Test func hexRGBColorConvertsToExpectedSRGBComponents() throws {
    let color = Color(hexRGB: "#3366CC")
    let converted = try #require(NSColor(color).usingColorSpace(.sRGB))

    #expect(abs(converted.redComponent - 0.2) < 0.001)
    #expect(abs(converted.greenComponent - 0.4) < 0.001)
    #expect(abs(converted.blueComponent - 0.8) < 0.001)
    #expect(abs(converted.alphaComponent - 1) < 0.001)
}
