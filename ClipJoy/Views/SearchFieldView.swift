import SwiftUI
import AppKit

class EmojiPickerWindow: NSWindow {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = true
        self.level = .popUpMenu
        self.isReleasedWhenClosed = false
    }
    
    override func setContentSize(_ size: NSSize) {
        super.setContentSize(size)
        setupTrackingArea()
    }
    
    override var contentView: NSView? {
        didSet {
            if let contentView = contentView {
                contentView.wantsLayer = true
                contentView.layer?.cornerRadius = 12
                contentView.layer?.masksToBounds = true
                setupTrackingArea()
                
                // Customize scrollbar appearance if the content view contains a scroll view
                if let hostingView = contentView as? NSHostingView<EmojiPickerView>,
                   let scrollView = hostingView.subviews.first(where: { $0 is NSScrollView }) as? NSScrollView {
                    scrollView.drawsBackground = false
                    scrollView.backgroundColor = .clear
                    scrollView.scrollerStyle = .overlay
                    
                    // Configure the scroller
                    if let verticalScroller = scrollView.verticalScroller {
                        verticalScroller.scrollerStyle = .overlay
                        verticalScroller.knobStyle = .light
                    }
                    
                    // Configure the content view
                    scrollView.contentView.drawsBackground = false
                    scrollView.contentView.backgroundColor = .clear
                }
            }
        }
    }
    
    private func setupTrackingArea() {
        guard let contentView = self.contentView else { return }
        
        // Remove any existing tracking areas
        contentView.trackingAreas.forEach { contentView.removeTrackingArea($0) }
        
        // Add new tracking area
        let trackingArea = NSTrackingArea(
            rect: contentView.bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        contentView.addTrackingArea(trackingArea)
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        self.close()
    }
}

struct SearchFieldView: View {
    var placeholder: LocalizedStringKey
    @Binding var query: String
    @State private var showEmojiPicker = false
    @State private var emojiWindow: EmojiPickerWindow?
    @State private var buttonFrame: CGRect = .zero

    @Environment(AppState.self) private var appState

    var body: some View {
        HStack(spacing: 8) {
            // Search field
            ZStack {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color.secondary)
                    .opacity(0.1)
                    .frame(height: 23)

                HStack {
                    Image(systemName: "magnifyingglass")
                        .frame(width: 11, height: 11)
                        .padding(.leading, 5)
                        .opacity(0.8)

                    TextField(placeholder, text: $query)
                        .disableAutocorrection(true)
                        .lineLimit(1)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            appState.select()
                        }

                    if !query.isEmpty {
                        Button {
                            query = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .frame(width: 11, height: 11)
                                .padding(.trailing, 5)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .opacity(query.isEmpty ? 0 : 0.9)
                    }
                }
            }
            
            // Emoji button
            Button {
                toggleEmojiPicker()
            } label: {
                Image(systemName: "face.smiling")
                    .frame(width: 11, height: 11)
            }
            .buttonStyle(PlainButtonStyle())
            .opacity(0.8)
            .background(GeometryReader { geometry in
                Color.clear.onAppear {
                    buttonFrame = geometry.frame(in: .global)
                }
                .onChange(of: geometry.frame(in: .global)) { oldFrame, newFrame in
                    buttonFrame = newFrame
                }
            })
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)) { notification in
            if let window = notification.object as? NSWindow,
               window == appState.appDelegate?.panel {
                emojiWindow?.close()
                emojiWindow = nil
                showEmojiPicker = false
            }
        }
    }

    private func toggleEmojiPicker() {
        if let window = emojiWindow {
            window.close()
            emojiWindow = nil
            showEmojiPicker = false
        } else {
            guard let mainWindow = appState.appDelegate?.panel else { return }
            
            // Convert button frame to window coordinates first
            let buttonFrameInWindow = NSRect(
                x: self.buttonFrame.minX,
                y: mainWindow.frame.height - self.buttonFrame.maxY,
                width: self.buttonFrame.width,
                height: self.buttonFrame.height
            )
            
            // Then convert to screen coordinates
            let buttonFrame = mainWindow.convertToScreen(buttonFrameInWindow)
            
            let contentSize = NSSize(width: 460, height: 200) // Increased width
            let windowSize = NSSize(width: contentSize.width, height: contentSize.height + 8) // +8 for arrow
            let pickerOrigin = NSPoint(
                x: buttonFrame.minX - (windowSize.width - buttonFrame.width) / 2,
                y: buttonFrame.minY - windowSize.height - 5
            )
            
            let pickerWindow = EmojiPickerWindow(
                contentRect: NSRect(origin: pickerOrigin, size: windowSize)
            )
            
            let hostingView = NSHostingView(rootView: 
                EmojiPickerView { emoji in
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(emoji, forType: .string)
                    pickerWindow.close()
                    emojiWindow = nil
                    showEmojiPicker = false
                }
                .frame(width: contentSize.width, height: contentSize.height)
            )
            
            pickerWindow.contentView = hostingView
            pickerWindow.makeKeyAndOrderFront(nil)
            emojiWindow = pickerWindow
            showEmojiPicker = true
        }
    }
}

