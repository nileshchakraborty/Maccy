import Defaults
import SwiftUI

enum SelectionAppearance {
  case none
  case topConnection
  case bottomConnection
  case topBottomConnection

  func rect(cornerRadius: CGFloat) -> some Shape {
    var cornerRadii = RectangleCornerRadii()
    switch self {
    case .none:
      cornerRadii.topLeading = cornerRadius
      cornerRadii.topTrailing = cornerRadius
      cornerRadii.bottomLeading = cornerRadius
      cornerRadii.bottomTrailing = cornerRadius
    case .topConnection:
      cornerRadii.bottomLeading = cornerRadius
      cornerRadii.bottomTrailing = cornerRadius
    case .bottomConnection:
      cornerRadii.topLeading = cornerRadius
      cornerRadii.topTrailing = cornerRadius
    case .topBottomConnection:
      break
    }
    return .rect(cornerRadii: cornerRadii)
  }
}

struct ListItemView<Title: View, ID: Hashable>: View {
  var id: ID
  var selectionId: UUID
  var appIcon: ApplicationImage?
  var image: NSImage?
  var accessoryImage: NSImage?
  var attributedTitle: AttributedString?
  var shortcuts: [KeyShortcut]
  var isSelected: Bool
  var selectionIndex: Int?
  var help: LocalizedStringKey?
  var selectionAppearance: SelectionAppearance = .none
  // Complete description used when the row's visual content is hidden from accessibility.
  var accessibilityLabel: String = ""
  var isPinned: Bool = false
  var onCopy: (() -> Void)? = nil
  var onTogglePin: (() -> Void)? = nil
  var onDelete: (() -> Void)? = nil
  @ViewBuilder var title: () -> Title

  @State private var isRowHovered: Bool = false
  @State private var isPinHovered: Bool = false
  @State private var isCopyHovered: Bool = false
  @State private var isDeleteHovered: Bool = false

  @Default(.showApplicationIcons) private var showIcons
  @Environment(AppState.self) private var appState
  @Environment(ModifierFlags.self) private var modifierFlags

  // Use the same selection number for the visible badge and accessibility value.
  private var displaySelectionIndex: String? {
    selectionIndex.map { "\($0 + 1)" }
  }

  var body: some View {
    HStack(spacing: 0) {
      if showIcons, let appIcon {
        VStack {
          Spacer(minLength: 0)
          AppImageView(appImage: appIcon, size: NSSize(width: 15, height: 15))
          Spacer(minLength: 0)
        }
        .padding(.leading, 4)
        .padding(.vertical, 5)
      }

      Spacer()
        .frame(width: showIcons ? 5 : 10)

      if let accessoryImage {
        Image(nsImage: accessoryImage)
          .accessibilityIdentifier("copy-history-item")
          .accessibilityHidden(true)
          .padding(.trailing, 5)
          .padding(.vertical, 5)
      }

      if let image {
        Image(nsImage: image)
          .accessibilityIdentifier("copy-history-item")
          .accessibilityHidden(true)
          .padding(.trailing, 5)
          .padding(.vertical, 5)
      } else {
        ListItemTitleView(attributedTitle: attributedTitle, title: title)
          .accessibilityHidden(true)
          .padding(.trailing, 5)
      }

      Spacer()

      HStack(spacing: 5) {
        if isRowHovered && (onCopy != nil || onTogglePin != nil || onDelete != nil) {
          if let onTogglePin {
            Button(action: onTogglePin) {
              Image(systemName: isPinned ? "pin.fill" : "pin")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(isPinHovered ? .white : (isPinned ? .orange : (isSelected ? .white : .secondary)))
                .frame(width: 20, height: 20)
                .background(
                  Circle()
                    .fill(isPinHovered ? Color.orange : (isPinned ? Color.orange.opacity(0.25) : Color.secondary.opacity(0.18)))
                )
                .scaleEffect(isPinHovered ? 1.15 : 1.0)
                .shadow(color: isPinHovered ? Color.orange.opacity(0.4) : Color.clear, radius: 3, x: 0, y: 1)
            }
            .buttonStyle(.plain)
            .help(isPinned ? "Unpin item" : "Pin to Pin Board")
            .onHover { h in
              withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                isPinHovered = h
              }
            }
          }

          if let onCopy {
            Button(action: onCopy) {
              Image(systemName: "doc.on.doc")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(isCopyHovered ? .white : (isSelected ? .white : .secondary))
                .frame(width: 20, height: 20)
                .background(
                  Circle()
                    .fill(isCopyHovered ? Color.blue : Color.secondary.opacity(0.18))
                )
                .scaleEffect(isCopyHovered ? 1.15 : 1.0)
                .shadow(color: isCopyHovered ? Color.blue.opacity(0.4) : Color.clear, radius: 3, x: 0, y: 1)
            }
            .buttonStyle(.plain)
            .help("Copy to clipboard")
            .onHover { h in
              withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                isCopyHovered = h
              }
            }
          }

          if let onDelete {
            Button(action: onDelete) {
              Image(systemName: "trash")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(isDeleteHovered ? .white : (isSelected ? .white : Color.red.opacity(0.85)))
                .frame(width: 20, height: 20)
                .background(
                  Circle()
                    .fill(isDeleteHovered ? Color.red : Color.red.opacity(0.18))
                )
                .scaleEffect(isDeleteHovered ? 1.15 : 1.0)
                .shadow(color: isDeleteHovered ? Color.red.opacity(0.4) : Color.clear, radius: 3, x: 0, y: 1)
            }
            .buttonStyle(.plain)
            .help("Delete item")
            .onHover { h in
              withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                isDeleteHovered = h
              }
            }
          }
        } else {
          if let displaySelectionIndex {
            Text(displaySelectionIndex)
              .font(.caption)
              .frame(minWidth: 10, alignment: .center)
              .padding(3)
              .background(
                Color.secondary.opacity(isSelected ? 0.5 : 0.8),
                in: Capsule()
              )
              .foregroundStyle(Color.white)
              .accessibilityHidden(true)
          }

          if !shortcuts.isEmpty {
            ZStack(alignment: .trailing) {
              ForEach(shortcuts) { shortcut in
                let visible = shortcut.isVisible(shortcuts, modifierFlags.flags)
                KeyboardShortcutView(shortcut: shortcut)
                  .opacity(visible ? 1 : 0)
                  .accessibilityHidden(true)
                  .frame(width: visible ? nil : 0)
              }
            }
          }
        }
      }
      .padding(.trailing, 10)
    }
    .frame(minHeight: Popup.itemHeight)
    .id(id)
    .frame(maxWidth: .infinity, alignment: .leading)
    .foregroundStyle(isSelected ? Color.white : .primary)
    // macOS 26 broke hovering if no background is present.
    // The slight opcaity white background is a workaround
    .background(
      isSelected ? Color.accentColor.opacity(0.8) : .white.opacity(0.001),
      in: selectionAppearance.rect(cornerRadius: Popup.cornerRadius)
    )
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text(accessibilityLabel))
    .accessibilityAddTraits(isSelected ? .isSelected : [])
    .accessibilityValue(Text(displaySelectionIndex ?? ""))
    .hoverSelectionId(selectionId)
    .onHover { hovering in
      withAnimation(.easeInOut(duration: 0.15)) {
        isRowHovered = hovering
        if !hovering {
          isPinHovered = false
          isCopyHovered = false
          isDeleteHovered = false
        }
      }
    }
    .help(help ?? "")
  }
}
