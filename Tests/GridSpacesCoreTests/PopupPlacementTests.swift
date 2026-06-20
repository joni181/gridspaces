import CoreGraphics
import Testing
@testable import GridSpacesCore

@Test func selectsScreenContainingPointer() {
    let frames = [
        CGRect(x: 0, y: 0, width: 1920, height: 1080),
        CGRect(x: 1920, y: 0, width: 2560, height: 1440),
    ]

    #expect(
        PopupPlacement.targetScreenIndex(
            pointerLocation: CGPoint(x: 2400, y: 700),
            screenFrames: frames,
            mainScreenIndex: 0
        ) == 1
    )
}

@Test func selectsScreenWithNegativeCoordinates() {
    let frames = [
        CGRect(x: 0, y: 0, width: 1920, height: 1080),
        CGRect(x: -1440, y: 100, width: 1440, height: 900),
    ]

    #expect(
        PopupPlacement.targetScreenIndex(
            pointerLocation: CGPoint(x: -700, y: 500),
            screenFrames: frames,
            mainScreenIndex: 0
        ) == 1
    )
}

@Test func fallsBackToMainThenFirstScreen() {
    let frames = [
        CGRect(x: 0, y: 0, width: 1920, height: 1080),
        CGRect(x: 1920, y: 0, width: 2560, height: 1440),
    ]
    let unmatchedPointer = CGPoint(x: 10_000, y: 10_000)

    #expect(
        PopupPlacement.targetScreenIndex(
            pointerLocation: unmatchedPointer,
            screenFrames: frames,
            mainScreenIndex: 1
        ) == 1
    )
    #expect(
        PopupPlacement.targetScreenIndex(
            pointerLocation: unmatchedPointer,
            screenFrames: frames,
            mainScreenIndex: nil
        ) == 0
    )
    #expect(
        PopupPlacement.targetScreenIndex(
            pointerLocation: unmatchedPointer,
            screenFrames: [],
            mainScreenIndex: nil
        ) == nil
    )
}

@Test func ignoresInvalidMainScreenIndex() {
    #expect(
        PopupPlacement.targetScreenIndex(
            pointerLocation: CGPoint(x: 10_000, y: 10_000),
            screenFrames: [CGRect(x: 0, y: 0, width: 1920, height: 1080)],
            mainScreenIndex: 4
        ) == 0
    )
}

@Test func centersWithinInsetVisibleFrame() {
    let origin = PopupPlacement.centeredOrigin(
        windowSize: CGSize(width: 800, height: 500),
        visibleFrame: CGRect(x: 0, y: 40, width: 1920, height: 1017)
    )

    #expect(origin == CGPoint(x: 560, y: 298.5))
}

@Test func centersWithinNegativeVisibleFrame() {
    let origin = PopupPlacement.centeredOrigin(
        windowSize: CGSize(width: 600, height: 400),
        visibleFrame: CGRect(x: -1440, y: -900, width: 1440, height: 860)
    )

    #expect(origin == CGPoint(x: -1020, y: -670))
}
