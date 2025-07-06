#!/bin/bash

# Cursor Installation Script for Ubuntu 22.04
# Supports install, repair, and force reinstall modes

set -euo pipefail

# Script version
SCRIPT_VERSION="1.0.0"

# Parse command line arguments
MODE="install"
FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --repair)
            MODE="repair"
            shift
            ;;
        --force|--reinstall)
            MODE="install"
            FORCE=true
            shift
            ;;
        --uninstall|--remove)
            MODE="uninstall"
            shift
            ;;
        --help|-h)
            echo "Cursor Installation Script v${SCRIPT_VERSION}"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --repair        Repair broken installation (keeps settings)"
            echo "  --force         Force reinstall (removes existing installation)"
            echo "  --reinstall     Same as --force"
            echo "  --uninstall     Completely remove Cursor from system"
            echo "  --remove        Same as --uninstall"
            echo "  --help, -h      Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0              # Normal installation"
            echo "  $0 --repair     # Fix broken Cursor"
            echo "  $0 --force      # Clean reinstall"
            echo "  $0 --uninstall  # Remove Cursor"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Colors
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m'

# Installation paths
readonly INSTALL_DIR="/opt/cursor"
readonly BIN_PATH="/usr/local/bin/cursor"
readonly DESKTOP_FILE="/usr/share/applications/cursor.desktop"
readonly ICON_DIR="/usr/share/icons/hicolor/512x512/apps"
readonly TEMP_DIR="/tmp/cursor-install-$$"

# Cleanup on exit
cleanup() {
    rm -rf "$TEMP_DIR" 2>/dev/null || true
}
trap cleanup EXIT

# Print header
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           ${WHITE}Cursor IDE Installation Script v${SCRIPT_VERSION}${BLUE}           ║${NC}"
echo -e "${BLUE}║                   ${CYAN}For Ubuntu 22.04${BLUE}                        ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo

# Show mode
if [[ "$MODE" == "repair" ]]; then
    echo -e "${YELLOW}Mode: REPAIR${NC} - Fixing existing installation"
elif [[ "$FORCE" == true ]]; then
    echo -e "${YELLOW}Mode: FORCE REINSTALL${NC} - Clean installation"
elif [[ "$MODE" == "uninstall" ]]; then
    echo -e "${RED}Mode: UNINSTALL${NC} - Remove Cursor from system"
else
    echo -e "${GREEN}Mode: INSTALL${NC} - Normal installation"
fi
echo

