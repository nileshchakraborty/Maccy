import AppKit
import SwiftUI

@Observable
class FooterItem: Equatable, Identifiable, HasVisibility {
  struct Confirmation {
    var message: String
    var comment: String
    var confirm: String
    var cancel: String
  }

  static func == (lhs: FooterItem, rhs: FooterItem) -> Bool {
    return lhs.id == rhs.id
  }

  let id = UUID()

  var title: String
  var shortcuts: [KeyShortcut] = []
  var help: LocalizedStringKey?
  var isSelected: Bool = false
  var confirmation: Confirmation?
  var showConfirmation: Bool = false
  var suppressConfirmation: Binding<Bool>?
  var isVisible: Bool = true
  var action: () -> Void

  init(
    title: String,
    shortcuts: [KeyShortcut] = [],
    help: LocalizedStringKey? = nil,
    confirmation: Confirmation? = nil,
    suppressConfirmation: Binding<Bool>? = nil,
    action: @escaping () -> Void
  ) {
    self.title = title
    self.shortcuts = shortcuts
    self.help = help
    self.confirmation = confirmation
    self.suppressConfirmation = suppressConfirmation
    self.action = action
  }

  @MainActor
  func performAction() {
    if let confirmation = confirmation, let suppressConfirmation = suppressConfirmation {
      if suppressConfirmation.wrappedValue {
        action()
      } else {
        showConfirmationAlert(confirmation: confirmation, suppressConfirmation: suppressConfirmation)
      }
    } else {
      action()
    }
  }

  @MainActor
  private func showConfirmationAlert(
    confirmation: Confirmation,
    suppressConfirmation: Binding<Bool>
  ) {
    let alert = NSAlert()
    alert.messageText = NSLocalizedString(confirmation.message, comment: "")
    alert.informativeText = NSLocalizedString(confirmation.comment, comment: "")
    let confirmButton = alert.addButton(withTitle: NSLocalizedString(confirmation.confirm, comment: ""))
    confirmButton.hasDestructiveAction = true
    confirmButton.setAccessibilityIdentifier("confirmation-confirm")
    let cancelButton = alert.addButton(withTitle: NSLocalizedString(confirmation.cancel, comment: ""))
    cancelButton.keyEquivalent = "\u{1b}"
    cancelButton.setAccessibilityIdentifier("confirmation-cancel")
    alert.showsSuppressionButton = true

    NSApp.activate(ignoringOtherApps: true)
    let response = alert.runModal()
    if response == .alertFirstButtonReturn {
      if alert.suppressionButton?.state == .on {
        suppressConfirmation.wrappedValue = true
      }
      action()
    }
  }
}
