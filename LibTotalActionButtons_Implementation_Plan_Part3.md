# LibTotalActionButtons - Implementation Plan (Part 3)

**Continuation from Part 2**

This document contains the remaining phases (5-10) of the implementation plan.

---

## Phase 5: Interaction Systems

**Duration**: 1-2 weeks
**Priority**: MEDIUM
**Goal**: Implement drag & drop, button locking, and click behavior

**Dependencies**: Phase 1 complete (combat lockdown checks required)

---

### Overview

Add user interaction features: drag & drop abilities, lock/unlock buttons, configure click behavior, and handle cursor states.

### Step 5.1: Implement Secure Drag & Drop (6-8 hours)

**Key Methods**:
- `LAB:EnableDragNDrop(button, enable)`
- Secure PreClick/PostClick handlers
- OnDragStart/OnReceiveDrag handlers
- Combat lockdown handling

**Implementation Notes**:
- Must use secure templates for combat safety
- PickupAction/PlaceAction for action buttons
- PickupSpell/PickupItem for other types
- Register for appropriate drag types per button type

### Step 5.2: Implement Button Locking (3-4 hours)

**Key Methods**:
- `LAB:SetLocked(button, locked)`
- `LAB:GetLocked(button)`
- Toggle drag/drop based on lock state
- Visual lock indicator (optional)

### Step 5.3: Implement Click Behavior Configuration (2-3 hours)

**Key Methods**:
- `LAB:SetClickOnDown(button, clickOnDown)`
- Register for AnyDown vs AnyUp clicks
- Configurable per button or globally

### Step 5.4: Cursor Pickup Handling (2-3 hours)

**Key Methods**:
- `LAB:PickupButton(button)` - Pick up button's action
- `LAB:PlaceOnButton(button)` - Place cursor on button
- Handle all button types appropriately

### Step 5.5: Testing (4 hours)

**Test Cases**:
- Drag ability from bar to bar
- Drag ability from spellbook to button
- Drag item to button
- Lock/unlock buttons
- Click-on-down vs click-on-up
- Combat lockdown prevents changes

### Completion Checklist
- [ ] Drag & drop functional for all button types
- [ ] Locking works
- [ ] Click behavior configurable
- [ ] Cursor handling works
- [ ] Combat lockdown enforced
- [ ] All tests passing

---

## Phase 6: Configuration & Customization

**Duration**: 1-2 weeks
**Priority**: MEDIUM
**Goal**: Comprehensive configuration system with deep merging

**Dependencies**: Phase 2 complete (button types needed)

---

### Overview

Create a flexible configuration system with default values, deep merging, per-element control, and extensive customization options.

### Step 6.1: Create Default Configuration (6-8 hours)

**Default Config Structure**:
```lua
LAB.DefaultConfig = {
    showGrid = false,
    showCooldown = true,
    showCooldownNumbers = true,
    showCount = true,
    showHotkey = true,
    showTooltip = "enabled",  -- "enabled", "disabled", "nocombat"

    hideElements = {
        macro = false,
        hotkey = false,
        equipped = false,
    },

    colors = {
        range = { r = 0.8, g = 0.1, b = 0.1 },
        power = { r = 0.1, g = 0.3, b = 1.0 },
        usable = { r = 1.0, g = 1.0, b = 1.0 },
        unusable = { r = 0.4, g = 0.4, b = 0.4 },
    },

    text = {
        hotkey = {
            font = "Fonts\\FRIZQT__.TTF",
            size = 12,
            flags = "OUTLINE",
            color = { r = 1, g = 1, b = 1, a = 1 },
            position = {
                anchor = "TOPRIGHT",
                relAnchor = "TOPRIGHT",
                offsetX = -2,
                offsetY = -2,
            },
            justifyH = "RIGHT",
        },
        -- count, macro configs...
    },

    outOfRangeColoring = "button",  -- "button" or "hotkey"
    outOfManaColoring = "button",
    desaturateUnusable = false,

    allowDragAndDrop = true,
    locked = false,
    clickOnDown = false,
}
```