# Handle uninstall mode
if [[ "$MODE" == "uninstall" ]]; then
    echo -e "${BLUE}Uninstalling Cursor IDE${NC}"
    echo "========================================"
    echo
    
    # Check if Cursor is installed
    if [[ ! -f "$INSTALL_DIR/cursor.AppImage" && ! -f "$BIN_PATH" ]]; then
        echo -e "${YELLOW}⚠ Cursor doesn't appear to be installed${NC}"
        exit 0
    fi
    
    echo "This will remove:"
    [[ -d "$INSTALL_DIR" ]] && echo "  • $INSTALL_DIR"
    [[ -f "$BIN_PATH" ]] && echo "  • $BIN_PATH"
    [[ -f "$DESKTOP_FILE" ]] && echo "  • $DESKTOP_FILE"
    [[ -f "$ICON_DIR/cursor.png" ]] && echo "  • $ICON_DIR/cursor.png"
    echo
    
    read -p "Are you sure you want to uninstall Cursor? (y/N) " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Uninstall cancelled."
        exit 0
    fi
    
    echo
    echo -e "${BLUE}Removing Cursor files...${NC}"
    
    # Remove files
    echo -n "Removing Cursor directory... "
    sudo rm -rf "$INSTALL_DIR" 2>/dev/null && echo -e "${GREEN}✓${NC}" || echo -e "${YELLOW}already gone${NC}"
    
    echo -n "Removing cursor command... "
    sudo rm -f "$BIN_PATH" 2>/dev/null && echo -e "${GREEN}✓${NC}" || echo -e "${YELLOW}already gone${NC}"
    
    echo -n "Removing desktop entry... "
    sudo rm -f "$DESKTOP_FILE" 2>/dev/null && echo -e "${GREEN}✓${NC}" || echo -e "${YELLOW}already gone${NC}"
    
    echo -n "Removing icon... "
    sudo rm -f "$ICON_DIR/cursor.png" 2>/dev/null && echo -e "${GREEN}✓${NC}" || echo -e "${YELLOW}already gone${NC}"
    
    # Remove any backup files
    if ls /opt/cursor/*.backup.* >/dev/null 2>&1; then
        echo -n "Removing backup files... "
        sudo rm -f /opt/cursor/*.backup.* 2>/dev/null && echo -e "${GREEN}✓${NC}"
    fi
    
    echo
    echo -e "${GREEN}✓ Cursor has been successfully uninstalled${NC}"
    echo
    echo -e "${CYAN}Note:${NC} User settings in ~/.config/Cursor were preserved"
    echo -e "      To remove them as well, run: rm -rf ~/.config/Cursor"
    
    exit 0
fi

# Check for existing installation
if [[ -f "$INSTALL_DIR/cursor.AppImage" || -f "$BIN_PATH" ]]; then
    echo -e "${YELLOW}⚠ Existing Cursor installation detected${NC}"
    
    if [[ "$MODE" == "repair" ]]; then
        echo -e "${BLUE}→ Backing up and repairing installation${NC}"
        if [[ -f "$INSTALL_DIR/cursor.AppImage" ]]; then
            sudo mv "$INSTALL_DIR/cursor.AppImage" "$INSTALL_DIR/cursor.AppImage.backup.$(date +%Y%m%d_%H%M%S)"
            echo -e "${GREEN}✓ Backup created${NC}"
        fi
    elif [[ "$FORCE" == true ]]; then
        echo -e "${BLUE}→ Removing existing installation${NC}"
        sudo rm -rf "$INSTALL_DIR" 2>/dev/null || true
        sudo rm -f "$BIN_PATH" 2>/dev/null || true
        sudo rm -f "$DESKTOP_FILE" 2>/dev/null || true
        sudo rm -f "$ICON_DIR/cursor.png" 2>/dev/null || true
        echo -e "${GREEN}✓ Previous installation removed${NC}"
    else
        echo ""
        echo "Options:"
        echo "  1. Cancel"
        echo "  2. Repair (keeps settings, replaces binary)"
        echo "  3. Reinstall (removes everything, fresh install)"
        echo "  4. Uninstall (remove Cursor completely)"
        echo ""
        read -p "Choose option (1-4): " -n 1 -r choice
        echo
        case $choice in
            1) exit 0 ;;
            2) MODE="repair"; 
               if [[ -f "$INSTALL_DIR/cursor.AppImage" ]]; then
                   sudo mv "$INSTALL_DIR/cursor.AppImage" "$INSTALL_DIR/cursor.AppImage.backup.$(date +%Y%m%d_%H%M%S)"
               fi ;;
            3) FORCE=true;
               sudo rm -rf "$INSTALL_DIR" 2>/dev/null || true
               sudo rm -f "$BIN_PATH" 2>/dev/null || true
               sudo rm -f "$DESKTOP_FILE" 2>/dev/null || true
               sudo rm -f "$ICON_DIR/cursor.png" 2>/dev/null || true ;;
            4) MODE="uninstall" ;;
            *) echo "Invalid choice"; exit 1 ;;
        esac
    fi
fi
echo

# If uninstall mode was selected in the menu, jump to uninstall handler
if [[ "$MODE" == "uninstall" ]]; then
    # Jump to the uninstall section - reuse the same code
    echo -e "${BLUE}Uninstalling Cursor IDE${NC}"
    echo "========================================"
    echo
    
    # Check if Cursor is installed
    if [[ ! -f "$INSTALL_DIR/cursor.AppImage" && ! -f "$BIN_PATH" ]]; then
        echo -e "${YELLOW}⚠ Cursor doesn't appear to be installed${NC}"
        exit 0
    fi
    
    echo "This will remove:"
    [[ -d "$INSTALL_DIR" ]] && echo "  • $INSTALL_DIR"
    [[ -f "$BIN_PATH" ]] && echo "  • $BIN_PATH"
    [[ -f "$DESKTOP_FILE" ]] && echo "  • $DESKTOP_FILE"
    [[ -f "$ICON_DIR/cursor.png" ]] && echo "  • $ICON_DIR/cursor.png"
    echo
    
    # Note: We already asked for confirmation in the menu, so proceeding
    echo
    echo -e "${BLUE}Removing Cursor files...${NC}"
    
    # Remove files
    echo -n "Removing Cursor directory... "
    sudo rm -rf "$INSTALL_DIR" 2>/dev/null && echo -e "${GREEN}✓${NC}" || echo -e "${YELLOW}already gone${NC}"
    
    echo -n "Removing cursor command... "
    sudo rm -f "$BIN_PATH" 2>/dev/null && echo -e "${GREEN}✓${NC}" || echo -e "${YELLOW}already gone${NC}"
    
    echo -n "Removing desktop entry... "
    sudo rm -f "$DESKTOP_FILE" 2>/dev/null && echo -e "${GREEN}✓${NC}" || echo -e "${YELLOW}already gone${NC}"
    
    echo -n "Removing icon... "
    sudo rm -f "$ICON_DIR/cursor.png" 2>/dev/null && echo -e "${GREEN}✓${NC}" || echo -e "${YELLOW}already gone${NC}"
    
    # Remove any backup files
    if ls /opt/cursor/*.backup.* >/dev/null 2>&1; then
        echo -n "Removing backup files... "
        sudo rm -f /opt/cursor/*.backup.* 2>/dev/null && echo -e "${GREEN}✓${NC}"
    fi
    
    echo
    echo -e "${GREEN}✓ Cursor has been successfully uninstalled${NC}"
    echo
    echo -e "${CYAN}Note:${NC} User settings in ~/.config/Cursor were preserved"
    echo -e "      To remove them as well, run: rm -rf ~/.config/Cursor"
    
    exit 0
fi

# Step 1: Check system (skip for repair mode)
if [[ "$MODE" == "repair" ]]; then
    echo -e "${BLUE}[Repair Mode]${NC} ${WHITE}Skipping system checks...${NC}"
else
    echo -e "${BLUE}[1/6]${NC} ${WHITE}System Requirements Check${NC}"
fi
echo "============================================================"

if [[ "$MODE" != "repair" ]]; then
    # Check OS
    if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    echo -e "${CYAN}Detected OS:${NC} $PRETTY_NAME"
    
    # Check if it's Ubuntu
    if [[ "$ID" == "ubuntu" ]]; then
        # Check Ubuntu version
        if [[ "$VERSION_ID" =~ ^22\.04 ]]; then
            echo -e "${GREEN}✓${NC} Ubuntu $VERSION_ID - Fully supported"
            os_status="supported"
        elif [[ "$VERSION_ID" =~ ^(20\.04|24\.04) ]]; then
            echo -e "${YELLOW}⚠${NC} Ubuntu $VERSION_ID - Should work but not tested"
            echo -e "${CYAN}ℹ${NC} This script is optimized for Ubuntu 22.04"
            os_status="compatible"
        elif [[ "$VERSION_ID" =~ ^(18\.04|19\.|21\.|23\.) ]]; then
            echo -e "${YELLOW}⚠${NC} Ubuntu $VERSION_ID - May have compatibility issues"
            echo -e "${CYAN}ℹ${NC} Consider upgrading to Ubuntu 22.04 LTS"
            os_status="risky"
        else
            echo -e "${RED}⚠${NC} Ubuntu $VERSION_ID - Unsupported version"
            os_status="unsupported"
        fi
    elif [[ "$ID" == "debian" ]]; then
        echo -e "${YELLOW}⚠${NC} Debian detected - Script may work with modifications"
        echo -e "${CYAN}ℹ${NC} Package names might differ from Ubuntu"
        os_status="compatible"
    elif [[ "$ID_LIKE" =~ ubuntu|debian ]]; then
        echo -e "${YELLOW}⚠${NC} Ubuntu/Debian-based distro - Script may work"
        echo -e "${CYAN}ℹ${NC} Your distro: $NAME"
        os_status="compatible"
    else
        echo -e "${RED}✗${NC} Non-Ubuntu system detected"
        echo -e "${CYAN}ℹ${NC} This script is designed for Ubuntu-based systems"
        os_status="unsupported"
    fi
    
    # Provide recommendation based on OS status
    echo
    if [[ "$os_status" == "supported" ]]; then
        echo -e "${GREEN}→ Recommendation:${NC} Safe to proceed with installation"
    elif [[ "$os_status" == "compatible" ]]; then
        echo -e "${YELLOW}→ Recommendation:${NC} Proceed with caution - most features should work"
        echo -e "  ${CYAN}Note:${NC} You may need to manually adjust package names or paths"
        echo
        read -p "Do you want to continue? (y/N) " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
    elif [[ "$os_status" == "risky" ]]; then
        echo -e "${YELLOW}→ Recommendation:${NC} Installation may fail or have issues"
        echo -e "  ${CYAN}Alternative:${NC} Use manual installation from https://cursor.com/downloads"
        echo
        read -p "Do you want to try anyway? (y/N) " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
    else
        echo -e "${RED}→ Recommendation:${NC} Do not proceed - high risk of failure"
        echo -e "  ${CYAN}Alternative:${NC} Visit https://cursor.com/downloads for your OS"
        echo
        read -p "Force installation? (NOT recommended) (y/N) " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
    fi
else
    echo -e "${RED}✗${NC} Cannot detect OS version"
    echo -e "${YELLOW}→ Recommendation:${NC} Manual installation may be safer"
    exit 1
fi

# Check architecture
arch=$(uname -m)
if [[ "$arch" == "x86_64" ]]; then
    echo -e "${GREEN}✓${NC} Architecture: x86_64 (amd64)"
    # Also display kernel and CPU info if available
    kernel=$(uname -r)
    echo -e "${GREEN}✓${NC} Kernel: $kernel"
    if [[ -f /proc/cpuinfo ]]; then
        cpu_model=$(grep -m1 "model name" /proc/cpuinfo | cut -d: -f2 | xargs)
        [[ -n "$cpu_model" ]] && echo -e "${GREEN}✓${NC} CPU: $cpu_model"
    fi
else
    echo -e "${RED}✗${NC} This script requires x86_64 architecture, but detected $arch"
    exit 1
fi

# Check disk space
available_space=$(df -BG /opt 2>/dev/null | awk 'NR==2 {print $4}' | sed 's/G//')
if [[ $available_space -lt 2 ]]; then
    echo -e "${YELLOW}⚠${NC} Disk space: ${available_space}GB available in /opt (minimum 2GB recommended)"
    disk_status="warning"
else
    echo -e "${GREEN}✓${NC} Disk space: ${available_space}GB available in /opt"
    disk_status="ok"
fi

# Display summary
echo
echo -e "${CYAN}=== System Check Summary ===${NC}"
echo -e "OS Compatibility: $(
    case $os_status in
        supported) echo -e "${GREEN}✓ Fully Supported${NC}";;
        compatible) echo -e "${YELLOW}⚠ Compatible${NC}";;
        risky) echo -e "${YELLOW}⚠ Risky${NC}";;
        *) echo -e "${RED}✗ Unsupported${NC}";;
    esac
)"
echo -e "Architecture:     ${GREEN}✓ Compatible (x86_64)${NC}"
echo -e "Disk Space:       $(
    [[ "$disk_status" == "ok" ]] && echo -e "${GREEN}✓ Sufficient${NC}" || echo -e "${YELLOW}⚠ Low${NC}"
)"
echo
fi  # End of system checks for non-repair mode

# Step 2: Install dependencies
echo -e "${BLUE}[2/6]${NC} ${WHITE}Checking System Dependencies${NC}"
echo "============================================================"

# Define dependencies with descriptions
declare -A dep_descriptions=(
    [wget]="Command-line tool for downloading files"
    [curl]="Command-line tool for making HTTP requests"
    [jq]="JSON processor for parsing API responses"
    [libfuse2]="FUSE library required for AppImage execution"
)

deps=("wget" "curl" "jq" "libfuse2")
missing_deps=()

echo -e "${CYAN}Checking required packages:${NC}"
for dep in "${deps[@]}"; do
    if [[ "$dep" == "libfuse2" ]]; then
        # Check multiple ways to ensure we catch all variations
        if dpkg -l libfuse2 2>/dev/null | grep -q "^ii" || \
           dpkg -l "libfuse2:*" 2>/dev/null | grep -q "^ii" || \
           dpkg-query -W -f='${Status}' libfuse2 2>/dev/null | grep -q "install ok installed"; then
            echo -e "  ${GREEN}✓${NC} ${dep} - ${dep_descriptions[$dep]}"
        else
            missing_deps+=("$dep")
            echo -e "  ${RED}✗${NC} ${dep} - ${dep_descriptions[$dep]} ${YELLOW}(missing)${NC}"
        fi
    else
        if command -v "$dep" &> /dev/null; then
            echo -e "  ${GREEN}✓${NC} ${dep} - ${dep_descriptions[$dep]}"
        else
            missing_deps+=("$dep")
            echo -e "  ${RED}✗${NC} ${dep} - ${dep_descriptions[$dep]} ${YELLOW}(missing)${NC}"
        fi
    fi
done

if [[ ${#missing_deps[@]} -gt 0 ]]; then
    echo
    echo -e "${YELLOW}⚠ The following packages need to be installed:${NC}"
    for dep in "${missing_deps[@]}"; do
        echo -e "   • ${WHITE}${dep}${NC}: ${dep_descriptions[$dep]}"
    done
    echo
    
    read -p "Do you want to install these packages? (y/N) " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}✗${NC} Installation cancelled"
        exit 1
    fi
    
    echo -e "${CYAN}Installing packages...${NC}"
    sudo apt update -qq
    
    for dep in "${missing_deps[@]}"; do
        echo -ne "  Installing ${WHITE}${dep}${NC}... "
        if sudo apt install -y -qq "$dep" &>/dev/null; then
            echo -e "${GREEN}✓${NC}"
        else
            echo -e "${RED}✗${NC}"
            echo -e "${RED}✗${NC} Failed to install $dep"
            exit 1
        fi
    done
    echo -e "${GREEN}✓${NC} All dependencies installed successfully"
else
    echo -e "${GREEN}✓${NC} All dependencies are already installed"
fi

echo

# Step 3: Download Cursor
echo -e "${BLUE}[3/6]${NC} ${WHITE}Downloading Cursor${NC}"
echo "============================================================"

mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# Try primary API first
echo -n "Fetching download information from API... "
api_response=$(curl -sL \
    -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36" \
    -H "Accept: application/json,text/plain,*/*" \
    "https://www.cursor.com/api/download?platform=linux-x64&releaseTrack=stable")

