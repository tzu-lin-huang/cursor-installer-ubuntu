# GPU Troubleshooting Guide

Common GPU-related issues and solutions for Cursor IDE on Linux.

## GPU Detection and Configuration

**The installer automatically detects your GPU hardware and configuration:**

### What Gets Detected
- **GPU Hardware**: NVIDIA, Intel, AMD graphics cards via `lspci`
- **Driver Status**: 
  - NVIDIA: Checks `nvidia-smi` functionality and driver version
  - Intel: Verifies `i915` kernel module is loaded  
  - AMD: Checks for `amdgpu` or `radeon` kernel modules
- **OpenGL Support**: Tests hardware acceleration capability via `glxinfo`
- **Rendering Status**: Identifies hardware vs software rendering

### Default Configuration

**GPU acceleration is disabled by default on Linux:**
- `--disable-gpu` flag prevents common Electron/Chromium issues
- Environment variables `vblank_mode=0` and `__GL_SYNC_TO_VBLANK=0` disable VSync
- `--no-sandbox` flag for proper AppImage execution

This configuration prevents hanging, black screens, and rendering glitches common with Electron apps on Linux.

## Common Issues

### Cursor Hangs on Startup
The most common issue is Cursor hanging indefinitely when starting. This is typically caused by GPU initialization problems.

### VSync Errors
```
GetVSyncParametersIfAvailable() failed for X times!
```

### GL Context Errors
```
ERROR:gl_surface_presentation_helper.cc
ERROR:gpu_process_host.cc
```

### WebGL Warnings
```
WebGL: context lost
Hardware acceleration disabled
```

## Solutions

### Re-enabling GPU Support (Advanced Users)

**WARNING**: Enabling GPU acceleration may cause hanging, black screens, or rendering issues on Linux.

If your system has proper GPU drivers and you want to try enabling GPU acceleration:

1. Edit the launcher script:
```bash
sudo nano /usr/local/bin/cursor
```

2. Remove the `--disable-gpu` flag from the exec line
3. Optionally comment out the VSync environment variables
4. Try different GPU configurations:

```bash
# Try with just VSync disabled via environment
vblank_mode=0 __GL_SYNC_TO_VBLANK=0 cursor

# Try with software rendering for WebGL only
cursor --use-gl=swiftshader

# Try with EGL backend
cursor --use-gl=egl
```

### 2. Environment Variables (Already Set by Default)

The installer already sets these environment variables in the launcher script:
```bash
export vblank_mode=0
export __GL_SYNC_TO_VBLANK=0
```

To add them system-wide:
```bash
# Add to ~/.bashrc
echo 'export vblank_mode=0' >> ~/.bashrc
echo 'export __GL_SYNC_TO_VBLANK=0' >> ~/.bashrc
source ~/.bashrc
```

### 3. Use Software Rendering for WebGL

If VSync fix doesn't work:

```bash
cursor --use-gl=swiftshader
```

### 4. Disable GPU Acceleration

Last resort - may impact performance:

```bash
cursor --disable-gpu
```

### 5. Combined Flags

For persistent issues:

```bash
cursor --disable-gpu --disable-software-rasterizer
```

## System-Level Fixes

### Graphics Driver Updates

### Update Graphics Drivers

#### Intel Graphics
```bash
sudo apt update
sudo apt install -y intel-media-va-driver
```

#### NVIDIA
```bash
# Check current driver
nvidia-smi

# Update driver
sudo apt update
sudo apt install -y nvidia-driver-535  # or latest version
```

#### AMD
```bash
sudo apt update
sudo apt install -y mesa-vulkan-drivers
```

## Environment Variables

Create a launcher script with all fixes:

```bash
#!/bin/bash
# Save as ~/bin/cursor-fixed

export vblank_mode=0
export LIBGL_ALWAYS_SOFTWARE=0
export ELECTRON_DISABLE_GPU_COMPOSITING=0

exec /opt/cursor/cursor.AppImage --no-sandbox --disable-gpu "$@"
```

## Debugging

### Check GPU Detection Results
The installer saves GPU detection results in the launcher script comments:
```bash
# View GPU detection results
head -20 /usr/local/bin/cursor
```

### Manual GPU Detection Commands
```bash
# List all GPUs
lspci | grep -E "VGA|3D|Display"

# Check NVIDIA driver
nvidia-smi  # If NVIDIA GPU present

# Check Intel driver
lsmod | grep i915

# Check AMD driver  
lsmod | grep -E "amdgpu|radeon"

# OpenGL info
glxinfo | grep -E "direct rendering|OpenGL renderer"

# Check kernel messages
dmesg | grep -i gpu
```

### Test with Different Renderers
```bash
# Test each renderer
cursor --use-gl=desktop    # Default
cursor --use-gl=egl        # EGL backend
cursor --use-gl=swiftshader # Software renderer
```

## Performance Impact

- **Environment variables (vblank_mode=0)**: Minimal impact, fixes sync issues
- **--disable-gpu**: Moderate impact, disables GPU acceleration
- **--use-gl=swiftshader**: Moderate impact, software rendering

## Electron Flags Reference

Cursor is built on Electron, so these flags apply:

- `--disable-gpu`: Disable GPU hardware acceleration
- `--disable-software-rasterizer`: Disable software rasterizer
- `--enable-features=VaapiVideoDecoder`: Enable VA-API
- `--use-gl=[desktop|egl|swiftshader]`: Select GL implementation
- `--disable-features=UseChromeOSDirectVideoDecoder`: Fix video decode issues

## Verifying GPU Acceleration Status

To check if GPU acceleration is working in Cursor:

1. Open Cursor
2. Press `Ctrl+Shift+I` to open Developer Tools
3. Navigate to the Console tab
4. Type: `chrome://gpu`
5. Look for "Graphics Feature Status" section

Alternatively, check GPU process:
```bash
# Check if GPU process is running
ps aux | grep -i "cursor.*gpu-process"
```

## Still Having Issues?

1. Check Cursor logs: `~/.config/Cursor/logs/`
2. Try running with verbose output: `cursor --verbose`
3. Run the installer's GPU detection:
   ```bash
   # The installer logs GPU detection results during installation
   ./install_cursor.sh --repair  # Will show GPU detection again
   ```
4. Report issues with:
   - GPU info: `lspci | grep -E "VGA|3D|Display"`
   - Driver status: `lsmod | grep -E "i915|nvidia|amdgpu|radeon"`
   - OpenGL status: `glxinfo | grep -E "direct rendering|renderer"`