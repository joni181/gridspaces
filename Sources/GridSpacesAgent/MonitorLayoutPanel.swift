import AppKit
import CoreGraphics
import GridSpacesCore
import SwiftUI

struct MonitorScreenDescriptor: Equatable {
    let frame: CGRect
    let displayID: Int?
    let name: String

    init(frame: CGRect, displayID: Int? = nil, name: String = "") {
        self.frame = frame
        self.displayID = displayID
        self.name = name
    }

    init(screen: NSScreen) {
        let screenNumberKey = NSDeviceDescriptionKey("NSScreenNumber")
        let displayID = (screen.deviceDescription[screenNumberKey] as? NSNumber)?.intValue
        self.init(
            frame: screen.frame,
            displayID: displayID,
            name: screen.localizedName
        )
    }
}

struct MonitorLayoutModel: Equatable {
    let virtualSize: CGSize
    let items: [MonitorLayoutItem]

    static let empty = MonitorLayoutModel(virtualSize: .zero, items: [])

    static func build(
        screens: [MonitorScreenDescriptor],
        monitors: [MonitorInfo],
        activeMonitorID: Int?,
        palette configuredPalette: [String]
    ) -> MonitorLayoutModel {
        let palette = configuredPalette.isEmpty
            ? Appearance.defaults.monitorColors
            : configuredPalette
        let indexedScreens = screens.enumerated().filter { _, screen in
            screen.frame.width > 0 && screen.frame.height > 0
        }
        guard let firstFrame = indexedScreens.first?.element.frame else {
            return .empty
        }

        let union = indexedScreens.dropFirst().reduce(firstFrame) { partial, entry in
            partial.union(entry.element.frame)
        }
        guard union.width > 0, union.height > 0 else {
            return .empty
        }

        let fallbackOrder = fallbackOrderByScreenIndex(indexedScreens)
        let monitorMatches = monitorMatches(
            for: indexedScreens,
            monitors: monitors,
            fallbackOrder: fallbackOrder
        )

        let items = indexedScreens.map { originalIndex, screen in
            let fallbackIndex = fallbackOrder[originalIndex] ?? originalIndex
            let monitorMatch = monitorMatches[originalIndex]
            let colorIndex = monitorMatch?.index ?? fallbackIndex
            let rect = CGRect(
                x: screen.frame.minX - union.minX,
                y: union.maxY - screen.frame.maxY,
                width: screen.frame.width,
                height: screen.frame.height
            )
            let monitorID = monitorMatch?.monitor.id
            return MonitorLayoutItem(
                id: "\(originalIndex)-\(screen.displayID.map(String.init) ?? "screen")",
                monitorID: monitorID,
                name: monitorMatch?.monitor.name ?? screen.name,
                rect: rect,
                colorHex: palette[colorIndex % palette.count],
                isActive: activeMonitorID != nil && monitorID == activeMonitorID
            )
        }

        return MonitorLayoutModel(
            virtualSize: CGSize(width: union.width, height: union.height),
            items: items
        )
    }

    private static func fallbackOrderByScreenIndex(
        _ indexedScreens: [(offset: Int, element: MonitorScreenDescriptor)]
    ) -> [Int: Int] {
        let sorted = indexedScreens.sorted { left, right in
            let lhs = left.element.frame
            let rhs = right.element.frame
            if lhs.minX != rhs.minX { return lhs.minX < rhs.minX }
            if lhs.maxY != rhs.maxY { return lhs.maxY > rhs.maxY }
            if lhs.width != rhs.width { return lhs.width > rhs.width }
            if lhs.height != rhs.height { return lhs.height > rhs.height }
            if left.element.name != right.element.name {
                return left.element.name < right.element.name
            }
            return left.offset < right.offset
        }
        return Dictionary(uniqueKeysWithValues: sorted.enumerated().map { order, entry in
            (entry.offset, order)
        })
    }

    private struct MonitorMatch {
        let monitor: MonitorInfo
        let index: Int
    }