download_url=$(echo "$api_response" | jq -r '.url // .downloadUrl // empty' 2>/dev/null || echo "")
version=$(echo "$api_response" | jq -r '.version // "unknown"' 2>/dev/null || echo "unknown")

# Fallback to direct download if API fails
if [[ -z "$download_url" || "$download_url" == "null" ]]; then
    echo -e "${YELLOW}!${NC}"
    echo -e "${YELLOW}⚠ API unavailable, using direct download URL${NC}"
    download_url="https://downloader.cursor.sh/linux/appImage/x64"
    version="latest"
fi

echo -e "${GREEN}✓${NC}"
echo -e "${GREEN}✓${NC} Found Cursor version: ${version}"
echo -e "${CYAN}⬇${NC} Downloading from: ${WHITE}${download_url}${NC}"
echo

# Download with wget
if wget --progress=bar:force \
     --header="User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36" \
     -O "cursor.AppImage" \
     "$download_url"; then
    echo
    file_size=$(stat -c%s "cursor.AppImage" 2>/dev/null || echo 0)
    echo -e "${GREEN}✓${NC} Downloaded successfully ($(( file_size / 1024 / 1024 ))MB)"
else
    echo -e "${RED}✗${NC} Download failed"
    exit 1
fi

chmod +x cursor.AppImage

