import AppKit
import GridSpacesCore

struct ScreenOverlayAssignment: Equatable {
    let screenIndex: Int
    let monitorIndex: Int
}

enum ScreenOverlayMapping {
    static func assignments(
        screenNames: [String],
        monitorNames: [String]
    ) -> [ScreenOverlayAssignment] {
        var monitorIndexByScreen = Array<Int?>(repeating: nil, count: screenNames.count)
        var usedScreens: Set<Int> = []
        var usedMonitors: Set<Int> = []

        for (monitorIndex, monitorName) in monitorNames.enumerated() {
            guard let screenIndex = screenNames.indices.first(where: {
                !usedScreens.contains($0)
                    && screenNames[$0].localizedCaseInsensitiveCompare(monitorName) == .orderedSame
            }) else {
                continue
            }
            monitorIndexByScreen[screenIndex] = monitorIndex
            usedScreens.insert(screenIndex)
            usedMonitors.insert(monitorIndex)
        }

        var remainingMonitorIndices = monitorNames.indices.filter { !usedMonitors.contains($0) }
        for screenIndex in screenNames.indices where monitorIndexByScreen[screenIndex] == nil {
            if remainingMonitorIndices.isEmpty {
                monitorIndexByScreen[screenIndex] = screenIndex
            } else {
                monitorIndexByScreen[screenIndex] = remainingMonitorIndices.removeFirst()
            }
        }

        return screenNames.indices.map {
            ScreenOverlayAssignment(
                screenIndex: $0,
                monitorIndex: monitorIndexByScreen[$0] ?? $0
            )
        }
    }
}

struct ScreenOverlayStyle: Equatable {
    let borderWidth: CGFloat

    static func make(
        screenCount: Int,
        appearance: Appearance
    ) -> ScreenOverlayStyle? {
        guard
            screenCount >= appearance.screenMinimumMonitors,
            appearance.screenBorders
        else { return nil }
        return ScreenOverlayStyle(borderWidth: CGFloat(appearance.screenBorderWidth))
    }
}

enum ScreenOverlayGeometry {
    static func drawingBounds(
        screenFrame: CGRect,
        visibleFrame: CGRect
    ) -> CGRect {
        let topInset = max(0, screenFrame.maxY - visibleFrame.maxY)
        return CGRect(
            x: 0,
            y: 0,
            width: screenFrame.width,
            height: max(0, screenFrame.height - topInset)
        )
    }

    static func borderFrames(
        screenFrame: CGRect,
        visibleFrame: CGRect,
        width: CGFloat
    ) -> [CGRect] {
        guard width > 0 else { return [] }
        let topY = min(screenFrame.maxY, visibleFrame.maxY)
        let height = max(0, topY - screenFrame.minY)
        guard screenFrame.width > 0, height > 0 else { return [] }

        let horizontalWidth = screenFrame.width
        let verticalHeight = max(0, height - width * 2)
        return [
            CGRect(
                x: screenFrame.minX,
                y: topY - width,
                width: horizontalWidth,
                height: width
            ),
            CGRect(
                x: screenFrame.minX,
                y: screenFrame.minY,
                width: horizontalWidth,
                height: width
            ),
            CGRect(
                x: screenFrame.minX,
                y: screenFrame.minY + width,
                width: width,
                height: verticalHeight
            ),
            CGRect(
                x: screenFrame.maxX - width,
                y: screenFrame.minY + width,
                width: width,
                height: verticalHeight
            ),
        ].filter { !$0.isEmpty }
    }
}

@MainActor
protocol ScreenOverlayRendering: AnyObject {
    func update(
        screens: [NSScreen],
        monitors: [MonitorInfo],
        appearance: Appearance
    )
    func remove()
}

@MainActor
public final class ScreenOverlayController: ScreenOverlayRendering {
    private var windows: [NSPanel] = []

    public init() {}

    public func update(
        screens: [NSScreen],
        monitors: [MonitorInfo],
        appearance: Appearance
    ) {
        remove()

        guard let style = ScreenOverlayStyle.make(
            screenCount: screens.count,
            appearance: appearance
        ) else {
            return
        }

        let palette = appearance.monitorColors.isEmpty
            ? Appearance.defaults.monitorColors
            : appearance.monitorColors
        let assignments = ScreenOverlayMapping.assignments(
            screenNames: screens.map(\.localizedName),
            monitorNames: monitors.map(\.name)
        )

        windows = assignments.flatMap { assignment -> [NSPanel] in
            guard screens.indices.contains(assignment.screenIndex) else { return [] }
            let color = NSColor(hexRGB: palette[assignment.monitorIndex % palette.count])
            let screen = screens[assignment.screenIndex]
            return ScreenBorderWindow.makeWindows(
                screen: screen,
                color: color,
                width: style.borderWidth
            )
        }
        windows.forEach { $0.orderFrontRegardless() }
    }

    public func remove() {
        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
    }
}

final class ScreenBorderWindow: NSPanel {
    static func makeWindows(
        screen: NSScreen,
        color: NSColor,
        width: CGFloat
    ) -> [NSPanel] {
        ScreenOverlayGeometry.borderFrames(
            screenFrame: screen.frame,
            visibleFrame: screen.visibleFrame,
            width: width
        ).map { ScreenBorderWindow(frame: $0, color: color) }
    }

    private init(frame: CGRect, color: NSColor) {
        super.init(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        setFrame(frame, display: false)
        backgroundColor = color
        isOpaque = true
        hasShadow = false
        ignoresMouseEvents = true
        acceptsMouseMovedEvents = false
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue - 1)
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

extension NSColor {
    convenience init(hexRGB: String) {
        let digits = hexRGB.dropFirst()
        let value = UInt64(digits, radix: 16)!
        let red = CGFloat((value >> 16) & 0xFF) / 255
        let green = CGFloat((value >> 8) & 0xFF) / 255
        let blue = CGFloat(value & 0xFF) / 255
        self.init(
            srgbRed: red,
            green: green,
            blue: blue,
            alpha: 1
        )
    }
}