    private static func monitorMatches(
        for indexedScreens: [(offset: Int, element: MonitorScreenDescriptor)],
        monitors: [MonitorInfo],
        fallbackOrder: [Int: Int]
    ) -> [Int: MonitorMatch] {
        var matches: [Int: MonitorMatch] = [:]
        var usedMonitorIndices: Set<Int> = []
        let monitorNameCounts = Dictionary(
            grouping: monitors.map { normalizedName($0.name) },
            by: { $0 }
        ).mapValues(\.count)
        let screenNameCounts = Dictionary(
            grouping: indexedScreens.map { normalizedName($0.element.name) },
            by: { $0 }
        ).mapValues(\.count)

        for originalIndex in indexedScreens.map(\.offset) {
            let screenPosition = originalIndex + 1
            if let monitorIndex = monitors.firstIndex(
                where: { $0.appKitScreenIndex == screenPosition }
            ), !usedMonitorIndices.contains(monitorIndex) {
                matches[originalIndex] = MonitorMatch(
                    monitor: monitors[monitorIndex],
                    index: monitorIndex
                )
                usedMonitorIndices.insert(monitorIndex)
                continue
            }

            guard let screen = indexedScreens.first(where: { $0.offset == originalIndex })?.element,
                  let displayID = screen.displayID,
                  let monitorIndex = monitors.firstIndex(where: { $0.id == displayID }),
                  !usedMonitorIndices.contains(monitorIndex)
            else {
                continue
            }
            matches[originalIndex] = MonitorMatch(
                monitor: monitors[monitorIndex],
                index: monitorIndex
            )
            usedMonitorIndices.insert(monitorIndex)
        }

        for originalIndex in indexedScreens.map(\.offset) {
            guard matches[originalIndex] == nil,
                  let screen = indexedScreens.first(where: { $0.offset == originalIndex })?.element
            else {
                continue
            }
            let screenName = normalizedName(screen.name)
            guard !screenName.isEmpty,
                  screenNameCounts[screenName] == 1,
                  monitorNameCounts[screenName] == 1,
                  let monitorIndex = monitors.firstIndex(
                    where: { normalizedName($0.name) == screenName }
                  ),
                  !usedMonitorIndices.contains(monitorIndex)
            else {
                continue
            }
            matches[originalIndex] = MonitorMatch(
                monitor: monitors[monitorIndex],
                index: monitorIndex
            )
            usedMonitorIndices.insert(monitorIndex)
        }

        let screensByFallbackOrder = indexedScreens.sorted { left, right in
            (fallbackOrder[left.offset] ?? left.offset) < (fallbackOrder[right.offset] ?? right.offset)
        }
        for originalIndex in screensByFallbackOrder.map(\.offset) where matches[originalIndex] == nil {
            let preferredIndex = fallbackOrder[originalIndex] ?? originalIndex
            let monitorIndex = preferredUnusedMonitorIndex(
                preferredIndex: preferredIndex,
                monitors: monitors,
                usedMonitorIndices: usedMonitorIndices
            )
            guard let monitorIndex else { continue }
            matches[originalIndex] = MonitorMatch(
                monitor: monitors[monitorIndex],
                index: monitorIndex
            )
            usedMonitorIndices.insert(monitorIndex)
        }

        return matches
    }

    private static func preferredUnusedMonitorIndex(
        preferredIndex: Int,
        monitors: [MonitorInfo],
        usedMonitorIndices: Set<Int>
    ) -> Int? {
        if monitors.indices.contains(preferredIndex),
           !usedMonitorIndices.contains(preferredIndex) {
            return preferredIndex
        }
        return monitors.indices.first { !usedMonitorIndices.contains($0) }
    }

    private static func normalizedName(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

struct MonitorLayoutItem: Identifiable, Equatable {
    let id: String
    let monitorID: Int?
    let name: String
    let rect: CGRect
    let colorHex: String
    let isActive: Bool
}

struct MonitorLayoutPanel: View {
    @ObservedObject var viewModel: GridViewModel

    private let canvasSize = CGSize(width: 150, height: 110)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
                .padding(.horizontal, 14)
            MonitorLayoutCanvas(layout: viewModel.monitorLayoutModel)
                .frame(width: canvasSize.width, height: canvasSize.height)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
        }
        .padding(.top, -14)
        .background(.ultraThinMaterial)
        .fixedSize()
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "display.2")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("Displays")
                .font(.headline.weight(.semibold))
            Spacer()
            let count = viewModel.connectedMonitorCount
            if count > 0 {
                Text("\(count)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.primary.opacity(0.08)))
            }
        }
        .frame(width: canvasSize.width)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

private struct MonitorLayoutCanvas: View {
    let layout: MonitorLayoutModel
    private let monitorInset: CGFloat = 2

    var body: some View {
        GeometryReader { geometry in
            if layout.items.isEmpty || layout.virtualSize.width <= 0 || layout.virtualSize.height <= 0 {
                Color.clear
                    .accessibilityHidden(true)
            } else {
                let scale = min(
                    geometry.size.width / layout.virtualSize.width,
                    geometry.size.height / layout.virtualSize.height
                )
                let scaledSize = CGSize(
                    width: layout.virtualSize.width * scale,
                    height: layout.virtualSize.height * scale
                )
                let origin = CGPoint(
                    x: (geometry.size.width - scaledSize.width) / 2,
                    y: (geometry.size.height - scaledSize.height) / 2
                )

                ZStack(alignment: .topLeading) {
                    ForEach(layout.items) { item in
                        monitorShape(for: item)
                            .frame(
                                width: max(2, item.rect.width * scale - monitorInset * 2),
                                height: max(2, item.rect.height * scale - monitorInset * 2)
                            )
                            .position(
                                x: origin.x + item.rect.midX * scale,
                                y: origin.y + item.rect.midY * scale
                            )
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
    }

    private func monitorShape(for item: MonitorLayoutItem) -> some View {
        let color = Color(hexRGB: item.colorHex)
        return RoundedRectangle(cornerRadius: 4)
            .fill(color.opacity(item.isActive ? 0.56 : 0.16))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(color.opacity(item.isActive ? 1 : 0.7), lineWidth: item.isActive ? 3 : 1.5)
            )
            .shadow(
                color: color.opacity(item.isActive ? 0.45 : 0),
                radius: item.isActive ? 8 : 0
            )
            .accessibilityLabel(accessibilityLabel(for: item))
    }

    private func accessibilityLabel(for item: MonitorLayoutItem) -> Text {
        let name = item.name.isEmpty ? "Display" : item.name
        return Text(item.isActive ? "\(name), active display" : "\(name), inactive display")
    }
}