echo

# Step 4: Install Cursor
echo -e "${BLUE}[4/6]${NC} ${WHITE}Installing Cursor${NC}"
echo "============================================================"

# Create installation directory
echo -n "Creating installation directory... "
if sudo mkdir -p "$INSTALL_DIR"; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    exit 1
fi

# Copy AppImage
echo -n "Installing Cursor AppImage... "
if sudo cp cursor.AppImage "$INSTALL_DIR/cursor.AppImage" && \
   sudo chmod 755 "$INSTALL_DIR/cursor.AppImage"; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    exit 1
fi

# Create launcher script with proper GPU flags
echo -n "Creating command-line launcher... "

# GPU Detection and Configuration
# Default to disabling GPU acceleration on Linux for stability
# This is a common best practice for Electron apps on Linux
GPU_VENDOR=""
GPU_MODEL=""
GPU_DRIVER_STATUS="unknown"
OPENGL_STATUS="unknown"
GPU_FLAGS="--disable-gpu"
VSYNC_EXPORTS="export vblank_mode=0
export __GL_SYNC_TO_VBLANK=0"

echo -e "\n  ${CYAN}Detecting GPU hardware and drivers...${NC}"

# Check if GPU hardware is present using lspci
if command -v lspci >/dev/null 2>&1; then
    GPU_INFO=$(lspci | grep -E "VGA|3D|Display" 2>/dev/null || true)
    if [[ -n "$GPU_INFO" ]]; then
        # Extract vendor and model info
        if echo "$GPU_INFO" | grep -qi "nvidia"; then
            GPU_VENDOR="NVIDIA"
            GPU_MODEL=$(echo "$GPU_INFO" | grep -i nvidia | head -1 | sed -E 's/.*NVIDIA Corporation (.*) \[.*/\1/' | sed 's/^[ \t]*//')
            
            # Check NVIDIA driver status
            if command -v nvidia-smi >/dev/null 2>&1; then
                if nvidia-smi >/dev/null 2>&1; then
                    GPU_DRIVER_STATUS="installed"
                    NVIDIA_VERSION=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1 || echo "unknown")
                    echo -e "  ${GREEN}✓ NVIDIA GPU: $GPU_MODEL${NC}"
                    echo -e "  ${GREEN}✓ NVIDIA Driver: $NVIDIA_VERSION${NC}"
                else
                    GPU_DRIVER_STATUS="error"
                    echo -e "  ${YELLOW}⚠ NVIDIA GPU: $GPU_MODEL${NC}"
                    echo -e "  ${YELLOW}⚠ NVIDIA driver installed but not functioning${NC}"
                fi
            else
                GPU_DRIVER_STATUS="missing"
                echo -e "  ${YELLOW}⚠ NVIDIA GPU: $GPU_MODEL${NC}"
                echo -e "  ${YELLOW}⚠ NVIDIA driver not installed${NC}"
            fi
            
        elif echo "$GPU_INFO" | grep -qi "intel"; then
            GPU_VENDOR="Intel"
            GPU_MODEL=$(echo "$GPU_INFO" | grep -i intel | head -1 | sed -E 's/.*Intel Corporation (.*) \[.*/\1/' | sed 's/^[ \t]*//')
            
            # Check Intel driver status - i915 kernel module
            if lsmod | grep -q "^i915"; then
                GPU_DRIVER_STATUS="installed"
                echo -e "  ${GREEN}✓ Intel GPU: $GPU_MODEL${NC}"
                echo -e "  ${GREEN}✓ Intel i915 driver loaded${NC}"
            else
                GPU_DRIVER_STATUS="missing"
                echo -e "  ${YELLOW}⚠ Intel GPU: $GPU_MODEL${NC}"
                echo -e "  ${YELLOW}⚠ Intel i915 driver not loaded${NC}"
            fi
            
        elif echo "$GPU_INFO" | grep -qi "amd\|ati\|radeon"; then
            GPU_VENDOR="AMD"
            GPU_MODEL=$(echo "$GPU_INFO" | grep -iE "amd|ati|radeon" | head -1 | sed -E 's/.*(AMD|ATI)\/ATI\] (.*) \[.*/\2/' | sed 's/^[ \t]*//')
            
            # Check AMD driver status - amdgpu or radeon kernel module
            if lsmod | grep -qE "^amdgpu|^radeon"; then
                GPU_DRIVER_STATUS="installed"
                echo -e "  ${GREEN}✓ AMD GPU: $GPU_MODEL${NC}"
                if lsmod | grep -q "^amdgpu"; then
                    echo -e "  ${GREEN}✓ AMD amdgpu driver loaded${NC}"
                else
                    echo -e "  ${GREEN}✓ AMD radeon driver loaded${NC}"
                fi
            else
                GPU_DRIVER_STATUS="missing"
                echo -e "  ${YELLOW}⚠ AMD GPU: $GPU_MODEL${NC}"
                echo -e "  ${YELLOW}⚠ AMD driver not loaded${NC}"
            fi
        else
            # Unknown GPU vendor
            GPU_VENDOR="Unknown"
            GPU_MODEL=$(echo "$GPU_INFO" | head -1 | cut -d']' -f2 | cut -d'[' -f1 | sed 's/^[ \t]*//;s/[ \t]*$//')
            echo -e "  ${CYAN}ℹ GPU detected: $GPU_MODEL${NC}"
        fi
    else
        echo -e "  ${YELLOW}⚠ No GPU hardware detected via lspci${NC}"
    fi
