# Library Integration Guide

This document explains how to download and integrate the required libraries for TotalUI.

## Required Libraries

### 1. LibStub
**Purpose**: Library loading system
**Download**: https://www.wowace.com/projects/libstub/files
**Installation**:
1. Download the latest release
2. Extract `LibStub.lua` to `TotalUI/Libraries/LibStub/`

### 2. Ace3
**Purpose**: Core framework (AceAddon, AceDB, AceConfig, AceEvent, AceHook, etc.)
**Download**: https://www.wowace.com/projects/ace3/files
**Installation**:
1. Download the latest release
2. Extract all Ace3 folders to `TotalUI/Libraries/Ace3/`
3. The structure should look like:
   ```
   TotalUI/Libraries/Ace3/
   ├── AceAddon-3.0/
   ├── AceConfig-3.0/
   ├── AceConsole-3.0/
   ├── AceDB-3.0/
   ├── AceDBOptions-3.0/
   ├── AceEvent-3.0/
   ├── AceGUI-3.0/
   ├── AceHook-3.0/
   ├── AceLocale-3.0/
   └── AceTimer-3.0/
   ```

### 3. LibSharedMedia-3.0
**Purpose**: Media (fonts, textures, sounds) management
**Download**: https://www.wowace.com/projects/libsharedmedia-3-0/files
**Installation**:
1. Download the latest release
2. Extract the LibSharedMedia-3.0 folder to `TotalUI/Libraries/`
3. The structure should look like:
   ```
   TotalUI/Libraries/LibSharedMedia-3.0/
   ├── LibSharedMedia-3.0.lua
   └── lib.xml
   ```

### 4. LibTotalActionButtons (Built-in)
**Purpose**: Action button handling
**Status**: Built into TotalUI, no installation required
**Location**: `TotalUI/Libraries/LibTotalActionButtons/`

**Note**: This is TotalUI's custom implementation of action buttons. Unlike external libraries, this is maintained as part of TotalUI and follows our coding conventions.

## Integration Steps

After downloading the libraries:

1. **Update TOC file**: Uncomment the library loading sections in `TotalUI.toc`
2. **Test loading**: Start WoW and check for any loading errors with `/console scriptErrors 1`
3. **Verify libraries**: Type `/run print(LibStub and "LibStub OK" or "LibStub Missing")` in-game

## Library Loading Order

The TOC file loads libraries in this order:
1. LibStub (must be first)
2. Ace3 libraries (AceAddon, AceDB, AceConfig, etc.)
3. LibSharedMedia-3.0
4. LibActionButton-1.0 (Phase 1)

## Checking Library Status

Use the in-game command to check which libraries are loaded:
```lua
/run print("LibStub:", LibStub ~= nil)
/run print("AceAddon:", LibStub:GetLibrary("AceAddon-3.0", true) ~= nil)
/run print("AceDB:", LibStub:GetLibrary("AceDB-3.0", true) ~= nil)
/run print("LSM:", LibStub:GetLibrary("LibSharedMedia-3.0", true) ~= nil)
/run print("LibActionButton:", LibStub:GetLibrary("LibActionButton-1.0", true) ~= nil)
```

Or use TotalUI's built-in status command:
```
/totalui status
```

This will show all libraries and their loading status.

## Without Libraries

The addon will still load without libraries, but with reduced functionality:
- Basic module system (without AceAddon features)
- No profile management (without AceDB)
- No configuration UI (without AceConfig)
- Default fonts/textures only (without LibSharedMedia)

The addon is designed to gracefully degrade if libraries are missing.

## Updating Libraries

To update a library:
1. Download the latest version
2. Replace the old files with new ones
3. Restart WoW or `/reload`
4. Check for errors

## Alternative: Embedded Libraries

Instead of downloading separately, you can:
1. Use CurseForge/WoWInterface packager (automatically includes libs)
2. Use git submodules for development
3. Copy libs from other addons (ensure license compatibility)

## Troubleshooting

**Libraries not loading:**
- Check file paths match TOC file
- Ensure LibStub.lua is present and loads first
- Check for typos in TOC file paths

**Version conflicts:**
- TotalUI uses the latest library versions
- Older libraries may not work with newer WoW versions
- Always use libraries compatible with your WoW version

**Missing functions:**
- Some Classic versions don't have all Retail APIs
- The Compatibility layer handles most differences
- Check WoW version compatibility for each library
