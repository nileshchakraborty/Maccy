import Defaults
import SwiftUI

struct HistoryListView: View {
  @Binding var searchQuery: String
  @FocusState.Binding var searchFocused: Bool

  @Environment(AppState.self) private var appState
  @Environment(ModifierFlags.self) private var modifierFlags
  @Environment(\.scenePhase) private var scenePhase

  @Default(.pinTo) private var pinTo
  @Default(.previewDelay) private var previewDelay
  @Default(.showFooter) private var showFooter

  private var pinnedItems: [HistoryItemDecorator] {
    appState.history.pinnedItems
  }
  private var unpinnedItems: [HistoryItemDecorator] {
    appState.history.unpinnedItems
  }
  private var showPinsSeparator: Bool {
    pinsVisible && !unpinnedItems.isEmpty
  }

  private var pinsVisible: Bool {
    return !pinnedItems.isEmpty
  }

  private var pasteStackVisible: Bool {
    if let stack = appState.history.pasteStack,
       !stack.items.isEmpty {
      return true
    }
    return false
  }

  private var isSearching: Bool {
    !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  private var totalMatchCount: Int {
    pinnedItems.count + unpinnedItems.count
  }

  private func searchBanner() -> some View {
    HStack(spacing: 6) {
      Image(systemName: "magnifyingglass")
        .font(.system(size: 10, weight: .bold))
        .foregroundColor(.accentColor)

      Text("SEARCH RESULTS FOR \"\(searchQuery)\"")
        .font(.system(size: 10, weight: .bold))
        .foregroundColor(.accentColor)
        .lineLimit(1)

      Spacer()

      Text("\(totalMatchCount) match\(totalMatchCount == 1 ? "" : "es")")
        .font(.system(size: 10, weight: .semibold, design: .monospaced))
        .foregroundColor(.secondary)

      Button(action: { searchQuery = "" }) {
        Text("Clear")
          .font(.system(size: 10, weight: .medium))
          .foregroundColor(.accentColor)
      }
      .buttonStyle(.plain)
      .help("Clear search")
    }
    .padding(.horizontal, Popup.horizontalPadding)
    .padding(.vertical, 4)
  }

  private var topPadding: CGFloat {
    return Popup.verticalSeparatorPadding
  }

  private var bottomPadding: CGFloat {
    return showFooter
      ? Popup.verticalSeparatorPadding
      : (Popup.verticalSeparatorPadding - 1)
  }

  private func topSeparator() -> some View {
    Divider()
      .padding(.horizontal, Popup.horizontalSeparatorPadding)
      .padding(.top, Popup.verticalSeparatorPadding)
  }

  @ViewBuilder
  private func bottomSeparator() -> some View {
    Divider()
      .padding(.horizontal, Popup.horizontalSeparatorPadding)
      .padding(.bottom, Popup.verticalSeparatorPadding)
  }

  @ViewBuilder
  private func separator() -> some View {
    Divider()
      .padding(.horizontal, Popup.horizontalSeparatorPadding)
      .padding(.vertical, Popup.verticalSeparatorPadding)
  }

  var body: some View {
    let topPinsVisible = pinTo == .top && pinsVisible
    let bottomPinsVisible = pinTo == .bottom && pinsVisible
    let historyEmpty = unpinnedItems.isEmpty
    let topSeparatorVisible = !historyEmpty && (topPinsVisible || pasteStackVisible)
    let bottomSeparatorVisible = !historyEmpty && bottomPinsVisible
    let scrollTopPadding = topSeparatorVisible ? Popup.verticalSeparatorPadding : topPadding
    let scrollBottomPadding = bottomSeparatorVisible ? Popup.verticalSeparatorPadding : bottomPadding

    VStack(spacing: 0) {
      if isSearching {
        searchBanner()
        topSeparator()
      }

      if let stack = appState.history.pasteStack,
         !stack.items.isEmpty {
        PasteStackView(stack: stack)

        if topPinsVisible {
          separator()
        }
      }

      if topPinsVisible {
        PinsView(items: pinnedItems)
      }

      if topSeparatorVisible {
        topSeparator()
      } else if showFooter && historyEmpty {
        Spacer()
          .frame(height: Popup.verticalSeparatorPadding)
      }
    }
    .padding(.top, topSeparatorVisible ? topPadding : 0)
    .readHeight(appState, into: \.popup.extraTopHeight)

    ScrollView {
      if isSearching && pinnedItems.isEmpty && unpinnedItems.isEmpty {
        VStack(spacing: 8) {
          Image(systemName: "magnifyingglass")
            .font(.system(size: 24))
            .foregroundColor(.secondary.opacity(0.6))
            .padding(.top, 24)
          Text("No results for \"\(searchQuery)\"")
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.secondary)
          Text("Try searching for different keywords")
            .font(.system(size: 11))
            .foregroundColor(.secondary.opacity(0.7))
          Button("Clear Search") {
            searchQuery = ""
          }
          .buttonStyle(.bordered)
          .controlSize(.small)
          .padding(.top, 4)
          .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
      } else {
        ScrollViewReader { proxy in
          MultipleSelectionListView(items: unpinnedItems) { previous, item, next, index in
            HistoryItemView(item: item, previous: previous, next: next, index: index)
          }
          .padding(.top, scrollTopPadding)
          .padding(.bottom, scrollBottomPadding)
          .task(id: appState.navigator.scrollTarget) {
            guard appState.navigator.scrollTarget != nil else { return }

            try? await Task.sleep(for: .milliseconds(10))
            guard !Task.isCancelled else { return }

            if let selection = appState.navigator.scrollTarget {
              proxy.scrollTo(selection)
              appState.navigator.scrollTarget = nil
            }
          }
          .onChange(of: scenePhase) {
            if scenePhase == .active {
              searchFocused = true
              appState.navigator.isKeyboardNavigating = true
              appState.navigator.select(item: appState.history.firstUnpinnedItem ?? appState.history.firstPinnedItem)
              appState.preview.enableAutoOpen()
              appState.preview.resetAutoOpenSuppression()
              appState.preview.startAutoOpen()
            } else {
              modifierFlags.flags = []
              appState.navigator.isKeyboardNavigating = true
              appState.preview.cancelAutoOpen()
            }
          }
          // Calculate the total height inside a scroll view.
          .background {
            GeometryReader { geo in
              Color.clear
                .task(id: appState.popup.needsResize) {
                  try? await Task.sleep(for: .milliseconds(10))
                  guard !Task.isCancelled else { return }

                  if appState.popup.needsResize {
                    appState.popup.resize(height: geo.size.height)
                  }
                }
            }
          }
        }
        .contentMargins(.leading, 10, for: .scrollIndicators)
        .contentMargins(.top, scrollTopPadding, for: .scrollIndicators)
        .contentMargins(.bottom, scrollBottomPadding, for: .scrollIndicators)
      }
    }
    .accessibilityIdentifier("history-scroll-view")

    VStack(spacing: 0) {
      if bottomSeparatorVisible {
        bottomSeparator()
      }

      if bottomPinsVisible {
        PinsView(items: pinnedItems)
      }
    }
    .padding(.bottom, bottomPinsVisible ? bottomPadding : 0)
    .readHeight(appState, into: \.popup.extraBottomHeight)
  }
}