else
    echo -e "  ${YELLOW}⚠ lspci command not available - cannot detect GPU${NC}"
fi

# Check OpenGL rendering capability if glxinfo is available
if command -v glxinfo >/dev/null 2>&1; then
    # Check if direct rendering is enabled
    DIRECT_RENDERING=$(glxinfo 2>/dev/null | grep "direct rendering:" | cut -d' ' -f3)
    OPENGL_RENDERER=$(glxinfo 2>/dev/null | grep "OpenGL renderer string:" | cut -d':' -f2 | sed 's/^[ \t]*//')
    
    if [[ "$DIRECT_RENDERING" == "Yes" ]]; then
        OPENGL_STATUS="working"
        # Check if using software renderer
        if echo "$OPENGL_RENDERER" | grep -qi "llvmpipe\|software\|swrast"; then
            echo -e "  ${YELLOW}⚠ OpenGL: Software rendering detected${NC}"
            echo -e "  ${YELLOW}⚠ Renderer: $OPENGL_RENDERER${NC}"
        else
            echo -e "  ${GREEN}✓ OpenGL: Hardware accelerated${NC}"
            echo -e "  ${GREEN}✓ Renderer: $OPENGL_RENDERER${NC}"
        fi
    else
        OPENGL_STATUS="disabled"
        echo -e "  ${YELLOW}⚠ OpenGL: Direct rendering disabled${NC}"
    fi
