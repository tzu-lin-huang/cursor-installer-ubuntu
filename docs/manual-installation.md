# Manual Installation Guide

This guide provides step-by-step instructions for manually installing Cursor IDE on Ubuntu systems.

## Prerequisites

- Ubuntu 22.04 or compatible system (20.04, 24.04 may also work)
- x86_64 (amd64) architecture
- sudo access
- At least 2GB free disk space

## Installation Steps

### 1. Install Dependencies

```bash
# Update package list
sudo apt update

# Install required packages
sudo apt install -y wget curl jq libfuse2
```

**Package explanations:**
- `wget/curl`: For downloading files
- `jq`: For parsing API responses
- `libfuse2`: Required for AppImage execution

### 2. Download Cursor

#### Option A: Using the API (Recommended)
```bash
# Get the latest download URL
API_URL="https://www.cursor.com/api/download?platform=linux-x64&releaseTrack=stable"
DOWNLOAD_URL=$(curl -sL "$API_URL" | jq -r '.url // .downloadUrl')
VERSION=$(curl -sL "$API_URL" | jq -r '.version // "unknown"')

# Download Cursor
wget -O cursor.AppImage "$DOWNLOAD_URL"
```

#### Option B: Direct Download
```bash
# Visit https://cursor.com/downloads and copy the Linux AppImage URL
wget -O cursor.AppImage "PASTE_URL_HERE"
```

### 3. Make Executable

```bash
chmod +x cursor.AppImage
```

### 4. System-wide Installation

```bash
# Create installation directory
sudo mkdir -p /opt/cursor

# Move AppImage
sudo mv cursor.AppImage /opt/cursor/cursor.AppImage

# Create launcher script with GPU hang prevention
sudo tee /usr/local/bin/cursor > /dev/null << 'EOF'
#!/bin/bash
# Disable vsync via environment variables
export vblank_mode=0
export __GL_SYNC_TO_VBLANK=0
exec /opt/cursor/cursor.AppImage --no-sandbox --disable-gpu "$@"
EOF

# Make launcher executable
sudo chmod +x /usr/local/bin/cursor
```

### 5. Desktop Integration

```bash
# Create desktop entry
sudo tee /usr/share/applications/cursor.desktop > /dev/null << 'EOF'
[Desktop Entry]
Version=1.0
Name=Cursor
GenericName=Code Editor
Comment=The AI-first code editor
Exec=/usr/local/bin/cursor %F
Icon=cursor
Type=Application
StartupNotify=true
StartupWMClass=Cursor
Categories=Development;IDE;TextEditor;
MimeType=text/plain;inode/directory;
Actions=new-window;
Keywords=vscode;code;editor;ide;development;

[Desktop Action new-window]
Name=New Window
Exec=/usr/local/bin/cursor --new-window %F
Icon=cursor
EOF

# Extract and install icon (optional)
cd /tmp
/opt/cursor/cursor.AppImage --appimage-extract usr/share/icons/hicolor/512x512/apps/cursor.png
sudo mkdir -p /usr/share/icons/hicolor/512x512/apps
sudo cp squashfs-root/usr/share/icons/hicolor/512x512/apps/cursor.png /usr/share/icons/hicolor/512x512/apps/
rm -rf squashfs-root

# Update desktop database
sudo update-desktop-database

# Update icon cache
sudo gtk-update-icon-cache -f -t /usr/share/icons/hicolor 2>/dev/null || 
sudo update-icon-caches /usr/share/icons/hicolor 2>/dev/null || true
```

## Alternative: Local Installation

If you prefer not to install system-wide:

```bash
# Run directly from current directory
./cursor.AppImage

# Or create a local launcher
mkdir -p ~/.local/bin
echo '#!/bin/bash' > ~/.local/bin/cursor
echo 'export vblank_mode=0' >> ~/.local/bin/cursor
echo 'export __GL_SYNC_TO_VBLANK=0' >> ~/.local/bin/cursor
echo 'exec ~/cursor.AppImage --no-sandbox --disable-gpu "$@"' >> ~/.local/bin/cursor
chmod +x ~/.local/bin/cursor

# Add to PATH if not already there
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## Verification

After installation, verify it works:

```bash
# Check version
cursor --version

# Launch Cursor
cursor
```

## Uninstallation

To remove Cursor:

```bash
# Use the automated uninstall option
./install_cursor.sh --uninstall

# Or manually remove files:
sudo rm -rf /opt/cursor
sudo rm -f /usr/local/bin/cursor
sudo rm -f /usr/share/applications/cursor.desktop
sudo rm -f /usr/share/icons/hicolor/512x512/apps/cursor.png

# Update desktop database and icon cache
sudo update-desktop-database
sudo gtk-update-icon-cache -f -t /usr/share/icons/hicolor 2>/dev/null || true
```

## Troubleshooting

If you encounter issues:

1. **Permission denied**: Ensure you use `sudo` for system directories
2. **Command not found**: Check your PATH includes `/usr/local/bin`
3. **GPU errors**: The `--disable-gpu` flag and environment variables prevent most issues
4. **Sandbox errors**: The `--no-sandbox` flag is included in desktop entries

For additional help, see the [GPU troubleshooting guide](gpu-troubleshooting.md).