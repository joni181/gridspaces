import CoreGraphics

public enum PopupPlacement {
    public static func targetScreenIndex(
        pointerLocation: CGPoint,
        screenFrames: [CGRect],
        mainScreenIndex: Int?
    ) -> Int? {
        if let pointerScreenIndex = screenFrames.firstIndex(where: { $0.contains(pointerLocation) }) {
            return pointerScreenIndex
        }
        if let mainScreenIndex, screenFrames.indices.contains(mainScreenIndex) {
            return mainScreenIndex
        }
        return screenFrames.indices.first
    }

    public static func centeredOrigin(
        windowSize: CGSize,
        visibleFrame: CGRect
    ) -> CGPoint {
        CGPoint(
            x: visibleFrame.midX - windowSize.width / 2,
            y: visibleFrame.midY - windowSize.height / 2
        )
    }
}
