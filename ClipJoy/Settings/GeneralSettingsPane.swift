import SwiftUI
import Defaults
import KeyboardShortcuts
import LaunchAtLogin
import Settings

struct GeneralSettingsPane: View {
  private let notificationsURL = URL(
    string: "x-apple.systempreferences:com.apple.preference.notifications?id=\(Bundle.main.bundleIdentifier ?? "")"
  )

  @Default(.searchMode) private var searchMode
  @State private var isCheckingForUpdates = false
  @State private var updateAvailable = false
  @State private var updateURL: String?
  @State private var releaseNotes: String?
  @State private var showNoUpdateAlert = false
  @State private var lastCheckTime: Date?

  @State private var copyModifier = HistoryItemAction.copy.modifierFlags.description
  @State private var pasteModifier = HistoryItemAction.paste.modifierFlags.description
  @State private var pasteWithoutFormatting = HistoryItemAction.pasteWithoutFormatting.modifierFlags.description

  var body: some View {
    Settings.Container(contentWidth: 450) {
      Settings.Section(title: "", bottomDivider: true) {
        LaunchAtLogin.Toggle {
          Text("LaunchAtLogin", tableName: "GeneralSettings")
        }
        
        VStack(alignment: .leading, spacing: 8) {
          Button(action: checkForUpdates) {
            HStack {
              if isCheckingForUpdates {
                ProgressView()
                  .scaleEffect(0.7)
                  .frame(width: 16, height: 16)
                Text("CheckingForUpdates", tableName: "GeneralSettings")
              } else {
                Text("CheckForUpdates", tableName: "GeneralSettings")
              }
            }
          }
          .disabled(isCheckingForUpdates)
          
          if let time = lastCheckTime {
            Text("Last checked: \(time, style: .relative)")
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }
        
        if updateAvailable, let url = updateURL, let notes = releaseNotes {
          VStack(alignment: .leading, spacing: 8) {
            Text("UpdateAvailable", tableName: "GeneralSettings")
              .foregroundColor(.green)
              .bold()
            Text(notes)
              .font(.caption)
              .foregroundColor(.secondary)
            Link("DownloadUpdate", destination: URL(string: url)!)
              .buttonStyle(.borderedProminent)
          }
          .padding(.vertical, 8)
        }
      }

      Settings.Section(label: { Text("Open", tableName: "GeneralSettings") }) {
        KeyboardShortcuts.Recorder(for: .popup)
          .help(Text("OpenTooltip", tableName: "GeneralSettings"))
      }
      Settings.Section(label: { Text("Pin", tableName: "GeneralSettings") }) {
        KeyboardShortcuts.Recorder(for: .pin)
          .help(Text("PinTooltip", tableName: "GeneralSettings"))
      }
      Settings.Section(
        bottomDivider: true,
        label: { Text("Delete", tableName: "GeneralSettings") }
      ) {
        KeyboardShortcuts.Recorder(for: .delete)
          .help(Text("DeleteTooltip", tableName: "GeneralSettings"))
      }

      Settings.Section(
        bottomDivider: true,
        label: { Text("Search", tableName: "GeneralSettings") }
      ) {
        Picker("", selection: $searchMode) {
          ForEach(Search.Mode.allCases) { mode in
            Text(mode.description)
          }
        }
        .labelsHidden()
        .frame(width: 180)
      }

      Settings.Section(
        bottomDivider: true,
        label: { Text("Behavior", tableName: "GeneralSettings") }
      ) {
        Defaults.Toggle(key: .pasteByDefault) {
          Text("PasteAutomatically", tableName: "GeneralSettings")
        }
        .onChange(refreshModifiers)
        .fixedSize()

        Defaults.Toggle(key: .removeFormattingByDefault) {
          Text("PasteWithoutFormatting", tableName: "GeneralSettings")
        }
        .onChange(refreshModifiers)
        .fixedSize()

        Text(String(
          format: NSLocalizedString("Modifiers", tableName: "GeneralSettings", comment: ""),
          copyModifier, pasteModifier, pasteWithoutFormatting
        ))
        .fixedSize(horizontal: false, vertical: true)
        .foregroundStyle(.gray)
        .controlSize(.small)
      }

      Settings.Section(title: "") {
        if let notificationsURL = notificationsURL {
          Link(destination: notificationsURL, label: {
            Text("NotificationsAndSounds", tableName: "GeneralSettings")
          })
        }
      }
    }
    .alert("No Update Available", isPresented: $showNoUpdateAlert) {
      Button("OK", role: .cancel) { }
    } message: {
      Text("You're running the latest version (\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"))")
    }
  }

  private func refreshModifiers(_ sender: Sendable) {
    copyModifier = HistoryItemAction.copy.modifierFlags.description
    pasteModifier = HistoryItemAction.paste.modifierFlags.description
    pasteWithoutFormatting = HistoryItemAction.pasteWithoutFormatting.modifierFlags.description
  }

  private func checkForUpdates() {
    print("Check for updates button clicked")
    isCheckingForUpdates = true
    VersionChecker.shared.checkForUpdates { needsUpdate, url, notes in
      print("Update check completed. Needs update: \(needsUpdate), URL: \(url ?? "nil"), Notes: \(notes ?? "nil")")
      DispatchQueue.main.async {
        isCheckingForUpdates = false
        updateAvailable = needsUpdate
        updateURL = url
        releaseNotes = notes
        lastCheckTime = Date()
        
        if !needsUpdate {
          showNoUpdateAlert = true
        }
      }
    }
  }
}

#Preview {
  GeneralSettingsPane()
    .environment(\.locale, .init(identifier: "en"))
}