### Step 6.2: Implement Deep Config Merging (4-6 hours)

**Key Method**:
- `LAB:UpdateConfig(button, config)`
- Deep merge with defaults
- Apply changes immediately
- Validate config values

### Step 6.3: Add Per-Element Show/Hide Methods (4-6 hours)

**Key Methods**:
- `LAB:SetShowGrid(button, show)`
- `LAB:SetShowCooldown(button, show)`
- `LAB:SetShowCount(button, show)`
- `LAB:SetShowHotkey(button, show)`
- `LAB:SetShowMacroText(button, show)`
- `LAB:SetShowTooltip(button, mode)`

### Step 6.4: Add Range/Mana Coloring Options (3-4 hours)

**Features**:
- Color entire button vs just hotkey text
- Configurable colors
- Desaturation option for unusable

### Step 6.5: Add Text Alignment Options (2-3 hours)

**Features**:
- JustifyH for text elements
- Custom positioning for all text
- Font/size/flags customization

### Step 6.6: Testing (4 hours)

**Test Cases**:
- Default config applies correctly
- Custom config merges properly
- Show/hide methods work
- Color schemes apply
- Text positioning works

### Completion Checklist
- [ ] Default config comprehensive
- [ ] Config merging works
- [ ] Show/hide methods implemented
- [ ] Coloring options work
- [ ] Text customization works
- [ ] All tests passing

---

## Phase 7: Integration & Extensibility

**Duration**: 2-3 weeks
**Priority**: MEDIUM
**Goal**: CallbackHandler, Masque, LibKeyBound integration

**Dependencies**: Phase 2 complete (button types needed)

---

### Overview

Make LibTotalActionButtons extensible and compatible with popular addons.

### Step 7.1: Integrate CallbackHandler-1.0 (6-8 hours)

**Callbacks to Implement**:
- `OnButtonCreated(button)`
- `OnButtonUpdate(button)`
- `OnButtonContentsChanged(button)`
- `OnButtonStateChanged(button, newState)`
- `OnButtonEnter(button)`
- `OnButtonLeave(button)`

**Implementation**:
```lua
local CBH = LibStub("CallbackHandler-1.0")
LAB.callbacks = LAB.callbacks or CBH:New(LAB)

-- Fire callbacks at appropriate times
LAB.callbacks:Fire("OnButtonCreated", button)
```

### Step 7.2: Implement Masque Support (8-10 hours)

**Key Method**:
- `LAB:AddToMasque(button, group)`
- Create button data structure for Masque
- Handle texture updates when skinned
- Test with multiple Masque skins

### Step 7.3: Implement ButtonFacade Support (3-4 hours)

**Legacy Support**:
- Similar to Masque but for older addon
- Backward compatibility layer

### Step 7.4: Implement LibKeyBound Integration (6-8 hours)

**Key Methods**:
- `button:GetBindingAction()`
- `button:GetActionName()`
- `button:GetHotkey()`
- Register buttons with LibKeyBound
- Support in-game keybinding mode

### Step 7.5: Action Button UI Registration (Retail, 2-3 hours)

**Retail Integration**:
- `C_ActionBar.SetActionUIButton(slot, button, cooldown)`
- Register action buttons with Blizzard system

### Step 7.6: Testing (6-8 hours)

**Test Cases**:
- Callbacks fire correctly
- Masque skins apply
- LibKeyBound binds keys
- Other addons can use library

### Completion Checklist
- [ ] CallbackHandler integrated
- [ ] All callbacks firing
- [ ] Masque support working
- [ ] LibKeyBound integration working
- [ ] Action UI registration working (Retail)
- [ ] Other addons can use library
- [ ] All tests passing

---

## Phase 8: Performance Optimization

