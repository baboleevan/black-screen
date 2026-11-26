#!/bin/bash
# Black Screen.app 을 빌드해서 ~/Applications 에 설치하고, black 명령을 ~/.local/bin 에 복사한다.
set -e
cd "$(dirname "$0")"
APP="$HOME/Applications/Black Screen.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$HOME/.local/bin"
swiftc -O BlackScreen.swift -o "$APP/Contents/MacOS/BlackScreen"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>Black Screen</string>
<key>CFBundleDisplayName</key><string>Black Screen</string>
<key>CFBundleIdentifier</key><string>com.hunkii.blackscreen</string>
<key>CFBundleExecutable</key><string>BlackScreen</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleVersion</key><string>2</string>
<key>CFBundleShortVersionString</key><string>2.0</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --sign - "$APP"
install -m 755 black "$HOME/.local/bin/black"
echo "installed: $APP"
echo "CLI: ~/.local/bin/black (PATH에 ~/.local/bin 이 있어야 합니다)"
