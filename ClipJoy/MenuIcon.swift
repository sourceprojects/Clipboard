import AppKit
import Defaults

enum MenuIcon: String, CaseIterable, Identifiable, Defaults.Serializable {
  case paperclip

  var id: Self { self }

  var image: NSImage {
    switch self {
    case .paperclip:
      return NSImage(named: .paperclip)!
    }
  }
}
