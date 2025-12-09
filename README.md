# Window Resizer

A macOS menu bar application that allows you to resize the active window according to a customizable grid pattern.

<img width="810" height="1046" alt="image" src="https://github.com/user-attachments/assets/748d6807-353e-4465-add3-534f7b1b385b" />

## Features

- **Menu Bar Integration**: Access the window resizer from the menu bar with a hashtag icon
- **Customizable Grid**: Configure grid patterns from 1x1 to 8x8 (rows x columns), default 4x4
- **Visual Grid Selection**: Click and drag to select grid squares visually with hover highlighting
- **Smart Window Resizing**: Automatically resizes the frontmost window to match selected grid cells
- **Quick Snap Buttons**: One-click shortcuts for common window positions (left, right, top, bottom, full screen)
- **Keyboard Shortcuts**: Global hotkeys for quick snap actions (⌘⌥ + Arrow Keys)

## Requirements

- macOS 13.0 (Ventura) or later
- Accessibility permissions (required for window management)

## Setup Instructions

### 1. Build and Install the Application

Use the provided build script to build, install, and set up the application to run at login:

```bash
./build.sh
```

This script will:

- Build the application in release mode
- Install the binary to `/usr/local/bin/WindowResizer`
- Set up LaunchAgents to run the app at login
- Start the application automatically

**Alternative: Manual Build**

If you prefer to build manually:

```bash
swift build -c release
```

Or open in Xcode:

```bash
open Package.swift
```

### 2. Grant Accessibility Permissions

1. Go to **System Settings** > **Privacy & Security** > **Accessibility**
2. Click the lock icon and enter your password
3. Click the **+** button and add the WindowResizer application (located at `/usr/local/bin/WindowResizer`)
4. Ensure it's enabled (checkbox is checked)

### 3. Run the Application

If installed via `./build.sh`, the application will start automatically and run at login.

To run manually:

```bash
/usr/local/bin/WindowResizer
```

Or if building manually:

```bash
swift run
```

## Usage

1. **Select a Window**: Click on the application window you want to resize to make it active
2. **Open Grid Selector**:
   - **Left-click** the hashtag (#) icon in the menu bar to open the grid selector popover
   - **Right-click** the icon to access the menu with quick grid presets
3. **Configure Grid**:
   - Use the steppers in the popover to set custom rows and columns (default: 4x4)
   - Or use the right-click menu to quickly select preset grid patterns (1x1, 2x2, 3x3, 4x4, etc.)
4. **Select Grid Cells**:
   - Hover over cells to see them highlighted
   - Click on a single cell to select it
   - Click and drag from one cell to another to select a range of cells
5. **Resize**: Click the "Resize Window" button to apply the resize

### Quick Snap Shortcuts

For faster window management, use the quick snap buttons or keyboard shortcuts:

**Quick Snap Buttons:**

- **Left** - Snap window to left half of screen
- **Right** - Snap window to right half of screen
- **Top** - Snap window to top half of screen
- **Bottom** - Snap window to bottom half of screen
- **Full** - Snap window to full screen

**Keyboard Shortcuts:**

- **⌘⌥←** (Cmd+Option+Left Arrow) - Snap to left half
- **⌘⌥→** (Cmd+Option+Right Arrow) - Snap to right half
- **⌘⌥↑** (Cmd+Option+Up Arrow) - Snap to top half
- **⌘⌥↓** (Cmd+Option+Down Arrow) - Snap to bottom half
- **⌘⌥F** (Cmd+Option+F) - Full screen

These shortcuts work globally from any application, so you can quickly resize windows without opening the popover!

### Example Use Cases

**Quick Snap (Fastest)**:

- Use the quick snap buttons or keyboard shortcuts for instant window positioning
- Perfect for common layouts like side-by-side windows or full screen

**Left Side (4x4 grid)**:

- Select column A, rows 1, 2, 3, and 4 (the leftmost column)

**Top Right Quarter (4x4 grid)**:

- Select columns C and D, rows 1 and 2 (top right quadrant)

**Custom Region**:

- Select any rectangular region by dragging from one corner to another
- Great for precise window placement

## Project Structure

```
WindowResizer/
├── WindowResizerApp.swift    # Main app entry point and menu bar setup
├── GridSelectionView.swift         # Grid UI and selection logic
└── Info.plist                      # App configuration
```

## Development

The application uses:

- **SwiftUI** for the user interface
- **AppKit** for menu bar integration
- **Accessibility APIs** for window management

## Troubleshooting

**Window doesn't resize:**

- Ensure Accessibility permissions are granted
- Make sure the target window is the frontmost/active window
- Some system windows may not be resizable

**Menu bar icon doesn't appear:**

- Check that the app is running
- Look for the hashtag/number icon in the menu bar
- Restart the application if needed

**LaunchAgents installation fails:**
If the build script fails when setting up LaunchAgents, you may need to fix folder ownership. Run these commands and then try `./build.sh` again:

```bash
sudo chown -R $(whoami) ~/Library/LaunchAgents
chmod 700 ~/Library/LaunchAgents
```

**Application not starting at login:**

- Check that the plist file exists: `~/Library/LaunchAgents/com.windowresizer.plist`
- Verify the binary exists: `/usr/local/bin/WindowResizer`
- Manually start with: `launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.windowresizer.plist`

## License

Copyright © 2024. All rights reserved.