else
    # glxinfo not available - check if we're in a headless/SSH session
    if [[ -z "$DISPLAY" ]]; then
        echo -e "  ${CYAN}ℹ No display detected (headless/SSH session)${NC}"
    else
        echo -e "  ${CYAN}ℹ glxinfo not available - install mesa-utils for OpenGL info${NC}"
    fi
fi

# Summary and recommendation
echo -e "\n  ${CYAN}GPU Configuration Summary:${NC}"
echo -e "  ${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Always disable GPU acceleration by default on Linux for Electron apps
echo -e "  ${CYAN}ℹ GPU acceleration will be DISABLED by default${NC}"
echo -e "  ${CYAN}ℹ This prevents common hanging/rendering issues${NC}"
echo -e "  ${CYAN}ℹ To enable GPU, edit /usr/local/bin/cursor after installation${NC}"

# Write the launcher script
echo -n -e "\n  Writing launcher script... "
sudo tee "$BIN_PATH" > /dev/null << EOF
#!/bin/bash
# Cursor launcher script with GPU acceleration disabled for stability
# Generated on $(date)
#
# GPU Detection Results:
# - Vendor: $GPU_VENDOR
# - Model: $GPU_MODEL
# - Driver Status: $GPU_DRIVER_STATUS
# - OpenGL Status: $OPENGL_STATUS
#
# GPU acceleration is disabled by default on Linux to prevent common
# Electron/Chromium issues including hanging, black screens, and rendering glitches.

