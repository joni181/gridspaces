## 1. Popup placement logic

- [x] 1.1 Add a helper that selects the screen containing a global pointer location, with main-screen and first-screen fallbacks
- [x] 1.2 Add a helper that calculates a panel origin centered within a screen's visible frame
- [x] 1.3 Update `PanelController.open()` to sample the pointer after refresh, position the panel on the selected screen, and then present it

## 2. Automated verification

- [x] 2.1 Add unit tests for screen selection, including non-main screens, negative coordinates, and fallback ordering
- [x] 2.2 Add unit tests for centering within visible frames with non-zero and negative origins
- [x] 2.3 Run the Swift test suite and resolve any regressions

## 3. Multi-display verification

- [ ] 3.1 Verify repeated opens follow the pointer across the main and secondary displays
- [ ] 3.2 Verify placement with a secondary display arranged left of or above the main display
- [ ] 3.3 Verify the popup is centered in usable space when the menu bar or Dock reduces the target display's visible frame
