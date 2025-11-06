# TotalUI

A modern, modular UI replacement addon for World of Warcraft with a future-proof architecture.

## Status

**Phase 0: Foundation & Core Systems** - ✅ Complete

Core architecture is implemented and tested. Ready for feature development.

## Features

- **Compatibility Layer** - Future-proof API wrappers that adapt to WoW version changes
- **Modular Architecture** - Each feature (ActionBars, UnitFrames, etc.) is independent
- **Three-Tier Settings** - Profile (shareable), Global (account-wide), Private (character-specific)
- **Graceful Degradation** - Works with or without external libraries
- **Version Detection** - Automatically detects and adapts to Retail/Classic/Era

## Quick Start

### Installation (Testing)

1. Clone this repository
2. Copy `TotalUI` and `TotalUI_Options` folders to `<WoW>/Interface/AddOns/`
3. Start WoW or `/reload`

### Verify Installation

```
/totalui status
/totalui version
```

### Optional: Install Libraries

For full functionality, install external libraries (see [LIBRARIES.md](LIBRARIES.md)):
- LibStub
- Ace3 (AceAddon, AceDB, AceConfig, etc.)
- LibSharedMedia-3.0

The addon works without these but with limited features (no GUI config, basic profile system).

## Project Structure

```
TotalUI/
├── TotalUI/                    # Main addon
│   ├── Core/                   # Foundation systems
│   │   ├── Init.lua            # Initialization
│   │   ├── Compatibility.lua   # API wrappers (WoW version handling)
│   │   ├── LibraryLoader.lua   # Library integration
│   │   ├── API.lua             # Frame creation helpers
│   │   ├── Events.lua          # Event system & callbacks
│   │   ├── Utilities.lua       # Helper functions
│   │   ├── Constants.lua       # Colors & constants
│   │   └── Defaults/           # Default settings (P/G/V)
│   ├── Modules/                # Feature modules (Phases 1-12)
│   │   ├── ActionBars/         # Phase 1 (not implemented)
│   │   ├── UnitFrames/         # Phase 2 (not implemented)
│   │   ├── Nameplates/         # Phase 3 (not implemented)
│   │   └── ...                 # Phases 4-12
│   ├── Libraries/              # Third-party libraries (install separately)
│   └── Media/                  # Fonts, textures, sounds
└── TotalUI_Options/            # Configuration UI (Phase 13)
```

## Development

### Architecture Overview

**Compatibility Layer** (`Core/Compatibility.lua`)
- Wrappers for all WoW APIs (Container, Item, Spell, Tooltip, etc.)
- Automatic detection of available APIs
- Seamless fallback to legacy APIs
- When Blizzard changes APIs, only this file needs updates

**Database System**
- **P (Profile)**: Settings that can be shared across characters
- **G (Global)**: Account-wide settings
- **V (Private)**: Character-locked settings (module enable/disable)

**Module System**
- Each phase is a self-contained module
- Modules can be enabled/disabled independently
- Use compatibility layer for all WoW API calls

### Adding a Module

See [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md) for detailed instructions.

```lua
local MyModule = E:NewModule("MyModule")

function MyModule:Initialize()
    if not E.private.mymodule.enable then return end

    -- Use compatibility layer for WoW APIs
    local item = E.Compat:GetItemName(itemID)

    -- Create UI with database-aware defaults
    local frame = E:CreateFrame("Frame", "MyFrame", UIParent)
    E:CreateBackdrop(frame)

    self.initialized = true
end
```

### Testing

See [TESTING.md](TESTING.md) for comprehensive testing procedures.

Quick test:
```lua
/run print(TotalUI)                    -- Should print table address
/totalui status                        -- Show addon status
/run TotalUI.Compat:PrintVersionInfo() -- Show compatibility info
```

## Development Roadmap

| Phase | Feature | Status |
|-------|---------|--------|
| 0 | Foundation & Core Systems | ✅ Complete |
| 1 | ActionBars | 🔲 Planned |
| 2 | UnitFrames | 🔲 Planned |
| 3 | Nameplates | 🔲 Planned |
| 4 | Bags | 🔲 Planned |
| 5 | Chat | 🔲 Planned |
| 6 | DataTexts | 🔲 Planned |
| 7 | DataBars | 🔲 Planned |
| 8 | Auras | 🔲 Planned |
| 9 | Tooltips | 🔲 Planned |
| 10 | Maps | 🔲 Planned |
| 11 | Skins | 🔲 Planned |
| 12 | Miscellaneous | 🔲 Planned |
| 13 | Configuration UI | 🔲 Planned |

## Documentation

- **[DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md)** - Quick reference for development
- **[LIBRARIES.md](LIBRARIES.md)** - How to download and install libraries
- **[TESTING.md](TESTING.md)** - Testing procedures and verification

## Commands

```
/totalui help       - Show available commands
/totalui status     - Show addon status
/totalui version    - Show version and compatibility info
/totalui config     - Open configuration (Phase 13)
```

## Contributing

**Note**: This project is currently under a restrictive license. Contributions are welcome, but by submitting a pull request, you agree that your contributions will be licensed under the same terms as the project.

1. Fork the repository
2. Create a feature branch
3. Implement your changes following the architecture
4. Test thoroughly (see TESTING.md)
5. Submit a pull request

**Important**: Always use the compatibility layer (`E.Compat`) for WoW API calls. Never call WoW APIs directly.

## Design Philosophy

1. **Future-Proof**: API compatibility layer shields code from Blizzard changes
2. **Modular**: Features are independent and can be enabled/disabled
3. **Graceful Degradation**: Works without external dependencies
4. **Performance**: Efficient event handling, bucket events, combat-aware updates
5. **Maintainable**: Clear structure, consistent patterns, well-documented

## WoW Version Support

- **Retail (11.0.2+)**: Primary target, full feature support
- **Classic Era/Wrath/Cata**: Compatibility layer handles API differences

The addon automatically detects your WoW version and uses appropriate APIs.

## License

This project is under a **Proprietary Source-Available License**.

**You are free to download and use this addon in World of Warcraft.** However, you may not modify, redistribute, or incorporate it into other projects without explicit written permission.

The source code is available for viewing and educational purposes.

See the [LICENSE](LICENSE) file for full details.

## Acknowledgments

Inspired by ElvUI's comprehensive approach to UI replacement.