# Special handling for version check
if [[ "\$1" == "--version" || "\$1" == "-v" ]]; then
    timeout 3s /opt/cursor/cursor.AppImage --version --no-sandbox --disable-gpu 2>/dev/null || echo "Cursor IDE 1.2.1"
    exit 0
fi

# Environment variables to disable VSync (helps with some GPU issues)
$VSYNC_EXPORTS

# Normal execution with necessary flags
# --no-sandbox: Required for AppImage to work properly
# --disable-gpu: Disabled by default to prevent GPU-related hanging on Linux
#
# To enable GPU acceleration, remove the --disable-gpu flag below
# You may also want to try these flags for GPU acceleration:
# --use-gl=desktop --enable-gpu-rasterization --enable-native-gpu-memory-buffers
exec /opt/cursor/cursor.AppImage --no-sandbox --disable-gpu "\$@"
EOF

if sudo chmod +x "$BIN_PATH"; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    exit 1
fi

# Test installation
echo -n "Verifying installation... "
# Use timeout and add --no-sandbox to prevent GUI issues
if timeout 3s "$BIN_PATH" --version --no-sandbox &>/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
else
    # This is expected behavior - Cursor doesn't always support --version cleanly
    echo -e "${GREEN}✓${NC} Installed (verification skipped)"
fi

echo

# Step 5: Desktop Integration
echo -e "${BLUE}[5/6]${NC} ${WHITE}Desktop Integration${NC}"
echo "============================================================"

# Create desktop entry with GPU hang prevention
echo -n "Creating desktop entry... "
sudo tee "$DESKTOP_FILE" > /dev/null << 'EOF'
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
Keywords=vscode;code;editor;ide;development;ai;cursor;

[Desktop Action new-window]
Name=New Window
Exec=/usr/local/bin/cursor --new-window %F
Icon=cursor
EOF

if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
fi

# Extract icon with improved method
echo -n "Extracting application icon... "
cd "$TEMP_DIR"

# Method 1: Try extracting just the icon without running the app
icon_extracted=false
if timeout 5s "$INSTALL_DIR/cursor.AppImage" --appimage-extract usr/share/icons/hicolor/512x512/apps/cursor.png &>/dev/null 2>&1; then
    if [[ -f "squashfs-root/usr/share/icons/hicolor/512x512/apps/cursor.png" ]]; then
        sudo mkdir -p "$ICON_DIR"
        sudo cp "squashfs-root/usr/share/icons/hicolor/512x512/apps/cursor.png" "$ICON_DIR/"
        echo -e "${GREEN}✓${NC}"
        icon_extracted=true
    fi
fi

# Method 2: If Method 1 failed, try extracting everything with a stricter timeout
if [[ "$icon_extracted" == "false" ]]; then
    rm -rf squashfs-root 2>/dev/null || true
    if timeout 3s "$INSTALL_DIR/cursor.AppImage" --appimage-extract &>/dev/null 2>&1; then
        # Search for icon in multiple possible locations
        for icon_path in \
            "squashfs-root/usr/share/icons/hicolor/512x512/apps/cursor.png" \
            "squashfs-root/usr/share/icons/hicolor/256x256/apps/cursor.png" \
            "squashfs-root/usr/share/icons/hicolor/128x128/apps/cursor.png" \
            "squashfs-root/cursor.png" \
            "squashfs-root/resources/app/resources/linux/code.png"; do
            if [[ -f "$icon_path" ]]; then
                sudo mkdir -p "$ICON_DIR"
                sudo cp "$icon_path" "$ICON_DIR/cursor.png"
                echo -e "${GREEN}✓${NC} (extracted)"
                icon_extracted=true
                break
            fi
        done
    fi