**Duration**: 1 week
**Priority**: MEDIUM-LOW
**Goal**: Optimize for many buttons and frequent updates

**Dependencies**: Phase 2 complete

---

### Overview

Optimize event handling, update logic, and memory usage for large numbers of buttons.

### Step 8.1: Centralize Event Handling (6-8 hours)

**Optimization**:
- Single event frame for all buttons
- Route events to relevant buttons
- Reduce per-button event overhead

**Before**: Each button registers 15+ events
**After**: One frame registers events, routes to buttons

### Step 8.2: Implement Batch Update Functions (4-6 hours)

**Key Methods**:
- `LAB:ForAllButtons(func, ...)`
- `LAB:ForAllButtonsWithSpell(spellID, func, ...)`
- Update multiple buttons efficiently

### Step 8.3: Add Range Update Throttling (3-4 hours)

**Optimization**:
- Don't update range every frame
- Throttle to ~0.2s intervals
- Use OnUpdate for range checks

### Step 8.4: Implement Active Button Tracking (4-6 hours)

**Optimization**:
- Only update buttons with actions
- Separate active/inactive registries
- Skip updates for empty buttons

### Step 8.5: Add Lazy Initialization (3-4 hours)

**Optimization**:
- Don't create optional elements until needed
- Create overlay frames on demand
- Create charge cooldown frames on demand

### Step 8.6: Profile and Optimize (6-8 hours)

**Profiling**:
- Memory usage with 100+ buttons
- CPU time per update
- Event handling overhead
- Identify bottlenecks

### Completion Checklist
- [ ] Centralized event frame
- [ ] Batch updates working
- [ ] Range throttling implemented
- [ ] Active tracking working
- [ ] Lazy init working
- [ ] Profiling complete
- [ ] Performance targets met

---

## Phase 9: Advanced Features

**Duration**: 2-3 weeks
**Priority**: LOW
**Goal**: Flyouts, global grid, advanced tooltips

**Dependencies**: Phase 3 complete (state system helps with flyouts)

---

### Overview

Implement advanced features that enhance functionality but aren't critical.

### Step 9.1: Implement Flyout System (10-12 hours)

**Features**:
- Detect flyout actions
- Create flyout menu
- Position flyout buttons
- Handle flyout direction (UP/DOWN/LEFT/RIGHT)
- Object pooling for flyout buttons

**Complexity**: HIGH - Requires significant work

### Step 9.2: Implement Global Grid System (4-6 hours)

**Key Methods**:
- `LAB:ShowGrid()`
- `LAB:HideGrid()`
- Grid counter tracking
- Pet grid mode

### Step 9.3: Add Tooltip Enhancements (3-4 hours)

**Features**:
- Combat-aware tooltips
- Custom tooltip callbacks
- Tooltip positioning options

### Step 9.4: Add Spell Highlight Animations (3-4 hours)

**Features**:
- Use SpellHighlightAnim template element
- Animated proc highlights
- Configurable animation

### Step 9.5: Add Spell Cast VFX (3-4 hours)

**Features**:
- Use SpellCastAnimFrame template element
- Show cast animation when casting
- Retail only

### Step 9.6: Testing (6-8 hours)

### Completion Checklist
- [ ] Flyouts working
- [ ] Global grid working
- [ ] Tooltip enhancements working
- [ ] Animations working
- [ ] All tests passing

---

## Phase 10: Testing & Documentation

**Duration**: Ongoing throughout + 2 weeks final
**Priority**: HIGH
**Goal**: Comprehensive testing and complete documentation

**Dependencies**: All phases

---

### Overview

Continuous testing throughout development plus final comprehensive testing and documentation before release.

### Step 10.1: Unit Testing (Ongoing)

**Coverage**:
- Test all public methods
- Test error conditions
- Test edge cases
- Maintain test suite

### Step 10.2: Integration Testing (Ongoing)

