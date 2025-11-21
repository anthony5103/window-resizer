import AppKit
import ApplicationServices
import SwiftUI

@main
struct WindowResizerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // Prevent multiple instances at app level
        let currentPID = ProcessInfo.processInfo.processIdentifier
        let executableName = "WindowResizer"

        let runningApps = NSWorkspace.shared.runningApplications.filter {
            if let appURL = $0.executableURL {
                let appName = appURL.lastPathComponent
                return appName == executableName && $0.processIdentifier != currentPID
            }
            return false
        }

        if !runningApps.isEmpty {
            // Another instance is running, exit immediately
            exit(0)
        }
    }

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var gridConfig = GridConfiguration(rows: 2, columns: 2)
    private var hostingController: NSHostingController<GridSelectionView>?
    func applicationWillFinishLaunching(_ notification: Notification) {
        // Check for other instances EARLY, before UI is created
        let currentPID = ProcessInfo.processInfo.processIdentifier
        let executableName =
            (Bundle.main.executablePath as NSString?)?.lastPathComponent ?? "WindowResizer"

        // Check by bundle ID first
        if let bundleID = Bundle.main.bundleIdentifier {
            let runningApps = NSWorkspace.shared.runningApplications.filter {
                $0.bundleIdentifier == bundleID && $0.processIdentifier != currentPID
            }
            if !runningApps.isEmpty {
                NSApplication.shared.terminate(nil)
                return
            }
        }

        // Also check by executable name (for development builds)
        let runningApps = NSWorkspace.shared.runningApplications.filter {
            if let appURL = $0.executableURL {
                let appName = appURL.lastPathComponent
                return appName == executableName && $0.processIdentifier != currentPID
            }
            return false
        }

        if !runningApps.isEmpty {
            // Another instance is already running, terminate immediately
            NSApplication.shared.terminate(nil)
            return
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Double-check we're still the only instance
        let bundleID = Bundle.main.bundleIdentifier ?? "com.windowresizer"
        let runningApps = NSWorkspace.shared.runningApplications.filter {
            $0.bundleIdentifier == bundleID
                && $0.processIdentifier != ProcessInfo.processInfo.processIdentifier
        }

        if !runningApps.isEmpty {
            NSApplication.shared.terminate(nil)
            return
        }
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)

        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(
                systemSymbolName: "number", accessibilityDescription: "Window Resizer")
            button.action = #selector(togglePopover)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // Create popover first
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 400, height: 450)
        popover?.behavior = .transient

        // Create popover with hosting controller
        updatePopoverContent()

        // Make popover delegate to handle focus
        popover?.delegate = self
    }

    private var isToggling = false

    @objc func togglePopover() {
        guard !isToggling else { return }
        isToggling = true
        defer {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.isToggling = false
            }
        }

        guard let button = statusItem?.button else { return }
        let event = NSApp.currentEvent!

        if event.type == .rightMouseUp {
            // Show menu on right click
            statusItem?.menu = createMenu()
            statusItem?.button?.performClick(nil)
            statusItem?.menu = nil
        } else {
            // Show popover on left click
            if let popover = popover {
                if popover.isShown {
                    popover.performClose(nil)
                } else {
                    updatePopoverContent()
                    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                    // Enable mouse events immediately
                    DispatchQueue.main.async {
                        if let window = popover.contentViewController?.view.window {
                            window.acceptsMouseMovedEvents = true
                            window.makeKey()
                        }
                    }
                }
            }
        }
    }

    func createMenu() -> NSMenu {
        let menu = NSMenu()

        // Grid pattern submenu
        let gridMenu = NSMenu()
        let gridMenuItem = NSMenuItem(title: "Grid Pattern", action: nil, keyEquivalent: "")
        gridMenuItem.submenu = gridMenu

        // Quick grid presets
        let presets = [
            ("1x1", 1, 1),
            ("2x2", 2, 2),
            ("3x3", 3, 3),
            ("4x4", 4, 4),
            ("2x3", 2, 3),
            ("3x2", 3, 2),
            ("4x2", 4, 2),
            ("2x4", 2, 4),
        ]

        for (title, rows, cols) in presets {
            let item = NSMenuItem(
                title: title,
                action: #selector(setGridPattern(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = (rows, cols)
            item.state = (gridConfig.rows == rows && gridConfig.columns == cols) ? .on : .off
            gridMenu.addItem(item)
        }

        gridMenu.addItem(NSMenuItem.separator())

        // Custom grid option
        let customItem = NSMenuItem(
            title: "Custom...",
            action: #selector(showCustomGrid),
            keyEquivalent: ""
        )
        customItem.target = self
        gridMenu.addItem(customItem)

        menu.addItem(gridMenuItem)
        menu.addItem(NSMenuItem.separator())

        // Open grid selector
        let openItem = NSMenuItem(
            title: "Open Grid Selector",
            action: #selector(openGridSelector),
            keyEquivalent: ""
        )
        openItem.target = self
        menu.addItem(openItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)

        return menu
    }

    @objc func setGridPattern(_ sender: NSMenuItem) {
        if let (rows, cols) = sender.representedObject as? (Int, Int) {
            gridConfig.rows = rows
            gridConfig.columns = cols
        }
    }

    @objc func showCustomGrid() {
        // Show popover for custom grid configuration
        guard let button = statusItem?.button else { return }
        updatePopoverContent()
        popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    @objc func openGridSelector() {
        guard let button = statusItem?.button else { return }
        updatePopoverContent()
        popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    func updatePopoverContent() {
        let view = GridSelectionView(
            gridConfig: Binding(
                get: { [weak self] in self?.gridConfig ?? GridConfiguration(rows: 2, columns: 2) },
                set: { [weak self] newValue in self?.gridConfig = newValue }
            ),
            onResize: { [weak self] selectedCells in
                self?.resizeWindow(selectedCells: selectedCells)
            }
        )
        hostingController = NSHostingController(rootView: view)
        popover?.contentViewController = hostingController
    }

    private var isResizing = false
    private var hasShownPermissionAlert = false

    func resizeWindow(selectedCells: Set<GridCell>) {
        // Prevent double execution
        guard !isResizing else {
            print("Resize already in progress, ignoring duplicate call")
            return
        }
        isResizing = true
        defer {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.isResizing = false
            }
        }

        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            showAlert(message: "No active application found. Please select a window first.")
            return
        }

        print("Attempting to resize window for app: \(frontmostApp.localizedName ?? "Unknown")")

        // Check permissions - don't cache, check fresh each time
        let hasPermission = AXIsProcessTrusted()
        print("Permissions granted: \(hasPermission)")

        if !hasPermission {
            if !hasShownPermissionAlert {
                hasShownPermissionAlert = true
                // Request permissions with system prompt
                let options =
                    [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
                    as CFDictionary
                AXIsProcessTrustedWithOptions(options)

                showAlert(
                    message:
                        "Accessibility permissions are required. Please grant permissions in System Settings > Privacy & Security > Accessibility, then restart the app."
                )
            }
            return
        }

        // Try to get the window
        guard let window = getFrontmostWindow() else {
            print("Failed to get frontmost window")
            showAlert(
                message:
                    "No resizable window found. The frontmost application may not have any windows."
            )
            return
        }

        print("Successfully got window, calculating new frame...")

        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame

        // Calculate grid cell size
        let cellWidth = screenFrame.width / CGFloat(gridConfig.columns)
        let cellHeight = screenFrame.height / CGFloat(gridConfig.rows)

        // Find bounds of selected cells
        var minRow = Int.max
        var maxRow = Int.min
        var minCol = Int.max
        var maxCol = Int.min

        for cell in selectedCells {
            minRow = min(minRow, cell.row)
            maxRow = max(maxRow, cell.row)
            minCol = min(minCol, cell.column)
            maxCol = max(maxCol, cell.column)
        }

        // Calculate new frame (macOS uses bottom-left origin)
        // In UI: row 0 is top, row N-1 is bottom
        // On screen: top has highest Y, bottom has lowest Y
        let x = screenFrame.origin.x + CGFloat(minCol) * cellWidth
        let width = CGFloat(maxCol - minCol + 1) * cellWidth
        let height = CGFloat(maxRow - minRow + 1) * cellHeight
        // Window Y: bottom edge of selected area in screen coordinates
        // Row 0 (top) maps to screen top, row N-1 (bottom) maps to screen bottom
        // For row N-1: y = screenFrame.origin.y (bottom of screen)
        // For row 0: y = screenFrame.origin.y + screenFrame.height - cellHeight (top)
        let y = screenFrame.origin.y + CGFloat(gridConfig.rows - maxRow - 1) * cellHeight

        let newFrame = CGRect(x: x, y: y, width: width, height: height)
        print("New frame: \(newFrame)")

        // Resize window using Accessibility API
        let success = applyWindowResize(window, to: newFrame)
        print("Resize result: \(success)")

        // Close popover after resize
        popover?.performClose(nil)
    }

    func getFrontmostWindow() -> AXUIElement? {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            return nil
        }

        let app = AXUIElementCreateApplication(frontmostApp.processIdentifier)

        // Try to get the main window first
        var mainWindow: CFTypeRef?
        let mainWindowResult = AXUIElementCopyAttributeValue(
            app, kAXMainWindowAttribute as CFString, &mainWindow)

        if mainWindowResult == .success, let window = mainWindow {
            // AXUIElement is a typealias for CFTypeRef, use unsafeBitCast for type conversion
            return unsafeBitCast(window, to: AXUIElement.self)
        }

        // Fallback to getting the first window from the windows list
        var windowList: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            app, kAXWindowsAttribute as CFString, &windowList)

        guard result == .success,
            let windows = windowList as? [AXUIElement],
            !windows.isEmpty
        else {
            return nil
        }

        // Try to find a window that's not minimized and is resizable
        for window in windows {
            var minimized: CFTypeRef?
            let minimizedResult = AXUIElementCopyAttributeValue(
                window, kAXMinimizedAttribute as CFString, &minimized)

            if minimizedResult == .success,
                let isMinimized = minimized as? Bool,
                !isMinimized
            {
                return window
            }
        }

        // Return first window if all are minimized or we can't check
        return windows.first
    }

    func applyWindowResize(_ window: AXUIElement, to frame: CGRect) -> Bool {
        // Convert to screen coordinates (macOS uses bottom-left origin)
        guard let screen = NSScreen.main else {
            print("No main screen found")
            return false
        }
        let screenHeight = screen.frame.height

        // Convert Y coordinate from bottom-left to top-left for Accessibility API
        let convertedY = screenHeight - frame.origin.y - frame.height

        var position = CGPoint(x: frame.origin.x, y: convertedY)
        var size = CGSize(width: frame.width, height: frame.height)

        guard let positionValue = AXValueCreate(.cgPoint, &position),
            let sizeValue = AXValueCreate(.cgSize, &size)
        else {
            print("Failed to create AXValue objects")
            return false
        }

        let posResult = AXUIElementSetAttributeValue(
            window, kAXPositionAttribute as CFString, positionValue)
        let sizeResult = AXUIElementSetAttributeValue(
            window, kAXSizeAttribute as CFString, sizeValue)

        print("Position set result: \(posResult.rawValue), Size set result: \(sizeResult.rawValue)")

        return posResult == .success && sizeResult == .success
    }

    func showAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    // NSPopoverDelegate
    func popoverDidShow(_ notification: Notification) {
        // Make the popover window accept mouse events immediately
        if let window = popover?.contentViewController?.view.window {
            window.acceptsMouseMovedEvents = true
            window.makeKey()
            // Ensure the view can receive mouse events
            window.makeFirstResponder(window.contentView)
        }
    }
}

struct GridConfiguration: Equatable {
    var rows: Int
    var columns: Int
}

struct GridCell: Hashable {
    let row: Int
    let column: Int
}