struct EmojiData {
    static let smileysAndPeople = [
        "😀", "😃", "😄", "😁", "😅", "😂", "🤣", "😊", "😇", "🙂", "😉", "😌", "😍", "🥰",
        "😘", "😗", "😙", "😚", "😋", "😛", "😝", "😜", "🤪", "🤨", "🧐", "🤓", "😎", "🥸",
        "🤩", "🥳", "😏", "😒", "😞", "😔", "😟", "😕", "🙁", "☹️", "😣", "😖", "😫", "😩",
        "🥺", "😢", "😭", "😤", "😠", "😡", "🤬", "🤯", "😳", "🥵", "🥶", "😱", "😨", "😰",
        "😥", "😓", "🤗", "🤔", "🤭", "🤫", "🫢", "🫣", "🤥", "😶", "😐", "😑", "😬", "🙄",
        "😯", "😦", "😧", "😮", "😲", "🥱", "😴", "🤤", "😪", "😵", "🤐", "🥴", "🤢", "🤮",
        "🤧", "😷", "😈", "🙊", "🙉", "🙈"
    ]
    
    static let foodAndDrink = [
        "🍆", "🍉", "🥖", "🍕", "🍔", "🥩", "🍗", "🍟", "🍦", "🍭"
    ]
    
    static let heartsAndLove = [
        "❤️", "🧡", "💛", "💚", "💙", "💜", "🖤", "🤍", "🤎", "💔", "❤️‍🔥", "❤️‍🩹", "❣️",
        "💕", "💞", "💓", "💗", "💖", "💘", "💝", "💟", "💌", "💋", "💯", "💦", "💫"
    ]
    
    static let gesturesAndBody = [
        "👋", "🤚", "🖐️", "✋", "🖖", "👌", "🤌", "🤏", "✌️", "🤞", "🫰", "🤟", "🤘", "🤙",
        "👈", "👉", "👆", "🖕", "👇", "☝️", "👍", "👎", "✊", "👊", "🤛", "🤜", "👏", "🙌",
        "👐", "🤲", "🤝", "🙏", "✍️", "💅", "🤳", "💪", "🦾", "🦿", "🦵", "🦶", "👂", "🦻",
        "👃", "🧠", "🫀", "🫁", "🦷", "🦴", "👀", "👁️", "👅", "👄", "🫦"
    ]
    
    static let categories: [(String, [String])] = [
        ("Recent", []),
        ("Smileys & People", smileysAndPeople),
        ("Food & Drink", foodAndDrink),
        ("Hearts & Love", heartsAndLove),
        ("Gestures & Body", gesturesAndBody)
    ]
}

struct EmojiGridView: View {
    let emojis: [String]
    let onSelect: (String) -> Void
    let addToRecent: (String) -> Void
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 9),
                spacing: 0) {
            ForEach(emojis, id: \.self) { emoji in
                Button {
                    addToRecent(emoji)
                    onSelect(emoji)
                } label: {
                    Text(emoji)
                        .font(.system(size: 18))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 4)
    }
}

struct EmojiCategoryView: View {
    let category: (String, [String])
    let recentEmojis: [String]
    let onSelect: (String) -> Void
    let addToRecent: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(category.0)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.top, 4)
            
            let emojis = category.0 == "Recent" ? recentEmojis : category.1
            
            EmojiGridView(
                emojis: emojis,
                onSelect: onSelect,
                addToRecent: addToRecent
            )
        }
    }
}

struct EmojiPickerView: View {
    let onSelect: (String) -> Void
    @AppStorage("recentEmojis") private var storedRecentEmojis: String = "😂,💙,🙈,😊,💪,😻,😇,🥺,😌,👍,💖,😌,💯,❤️,🙏,😍,😊,👍"
    
    private var recentEmojis: [String] {
        Array(storedRecentEmojis.split(separator: ",").prefix(18)).map(String.init)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Arrow/tail at the top
            Path { path in
                let arrowWidth: CGFloat = 16
                let arrowHeight: CGFloat = 8
                let centerX = 460.0 / 2.0
                
                path.move(to: CGPoint(x: centerX - arrowWidth/2, y: arrowHeight))
                path.addLine(to: CGPoint(x: centerX, y: 0))
                path.addLine(to: CGPoint(x: centerX + arrowWidth/2, y: arrowHeight))
            }
            .fill(Color(.windowBackgroundColor))
            .frame(height: 8)
            .zIndex(1)
            
            // Main content
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(EmojiData.categories, id: \.0) { category in
                        EmojiCategoryView(
                            category: category,
                            recentEmojis: recentEmojis,
                            onSelect: onSelect,
                            addToRecent: addToRecent
                        )
                        
                        if category.0 != EmojiData.categories.last?.0 {
                            Divider()
                                .padding(.vertical, 2)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.windowBackgroundColor))
        )
    }
    
    private func addToRecent(_ emoji: String) {
        var recent = recentEmojis
        if let index = recent.firstIndex(of: emoji) {
            recent.remove(at: index)
        }
        recent.insert(emoji, at: 0)
        recent = Array(recent.prefix(18))
        storedRecentEmojis = recent.joined(separator: ",")
    }
}

#Preview {
    return List {
        SearchFieldView(placeholder: "search_placeholder", query: .constant(""))
        SearchFieldView(placeholder: "search_placeholder", query: .constant("search"))
    }
    .frame(width: 300)
    .environment(\.locale, .init(identifier: "en"))
}