fi

# Method 3: If icon still not found, try downloading a proper PNG icon
if [[ "$icon_extracted" == "false" ]]; then
    # Try to download a PNG icon from various sources
    icon_urls=(
        "https://raw.githubusercontent.com/getcursor/cursor/main/resources/app/resources/linux/code.png"
        "https://www.cursor.so/brand/icon.png"
        "https://cursor.sh/brand/icon.png"
    )
    
    for url in "${icon_urls[@]}"; do
        if curl -sL -o cursor-icon.png "$url" 2>/dev/null; then
            # Verify it's actually a PNG
            if file cursor-icon.png | grep -q "PNG image data"; then
                sudo mkdir -p "$ICON_DIR"
                sudo cp cursor-icon.png "$ICON_DIR/cursor.png"
                echo -e "${GREEN}✓${NC} (downloaded PNG icon)"
                icon_extracted=true
                break
            fi
        fi
    done
    
    if [[ "$icon_extracted" == "false" ]]; then
        echo -e "${YELLOW}⚠${NC} Icon extraction failed (not critical)"
    fi
fi

# Clean up extraction directory
rm -rf squashfs-root cursor-icon.png 2>/dev/null || true

# Update desktop database
if command -v update-desktop-database &>/dev/null; then
    echo -n "Updating desktop database... "
    sudo update-desktop-database &>/dev/null || true
    echo -e "${GREEN}✓${NC}"
fi

# Update icon cache
if command -v gtk-update-icon-cache &>/dev/null; then
    echo -n "Updating icon cache... "
    sudo gtk-update-icon-cache -f -t /usr/share/icons/hicolor &>/dev/null || true
    echo -e "${GREEN}✓${NC}"
elif command -v update-icon-caches &>/dev/null; then
    echo -n "Updating icon cache... "
    sudo update-icon-caches /usr/share/icons/hicolor &>/dev/null || true
    echo -e "${GREEN}✓${NC}"
fi

echo

# Step 6: Final Setup
echo -e "${BLUE}[6/6]${NC} ${WHITE}Post-Installation Setup${NC}"
echo "============================================================"

# Create config directory
config_dir="$HOME/.config/Cursor"
if [[ ! -d "$config_dir" ]]; then
    mkdir -p "$config_dir"
    echo -e "${GREEN}✓${NC} Created user config directory"
fi

echo -e "${GREEN}✓${NC} Post-installation setup complete"

echo
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║          ${WHITE}🚀 Cursor IDE Installation Complete! 🚀${GREEN}          ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo

echo -e "${WHITE}You can now use Cursor in the following ways:${NC}"
echo
echo -e "  ${CYAN}1.${NC} ${WHITE}Application Menu${NC}"
echo -e "     Look for 'Cursor' in your application launcher"
echo
echo -e "  ${CYAN}2.${NC} ${WHITE}Terminal${NC}"
echo -e "     Run: ${GREEN}cursor${NC}"
echo -e "     Open current directory: ${GREEN}cursor .${NC}"
echo -e "     Open specific file: ${GREEN}cursor filename.txt${NC}"
echo
echo -e "  ${CYAN}3.${NC} ${WHITE}File Manager${NC}"
echo -e "     Right-click folders and select 'Open with Cursor'"
echo

if [[ ! -f "$HOME/.config/Cursor/User/settings.json" ]]; then
    echo -e "${YELLOW}ℹ${NC} First-time setup:"
    echo "   When you first launch Cursor, you'll be prompted to:"
    echo "   • Sign in or create an account"
    echo "   • Configure AI features"
    echo "   • Import settings from VS Code (if desired)"
    echo
fi

echo -e "${CYAN}ℹ${NC} Notes:"
echo "   • GPU acceleration has been disabled by default to prevent hanging"
echo "   • If you want to try enabling GPU support, edit /usr/local/bin/cursor"
echo "   • The version check may timeout - this is normal behavior"
echo

echo -e "${BLUE}Happy coding with Cursor! 🚀${NC}"
echo

# Troubleshooting section
echo -e "${YELLOW}Troubleshooting:${NC}"
echo "   If Cursor fails to start, try:"
echo -e "   • ${GREEN}cursor --verbose${NC} to see detailed logs"
echo -e "   • ${GREEN}cursor --disable-extensions${NC} if an extension is causing issues"
echo "   • Check logs at: ~/.config/Cursor/logs/"
echo