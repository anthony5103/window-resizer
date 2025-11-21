#!/bin/bash

echo "Building Window Resizer..."
swift build -c release || { echo "Build failed!"; exit 1; }

echo "Build successful!"

# Copy binary
sudo cp .build/release/WindowResizer /usr/local/bin/WindowResizer

# Ensure LaunchAgents folder exists and has correct permissions
mkdir -p ~/Library/LaunchAgents
chmod 700 ~/Library/LaunchAgents
chown $(whoami) ~/Library/LaunchAgents

# Validate plist
plutil -lint com.windowresizer.plist || { echo "Plist is invalid"; exit 1; }

# Copy plist
cp com.windowresizer.plist ~/Library/LaunchAgents/

# Get UID
USER_UID=$(id -u)

# Unload old instance
launchctl bootout gui/$USER_UID ~/Library/LaunchAgents/com.windowresizer.plist 2>/dev/null

# Bootstrap agent
launchctl bootstrap gui/$USER_UID ~/Library/LaunchAgents/com.windowresizer.plist

echo "Window Resizer installed and set to run at login!"