**Testing**:
- Test button types together
- Test state switching
- Test visual features together
- Test with TotalUI

### Step 10.3: Version-Specific Testing (1 week)

**Test on All Versions**:
- Retail
- Classic Era
- TBC Classic (if applicable)
- Wrath Classic
- Cataclysm Classic
- Document version-specific issues

### Step 10.4: Load Testing (2-3 days)

**Performance Testing**:
- Create 100+ buttons
- Measure memory usage
- Measure update time
- Test event handling load
- Profile performance

### Step 10.5: API Documentation (3-4 days)

**Create Documentation For**:
- All public methods
- Parameters and return values
- Usage examples
- Configuration options
- Best practices

### Step 10.6: Configuration Guide (2-3 days)

**User Documentation**:
- All config options
- Examples
- Screenshots
- Common configurations

### Step 10.7: Integration Guide (2-3 days)

**Developer Documentation**:
- How to use library in your addon
- Callback examples
- Masque integration
- LibKeyBound usage

### Step 10.8: Migration Guide (1-2 days)

**For Users of LibActionButton-1.0**:
- API differences
- Migration steps
- Breaking changes
- Benefits of switching

### Completion Checklist
- [ ] 100% test coverage of critical paths
- [ ] Tested on all WoW versions
- [ ] Performance benchmarks met
- [ ] API documentation complete
- [ ] User configuration guide complete
- [ ] Developer integration guide complete
- [ ] Migration guide complete
- [ ] Ready for production use

---

## Final Notes

### Total Implementation Time

**Breakdown by Phase**:
1. Phase 0: 2-3 days (Preparation)
2. Phase 1: 1-2 weeks (Critical Foundation)
3. Phase 2: 2-3 weeks (Button Types)
4. Phase 3: 1-2 weeks (State Management)
5. Phase 4: 2-3 weeks (Visual Enhancements)
6. Phase 5: 1-2 weeks (Interaction)
7. Phase 6: 1-2 weeks (Configuration)
8. Phase 7: 2-3 weeks (Integration)
9. Phase 8: 1 week (Performance)
10. Phase 9: 2-3 weeks (Advanced Features)
11. Phase 10: Ongoing + 2 weeks final (Testing/Docs)

**Total**: 16-22 weeks (4-5.5 months)

**Recommended Approach**: Start with Phases 0-4 (8-12 weeks) for MVP, then continue with remaining phases.

### Success Criteria

Before calling LibTotalActionButtons "complete":

✅ **Functionality**:
- All 5 button types working
- State management functional
- All Blizzard visual APIs integrated
- Drag & drop working
- Comprehensive configuration

✅ **Quality**:
- Zero Lua errors on all WoW versions
- Comprehensive error handling
- Good performance (100+ buttons)
- Clean, maintainable code

✅ **Compatibility**:
- Works on Retail and Classic variants
- Integrates with Masque
- Integrates with LibKeyBound
- Other addons can use it

✅ **Documentation**:
- Complete API documentation
- User configuration guide
- Developer integration guide
- Migration guide from LAB-1.0

### Maintenance Plan

After completion:
- Monitor for WoW API changes
- Update for new WoW versions
- Address bug reports
- Consider community feature requests
- Keep documentation current

---

**End of Implementation Plan**

**Total Document Pages**: ~100+ pages across all parts
**Total Phases**: 10
**Total Steps**: 60+
**Total Time Estimate**: 4-5.5 months

All temporary planning documents:
- `LibTotalActionButtons_Implementation_Plan.md` (Part 1)
- `LibTotalActionButtons_Implementation_Plan_Part2.md` (Part 2)
- `LibTotalActionButtons_Implementation_Plan_Part3.md` (Part 3)
- `LibTotalActionButtons_Implementation_Summary.md` (Quick reference)
- `LibTotalActionButtons_FeatureGap.md` (Analysis)

None of these will be committed to git.

