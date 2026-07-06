import AppKit
import GridSpacesCore
import SwiftUI

struct WorkspaceTreeView: View {
    @ObservedObject var viewModel: GridViewModel

    private var highlightedTile: GridTile? {
        guard let name = viewModel.highlightedWorkspace else { return nil }
        return viewModel.model.tile(named: name)
    }

    private var groupedWindows: [(appName: String, windows: [WindowInfo])] {
        var order: [String] = []
        var groups: [String: [WindowInfo]] = [:]
        for window in highlightedTile?.workspace.windows ?? [] {
            if groups[window.appName] == nil {
                order.append(window.appName)
                groups[window.appName] = []
            }
            groups[window.appName]!.append(window)
        }
        return order.map { (appName: $0, windows: groups[$0]!) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
                .padding(.horizontal, 14)
            treeList
        }
        .padding(.top, -14)
        .background(.ultraThinMaterial)
        .fixedSize()
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "rectangle.split.2x2")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            if let name = viewModel.highlightedWorkspace {
                Text("Workspace \(name)")
                    .font(.headline.weight(.semibold))
            } else {
                Text("No workspace")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            let count = highlightedTile?.workspace.windows.count ?? 0
            if count > 0 {
                Text("\(count)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.primary.opacity(0.08)))
            }
        }
        .frame(minWidth: 260)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var treeList: some View {
        let groups = groupedWindows
        if groups.isEmpty {
            Text("Empty workspace")
                .font(.callout)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(groups.enumerated()), id: \.element.appName) { _, group in
                    AppGroupRow(
                        appName: group.appName,
                        windows: group.windows,
                        iconResolver: viewModel.iconResolver
                    )
                }
            }
            .padding(.bottom, 10)
        }
    }
}

private struct AppGroupRow: View {
    let appName: String
    let windows: [WindowInfo]
    let iconResolver: AppIconResolver

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // App row — no branch char, aligned with header icon at x=16
            HStack(spacing: 8) {
                Image(nsImage: iconResolver.icon(for: appName))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)

                Text(appName)
                    .font(.callout.weight(.medium))
                    .lineLimit(1)

                Spacer(minLength: 0)

                if windows.count > 1 {
                    Text("\(windows.count)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(Color.primary.opacity(0.08)))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 4)

            // Window rows — branch chars only when there are siblings
            ForEach(Array(windows.enumerated()), id: \.element.id) { index, window in
                let isLast = index == windows.count - 1
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(isLast ? "└" : "├")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Color.primary.opacity(0.25))

                    Text(window.title.isEmpty ? window.appName : window.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Spacer(minLength: 0)
                }
                .padding(.leading, 16)
                .padding(.trailing, 16)
                .padding(.vertical, 2)
                .help("\(window.appName): \(window.title)")
            }
            .padding(.bottom, 4)
        }
    }
}
