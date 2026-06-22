import AppKit
import GridSpacesCore
import SwiftUI

struct GridView: View {
    @ObservedObject var viewModel: GridViewModel
    let onOpenConfig: () -> Void
    private let tileSize = CGSize(width: 154, height: 112)

    var body: some View {
        VStack(spacing: 14) {
            header
            if viewModel.isLoading && viewModel.model.tiles.isEmpty {
                ProgressView("Reading AeroSpace…")
                    .frame(minWidth: 420, minHeight: 180)
            } else {
                workspaceGrid
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .padding(.top, -14)
        .background(.ultraThinMaterial)
        .fixedSize()
    }

    private var header: some View {
        HStack {
            Text("GridSpaces")
                .font(.title2.weight(.semibold))
            Spacer()
            if let pending = viewModel.pendingCloseWorkspace {
                Text("Close every window in \(pending)? Enter confirms; any other key cancels.")
                    .foregroundStyle(.red)
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .lineLimit(2)
                    .foregroundStyle(.red)
                    .help(error)
            }
            Button(action: onOpenConfig) {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.plain)
            .help("Open Config (⌘,)")
            .accessibilityLabel("Open GridSpaces Configuration")
        }
        .frame(minWidth: 420)
    }

    private var workspaceGrid: some View {
        let tileByPosition = Dictionary(
            uniqueKeysWithValues: viewModel.model.tiles.map { ($0.position, $0) }
        )
        return Grid(horizontalSpacing: 10, verticalSpacing: 10) {
            ForEach(0..<viewModel.model.rowCount, id: \.self) { row in
                GridRow {
                    ForEach(0..<viewModel.model.columnCount, id: \.self) { column in
                        if let tile = tileByPosition[Position(row: row, column: column)] {
                            WorkspaceTile(
                                tile: tile,
                                isHighlighted: tile.workspace.name == viewModel.highlightedWorkspace,
                                isFocused: tile.workspace.name == viewModel.focusedWorkspace,
                                isMoveModeActive: viewModel.isWorkspaceMoveModeActive,
                                outlineColor: viewModel.monitorColor(for: tile.workspace.monitorID),
                                iconResolver: viewModel.iconResolver
                            )
                            .frame(width: tileSize.width, height: tileSize.height)
                        } else {
                            Color.clear
                                .frame(width: tileSize.width, height: tileSize.height)
                        }
                    }
                }
            }
        }
    }
}

private struct WorkspaceTile: View {
    let tile: GridTile
    let isHighlighted: Bool
    let isFocused: Bool
    let isMoveModeActive: Bool
    let outlineColor: Color
    let iconResolver: AppIconResolver
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(tile.workspace.name)
                    .font(.title2.monospaced().weight(.bold))
                Spacer()
                if isFocused {
                    Text("ACTIVE")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if tile.workspace.distinctApplications.isEmpty {
                Text("Empty")
                    .font(.callout)
                    .foregroundStyle(.tertiary)
            } else {
                HStack(spacing: -5) {
                    ForEach(tile.workspace.distinctApplications.prefix(6), id: \.self) { app in
                        Image(nsImage: iconResolver.icon(for: app))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 34, height: 34)
                            .help(app)
                    }
                }
            }
        }
        .padding(13)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isHighlighted ? Color.accentColor.opacity(0.24) : Color.primary.opacity(0.055))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    isHighlighted ? Color.accentColor : outlineColor,
                    lineWidth: isHighlighted ? 4 : 2
                )
        )
        .scaleEffect(isMoveModeActive && reduceMotion ? 1.025 : 1)
        .rotationEffect(
            .degrees(isMoveModeActive && !reduceMotion ? 1.25 : 0)
        )
        .animation(
            isMoveModeActive && !reduceMotion
                ? .easeInOut(duration: 0.09)
                    .repeatForever(autoreverses: true)
                    .delay(Double(tile.position.row + tile.position.column) * 0.012)
                : .easeOut(duration: 0.12),
            value: isMoveModeActive
        )
        .accessibilityLabel("Workspace \(tile.workspace.name)")
    }
}
