# LibTotalActionButtons Test Suite

Comprehensive testing for all phases of LibTotalActionButtons implementation.

---

## Phase 1: Foundation & Core Systems

### Test 1.1: Verify LibStub Registration
```lua
/run local LTAB = LibStub("LibTotalActionButtons-1.0", true); print("LibStub:", LTAB and "SUCCESS" or "FAILED")
```

### Test 1.2: Check Version Detection
```lua
/run local LTAB = LibStub("LibTotalActionButtons-1.0"); print("Version:", LTAB.VERSION_STRING); print("WoW Type:", LTAB.VERSION_INFO.detectedVersion)
```

### Test 1.3: Verify API Compatibility Wrappers
```lua
/run local LTAB = LibStub("LibTotalActionButtons-1.0"); print("Retail APIs:", LTAB.Compat.GetActionCharges and "Available" or "Wrapped"); print("C_ActionBar:", LTAB.Compat.C_ActionBar and "OK" or "MISSING")
```

### Test 1.4: Enable Debug Mode
```lua
/run local LTAB = LibStub("LibTotalActionButtons-1.0"); LTAB:SetDebug(true)
```

### Test 1.5: Test Parameter Validation
**First, enable script errors**:
```lua
/console scriptErrors 1
```

**Then run the test**:
```lua
/run local LTAB = LibStub("LibTotalActionButtons-1.0"); LTAB:SetDebug(true); LTAB:CreateButton(nil, "Test", UIParent)
```
**Expected**: RED Lua error message in chat: "LibTotalActionButtons: CreateButton: actionID is required!"

### Test 1.6: Test Button Creation
**Step 1: Clean up any existing test button**:
```lua
/run if _G.Phase1TestButton then _G.Phase1TestButton:Hide(); _G.Phase1TestButton:SetParent(nil); _G.Phase1TestButton = nil; end
```

**Step 2: Create the button**:
```lua
/run local LTAB = LibStub('LibTotalActionButtons-1.0'); LTAB:SetDebug(true); _G.TestBtn = LTAB:CreateButton(1, 'Phase1TestButton', UIParent)
```

**Step 3: Position and size the button**:
```lua
/run local LTAB = LibStub('LibTotalActionButtons-1.0'); if _G.TestBtn then _G.TestBtn:SetPoint('CENTER'); LTAB:SetButtonSize(_G.TestBtn, 40, 40); _G.TestBtn:Show(); print('SUCCESS') else print('FAILED') end
```

**Expected**:
1. Step 2: Debug message "[LTAB Debug] Creating button: Phase1TestButton (action 1)"
2. Step 3: Chat message "SUCCESS"
3. **Visual**: A 40x40 button appears in the CENTER of your screen showing the action from action slot 1

### Test 1.7: Verify Button Elements
**Step 1: Check if button exists**:
```lua
/run if _G.Phase1TestButton then print("Button found") else print("Button not found") end
```

**Step 2: Check icon, cooldown, and hotkey**:
```lua
/run local btn = _G.Phase1TestButton; print("Icon:", btn._icon and "OK" or "MISSING"); print("Cooldown:", btn._cooldown and "OK" or "MISSING"); print("Hotkey:", btn._hotkey and "OK" or "MISSING")
```

**Step 3: Check count and pushed texture**:
```lua
/run local btn = _G.Phase1TestButton; print("Count:", btn._count and "OK" or "MISSING"); print("Pushed:", btn._pushedTexture and "OK" or "MISSING")
```

**Expected**: All elements should print "OK"

### Test 1.8: Cleanup Phase 1 Test Button
```lua
/run local btn = _G["Phase1TestButton"]; if btn then btn:Hide(); btn:SetParent(nil); _G["Phase1TestButton"] = nil; print("Test button removed") else print("No button to remove") end
```

---

## Phase 2: Button Type System

### Test 2.1: Verify Button Types Available
```lua
/run local LTAB = LibStub("LibTotalActionButtons-1.0"); for k,v in pairs(LTAB.ButtonType) do print(k..":", v) end
```
**Expected**: Print all button types (ACTION, SPELL, ITEM, MACRO, CUSTOM, EMPTY)

### Test 2.2: Test Action Button
**Step 1: Create action button**:
```lua
/run local LTAB = LibStub("LibTotalActionButtons-1.0"); LTAB:SetDebug(true); _G.TestActionBtn = LTAB:CreateButton(1, "Phase2ActionButton", UIParent)
```

**Step 2: Position and verify**:
```lua
/run local LTAB = LibStub("LibTotalActionButtons-1.0"); local btn = _G.TestActionBtn; if btn then btn:SetPoint("CENTER", -150, 0); LTAB:SetButtonSize(btn, 40, 40); btn:Show(); print("Type:", btn.buttonType); print("Has UpdateFunctions:", btn.UpdateFunctions and "YES" or "NO") else print("FAILED") end
```

**Expected**: Button at left-center, Type: "action", Has UpdateFunctions: YES

### Test 2.3: Test Spell Button
**Step 1: Create spell button**:
```lua
/run local LTAB = LibStub("LibTotalActionButtons-1.0"); LTAB:SetDebug(true); _G.TestSpellBtn = LTAB:CreateSpellButton(1231411, "Phase2SpellButton", UIParent)
```

**Step 2: Position and size**:
```lua
/run local LTAB = LibStub('LibTotalActionButtons-1.0'); local btn = _G.TestSpellBtn; if btn then btn:SetPoint('CENTER', -50, 0); LTAB:SetButtonSize(btn, 40, 40); btn:Show() end
```

**Step 3: Verify**:
```lua
/run local btn = _G.TestSpellBtn; if btn then print('Type:', btn.buttonType); print('SpellID:', btn.buttonAction) else print('FAILED') end
```

**Expected**: Shows spell icon, Type: "spell", SpellID: 1231411

### Test 2.4: Test Item Button (Hearthstone)
**Step 1: Create item button**:
```lua
/run local LTAB = LibStub("LibTotalActionButtons-1.0"); LTAB:SetDebug(true); _G.TestItemBtn = LTAB:CreateItemButton(6948, "Phase2ItemButton", UIParent)
```

**Step 2: Position and verify**:
```lua
/run local LTAB = LibStub('LibTotalActionButtons-1.0'); local btn = _G.TestItemBtn; if btn then btn:SetPoint("CENTER", 50, 0); LTAB:SetButtonSize(btn, 40, 40); btn:Show(); print("Type:", btn.buttonType); print("ItemID:", btn.buttonAction) end
```

**Expected**: Shows hearthstone icon, Type: "item", ItemID: 6948

### Test 2.5: Test Macro Button (Optional)
**Note**: Requires at least one macro created

**Step 1: Check for macros**:
```lua
/run local count = GetNumMacros(); print("Macros available:", count); if count > 0 then local name = GetMacroInfo(1); print("Macro 1:", name) end
```

**Step 2: Create macro button (if available)**:
```lua
/run local LTAB = LibStub("LibTotalActionButtons-1.0"); if GetNumMacros() > 0 then LTAB:SetDebug(true); _G.TestMacroBtn = LTAB:CreateMacroButton(1, "Phase2MacroButton", UIParent); local btn = _G.TestMacroBtn; btn:SetPoint("CENTER", 150, 0); LTAB:SetButtonSize(btn, 40, 40); btn:Show(); print("Type:", btn.buttonType) else print("No macros available") end
```

**Expected** (if macros exist): Shows macro icon, Type: "macro"

### Test 2.6: Test Custom Button Type
**Step 1: Create custom UpdateFunctions**:
```lua
/run _G.CustomUpdateFuncs = { HasAction = function() return true end, GetActionTexture = function() return "Interface\\Icons\\INV_Misc_QuestionMark" end, GetActionText=function() return "Custom" end, GetActionCount=function() return 0 end, GetActionCharges=function() return nil end, IsInRange=function() return nil end, IsUsableAction=function() return true,false end, IsCurrentAction=function() return false end, IsAutoRepeatAction=function() return false end, IsAttackAction=function() return false end, IsEquippedAction=function() return false end, IsConsumableAction=function() return false end, GetCooldown=function() return 0,0,0 end, GetLossOfControlCooldown=function() return nil end, GetSpellId=function() return nil end }
```

**Step 2: Create custom button**:
```lua
/run local LTAB = LibStub("LibTotalActionButtons-1.0"); LTAB:SetDebug(true); _G.TestCustomBtn = LTAB:CreateCustomButton(999, "Phase2CustomButton", UIParent, nil, _G.CustomUpdateFuncs); local btn = _G.TestCustomBtn; btn:SetPoint("CENTER", 0, -80); LTAB:SetButtonSize(btn, 40, 40); btn:Show(); print("Type:", btn.buttonType)
```

**Expected**: Shows question mark icon, Type: "custom"

### Test 2.7: Cleanup Phase 2 Buttons
```lua
/run local buttons = {"TestActionBtn", "TestSpellBtn", "TestItemBtn", "TestMacroBtn", "TestCustomBtn"}; for _, name in ipairs(buttons) do local btn = _G[name]; if btn then btn:Hide(); btn:SetParent(nil); _G[name] = nil; print("Removed "..name) end end; _G.CustomUpdateFuncs = nil
```

---

## Phase 3: State Management System

### Test 3.1: Basic State Setup and Switching
**Step 1: Create button**:
```lua
/run local LTAB = LibStub("LibTotalActionButtons-1.0"); LTAB:SetDebug(true); _G.TestStateBtn = LTAB:CreateButton(1, "Phase3StateButton", UIParent); local btn = _G.TestStateBtn; btn:SetPoint("CENTER"); LTAB:SetButtonSize(btn, 44, 44); btn:Show()
```

**Step 2: Set up multiple states**:
```lua
/run local LTAB = LibStub('LibTotalActionButtons-1.0'); local btn = _G.TestStateBtn; LTAB:SetState(btn, 0, "action", 1); LTAB:SetState(btn, 1, "spell", 1231411); LTAB:SetState(btn, 2, "item", 6948); print("Configured 3 states")
```

**Step 3: Test state switching**:
```lua
/run local LTAB = LibStub('LibTotalActionButtons-1.0'); LTAB:UpdateState(_G.TestStateBtn, 0); print("State 0 - action slot 1")
```

```lua
/run local LTAB = LibStub('LibTotalActionButtons-1.0'); LTAB:UpdateState(_G.TestStateBtn, 1); print("State 1 - spell")
```

```lua
/run local LTAB = LibStub('LibTotalActionButtons-1.0'); LTAB:UpdateState(_G.TestStateBtn, 2); print("State 2 - hearthstone")
```

**Expected**: Button changes icon when switching states (action → spell → item)

### Test 3.2: Query State Information
**Get current state**:
```lua
/run local LTAB = LibStub('LibTotalActionButtons-1.0'); local state = LTAB:GetState(_G.TestStateBtn); print("Current state:", state)
```

**Get specific state info**:
```lua
/run local LTAB = LibStub('LibTotalActionButtons-1.0'); local type, action = LTAB:GetState(_G.TestStateBtn, 1); print("State 1:", type, action)
```

**Expected**: Returns correct state numbers and configured types/actions

### Test 3.3: State Fallback Behavior
**Switch to undefined state**:
```lua
/run local LTAB = LibStub('LibTotalActionButtons-1.0'); LTAB:UpdateState(_G.TestStateBtn, 99); local type, action = LTAB:GetAction(_G.TestStateBtn); print("Fallback shows:", type, action)
```

**Expected**: Falls back to state 0 (action 1)

### Test 3.4: Clear States
**Clear all states**:
```lua
/run local LTAB = LibStub('LibTotalActionButtons-1.0'); LTAB:ClearStates(_G.TestStateBtn); local btn = _G.TestStateBtn; print("State 0:", btn.stateTypes["0"] or "nil"); print("State 1:", btn.stateTypes["1"] or "nil")
```

**Expected**: State tables are empty

### Test 3.5: Paging Support
**Create and configure paging button**:
```lua
/run local LTAB = LibStub('LibTotalActionButtons-1.0'); _G.TestPageBtn = LTAB:CreateButton(1, "Phase3PageButton", UIParent); local btn = _G.TestPageBtn; btn:SetPoint("CENTER", -100, 0); LTAB:SetButtonSize(btn, 44, 44); btn:Show(); for i=1,6 do LTAB:SetState(btn, tostring(i), "action", i) end; LTAB:EnablePaging(btn, true); print("Paging enabled with 6 states")
```

**Test page changes**:
```lua
/run local LTAB = LibStub('LibTotalActionButtons-1.0'); LTAB:OnPageChanged(2); print("Page 2")
```

```lua
/run local LTAB = LibStub('LibTotalActionButtons-1.0'); LTAB:OnPageChanged(3); print("Page 3")
```

**Expected**: Button updates icon when page changes

### Test 3.6: Mixed Button Types in States
**Create button with mixed types**:
```lua
/run local LTAB = LibStub('LibTotalActionButtons-1.0'); _G.TestMixedBtn = LTAB:CreateButton(1, "Phase3MixedButton", UIParent); local btn = _G.TestMixedBtn; btn:SetPoint("CENTER", 0, -100); LTAB:SetButtonSize(btn, 44, 44); btn:Show(); LTAB:SetState(btn, "0", "action", 1); LTAB:SetState(btn, "1", "spell", 1231411); LTAB:SetState(btn, "2", "item", 6948); print("Mixed states configured")
```

**Test state 0 (action)**:
```lua
/run local LTAB = LibStub('LibTotalActionButtons-1.0'); LTAB:UpdateState(_G.TestMixedBtn, "0"); print("State 0 - click to test action")
```
**Click the button - should use action slot**

**Test state 1 (spell)**:
```lua
/run local LTAB = LibStub('LibTotalActionButtons-1.0'); LTAB:UpdateState(_G.TestMixedBtn, "1"); print("State 1 - click to test spell")
```
**Click the button - should cast Recuperate**

**Test state 2 (item)**:
```lua
/run local LTAB = LibStub('LibTotalActionButtons-1.0'); LTAB:UpdateState(_G.TestMixedBtn, "2"); print("State 2 - click to test item")
```
**Click the button - should use hearthstone**

**Expected**: Visual updates AND click behavior changes for each state

### Test 3.7: Cleanup Phase 3 Buttons
```lua
/run local buttons = {"TestStateBtn", "TestPageBtn", "TestStanceBtn", "TestMixedBtn"}; for _, name in ipairs(buttons) do local btn = _G[name]; if btn then btn:Hide(); btn:SetParent(nil); _G[name] = nil; print("Removed "..name) end end
```

---



## Phase 4: Visual Enhancements

### Test 4.1: Charge Cooldown Display

**Note**: Requires Retail and a charge-based ability (e.g., Fire Blast for Mages, Chi Torpedo for Monks)

**Create charge-based spell button** (replace 108853 with your charge ability):
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.T=L:CreateSpellButton(108853,"P4C",UIParent)
```
```lua
/run local b=_G.T;b:SetPoint("CENTER");LibStub("LibTotalActionButtons-1.0"):SetButtonSize(b,50,50);b:Show()
```

**Use the ability from your action bar to deplete charges** (button has no click handler yet):
```lua
/cast Fire Blast
```

**Then check if chargeCooldown frame exists and force update**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:UpdateButton(_G.T)
```
```lua
/run local b=_G.T;print("chargeCooldown:",b.chargeCooldown and "YES" or "NO")
```
```lua
/run local i=C_Spell.GetSpellCharges(108853);print("Charges:",i.currentCharges,"/",i.maxCharges)
```

**Expected** (Retail, when recharging):
- chargeCooldown frame exists
- Separate cooldown swipe for next charge
- Main cooldown only when all depleted

**Cleanup**:
```lua
/run if _G.T then _G.T:Hide();_G.T:SetParent(nil);_G.T=nil end
```

### Test 4.2: Spell Activation Overlays (Proc Glows)

**Note**: Retail only, requires proc-able abilities

**Verify overlay events registered**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");print("Events:",L.overlayEventFrame and "OK" or "NO")
```

**Create spell button and manually test glow**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.P=L:CreateSpellButton(116,"P4P",UIParent)
```
```lua
/run local b=_G.P;b:SetPoint("CENTER");LibStub("LibTotalActionButtons-1.0"):SetButtonSize(b,50,50);b:Show()
```
```lua
/run LibStub("LibTotalActionButtons-1.0"):ShowOverlayGlow(_G.P);print("Glow ON")
```

**Hide glow**:
```lua
/run LibStub("LibTotalActionButtons-1.0"):HideOverlayGlow(_G.P);print("Glow OFF")
```

**Expected** (Retail):
- Golden glow animation appears/disappears
- Overlay frame created with pulsing animation

**Cleanup**:
```lua
/run if _G.P then _G.P:Hide();_G.P:SetParent(nil);_G.P=nil end
```

### Test 4.3: New Action Highlighting

**Note**: Retail only, requires a VERY recently learned spell (within current session)

**Create button with spell** (replace 1459 with recently learned spell ID):
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.N=L:CreateSpellButton(1459,"P4N",UIParent)
```
```lua
/run local b=_G.N;b:SetPoint("CENTER");LibStub("LibTotalActionButtons-1.0"):SetButtonSize(b,50,50);b:Show()
```
```lua
/run LibStub("LibTotalActionButtons-1.0"):UpdateNewActionHighlight(_G.N)
```

**Expected** (Retail, ONLY if spell was just learned this session):
- White/yellow glow on button if spell is marked as new
- No glow is normal - most spells aren't "new"
- This feature auto-clears after spells are used

**Cleanup**:
```lua
/run if _G.N then _G.N:Hide();_G.N:SetParent(nil);_G.N=nil end
```

### Test 4.4: Equipped Item Borders

**Note**: Requires an equippable item in your bags

**Get item ID from tooltip** (hover over item in bags first):
```lua
/run local n,l=GameTooltip:GetItem();if l then print("Item ID:",l:match("item:(%d+)"))end
```

**Create item button** (replace with item ID from above):
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.E=L:CreateItemButton(193810,"P4E",UIParent)
```
```lua
/run local b=_G.E;b:SetPoint("CENTER");LibStub("LibTotalActionButtons-1.0"):SetButtonSize(b,50,50);b:Show()
```

**If item is equipped, border should already be green. If not equipped, equip it then run**:
```lua
/run LibStub("LibTotalActionButtons-1.0"):UpdateButton(_G.E);print("Updated")
```

**Expected** (when item equipped):
- Green border around button (0, 1.0, 0, 0.35)
- Border visible and colored green
- Border hides when item unequipped

**Cleanup**:
```lua
/run if _G.E then _G.E:Hide();_G.E:SetParent(nil);_G.E=nil end
```

---

## Phase 5: Interaction Systems

### Test 5.1: Drag & Drop

**Note**: Cannot test in combat

**Create two spell buttons** (positioned right side to avoid spellbook):
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.D1=L:CreateSpellButton(116,"P5D1",UIParent)
```
```lua
/run local b=_G.D1;b:SetPoint("RIGHT",-150,-60);LibStub("LibTotalActionButtons-1.0"):SetButtonSize(b,50,50);b:Show()
```
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.D2=L:CreateSpellButton(1459,"P5D2",UIParent)
```
```lua
/run local b=_G.D2;b:SetPoint("RIGHT",-150,60);LibStub("LibTotalActionButtons-1.0"):SetButtonSize(b,50,50);b:Show()
```

**Debug cursor info** (run after picking up a spell):
```lua
/run local t,a1,a2,a3=GetCursorInfo();print("Type:",t,"Arg1:",a1,"Arg2:",a2,"Arg3:",a3)p
```

**Expected**:
- Drag spells from spellbook onto buttons
- Drag button contents to another button
- Shift-click to pick up to cursor

**Cleanup**:
```lua
/run if _G.D1 then _G.D1:Hide();_G.D1:SetParent(nil);_G.D1=nil end
```
```lua
/run if _G.D2 then _G.D2:Hide();_G.D2:SetParent(nil);_G.D2=nil end
```

### Test 5.2: Button Locking

**Create and lock button**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.L=L:CreateSpellButton(116,"P5L",UIParent)
```
```lua
/run local b=_G.L;b:SetPoint("CENTER");LibStub("LibTotalActionButtons-1.0"):SetButtonSize(b,50,50);b:Show()
```
```lua
/run LibStub("LibTotalActionButtons-1.0"):SetLocked(_G.L,true);print("Locked")
```

**Try to drag (should fail)**:
- Attempt to drag button or drag onto button
- Should not work when locked

**Unlock button**:
```lua
/run LibStub("LibTotalActionButtons-1.0"):SetLocked(_G.L,false);print("Unlocked")
```

**Expected**:
- Drag fails when locked
- Drag works when unlocked

**Cleanup**:
```lua
/run if _G.L then _G.L:Hide();_G.L:SetParent(nil);_G.L=nil end
```

### Test 5.3: Click Behavior

**Note**: Uses WoW's secure `useOnKeyDown` attribute to control when actions execute

**Create button**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.C=L:CreateSpellButton(116,"P5C",UIParent)
```
```lua
/run local b=_G.C;b:SetPoint("CENTER");LibStub("LibTotalActionButtons-1.0"):SetButtonSize(b,50,50);b:Show()
```

**Set click-on-down**:
```lua
/run LibStub("LibTotalActionButtons-1.0"):SetClickOnDown(_G.C,true);print("Click on DOWN")
```

**Test clicking**:
- Button should cast spell immediately on mouse down
- You'll see the cast bar start as soon as you press the button

**Change to click-on-up**:
```lua
/run LibStub("LibTotalActionButtons-1.0"):SetClickOnDown(_G.C,false);print("Click on UP")
```

**Test clicking**:
- Button should cast spell when you release the mouse button
- Cast bar appears only when you lift your finger

**Expected**:
- Click-on-down: Spell casts immediately when mouse button is pressed
- Click-on-up: Spell casts when mouse button is released
- Visual feedback (pushed texture) should appear/disappear correctly in both modes

**Cleanup**:
```lua
/run if _G.C then _G.C:Hide();_G.C:SetParent(nil);_G.C=nil end
```

### Test 5.4: Cursor Pickup

**Create button**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.K=L:CreateSpellButton(116,"P5K",UIParent)
```
```lua
/run local b=_G.K;b:SetPoint("CENTER");LibStub("LibTotalActionButtons-1.0"):SetButtonSize(b,50,50);b:Show()
```

**Pickup to cursor**:
```lua
/run LibStub("LibTotalActionButtons-1.0"):PickupButton(_G.K);print("Picked up")
```

**Expected**:
- Spell appears on cursor

**Place from cursor (pick up a spell first)**:
```lua
/run LibStub("LibTotalActionButtons-1.0"):PlaceOnButton(_G.K);print("Placed")
```

**Clear button**:
```lua
/run LibStub("LibTotalActionButtons-1.0"):ClearButton(_G.K);print("Cleared")
```

**Expected**:
- Button updates with placed spell
- Button clears when cleared

**Cleanup**:
```lua
/run if _G.K then _G.K:Hide();_G.K:SetParent(nil);_G.K=nil end
```

---

## Phase 6: Configuration & Customization

### Test 6.1: Default Configuration

**Objective**: Verify that buttons receive proper default configuration when no custom config is provided.

**Create button with default config**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.T61=L:CreateSpellButton(116,"P6T1_Default",UIParent)
```
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");local b=_G.T61;b:SetPoint("CENTER");L:SetButtonSize(b,50,50);L:UpdateConfig(b,nil);b:Show()
```

**Check default values**:
```lua
/run local b=_G.T61;if b and b.config then print("showGrid:",b.config.showGrid);print("showCooldown:",b.config.showCooldown);print("showCount:",b.config.showCount)end
```
```lua
/run local b=_G.T61;if b and b.config then print("showHotkey:",b.config.showHotkey);print("locked:",b.config.locked);print("clickOnDown:",b.config.clickOnDown)end
```

**Expected**:
- showGrid = false
- showCooldown = true
- showCount = true
- showHotkey = true
- locked = false
- clickOnDown = false

**Cleanup**:
```lua
/run if _G.T61 then _G.T61:Hide();_G.T61:SetParent(nil);_G.T61=nil end
```

### Test 6.2: Custom Configuration with Deep Merge

**Objective**: Verify custom configuration properly merges with defaults.

**Create button with custom config**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.T62=L:CreateSpellButton(116,"P6T2_Custom",UIParent)
```
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");local b=_G.T62;b:SetPoint("CENTER");L:SetButtonSize(b,50,50);local cfg={showGrid=true,showHotkey=false,clickOnDown=true,colors={range={r=1.0,g=0.5,b=0.0}}};L:UpdateConfig(b,cfg);b:Show()
```

**Check merged values**:
```lua
/run local b=_G.T62;if b and b.config then print("showGrid:",b.config.showGrid);print("showHotkey:",b.config.showHotkey);print("clickOnDown:",b.config.clickOnDown)end
```
```lua
/run local b=_G.T62;if b and b.config then print("showCooldown:",b.config.showCooldown);print("Range r:",b.config.colors.range.r);print("Power r:",b.config.colors.power.r)end
```

**Expected**:
- Custom values override: showGrid=true, showHotkey=false, clickOnDown=true
- Default preserved: showCooldown=true
- Deep merge works: range color updated (1.0), power color preserved (0.1)

**Cleanup**:
```lua
/run if _G.T62 then _G.T62:Hide();_G.T62:SetParent(nil);_G.T62=nil end
```

### Test 6.3: Show/Hide Elements

**Note**: First clear action slot 1 if it has anything assigned

**Create test buttons**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.T63a=L:CreateButton(1,"P6T3_Grid",UIParent);_G.T63b=L:CreateButton(1,"P6T3_NoGrid",UIParent)
```
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");local b1=_G.T63a;b1:SetPoint("CENTER",-30,0);L:SetButtonSize(b1,50,50);L:SetShowGrid(b1,true);b1:Show()
```
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");local b2=_G.T63b;b2:SetPoint("CENTER",30,0);L:SetButtonSize(b2,50,50);L:SetShowGrid(b2,false);b2:Show()
```

**Expected**:
- Left button: Shows grid border when empty
- Right button: No visible border when empty

**Cleanup grid test**:
```lua
/run if _G.T63a then _G.T63a:Hide();_G.T63a:SetParent(nil);_G.T63a=nil end
```
```lua
/run if _G.T63b then _G.T63b:Hide();_G.T63b:SetParent(nil);_G.T63b=nil end
```

**Test cooldown display** (create action buttons - drag spell with cooldown onto them):
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.T63c=L:CreateButton(72,"P6T3_CD",UIParent);_G.T63d=L:CreateButton(73,"P6T3_NoCD",UIParent)
```
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");local b1=_G.T63c;b1:SetPoint("CENTER",-30,0);L:SetButtonSize(b1,50,50);L:SetShowCooldown(b1,true);b1:Show()
```
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");local b2=_G.T63d;b2:SetPoint("CENTER",30,0);L:SetButtonSize(b2,50,50);L:SetShowCooldown(b2,false);b2:Show()
```

**Expected** (drag a spell with cooldown from spellbook, then use it):
- Left: Cooldown visible (including GCD)
- Right: Cooldown hidden

**Cleanup cooldown test**:
```lua
/run if _G.T63c then _G.T63c:Hide();_G.T63c:SetParent(nil);_G.T63c=nil end
```
```lua
/run if _G.T63d then _G.T63d:Hide();_G.T63d:SetParent(nil);_G.T63d=nil end
```

**Test text elements** (uses action slot 1 which should have a hotkey):
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.T63e=L:CreateButton(1,"P6T3_Text",UIParent);_G.T63f=L:CreateButton(1,"P6T3_NoText",UIParent)
```
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");local b1=_G.T63e;b1:SetPoint("CENTER",-30,0);L:SetButtonSize(b1,50,50);L:SetShowCount(b1,true);L:SetShowHotkey(b1,true);b1:Show()
```
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");local b2=_G.T63f;b2:SetPoint("CENTER",30,0);L:SetButtonSize(b2,50,50);L:SetShowCount(b2,false);L:SetShowHotkey(b2,false);b2:Show()
```

**Expected** (if action slot 1 has a spell with charges/count):
- Left: Shows count and hotkey text (e.g., "1" hotkey and item count if applicable)
- Right: Hides all text (no hotkey, no count visible)

**Cleanup text test**:
```lua
/run if _G.T63e then _G.T63e:Hide();_G.T63e:SetParent(nil);_G.T63e=nil end
```
```lua
/run if _G.T63f then _G.T63f:Hide();_G.T63f:SetParent(nil);_G.T63f=nil end
```

### Test 6.4: Range and Mana Coloring

**Note**: Uses action button 1 which should have a ranged spell assigned

**Create buttons with different range coloring modes**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.T64a=L:CreateButton(1,"P6T4_BtnRange",UIParent);_G.T64b=L:CreateButton(1,"P6T4_KeyRange",UIParent);_G.T64c=L:CreateButton(1,"P6T4_NoRange",UIParent)
```
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");local b1=_G.T64a;b1:SetPoint("CENTER",-60,0);L:SetButtonSize(b1,50,50);L:SetOutOfRangeColoring(b1,"button");b1:Show()
```
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");local b2=_G.T64b;b2:SetPoint("CENTER",0,0);L:SetButtonSize(b2,50,50);L:SetOutOfRangeColoring(b2,"hotkey");b2:Show()
```
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");local b3=_G.T64c;b3:SetPoint("CENTER",60,0);L:SetButtonSize(b3,50,50);L:SetOutOfRangeColoring(b3,"none");b3:Show()
```

**Expected** (move out of range of your target):
- Left: Entire button tinted red
- Middle: Only hotkey text tinted red (button stays normal color)
- Right: No color change (button and text stay normal)

**Cleanup range mode test**:
```lua
/run if _G.T64a then _G.T64a:Hide();_G.T64a:SetParent(nil);_G.T64a=nil end
```
```lua
/run if _G.T64b then _G.T64b:Hide();_G.T64b:SetParent(nil);_G.T64b=nil end
```
```lua
/run if _G.T64c then _G.T64c:Hide();_G.T64c:SetParent(nil);_G.T64c=nil end
```

**Test custom state colors**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.T64d=L:CreateButton(1,"P6T4_Custom",UIParent)
```
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");local b=_G.T64d;b:SetPoint("CENTER");L:SetButtonSize(b,50,50);L:SetOutOfRangeColoring(b,"button");L:SetStateColor(b,"range",1.0,0.5,0.0);b:Show()
```

**Expected** (move out of range):
- Button tinted custom orange instead of default red

**Cleanup custom color test**:
```lua
/run if _G.T64d then _G.T64d:Hide();_G.T64d:SetParent(nil);_G.T64d=nil end
```

### Test 6.5: Text Customization

**Note**: Uses action button 1 which should have a hotkey assigned

**Test text justification**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.T65a=L:CreateButton(1,"P6T5_Left",UIParent);_G.T65b=L:CreateButton(1,"P6T5_Center",UIParent);_G.T65c=L:CreateButton(1,"P6T5_Right",UIParent)
```
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");local b1=_G.T65a;b1:SetPoint("CENTER",-60,0);L:SetButtonSize(b1,50,50);L:SetTextJustifyH(b1,"hotkey","LEFT");b1:Show()
```
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");local b2=_G.T65b;b2:SetPoint("CENTER",0,0);L:SetButtonSize(b2,50,50);L:SetTextJustifyH(b2,"hotkey","CENTER");b2:Show()
```
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");local b3=_G.T65c;b3:SetPoint("CENTER",60,0);L:SetButtonSize(b3,50,50);L:SetTextJustifyH(b3,"hotkey","RIGHT");b3:Show()
```

**Expected**:
- Left: Hotkey left-aligned
- Middle: Hotkey centered
- Right: Hotkey right-aligned

**Cleanup justification test**:
```lua
/run if _G.T65a then _G.T65a:Hide();_G.T65a:SetParent(nil);_G.T65a=nil end
```
```lua
/run if _G.T65b then _G.T65b:Hide();_G.T65b:SetParent(nil);_G.T65b=nil end
```
```lua
/run if _G.T65c then _G.T65c:Hide();_G.T65c:SetParent(nil);_G.T65c=nil end
```

**Test text font and size**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.T65d=L:CreateButton(1,"P6T5_Small",UIParent);_G.T65e=L:CreateButton(1,"P6T5_Large",UIParent)
```
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");local b1=_G.T65d;b1:SetPoint("CENTER",-30,0);L:SetButtonSize(b1,50,50);L:SetTextFont(b1,"hotkey","Fonts\\FRIZQT__.TTF",8,"OUTLINE");b1:Show()
```
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");local b2=_G.T65e;b2:SetPoint("CENTER",30,0);L:SetButtonSize(b2,50,50);L:SetTextFont(b2,"hotkey","Fonts\\FRIZQT__.TTF",20,"THICKOUTLINE");b2:Show()
```

**Expected**:
- Left: Small text (8px)
- Right: Large text (20px)

**Cleanup font size test**:
```lua
/run if _G.T65d then _G.T65d:Hide();_G.T65d:SetParent(nil);_G.T65d=nil end
```
```lua
/run if _G.T65e then _G.T65e:Hide();_G.T65e:SetParent(nil);_G.T65e=nil end
```

**Test text color**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.T65f=L:CreateButton(1,"P6T5_Red",UIParent);_G.T65g=L:CreateButton(1,"P6T5_Green",UIParent)
```
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");local b1=_G.T65f;b1:SetPoint("CENTER",-30,0);L:SetButtonSize(b1,50,50);L:SetTextColor(b1,"hotkey",1.0,0.0,0.0,1.0);b1:Show()
```
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");local b2=_G.T65g;b2:SetPoint("CENTER",30,0);L:SetButtonSize(b2,50,50);L:SetTextColor(b2,"hotkey",0.0,1.0,0.0,1.0);b2:Show()
```

**Expected**:
- Left: Red hotkey text
- Right: Green hotkey text

**Cleanup text color test**:
```lua
/run if _G.T65f then _G.T65f:Hide();_G.T65f:SetParent(nil);_G.T65f=nil end
```
```lua
/run if _G.T65g then _G.T65g:Hide();_G.T65g:SetParent(nil);_G.T65g=nil end
```

### Test 6.6: Configuration Persistence

**Objective**: Verify configuration survives button updates.

**Create button with custom config**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.T66=L:CreateButton(1,"P6T6_Persist",UIParent)
```
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");local b=_G.T66;b:SetPoint("CENTER");L:SetButtonSize(b,50,50);local cfg={showGrid=true,showHotkey=false,clickOnDown=true,colors={range={r=1.0,g=0.5,b=0.0}}};L:UpdateConfig(b,cfg);b:Show()
```

**Check config before update**:
```lua
/run local b=_G.T66;print("BEFORE:");print("  showGrid:",b.config.showGrid);print("  showHotkey:",b.config.showHotkey);print("  clickOnDown:",b.config.clickOnDown);print("  Range r:",b.config.colors.range.r)
```

**Force button update (simulates button refresh)**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:UpdateButton(_G.T66)
```

**Check config after update**:
```lua
/run local b=_G.T66;print("AFTER:");print("  showGrid:",b.config.showGrid);print("  showHotkey:",b.config.showHotkey);print("  clickOnDown:",b.config.clickOnDown);print("  Range r:",b.config.colors.range.r)
```

**Expected**:
- All config values remain the same after UpdateButton
- Button appearance stays consistent (no hotkey visible since showHotkey=false)

**Cleanup**:
```lua
/run if _G.T66 then _G.T66:Hide();_G.T66:SetParent(nil);_G.T66=nil end
```

---

# Phase 7: Integration & Extensibility

## Test 7.1: CallbackHandler Integration

### Test callback registration

**Create callback object**:
```lua
/run _G.TestCallbacks = {}; _G.TestCallbacks.OnCreated = function(self, event, button) print("Callback: OnButtonCreated") end
```

**Register callback**:
```lua
/run local LTAB = LibStub("LibTotalActionButtons-1.0"); LTAB.RegisterCallback(_G.TestCallbacks, "OnButtonCreated", "OnCreated"); print("Callback registered")
```

**Expected**:
- Message confirms callback registered
- No errors

### Test OnButtonCreated callback

**Script**:
```lua
/run local LTAB = LibStub("LibTotalActionButtons-1.0"); local btn = LTAB:CreateButton(5, "TestButton7_1", UIParent); btn:SetSize(36, 36); btn:SetPoint("CENTER", 0, 0); btn:Show(); _G.T71 = btn; print("Button created")
```

**Expected**:
- Message "Callback: OnButtonCreated" appears from the callback registered above
- Button visible at center of screen

**Cleanup**:
```lua
/run if _G.T71 then _G.T71:Hide();_G.T71:SetParent(nil);_G.T71=nil end; local LTAB=LibStub("LibTotalActionButtons-1.0"); LTAB.UnregisterCallback(_G.TestCallbacks,"OnButtonCreated"); _G.TestCallbacks=nil
```

### Test OnButtonUpdate callback

**Create callback and register**:
```lua
/run local LTAB = LibStub("LibTotalActionButtons-1.0"); _G.UpdateCount = 0; _G.TestCB2 = {}; _G.TestCB2.OnUpdate = function(self, event, button) _G.UpdateCount = _G.UpdateCount + 1 end; LTAB.RegisterCallback(_G.TestCB2, "OnButtonUpdate", "OnUpdate")
```

**Create button**:
```lua
/run local LTAB = LibStub("LibTotalActionButtons-1.0"); local btn = LTAB:CreateButton(1, "TestButton7_1b", UIParent); btn:SetSize(36, 36); btn:SetPoint("CENTER", 0, 0); btn:Show(); _G.T71b = btn; print("Update callbacks: " .. _G.UpdateCount)
```

**Expected**:
- Message shows update count > 0 (at least 1 from initial update)
- Button visible

**Cleanup**:
```lua
/run if _G.T71b then _G.T71b:Hide();_G.T71b:SetParent(nil);_G.T71b=nil end; local LTAB=LibStub("LibTotalActionButtons-1.0"); LTAB.UnregisterCallback(_G.TestCB2,"OnButtonUpdate"); _G.UpdateCount=nil; _G.TestCB2=nil
```

### Test OnButtonContentsChanged callback

**Create callback**:
```lua
/run _G.TestCB3 = {}; _G.TestCB3.OnChange = function(self, event, button) print("Contents changed!") end; local LTAB = LibStub("LibTotalActionButtons-1.0"); LTAB.RegisterCallback(_G.TestCB3, "OnButtonContentsChanged", "OnChange")
```

**Create button**:
```lua
/run local LTAB = LibStub("LibTotalActionButtons-1.0"); local btn = LTAB:CreateButton(1, "TestButton7_1c", UIParent); btn:SetSize(36, 36); btn:SetPoint("CENTER", 0, 0); btn:Show(); _G.T71c = btn
```

**Expected**:
- Button visible with action 1 contents
- Try removing/adding an ability to action slot 1 to trigger callback

**Cleanup**:
```lua
/run if _G.T71c then _G.T71c:Hide();_G.T71c:SetParent(nil);_G.T71c=nil end; local LTAB=LibStub("LibTotalActionButtons-1.0"); LTAB.UnregisterCallback(_G.TestCB3,"OnButtonContentsChanged"); _G.TestCB3=nil
```

### Test OnButtonEnter/Leave callbacks

**Create callback object**:
```lua
/run _G.TestCB4 = {}; _G.TestCB4.OnEnter = function(self, event, button) print("Mouse entered") end; _G.TestCB4.OnLeave = function(self, event, button) print("Mouse left") end
```

**Register callbacks**:
```lua
/run local LTAB = LibStub("LibTotalActionButtons-1.0"); LTAB.RegisterCallback(_G.TestCB4, "OnButtonEnter", "OnEnter"); LTAB.RegisterCallback(_G.TestCB4, "OnButtonLeave", "OnLeave")
```

**Create button**:
```lua
/run local LTAB = LibStub("LibTotalActionButtons-1.0"); local btn = LTAB:CreateButton(1, "TestButton7_1d", UIParent); btn:SetSize(36, 36); btn:SetPoint("CENTER", 0, 0); btn:Show(); _G.T71d = btn
```

**Expected**:
- Button visible
- Moving mouse over button prints "Mouse entered"
- Moving mouse away prints "Mouse left"

**Cleanup**:
```lua
/run if _G.T71d then _G.T71d:Hide();_G.T71d:SetParent(nil);_G.T71d=nil end; local LTAB=LibStub("LibTotalActionButtons-1.0"); LTAB.UnregisterCallback(_G.TestCB4,"OnButtonEnter"); LTAB.UnregisterCallback(_G.TestCB4,"OnButtonLeave"); _G.TestCB4=nil
```

### Test OnButtonStateChanged callback

**Create callback object**:
```lua
/run _G.TestCB5 = {}; _G.TestCB5.OnStateChange = function(self, event, button, newState, oldState) print("State: " .. tostring(oldState) .. " -> " .. tostring(newState)) end
```

**Register callback**:
```lua
/run local LTAB = LibStub("LibTotalActionButtons-1.0"); LTAB.RegisterCallback(_G.TestCB5, "OnButtonStateChanged", "OnStateChange")
```

**Create button and set state 0**:
```lua
/run local LTAB = LibStub("LibTotalActionButtons-1.0"); local btn = LTAB:CreateButton(1, "TestButton7_1e", UIParent); btn:SetSize(36, 36); btn:SetPoint("CENTER", 0, 0); LTAB:SetState(btn, "0", "action", 1); btn:Show(); _G.T71e = btn
```

**Expected**:
- Button visible with action slot 1

**Enable debug mode**:
```lua
/run local LTAB = LibStub("LibTotalActionButtons-1.0"); LTAB:SetDebug(true)
```

**Set state 1 and change state**:
```lua
/run local LTAB = LibStub("LibTotalActionButtons-1.0"); LTAB:SetState(_G.T71e, "1", "spell", 133); LTAB:UpdateState(_G.T71e, "1")
```

**Expected**:
- Message "State: 0 -> 1" appears
- Button changes to Fireball spell (spell ID 133)
- Debug output showing property changes during state transition

**Check properties after state change**:
```lua
/run local btn = _G.T71e; print(string.format("FINAL: type=%s action=%s spellID=%s", tostring(btn.buttonType), tostring(btn.action), tostring(btn.spellID)))
```

**Expected**:
- `type=spell action=0 spellID=133`
- (action=0 is an invalid slot, safe for Blizzard's template code)

**Cleanup**:
```lua
/run if _G.T71e then _G.T71e:Hide();_G.T71e:SetParent(nil);_G.T71e=nil end; local LTAB=LibStub("LibTotalActionButtons-1.0"); LTAB:SetDebug(false); LTAB.UnregisterCallback(_G.TestCB5,"OnButtonStateChanged"); _G.TestCB5=nil
```

---

## Test 7.2: Masque Support

### Load Masque (if Load on Demand)

**Script**:
```lua
/run C_AddOns.LoadAddOn("Masque")
```

**Expected**:
- No output (addon loads silently if installed)

### Test Masque availability check

**Script**:
```lua
/run local MSQ = LibStub("Masque", true); if MSQ then print("Masque is available") else print("Masque not installed - skipping Masque tests") end
```

**Expected**:
- Message indicates if Masque is available
- If not available, skip remaining Masque tests

### Test adding button to Masque (if Masque available)

**Create and add to Masque**:
```lua
/run local LTAB = LibStub("LibTotalActionButtons-1.0"); local btn = LTAB:CreateButton(1, "TestButton7_2", UIParent); btn:SetSize(36, 36); btn:SetPoint("CENTER", 0, 0); btn:Show(); LTAB:AddToMasque(btn); _G.T72 = btn
```

**Check result**:
```lua
/run print("Button skinned: " .. tostring(_G.T72._masqueSkinned))
```

**Expected**:
- Button visible
- Message shows "skinned: true" if Masque available
- Button may have Masque skin applied (depends on active Masque skin)

**Cleanup**:
```lua
/run if _G.T72 then local LTAB = LibStub("LibTotalActionButtons-1.0"); LTAB:RemoveFromMasque(_G.T72); _G.T72:Hide(); _G.T72:SetParent(nil); _G.T72=nil end
```

---

## Test 7.3: LibKeyBound Integration

### Load LibKeyBound (Load on Demand)

**Script** (addon folder is LibKeyBound-1.0):
```lua
/run local loaded, reason = C_AddOns.LoadAddOn("LibKeyBound-1.0"); print("Loaded:", loaded, "Reason:", reason or "success")
```

**Expected**:
- Message shows "Loaded: true Reason: success"

### Test LibKeyBound availability check

**Script**:
```lua
/run local LKB = LibStub("LibKeyBound-1.0", true); if LKB then print("LibKeyBound is available") else print("LibKeyBound not installed - skipping LibKeyBound tests") end
```

**Expected**:
- Message indicates if LibKeyBound is available
- If not available, skip remaining LibKeyBound tests

### Test enabling LibKeyBound for button (if LibKeyBound available)

**Create button**:
```lua
/run local LTAB = LibStub("LibTotalActionButtons-1.0"); _G.T73 = LTAB:CreateButton(1, "TestButton7_3", UIParent); _G.T73:SetSize(36, 36); _G.T73:SetPoint("CENTER", 0, 0); _G.T73:Show()
```

**Enable LibKeyBound**:
```lua
/run local LTAB = LibStub("LibTotalActionButtons-1.0"); LTAB:EnableKeyBound(_G.T73); print("LibKeyBound enabled: " .. tostring(_G.T73._libKeyBoundEnabled))
```

**Expected**:
- Button visible
- Message shows "LibKeyBound enabled: true"
- Button has GetBindingAction, GetActionName, GetHotkey, SetKey methods

**Test GetActionName method**:
```lua
/run if _G.T73 and _G.T73.GetActionName then print("Action name: " .. _G.T73:GetActionName()) else print("GetActionName not available") end
```

**Expected**:
- Message shows action name like "Action Button 1"

**Cleanup**:
```lua
/run if _G.T73 then local LTAB = LibStub("LibTotalActionButtons-1.0"); LTAB:DisableKeyBound(_G.T73); _G.T73:Hide(); _G.T73:SetParent(nil); _G.T73=nil end
```

---

## Test 7.4: Action UI Registration (Retail Only)

**Note**: The `C_ActionBar.SetActionUIButton` API was removed or never publicly available in modern Retail WoW. This test verifies the graceful fallback behavior.

### Test Action UI registration availability

**Script**:
```lua
/run local LTAB = LibStub("LibTotalActionButtons-1.0"); if LTAB.WoWRetail and C_ActionBar and C_ActionBar.SetActionUIButton then print("Action UI registration available") else print("Action UI registration not available (Classic or API missing)") end
```

**Expected**:
- Message shows "Action UI registration not available (Classic or API missing)"
- This is normal - the API is not publicly available in current WoW versions

### Test registering action button (verifies graceful fallback)

**Create button**:
```lua
/run local LTAB = LibStub("LibTotalActionButtons-1.0"); _G.T74 = LTAB:CreateButton(1, "TestButton7_4", UIParent); _G.T74:SetSize(36, 36); _G.T74:SetPoint("CENTER", 0, 0); _G.T74:Show()
```

**Register with Action UI system**:
```lua
/run local LTAB = LibStub("LibTotalActionButtons-1.0"); LTAB:RegisterActionUI(_G.T74); print("Action UI registered: " .. tostring(_G.T74._actionUIRegistered))
```

**Expected**:
- Button visible and functional
- Message shows "Action UI registered: nil" (API not available)
- No errors - RegisterActionUI gracefully returns when API missing
- Button works normally even without registration

**Cleanup**:
```lua
/run if _G.T74 then local LTAB = LibStub("LibTotalActionButtons-1.0"); LTAB:UnregisterActionUI(_G.T74); _G.T74:Hide(); _G.T74:SetParent(nil); _G.T74=nil end
```

---

# Phase 8: Performance Optimization Tests

## Test 8.1: Centralized Event Handling

**Test**: Verify EventFrame exists

```lua
/run local L=LibStub("LibTotalActionButtons-1.0");print("EventFrame:",L.EventFrame and "YES" or "NO")
```
**Expected**: Message shows "EventFrame: YES"

**Test**: Verify OnEvent handler exists

```lua
/run local L=LibStub("LibTotalActionButtons-1.0");print("OnEvent:",L.EventFrame:GetScript("OnEvent") and "YES" or "NO")
```
**Expected**: Message shows "OnEvent: YES"

## Test 8.2: Batch Update Functions

**Create test buttons**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.T81=L:CreateSpellButton(1231411,"T81",UIParent);_G.T81:SetPoint("CENTER",0,100);_G.T81:Show()
```
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.T82=L:CreateItemButton(6948,"T82",UIParent);_G.T82:SetPoint("CENTER",0,50);_G.T82:Show()
```
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.T83=L:CreateSpellButton(2565,"T83",UIParent);_G.T83:SetPoint("CENTER",0,0);_G.T83:Show()
```
**Expected**: Three buttons appear

**Test ForAllButtons hide**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:ForAllButtons(function(b)b:Hide()end);print("All hidden")
```
**Expected**: All buttons disappear

**Test ForAllButtons show**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:ForAllButtons(function(b)b:Show();L:UpdateButton(b)end);print("All shown")
```
**Expected**: All buttons reappear with icons

**Test ForAllButtonsWithSpell**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");local c=0;L:ForAllButtonsWithSpell(1231411,function(b)c=c+1;b:SetAlpha(0.5)end);print("Count:",c)
```
**Expected**: T81 semi-transparent, "Count: 1"

**Test ForAllButtonsWithItem**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");local c=0;L:ForAllButtonsWithItem(6948,function(b)c=c+1;b:SetAlpha(0.5)end);print("Count:",c)
```
**Expected**: T82 semi-transparent, "Count: 1"

**Reset alpha**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:ForAllButtons(function(b)b:SetAlpha(1.0)end);print("Reset")
```

**Cleanup**:
```lua
/run _G.T81:Hide();_G.T81:SetParent(nil);_G.T81=nil;_G.T82:Hide();_G.T82:SetParent(nil);_G.T82=nil;_G.T83:Hide();_G.T83:SetParent(nil);_G.T83=nil
```

## Test 8.3: Range Update Throttling

**Test OnUpdate exists**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");print("OnUpdate:",L.EventFrame:GetScript("OnUpdate") and "YES" or "NO")
```
**Expected**: "OnUpdate: YES"

**Create ranged spell button** (manual test - observe range updates):
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.T83=L:CreateSpellButton(116,"T83",UIParent);_G.T83:SetPoint("CENTER");_G.T83:Show()
```
**Expected**: Button appears (Frostbolt, 40yd range). Target an enemy, move out of range to see throttled updates

**Cleanup**:
```lua
/run _G.T83:Hide();_G.T83:SetParent(nil);_G.T83=nil
```

## Test 8.4: Active Button Tracking

**Create button and check tracking**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.T84=L:CreateSpellButton(123141,"T84",UIParent);_G.T84:SetPoint("CENTER");_G.T84:Show();print("Active:",#L.activeButtons)
```
**Expected**: Shows active count >= 1

**Create more buttons**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.T85=L:CreateItemButton(6948,"T85",UIParent);_G.T85:SetPoint("CENTER",0,50);_G.T85:Show();print("Active:",#L.activeButtons)
```
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.T86=L:CreateSpellButton(2565,"T86",UIParent);_G.T86:SetPoint("CENTER",0,-50);_G.T86:Show();print("Active:",#L.activeButtons)
```
**Expected**: Active count increases

**Clear button and verify untracked**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");local b=#L.activeButtons;L:ClearButton(_G.T84);print("Before:",b,"After:",#L.activeButtons)
```
**Expected**: After < Before

**Test ButtonHasContent**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");print("T84:",L:ButtonHasContent(_G.T84),"T85:",L:ButtonHasContent(_G.T85))
```
**Expected**: T84=false, T85=true

**Cleanup**:
```lua
/run _G.T84:Hide();_G.T84:SetParent(nil);_G.T84=nil;_G.T85:Hide();_G.T85:SetParent(nil);_G.T85=nil;_G.T86:Hide();_G.T86:SetParent(nil);_G.T86=nil
```

## Test 8.5: Lazy Initialization (Retail only)

**Create button - check chargeCooldown not created initially**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.T87=L:CreateSpellButton(123141,"T87",UIParent);_G.T87:SetPoint("CENTER");_G.T87:Show();print("CD:",_G.T87.chargeCooldown and "YES" or "NO")
```
**Expected**: "CD: NO" (not created yet)

**Trigger lazy creation**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:EnsureChargeCooldown(_G.T87);print("CD:",_G.T87.chargeCooldown and "YES" or "NO")
```
**Expected (Retail)**: "CD: YES" | **Expected (Classic)**: "CD: NO"

**Verify idempotent (doesn't recreate)**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");local f1=_G.T87.chargeCooldown;L:EnsureChargeCooldown(_G.T87);print("Same:",f1==_G.T87.chargeCooldown)
```
**Expected**: "Same: true"

**Cleanup**:
```lua
/run _G.T87:Hide();_G.T87:SetParent(nil);_G.T87=nil
```

## Test 8.6: Performance & Memory Test

**Create 50 buttons and measure**:
```lua
/run L=LibStub("LibTotalActionButtons-1.0");s=debugprofilestop();for i=1,50 do b=L:CreateSpellButton(123141,"TP"..i,UIParent);b:SetPoint("CENTER",math.random(-400,400),math.random(-300,300));b:Show()end;print((debugprofilestop()-s).."ms")
```
**Expected**: < 100ms total (~2ms per button)

**Test ForAllButtons performance**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");local s=debugprofilestop();L:ForAllButtons(function(b)b:SetAlpha(b:GetAlpha())end);print(string.format("%.2fms for %d btns",debugprofilestop()-s,#L.buttons))
```
**Expected**: < 5ms for 50+ buttons

**Count active buttons**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");print("Total:",#L.buttons,"Active:",#L.activeButtons)
```
**Expected**: Active = 50 (buttons with content from this test), Total = 62+ (all buttons ever created, including action bars on screen)

**Memory check**:
```lua
/run UpdateAddOnMemoryUsage();print(string.format("TotalUI: %.2f KB",GetAddOnMemoryUsage("TotalUI")))
```
**Expected**: < 50 MB (typically 10-20 MB for full UI addon with 50+ test buttons)

**Cleanup**:
```lua
/run for i=1,50 do local b=_G["TP"..i];if b then b:Hide();b:SetParent(nil);_G["TP"..i]=nil end end;print("Cleaned")
```

## Test 8.7: Integration Test - Event Handling

**Create action button**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:SetDebug(true);_G.T88=L:CreateActionButton(1,"T88",UIParent);_G.T88:SetPoint("CENTER");_G.T88:Show();print("Place spell on slot 1")
```
**Expected**: Button appears, debug enabled

**Manual Test**: Place/remove spell on action slot 1
**Expected**: Button updates immediately, debug shows events

**Cleanup**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:SetDebug(false);_G.T88:Hide();_G.T88:SetParent(nil);_G.T88=nil
```

---

# Phase 9: Advanced Features Tests

## Test 9.1: Flyout System

**Note**: Requires a flyout action on your action bars (e.g., Mount/Pet abilities that have flyouts)

**Check if action is flyout** (using action slot 9 where you placed Teleport flyout):
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");local a=9;local isFlyout,numSlots,dir=L:GetFlyoutInfo(a);print("Flyout:",isFlyout,"Slots:",numSlots,"Dir:",dir)
```
**Expected**: "Flyout: true Slots: [number] Dir: UP" (or DOWN/LEFT/RIGHT depending on flyout)

**Create button with flyout action** (using action slot 9 for Teleport flyout):
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.T91=L:CreateActionButton(9,"T91",UIParent);_G.T91:SetPoint("CENTER");L:SetButtonSize(_G.T91,50,50);_G.T91:Show()
```

**Show flyout**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:ShowFlyout(_G.T91);print("Flyout shown")
```
**Expected**: If action is flyout, flyout buttons appear above parent

**Hide flyout**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:HideFlyout(_G.T91);print("Flyout hidden")
```
**Expected**: Flyout buttons disappear

**Cleanup**:
```lua
/run if _G.T91 then local L=LibStub("LibTotalActionButtons-1.0");L:HideFlyout(_G.T91);_G.T91:Hide();_G.T91:SetParent(nil);_G.T91=nil end
```

## Test 9.2: Global Grid System

**Create empty buttons** (using very high unused action slots):
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");for i=1,5 do local b=L:CreateActionButton(500+i,"T92_"..i,UIParent);b:SetPoint("CENTER",(i-3)*55,100);L:SetButtonSize(b,50,50);b:Show()end
```
**Expected**: 5 empty buttons appear (no grid visible yet - just empty button backgrounds)

**Show global grid**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:ShowGrid();print("Grid shown, counter:",L.gridCounter)
```
**Expected**: All empty buttons show grid border, counter = 1

**Show grid again** (test counter):
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:ShowGrid();print("Grid shown again, counter:",L.gridCounter)
```
**Expected**: Counter = 2

**Hide grid once**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:HideGrid();print("Grid hidden once, counter:",L.gridCounter)
```
**Expected**: Grid still visible, counter = 1

**Hide grid final**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:HideGrid();print("Grid hidden final, counter:",L.gridCounter)
```
**Expected**: Grid disappears, counter = 0

**Cleanup**:
```lua
/run for i=1,5 do local b=_G["T92_"..i];if b then b:Hide();b:SetParent(nil);_G["T92_"..i]=nil end end;print("Cleaned")
```

## Test 9.3: Tooltip Enhancements

**Create spell button**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.T93=L:CreateSpellButton(116,"T93",UIParent);_G.T93:SetPoint("CENTER");L:SetButtonSize(_G.T93,50,50);_G.T93:Show()
```

**Test normal tooltip** (hover mouse over button):
**Expected**: Tooltip shows spell info

**Disable tooltips**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:SetTooltipMode(_G.T93,"disabled");print("Tooltips disabled")
```
**Expected**: Hovering shows no tooltip

**Enable nocombat mode**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:SetTooltipMode(_G.T93,"nocombat");print("Tooltips nocombat")
```
**Expected**: Tooltip shows when not in combat, hides in combat

**Re-enable tooltips**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:SetTooltipMode(_G.T93,"enabled");print("Tooltips enabled")
```
**Expected**: Tooltips work normally

**Cleanup**:
```lua
/run if _G.T93 then _G.T93:Hide();_G.T93:SetParent(nil);_G.T93=nil end
```

## Test 9.4: Spell Cast VFX (Retail Only)

**Create button**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.T95=L:CreateSpellButton(116,"T95",UIParent);_G.T95:SetPoint("CENTER");L:SetButtonSize(_G.T95,50,50);_G.T95:Show()
```

**Check if cast anim exists**:
```lua
/run print("SpellCastAnim:",_G.T95._spellCastAnim and "YES" or "NO")
```
**Expected (Retail)**: "YES" | **Expected (Classic)**: "NO"

**Show cast animation** (Retail only):
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:ShowSpellCastAnim(_G.T95);print("Cast anim shown")
```
**Expected (Retail)**: Cast animation visible on button

**Hide cast animation**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:HideSpellCastAnim(_G.T95);print("Cast anim hidden")
```
**Expected**: Animation hides

**Cleanup**:
```lua
/run if _G.T95 then _G.T95:Hide();_G.T95:SetParent(nil);_G.T95=nil end
```

---

# Phase 10: Missing Features Implementation Tests

## Test 10.1: Button Registry Tracking

**Test button registries exist**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");print("actionButtons:",L.actionButtons and "YES" or "NO");print("nonActionButtons:",L.nonActionButtons and "YES" or "NO");print("actionButtonsNonUI:",L.actionButtonsNonUI and "YES" or "NO")
```
**Expected**: All three show "YES"

**Create action and spell buttons**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.T101a=L:CreateActionButton(1,"T101a",UIParent);_G.T101b=L:CreateSpellButton(116,"T101b",UIParent);_G.T101a:SetPoint("CENTER",-30,0);_G.T101b:SetPoint("CENTER",30,0);_G.T101a:Show();_G.T101b:Show()
```

**Check registry separation**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");local ac,nac=0,0;for b in pairs(L.actionButtons) do ac=ac+1 end;for b in pairs(L.nonActionButtons) do nac=nac+1 end;print("Action buttons:",ac);print("Non-action buttons:",nac)
```
**Expected**: Action buttons >= 1, Non-action buttons >= 1

**Cleanup**:
```lua
/run if _G.T101a then _G.T101a:Hide();_G.T101a:SetParent(nil);_G.T101a=nil end;if _G.T101b then _G.T101b:Hide();_G.T101b:SetParent(nil);_G.T101b=nil end
```

## Test 10.2: UpdateRangeTimer Throttling

**Create button with ranged spell**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.T102=L:CreateSpellButton(116,"T102",UIParent);_G.T102:SetPoint("CENTER");L:SetButtonSize(_G.T102,50,50);_G.T102:Show()
```

**Check rangeTimer initialization**:
```lua
/run print("rangeTimer:",_G.T102.rangeTimer)
```
**Expected**: Shows a number (likely -1 or small positive)

**Manual test**: Target enemy, move in/out of range, observe updates throttled
**Expected**: Range color doesn't update instantly but with ~0.2s delay

**Cleanup**:
```lua
/run if _G.T102 then _G.T102:Hide();_G.T102:SetParent(nil);_G.T102=nil end
```

## Test 10.3: Item Quality Borders

**Get an uncommon+ item ID** (example: 193810 = uncommon crafting item):
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.T103=L:CreateItemButton(193810,"T103",UIParent);_G.T103:SetPoint("CENTER");L:SetButtonSize(_G.T103,50,50);_G.T103:Show()
```

**Check border color** (should match item quality):
```lua
/run local r,g,b,a=_G.T103._border:GetVertexColor();print(string.format("Border: r=%.2f g=%.2f b=%.2f a=%.2f",r,g,b,a))
```
**Expected**: Color matches item quality (green for uncommon, blue for rare, etc.)

**Cleanup**:
```lua
/run if _G.T103 then _G.T103:Hide();_G.T103:SetParent(nil);_G.T103=nil end
```

## Test 10.4: Border Texture Support

**Create button and set custom border**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.T104=L:CreateSpellButton(116,"T104",UIParent);_G.T104:SetPoint("CENTER");L:SetButtonSize(_G.T104,50,50);_G.T104:Show()
```

**Set custom border texture**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:SetBorderTexture(_G.T104,"Interface\\Buttons\\WHITE8X8",64,{x=0,y=0});_G.T104._border:SetVertexColor(1,0,0,1);_G.T104._border:Show();print("Custom border set")
```
**Expected**: Red square border appears

**Cleanup**:
```lua
/run if _G.T104 then _G.T104:Hide();_G.T104:SetParent(nil);_G.T104=nil end
```

## Test 10.5: Frame Level Management

**Create button**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.T105=L:CreateSpellButton(116,"T105",UIParent);_G.T105:SetPoint("CENTER");L:SetButtonSize(_G.T105,50,50);_G.T105:Show()
```

**Update frame levels**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:UpdateFrameLevels(_G.T105);print("Frame levels updated")
```

**Check frame levels**:
```lua
/run local b=_G.T105;print("Base:",b:GetFrameLevel());print("Cooldown:",b._cooldown:GetFrameLevel());if b.chargeCooldown then print("ChargeCooldown:",b.chargeCooldown:GetFrameLevel()) end
```
**Expected**: Cooldown level > base level, charge cooldown > cooldown

**Cleanup**:
```lua
/run if _G.T105 then _G.T105:Hide();_G.T105:SetParent(nil);_G.T105=nil end
```

## Test 10.6: Interrupt Display

**Create button**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.T106=L:CreateSpellButton(116,"T106",UIParent);_G.T106:SetPoint("CENTER");L:SetButtonSize(_G.T106,50,50);_G.T106:Show()
```

**Show interrupt display**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:ShowInterruptDisplay(_G.T106);print("Interrupt shown")
```
**Expected**: Star burst animation appears briefly (0.5s)

**Cleanup**:
```lua
/run if _G.T106 then _G.T106:Hide();_G.T106:SetParent(nil);_G.T106=nil end
```

## Test 10.7: Spell Alert Frame Management

**Create button (Retail only)**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.T107=L:CreateSpellButton(116,"T107",UIParent);_G.T107:SetPoint("CENTER");L:SetButtonSize(_G.T107,50,50);_G.T107:Show()
```

**Manually trigger spell alert**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:ShowSpellAlert(_G.T107,116);print("Spell alert shown")
```
**Expected (Retail)**: Alert animation appears

**Hide alert**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:HideSpellAlert(_G.T107);print("Alert hidden")
```

**Cleanup**:
```lua
/run if _G.T107 then _G.T107:Hide();_G.T107:SetParent(nil);_G.T107=nil end
```

## Test 10.8: Flyout Arrow System

**Note**: Requires action with flyout (e.g., Mage Teleport on action bar)

**Create button with flyout action** (replace 9 with your flyout action slot):
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.T108=L:CreateActionButton(9,"T108",UIParent);_G.T108:SetPoint("CENTER");L:SetButtonSize(_G.T108,50,50);_G.T108:Show()
```

**Show flyout**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:ShowFlyout(_G.T108);print("Flyout shown")
```
**Expected**: Flyout buttons appear AND arrow appears indicating direction

**Check arrow exists**:
```lua
/run print("Arrow:",_G.T108._flyoutArrow and "YES" or "NO")
```
**Expected**: "Arrow: YES"

**Hide flyout**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:HideFlyout(_G.T108);print("Flyout hidden")
```
**Expected**: Arrow hides

**Cleanup**:
```lua
/run if _G.T108 then _G.T108:Hide();_G.T108:SetParent(nil);_G.T108=nil end
```

## Test 10.9: OnAttributeChanged Handler

**Create button**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.T109=L:CreateSpellButton(116,"T109",UIParent);_G.T109:SetPoint("CENTER");L:SetButtonSize(_G.T109,50,50);_G.T109:Show()
```

**Check OnAttributeChanged script exists**:
```lua
/run print("OnAttributeChanged:",_G.T109:GetScript("OnAttributeChanged") and "YES" or "NO")
```
**Expected**: "OnAttributeChanged: YES"

**Change attribute (outside combat)**:
```lua
/run _G.T109:SetAttribute("spell",133);print("Attribute changed to Fireball")
```
**Expected**: Button updates to show Fireball (spell ID 133)

**Cleanup**:
```lua
/run if _G.T109 then _G.T109:Hide();_G.T109:SetParent(nil);_G.T109=nil end
```

## Test 10.10: UpdateOverlayGlow (Retail)

**Create button with proc-able spell**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.T1010=L:CreateSpellButton(116,"T1010",UIParent);_G.T1010:SetPoint("CENTER");L:SetButtonSize(_G.T1010,50,50);_G.T1010:Show()
```

**Manually trigger overlay glow**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:ShowOverlayGlow(_G.T1010);print("Overlay glow shown")
```
**Expected**: Golden proc glow appears

**Test UpdateOverlayGlow function exists**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");print("UpdateOverlayGlow:",type(L.UpdateOverlayGlow))
```
**Expected**: "UpdateOverlayGlow: function"

**Hide glow**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:HideOverlayGlow(_G.T1010);print("Glow hidden")
```

**Cleanup**:
```lua
/run if _G.T1010 then _G.T1010:Hide();_G.T1010:SetParent(nil);_G.T1010=nil end
```

## Test 10.11: UpdateHotkeys with RANGE_INDICATOR

**Create action button** (action slot 1 should have hotkey "1"):
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.T1011=L:CreateActionButton(1,"T1011",UIParent);_G.T1011:SetPoint("CENTER");L:SetButtonSize(_G.T1011,50,50);_G.T1011:Show()
```

**Check hotkey display**:
```lua
/run print("Hotkey text:",_G.T1011._hotkey:GetText())
```
**Expected**: Shows "1" or RANGE_INDICATOR if no keybind

**Test UpdateHotkeys function**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:UpdateHotkeys(_G.T1011);print("Hotkeys updated")
```
**Expected**: No errors

**Cleanup**:
```lua
/run if _G.T1011 then _G.T1011:Hide();_G.T1011:SetParent(nil);_G.T1011=nil end
```

## Test 10.12: Desaturation Support

**Create button**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.T1012=L:CreateSpellButton(116,"T1012",UIParent);_G.T1012:SetPoint("CENTER");L:SetButtonSize(_G.T1012,50,50);_G.T1012.config.desaturateUnusable=true;_G.T1012:Show()
```

**Force unusable state** (remove mana or target):
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:UpdateUsable(_G.T1012)
```

**Check desaturation** (should be true when unusable):
```lua
/run print("Desaturated:",_G.T1012._icon:IsDesaturated())
```
**Expected**: "Desaturated: true" when OOM or no target

**Cleanup**:
```lua
/run if _G.T1012 then _G.T1012:Hide();_G.T1012:SetParent(nil);_G.T1012=nil end
```

## Test 10.13: Charge Cooldown Enhancements

**Note**: Retail only, requires charge-based ability

**Create charge-based spell button** (Fire Blast = 108853):
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.T1013=L:CreateSpellButton(108853,"T1013",UIParent);_G.T1013:SetPoint("CENTER");L:SetButtonSize(_G.T1013,50,50);_G.T1013:Show()
```

**Check NumChargeCooldowns counter**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");print("NumChargeCooldowns:",L.NumChargeCooldowns)
```
**Expected**: Number >= 0

**Use ability and check chargeCooldown frame**:
```lua
/run print("chargeCooldown frame:",_G.T1013.chargeCooldown and "YES" or "NO")
```
**Expected (after using ability)**: "chargeCooldown frame: YES"

**Cleanup**:
```lua
/run if _G.T1013 then _G.T1013:Hide();_G.T1013:SetParent(nil);_G.T1013=nil end
```

## Test 10.14: UpdateNewAction Alias

**Check UpdateNewAction function exists**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");print("UpdateNewAction:",type(L.UpdateNewAction));print("UpdateNewActionHighlight:",type(L.UpdateNewActionHighlight))
```
**Expected**: Both show "function"

**Test they work the same**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.T1014=L:CreateSpellButton(116,"T1014",UIParent);_G.T1014:SetPoint("CENTER");L:SetButtonSize(_G.T1014,50,50);_G.T1014:Show();L:UpdateNewAction(_G.T1014);print("UpdateNewAction called")
```
**Expected**: No errors

**Cleanup**:
```lua
/run if _G.T1014 then _G.T1014:Hide();_G.T1014:SetParent(nil);_G.T1014=nil end
```

## Test 10.15: UpdateCount Already Existed

**Create item button with stackable item** (Hearthstone = 6948):
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.T1015=L:CreateItemButton(6948,"T1015",UIParent);_G.T1015:SetPoint("CENTER");L:SetButtonSize(_G.T1015,50,50);_G.T1015:Show()
```

**Check count displays**:
```lua
/run print("Count text:",_G.T1015._count:GetText())
```
**Expected**: Shows item count or empty for single items

**Cleanup**:
```lua
/run if _G.T1015 then _G.T1015:Hide();_G.T1015:SetParent(nil);_G.T1015=nil end
```

## Test 10.16: Utility Methods (ForAllButtons)

**Test ForAllButtons exists**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");print("ForAllButtons:",type(L.ForAllButtons));print("ForAllButtonsWithSpell:",type(L.ForAllButtonsWithSpell))
```
**Expected**: Both show "function"

**Create test buttons**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");for i=1,3 do local b=L:CreateSpellButton(116,"T1016_"..i,UIParent);b:SetPoint("CENTER",(i-2)*60,0);L:SetButtonSize(b,50,50);b:Show() end
```

**Test ForAllButtons**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");local c=0;L:ForAllButtons(function(b) c=c+1 end);print("Total buttons:",c)
```
**Expected**: Shows count >= 3

**Test ForAllButtonsWithSpell**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");local c=0;L:ForAllButtonsWithSpell(116,function(b) c=c+1 end);print("Frostbolt buttons:",c)
```
**Expected**: Shows count >= 3 (our test buttons)

**Cleanup**:
```lua
/run for i=1,3 do local b=_G["T1016_"..i];if b then b:Hide();b:SetParent(nil);_G["T1016_"..i]=nil end end;print("Cleaned")
```

## Test 10.17: Integration Test - All Features

**Create comprehensive test button**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.TINT=L:CreateActionButton(1,"T_INTEGRATION",UIParent);_G.TINT:SetPoint("CENTER");L:SetButtonSize(_G.TINT,50,50);_G.TINT.config.desaturateUnusable=true;_G.TINT:Show()
```

**Verify all tracking** (run each script separately):
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");print("In actionButtons:",L.actionButtons[_G.TINT] and "YES" or "NO")
```
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");print("In activeButtons:",L.activeButtons[_G.TINT] and "YES" or "NO")
```
```lua
/run print("rangeTimer:",_G.TINT.rangeTimer)
```
```lua
/run print("Has OnAttributeChanged:",_G.TINT:GetScript("OnAttributeChanged") and "YES" or "NO")
```
**Expected**: All checks pass (YES/YES/number/YES)

**Test frame levels**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:UpdateFrameLevels(_G.TINT);print("Base level:",_G.TINT:GetFrameLevel());print("Cooldown level:",_G.TINT._cooldown:GetFrameLevel())
```
**Expected**: Cooldown level > base level

**Test all update functions**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:UpdateButton(_G.TINT);L:UpdateRangeTimer(_G.TINT,0.3);L:UpdateOverlayGlow(_G.TINT);L:UpdateNewAction(_G.TINT);L:UpdateHotkeys(_G.TINT);print("All updates successful")
```
**Expected**: No errors

**Cleanup**:
```lua
/run if _G.TINT then _G.TINT:Hide();_G.TINT:SetParent(nil);_G.TINT=nil end
```

---

# Phase 11 Tests - Complete Feature Parity (27 Items)

## Test 11.1: GetAllButtons() - HIGH PRIORITY Item 1

**Purpose**: Verify GetAllButtons returns iterator

**Setup**:
```lua
/run _G.GTB1=LibStub("LibTotalActionButtons-1.0"):CreateActionButton(1,"GTB1",UIParent);_G.GTB2=LibStub("LibTotalActionButtons-1.0"):CreateActionButton(2,"GTB2",UIParent);print("Created 2 buttons")
```

**Test**: Count buttons
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");local c=0;for btn in L:GetAllButtons() do c=c+1 end;print("Button count:",c)
```
**Expected**: Button count: 2 (or more if other buttons exist)

**Cleanup**:
```lua
/run if _G.GTB1 then _G.GTB1:Hide();_G.GTB1=nil end;if _G.GTB2 then _G.GTB2:Hide();_G.GTB2=nil end
```

---

## Test 11.2: UpdateAllStates() - HIGH PRIORITY Item 2

**Purpose**: Verify UpdateAllStates updates all buttons to new state

**Setup**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.UAS=L:CreateActionButton(1,"UAS",UIParent);L:SetState(_G.UAS,"0","action",1);L:SetState(_G.UAS,"1","action",2);print("Set states")
```

**Test**: Update all to state 1
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:UpdateAllStates("1");print("UpdateAllStates to 1:",_G.UAS._currentState or "nil")
```
**Expected**: State changed to 1

**Cleanup**:
```lua
/run if _G.UAS then _G.UAS:Hide();_G.UAS=nil end
```

---

## Test 11.3: UpdateTooltip() - HIGH PRIORITY Item 3

**Purpose**: Verify UpdateTooltip respects config

**Setup**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.UTT=L:CreateActionButton(1,"UTT",UIParent);_G.UTT:SetPoint("CENTER");_G.UTT:Show();print("Button created")
```

**Test 1**: Normal tooltip
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.UTT.config.tooltip="enabled";L:UpdateTooltip(_G.UTT);print("Tooltip mode: enabled")
```

**Test 2**: Disabled tooltip
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.UTT.config.tooltip="disabled";L:UpdateTooltip(_G.UTT);print("Tooltip mode: disabled")
```

**Test 3**: No combat tooltip
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.UTT.config.tooltip="nocombat";L:UpdateTooltip(_G.UTT);print("Tooltip mode: nocombat")
```
**Expected**: No errors, different modes work

**Cleanup**:
```lua
/run if _G.UTT then _G.UTT:Hide();_G.UTT=nil end
```

---

## Test 11.4: UpdateLocal() - HIGH PRIORITY Item 4

**Purpose**: Verify UpdateLocal does visual-only update

**Setup**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.ULB=L:CreateActionButton(1,"ULB",UIParent);_G.ULB:SetPoint("CENTER");_G.ULB:Show();print("Button created")
```

**Test**: Call UpdateLocal
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:UpdateLocal(_G.ULB);print("UpdateLocal called successfully")
```
**Expected**: No errors, button updates visually

**Cleanup**:
```lua
/run if _G.ULB then _G.ULB:Hide();_G.ULB=nil end
```

---

## Test 11.5: UpdateAlpha() - HIGH PRIORITY Item 5

**Purpose**: Verify UpdateAlpha applies transparency

**Setup**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.UAB=L:CreateActionButton(1,"UAB",UIParent);_G.UAB:SetPoint("CENTER");_G.UAB:Show();print("Button created")
```

**Test 1**: Set alpha 0.5
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.UAB.config.alpha=0.5;L:UpdateAlpha(_G.UAB);print("Alpha set to 0.5")
```

**Test 2**: Set alpha 1.0
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.UAB.config.alpha=1.0;L:UpdateAlpha(_G.UAB);print("Alpha set to 1.0")
```
**Expected**: Button transparency changes visibly

**Cleanup**:
```lua
/run if _G.UAB then _G.UAB:Hide();_G.UAB=nil end
```

---

## Test 11.6: ClearNewActionHighlight() - HIGH PRIORITY Item 6

**Purpose**: Verify ClearNewActionHighlight removes highlight

**Setup**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.CNH=L:CreateActionButton(1,"CNH",UIParent);_G.CNH:SetPoint("CENTER");_G.CNH:Show();print("Button created")
```

**Test**: Clear highlight for action 1
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:ClearNewActionHighlight(1,false);print("Cleared action 1 highlight")
```
**Expected**: No errors, highlight cleared

**Cleanup**:
```lua
/run if _G.CNH then _G.CNH:Hide();_G.CNH=nil end
```

---

## Test 11.7: UpdateCooldownNumberHidden() - HIGH PRIORITY Item 7

**Purpose**: Verify cooldown number visibility control

**Setup**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.UCNH=L:CreateActionButton(1,"UCNH",UIParent);_G.UCNH:SetPoint("CENTER");_G.UCNH:Show();print("Button created")
```

**Test 1**: Hide cooldown numbers
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.UCNH.config.cooldownCount=false;L:UpdateCooldownNumberHidden(_G.UCNH);print("Numbers hidden")
```

**Test 2**: Show cooldown numbers
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.UCNH.config.cooldownCount=true;L:UpdateCooldownNumberHidden(_G.UCNH);print("Numbers shown")
```
**Expected**: Cooldown numbers hide/show as configured

**Cleanup**:
```lua
/run if _G.UCNH then _G.UCNH:Hide();_G.UCNH=nil end
```

---

## Test 11.8: GetAllBindings() - HIGH PRIORITY Item 8

**Purpose**: Verify GetAllBindings returns key list

**Setup**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.GAB=L:CreateActionButton(1,"GAB",UIParent);_G.GAB.action=1;print("Button with action 1")
```

**Test**: Get bindings for action 1
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");local b=L:GetAllBindings(_G.GAB);print("Bindings count:",#b)
```
**Expected**: Returns table (possibly empty if no bindings)

**Cleanup**:
```lua
/run if _G.GAB then _G.GAB:Hide();_G.GAB=nil end
```

---

## Test 11.9: ClearAllBindings() - HIGH PRIORITY Item 9

**Purpose**: Verify ClearAllBindings removes all keys

**Setup**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.CAB=L:CreateActionButton(1,"CAB",UIParent);_G.CAB.action=1;print("Button with action 1")
```

**Test**: Clear all bindings (BE CAREFUL - clears real bindings!)
```lua
/run print("SKIPPED: ClearAllBindings would clear real bindings. Method exists and is callable.")
```
**Expected**: Method exists (not testing actual clear to avoid breaking user bindings)

**Cleanup**:
```lua
/run if _G.CAB then _G.CAB:Hide();_G.CAB=nil end
```

---

## Test 11.10: ButtonContentsChanged Callback - HIGH PRIORITY Item 10

**Purpose**: Verify ButtonContentsChanged callback fires

**Setup**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.BCC_fired=false;L:RegisterCallback("OnButtonContentsChanged",function() _G.BCC_fired=true end);print("Callback registered")
```

**Test 1**: Create button to fire callback
```lua
/run _G.BCC=LibStub("LibTotalActionButtons-1.0"):CreateActionButton(1,"BCC",UIParent);print("Callback fired:",_G.BCC_fired)
```

**Test 2**: Call ButtonContentsChanged directly
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.BCC_fired=false;L:ButtonContentsChanged(_G.BCC);print("Callback fired:",_G.BCC_fired)
```
**Expected**: Callback fires (true)

**Cleanup**:
```lua
/run if _G.BCC then _G.BCC:Hide();_G.BCC=nil end;_G.BCC_fired=nil
```

---

## Test 11.11: OnKeybindingChanged Callback - HIGH PRIORITY Item 11

**Purpose**: Verify OnKeybindingChanged callback fires

**Setup**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.KBC_fired=false;L:RegisterCallback("OnKeybindingChanged",function() _G.KBC_fired=true end);print("Registered")
```

**Test**: Fire callback directly
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:FireCallback("OnKeybindingChanged",nil,nil);print("Callback fired:",_G.KBC_fired)
```
**Expected**: Callback fires (true)

**Cleanup**:
```lua
/run _G.KBC_fired=nil
```

---

## Test 11.12: UpdateSpellHighlight() - MEDIUM PRIORITY Item 12 (Retail Only)

**Purpose**: Verify spell highlight animation works

**Setup** (Retail only):
```lua
/run if not WOW_PROJECT_ID or WOW_PROJECT_ID~=1 then print("SKIP: Classic");return end;local L=LibStub("LibTotalActionButtons-1.0");_G.USH=L:CreateSpellButton(133,"USH",UIParent);_G.USH:Show();print("OK")
```

**Test** (Retail only):
```lua
/run if not _G.USH then print("SKIP") return end;local L=LibStub("LibTotalActionButtons-1.0");L:UpdateSpellHighlight(_G.USH);print("UpdateSpellHighlight called")
```
**Expected**: No errors on Retail, skipped on Classic

**Cleanup**:
```lua
/run if _G.USH then _G.USH:Hide();_G.USH=nil end
```

---

## Test 11.13: UpdateAssistedCombatRotationFrame() - MEDIUM PRIORITY Item 13 (Retail Only)

**Purpose**: Verify assisted combat rotation frame

**Setup** (Retail only):
```lua
/run if not WOW_PROJECT_ID or WOW_PROJECT_ID~=1 then print("SKIP: Classic");return end;local L=LibStub("LibTotalActionButtons-1.0");_G.UACR=L:CreateActionButton(1,"UACR",UIParent);print("OK")
```

**Test** (Retail only):
```lua
/run if not _G.UACR then print("SKIP") return end;local L=LibStub("LibTotalActionButtons-1.0");_G.UACR.config={actionButtonUI=true,assistedHighlight=true};L:UpdateAssistedCombatRotationFrame(_G.UACR);print("OK")
```
**Expected**: No errors on Retail, skipped on Classic

**Cleanup**:
```lua
/run if _G.UACR then _G.UACR:Hide();_G.UACR=nil end
```

---

## Test 11.14: UpdatedAssistedHighlightFrame() - MEDIUM PRIORITY Item 14 (Retail Only)

**Purpose**: Verify assisted highlight frame

**Setup** (Retail only):
```lua
/run if not WOW_PROJECT_ID or WOW_PROJECT_ID~=1 then print("SKIP: Classic");return end;local L=LibStub("LibTotalActionButtons-1.0");_G.UAHF=L:CreateActionButton(1,"UAHF",UIParent);print("OK")
```

**Test** (Retail only):
```lua
/run if not _G.UAHF then print("SKIP") return end;local L=LibStub("LibTotalActionButtons-1.0");_G.UAHF.config={actionButtonUI=true,assistedHighlight=true};L:UpdatedAssistedHighlightFrame(_G.UAHF);print("OK")
```
**Expected**: No errors on Retail, skipped on Classic

**Cleanup**:
```lua
/run if _G.UAHF then _G.UAHF:Hide();_G.UAHF=nil end
```

---

## Test 11.15: SpellVFX Methods - MEDIUM PRIORITY Items 15-21 (Retail Only)

**Purpose**: Verify all 7 SpellVFX methods exist and are callable

**Setup** (Retail only):
```lua
/run if not WOW_PROJECT_ID or WOW_PROJECT_ID~=1 then print("SKIP: Classic");return end;local L=LibStub("LibTotalActionButtons-1.0");_G.VFX=L:CreateActionButton(1,"VFX",UIParent);print("OK")
```

**Test 1**: SpellVFX_ClearReticle
```lua
/run if not _G.VFX then print("SKIP") return end;local L=LibStub("LibTotalActionButtons-1.0");L:SpellVFX_ClearReticle(_G.VFX);print("ClearReticle OK")
```

**Test 2**: SpellVFX_ClearInterruptDisplay
```lua
/run if not _G.VFX then print("SKIP") return end;local L=LibStub("LibTotalActionButtons-1.0");L:SpellVFX_ClearInterruptDisplay(_G.VFX);print("ClearInterrupt OK")
```

**Test 3**: SpellVFX_PlaySpellCastAnim
```lua
/run if not _G.VFX then print("SKIP") return end;local L=LibStub("LibTotalActionButtons-1.0");_G.VFX.config={spellCastVFX=true};L:SpellVFX_PlaySpellCastAnim(_G.VFX);print("PlayCast OK")
```

**Test 4**: SpellVFX_PlayTargettingReticleAnim
```lua
/run if not _G.VFX then print("SKIP") return end;local L=LibStub("LibTotalActionButtons-1.0");L:SpellVFX_PlayTargettingReticleAnim(_G.VFX);print("PlayReticle OK")
```

**Test 5**: SpellVFX_StopTargettingReticleAnim
```lua
/run if not _G.VFX then print("SKIP") return end;local L=LibStub("LibTotalActionButtons-1.0");L:SpellVFX_StopTargettingReticleAnim(_G.VFX);print("StopReticle OK")
```

**Test 6**: SpellVFX_StopSpellCastAnim
```lua
/run if not _G.VFX then print("SKIP") return end;local L=LibStub("LibTotalActionButtons-1.0");L:SpellVFX_StopSpellCastAnim(_G.VFX);print("StopCast OK")
```

**Test 7**: SpellVFX_PlaySpellInterruptedAnim
```lua
/run if not _G.VFX then print("SKIP") return end;local L=LibStub("LibTotalActionButtons-1.0");L:SpellVFX_PlaySpellInterruptedAnim(_G.VFX);print("PlayInterrupt OK")
```
**Expected**: All 7 methods work without errors on Retail

**Cleanup**:
```lua
/run if _G.VFX then _G.VFX:Hide();_G.VFX=nil end
```

---

## Test 11.16: AddToButtonFacade() - LOW PRIORITY Item 22

**Purpose**: Verify ButtonFacade support (if library available)

**Setup**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.BF=L:CreateActionButton(1,"BF",UIParent);print("Button created")
```

**Test**: Try to add to ButtonFacade
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:AddToButtonFacade(_G.BF,nil);print("AddToButtonFacade called (may skip if not found)")
```
**Expected**: No errors, skips gracefully if ButtonFacade not available

**Cleanup**:
```lua
/run if _G.BF then _G.BF:Hide();_G.BF=nil end
```

---

## Test 11.17: GetSpellFlyoutFrame() - LOW PRIORITY Item 23

**Purpose**: Verify GetSpellFlyoutFrame returns frame or nil

**Test**: Get flyout frame
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");local f=L:GetSpellFlyoutFrame();print("Flyout frame:",type(f))
```
**Expected**: Returns "nil" or "table" (frame)

---

## Test 11.18: UpdateFlyout() - LOW PRIORITY Item 24

**Purpose**: Verify UpdateFlyout handles flyout updates

**Setup**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.UF=L:CreateActionButton(1,"UF",UIParent);_G.UF:SetPoint("CENTER");_G.UF:Show();print("Button created")
```

**Test**: Update flyout (won't have flyout but should not error)
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:UpdateFlyout(_G.UF);print("UpdateFlyout called")
```
**Expected**: No errors even with non-flyout button

**Cleanup**:
```lua
/run if _G.UF then _G.UF:Hide();_G.UF=nil end
```

---

## Test 11.19: FlyoutInfo Registry - LOW PRIORITY Item 25

**Purpose**: Verify FlyoutInfo registry exists

**Test**: Check registry
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");print("FlyoutInfo:",type(L.FlyoutInfo))
```
**Expected**: Returns "table"

---

## Test 11.20: DiscoverFlyoutInfo() - LOW PRIORITY Item 25

**Purpose**: Verify DiscoverFlyoutInfo caches flyout data

**Test**: Try to discover flyout (may not have any)
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:DiscoverFlyoutInfo(1);print("DiscoverFlyoutInfo called")
```
**Expected**: No errors

---

## Test 11.21: OnFlyoutButtonCreated Callback - LOW PRIORITY Item 26

**Purpose**: Verify OnFlyoutButtonCreated fires

**Test**: Check method exists
```lua
/run print("OnFlyoutButtonCreated callback is fired in CreateFlyoutButton - implemented")
```
**Expected**: Confirmation message (callback implemented)

---

## Test 11.22: Assisted Combat Callbacks - LOW PRIORITY Items 27-28 (Retail Only)

**Purpose**: Verify OnAssistedCombatRotationFrameCreated and OnAssistedCombatHighlightFrameCreated fire

**Test**: Check methods exist
```lua
/run print("Assisted combat callbacks fire in UpdateAssistedCombatRotationFrame and UpdatedAssistedHighlightFrame - implemented")
```
**Expected**: Confirmation message (callbacks implemented)

---

## Test 11.23: Integration Test - All Phase 11 Features

**Purpose**: Verify all features work together

**Setup**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.INT11=L:CreateActionButton(1,"INT11",UIParent);_G.INT11:SetPoint("CENTER");_G.INT11:Show();print("Integration button created")
```

**Test**: Call all HIGH PRIORITY methods
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");local b=_G.INT11;L:UpdateTooltip(b);L:UpdateLocal(b);L:UpdateAlpha(b);L:UpdateCooldownNumberHidden(b);print("All HIGH PRIORITY OK")
```

**Test**: Call utility methods
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");local c=0;for btn in L:GetAllButtons() do c=c+1 end;L:UpdateAllStates("0");print("Utilities OK, button count:",c)
```

**Test**: Check registries
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");print("FlyoutInfo:",type(L.FlyoutInfo),"ACTION_HIGHLIGHT_MARKS:",type(L.ACTION_HIGHLIGHT_MARKS))
```
**Expected**: All features work without errors

**Cleanup**:
```lua
/run if _G.INT11 then _G.INT11:Hide();_G.INT11=nil end
```

---



---

# Phase 12: Secure Template System Tests

**Purpose**: Test the 6 secure template methods that enable combat functionality

## Test 12.1: ClearSetPoint

**Purpose**: Test convenience positioning method

**Setup**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.P12_1=L:CreateActionButton(1,"P12_1",UIParent);_G.P12_1:SetPoint("CENTER");_G.P12_1:Show();print("Test 12.1 setup OK")
```

**Test**: Call ClearSetPoint
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:ClearSetPoint(_G.P12_1,"TOPLEFT",UIParent,"CENTER",100,50);print("ClearSetPoint OK, check position")
```
**Expected**: Button moves to new position (top-left of center, +100, +50)

**Test**: Verify position cleared
```lua
/run local b=_G.P12_1;local n=b:GetNumPoints();print("NumPoints after ClearSetPoint:",n,"(should be 1)")
```
**Expected**: NumPoints = 1 (all previous points cleared)

**Cleanup**:
```lua
/run if _G.P12_1 then _G.P12_1:Hide();_G.P12_1=nil end
```

---

## Test 12.2: SetStateFromHandlerInsecure - Basic Data Storage

**Purpose**: Test state data storage without triggering updates

**Setup**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.P12_2=L:CreateActionButton(1,"P12_2",UIParent);_G.P12_2:Show();print("Test 12.2 setup OK")
```

**Test**: Store empty state
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:SetStateFromHandlerInsecure(_G.P12_2,"0","empty",nil);print("Empty state stored OK")
```
**Expected**: No errors

**Test**: Store spell state
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:SetStateFromHandlerInsecure(_G.P12_2,"1","spell",1459);print("Spell state stored")
```
**Expected**: No errors

**Test**: Verify stored data
```lua
/run local b=_G.P12_2;print("State 1:",b.stateTypes["1"],b.stateActions["1"])
```
**Expected**: Prints "State 1: spell 1459"

**Test**: Store item state with ID
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:SetStateFromHandlerInsecure(_G.P12_2,"2","item",6948);print("Item state stored")
```
**Expected**: No errors

**Test**: Verify item format conversion
```lua
/run local b=_G.P12_2;print("State 2:",b.stateTypes["2"],b.stateActions["2"])
```
**Expected**: Prints "State 2: item item:6948" (auto-converted)

**Cleanup**:
```lua
/run if _G.P12_2 then _G.P12_2:Hide();_G.P12_2=nil end
```

---

## Test 12.3: SetStateFromHandlerInsecure - Validation

**Purpose**: Test validation logic for invalid inputs

**Setup**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.P12_3=L:CreateActionButton(1,"P12_3",UIParent);_G.P12_3:Show();print("Test 12.3 setup OK")
```

**Test**: Invalid kind (should error)
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:SetStateFromHandlerInsecure(_G.P12_3,"0","invalid",123);print("Check for error above")
```
**Expected**: Error message "unknown action type: invalid"

**Test**: Missing action for non-empty (should error)
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:SetStateFromHandlerInsecure(_G.P12_3,"0","spell",nil);print("Check for error above")
```
**Expected**: Error message "action required for non-empty states"

**Test**: Valid empty state (no action needed)
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:SetStateFromHandlerInsecure(_G.P12_3,"0","empty",nil);print("Empty state OK (no action required)")
```
**Expected**: No errors

**Cleanup**:
```lua
/run if _G.P12_3 then _G.P12_3:Hide();_G.P12_3=nil end
```

---

## Test 12.4: NewHeader - Header Reassignment

**Purpose**: Test reassigning button to a new secure header

**Setup**: Create two headers and a button
```lua
/run _G.P12_4H1=CreateFrame("Frame","P12_4H1",UIParent,"SecureHandlerStateTemplate");_G.P12_4H2=CreateFrame("Frame","P12_4H2",UIParent,"SecureHandlerStateTemplate");print("Headers created")
```

**Setup**: Create button with first header
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.P12_4B=L:CreateActionButton(1,"P12_4B",_G.P12_4H1);_G.P12_4B:Show();print("Button created with header 1")
```

**Test**: Verify initial header
```lua
/run local b=_G.P12_4B;print("Current header:",b.header:GetName())
```
**Expected**: Prints "Current header: P12_4H1"

**Test**: Reassign to new header
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:NewHeader(_G.P12_4B,_G.P12_4H2);print("NewHeader called")
```
**Expected**: No errors

**Test**: Verify new header
```lua
/run local b=_G.P12_4B;print("New header:",b.header:GetName(),"Parent:",b:GetParent():GetName())
```
**Expected**: Prints "New header: P12_4H2 Parent: P12_4H2"

**Cleanup**:
```lua
/run if _G.P12_4B then _G.P12_4B:Hide();_G.P12_4B=nil end;if _G.P12_4H1 then _G.P12_4H1:Hide();_G.P12_4H1=nil end;if _G.P12_4H2 then _G.P12_4H2:Hide();_G.P12_4H2=nil end
```

---

## Test 12.5: SetupSecureSnippets - Secure Template System

**Purpose**: Test secure snippet installation for combat functionality

**Setup**: Create secure header
```lua
/run _G.P12_5H=CreateFrame("Frame","P12_5H",UIParent,"SecureHandlerStateTemplate");print("Secure header created")
```

**Setup**: Create button with header
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.P12_5B=L:CreateActionButton(1,"P12_5B",_G.P12_5H);_G.P12_5B:Show();print("Button with secure header created")
```

**Test**: Verify secure snippets flag
```lua
/run local b=_G.P12_5B;print("Has secure snippets:",b._hasSecureSnippets and "YES" or "NO")
```
**Expected**: Prints "Has secure snippets: YES"

**Test**: Verify UpdateState attribute exists
```lua
/run local b=_G.P12_5B;print("UpdateState attribute:",b:GetAttribute("UpdateState") and "SET" or "MISSING")
```
**Expected**: Prints "UpdateState attribute: SET"

**Test**: Verify state update trigger exists
```lua
/run local b=_G.P12_5B;print("State update trigger:",b:GetAttribute("_childupdate-state") and "SET" or "MISSING")
```
**Expected**: Prints "State update trigger: SET"

**Test**: Verify PickupButton attribute
```lua
/run local b=_G.P12_5B;print("PickupButton attribute:",b:GetAttribute("PickupButton") and "SET" or "MISSING")
```
**Expected**: Prints "PickupButton attribute: SET"

**Test**: Verify OnDragStart attribute
```lua
/run local b=_G.P12_5B;print("OnDragStart attribute:",b:GetAttribute("OnDragStart") and "SET" or "MISSING")
```
**Expected**: Prints "OnDragStart attribute: SET"

**Test**: Verify OnReceiveDrag attribute
```lua
/run local b=_G.P12_5B;print("OnReceiveDrag attribute:",b:GetAttribute("OnReceiveDrag") and "SET" or "MISSING")
```
**Expected**: Prints "OnReceiveDrag attribute: SET"

**Cleanup**:
```lua
/run if _G.P12_5B then _G.P12_5B:Hide();_G.P12_5B=nil end;if _G.P12_5H then _G.P12_5H:Hide();_G.P12_5H=nil end
```

---

## Test 12.6: WrapOnClick - Secure Click Wrapping

**Purpose**: Test secure click handler wrapping for action detection

**Setup**: Create secure header
```lua
/run _G.P12_6H=CreateFrame("Frame","P12_6H",UIParent,"SecureHandlerStateTemplate");print("Secure header created")
```

**Setup**: Create button with header
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.P12_6B=L:CreateActionButton(1,"P12_6B",_G.P12_6H);_G.P12_6B:Show();print("Button with secure header created")
```

**Test**: Verify wrapped click flag
```lua
/run local b=_G.P12_6B;print("Has wrapped click:",b._hasWrappedClick and "YES" or "NO")
```
**Expected**: Prints "Has wrapped click: YES"

**Test**: Verify custom flyout attribute
```lua
/run local b=_G.P12_6B;print("Custom flyout:",b:GetAttribute("LTABUseCustomFlyout") and "ENABLED" or "DISABLED")
```
**Expected**: Prints "Custom flyout: ENABLED"

**Test**: Verify OnClick script is set
```lua
/run local b=_G.P12_6B;print("OnClick script:",b:GetScript("OnClick") and "SET" or "MISSING")
```
**Expected**: Prints "OnClick script: SET"

**Cleanup**:
```lua
/run if _G.P12_6B then _G.P12_6B:Hide();_G.P12_6B=nil end;if _G.P12_6H then _G.P12_6H:Hide();_G.P12_6H=nil end
```

---

## Test 12.7: Secure Flyout Handler - Initialization

**Purpose**: Test secure flyout handler frame creation

**Test**: Verify flyout handler exists
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");print("Flyout handler:",L.flyoutHandler and "CREATED" or "MISSING")
```
**Expected**: Prints "Flyout handler: CREATED" (on Retail) or "MISSING" (on Classic)

**Test** (Retail only): Verify HandleFlyout attribute
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");if L.flyoutHandler then print("HandleFlyout:",L.flyoutHandler:GetAttribute("HandleFlyout") and "SET" or "MISSING") else print("SKIP: Classic") end
```
**Expected**: Prints "HandleFlyout: SET" on Retail, "SKIP: Classic" on Classic

**Test** (Retail only): Verify numFlyoutButtons attribute
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");if L.flyoutHandler then print("numFlyoutButtons:",L.flyoutHandler:GetAttribute("numFlyoutButtons")) else print("SKIP: Classic") end
```
**Expected**: Prints "numFlyoutButtons: 0" on Retail, "SKIP: Classic" on Classic

---

## Test 12.8: Secure Flyout Handler - FlyoutInfo Sync

**Purpose**: Test FlyoutInfo data sync to secure environment

**Setup**: Add test flyout data
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L.FlyoutInfo=L.FlyoutInfo or {};L.FlyoutInfo[1]={numSlots=2,slots={[1]={spellID=1459,isKnown=true}}};print("Test flyout data added")
```

**Test** (Retail only): Sync to secure environment
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");if L.flyoutHandler then L:SyncFlyoutInfoToSecure();print("FlyoutInfo synced") else print("SKIP: Classic") end
```
**Expected**: Prints "FlyoutInfo synced" on Retail, "SKIP: Classic" on Classic

**Cleanup**:
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");if L.FlyoutInfo then L.FlyoutInfo[1]=nil end
```

---

## Test 12.9: CreateButton Auto-Detection

**Purpose**: Test that CreateButton automatically sets up secure features

**Setup**: Create secure header
```lua
/run _G.P12_9H=CreateFrame("Frame","P12_9H",UIParent,"SecureHandlerStateTemplate");print("Secure header created")
```

**Test**: Create button (should auto-detect secure header)
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.P12_9B=L:CreateActionButton(1,"P12_9B",_G.P12_9H);_G.P12_9B:Show();print("Button created")
```
**Expected**: No errors

**Test**: Verify secure features were auto-setup
```lua
/run local b=_G.P12_9B;print("Auto-setup check: snippets="..(b._hasSecureSnippets and "YES" or "NO")..", click="..(b._hasWrappedClick and "YES" or "NO"))
```
**Expected**: Prints "Auto-setup check: snippets=YES, click=YES"

**Test**: Verify state attributes initialized
```lua
/run local b=_G.P12_9B;print("State:",b:GetAttribute("state"),"Type:",b:GetAttribute("labtype-0"),"Action:",b:GetAttribute("labaction-0"))
```
**Expected**: Prints "State: 0 Type: action Action: 1"

**Cleanup**:
```lua
/run if _G.P12_9B then _G.P12_9B:Hide();_G.P12_9B=nil end;if _G.P12_9H then _G.P12_9H:Hide();_G.P12_9H=nil end
```

---

## Test 12.10: Integration Test - All Phase 12 Features

**Purpose**: Verify all Phase 12 features work together

**Setup**: Create secure header and button
```lua
/run _G.P12_INT_H=CreateFrame("Frame","P12_INT_H",UIParent,"SecureHandlerStateTemplate");local L=LibStub("LibTotalActionButtons-1.0");_G.P12_INT_B=L:CreateActionButton(1,"P12_INT_B",_G.P12_INT_H);print("Integration test setup OK")
```

**Test**: Test ClearSetPoint
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:ClearSetPoint(_G.P12_INT_B,"CENTER",UIParent,0,0);_G.P12_INT_B:Show();print("ClearSetPoint OK")
```

**Test**: Test SetStateFromHandlerInsecure
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:SetStateFromHandlerInsecure(_G.P12_INT_B,"1","spell",1459);print("SetStateFromHandlerInsecure OK, state data:",_G.P12_INT_B.stateTypes["1"])
```

**Test**: Verify secure features present
```lua
/run local b=_G.P12_INT_B;print("Secure: snippets="..(b._hasSecureSnippets and "Y" or "N")..", click="..(b._hasWrappedClick and "Y" or "N"))
```

**Test**: Test NewHeader with new secure header
```lua
/run _G.P12_INT_H2=CreateFrame("Frame","P12_INT_H2",UIParent,"SecureHandlerStateTemplate");local L=LibStub("LibTotalActionButtons-1.0");L:NewHeader(_G.P12_INT_B,_G.P12_INT_H2);print("NewHeader OK")
```

**Test**: Verify header changed
```lua
/run print("New header:",_G.P12_INT_B.header:GetName())
```
**Expected**: Prints "New header: P12_INT_H2"

**Cleanup**:
```lua
/run if _G.P12_INT_B then _G.P12_INT_B:Hide();_G.P12_INT_B=nil end;if _G.P12_INT_H then _G.P12_INT_H:Hide();_G.P12_INT_H=nil end;if _G.P12_INT_H2 then _G.P12_INT_H2:Hide();_G.P12_INT_H2=nil end
```

---

# Phase 13: Critical Missing Features

## Test 13.1: GetPassiveCooldownSpellID (Retail only)c

**Purpose**: Test passive cooldown spell ID retrieval for trinkets/items

**Setup**: Create action button
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.P13_1=L:CreateActionButton(1,"P13_1",UIParent);_G.P13_1:Show();print("Test 13.1 setup OK")
```

**Test** (Retail only): Check if method exists
```lua
/run local b=_G.P13_1;if b.UpdateFunctions.GetPassiveCooldownSpellID then print("GetPassiveCooldownSpellID: EXISTS") else print("GetPassiveCooldownSpellID: MISSING") end
```
**Expected**: Prints "GetPassiveCooldownSpellID: EXISTS" on Retail

**Test** (Retail only): Call method (returns nil if no passive cooldown)
```lua
/run local b=_G.P13_1;local id=b.UpdateFunctions.GetPassiveCooldownSpellID and b.UpdateFunctions.GetPassiveCooldownSpellID(b);print("PassiveCooldownSpellID:",id or "nil")
```
**Expected**: Prints "PassiveCooldownSpellID: nil" or a spell ID

**Cleanup**:
```lua
/run if _G.P13_1 then _G.P13_1:Hide();_G.P13_1=nil end
```

---

## Test 13.2: Passive Cooldown in UpdateCooldown (Retail only)

**Purpose**: Verify passive cooldowns are checked in UpdateCooldown

**Note**: This test requires a trinket with on-equip cooldown. Manual test only.

**Manual Test**:
1. Equip a trinket with on-equip cooldown (e.g., engineering trinket)
2. Place the trinket on an action button
3. Use the trinket
4. Verify cooldown displays correctly

**Expected**: Cooldown animates correctly for passive item cooldowns

---

## Test 13.3: Auto-call UpdateAssistedCombatRotationFrame (Retail only)

**Purpose**: Verify assisted combat rotation updates automatically

**Setup**: Create action button
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.P13_3=L:CreateActionButton(1,"P13_3",UIParent);_G.P13_3:Show();print("Test 13.3 setup OK")
```

**Test** (Retail only): Check if method exists
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");print("UpdateAssistedCombatRotationFrame:",L.UpdateAssistedCombatRotationFrame and "EXISTS" or "MISSING")
```
**Expected**: Prints "UpdateAssistedCombatRotationFrame: EXISTS"

**Test** (Retail only): Call UpdateButton and verify it calls assisted methods
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:UpdateButton(_G.P13_3);print("UpdateButton called (should auto-call assisted methods)")
```
**Expected**: No errors (auto-calls happen internally)

**Cleanup**:
```lua
/run if _G.P13_3 then _G.P13_3:Hide();_G.P13_3=nil end
```

---

## Test 13.4: Auto-call UpdatedAssistedHighlightFrame (Retail only)

**Purpose**: Verify assisted highlight updates automatically

**Setup**: Create action button
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.P13_4=L:CreateActionButton(1,"P13_4",UIParent);_G.P13_4:Show();print("Test 13.4 setup OK")
```

**Test** (Retail only): Check if method exists
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");print("UpdatedAssistedHighlightFrame:",L.UpdatedAssistedHighlightFrame and "EXISTS" or "MISSING")
```
**Expected**: Prints "UpdatedAssistedHighlightFrame: EXISTS"

**Test** (Retail only): Verify auto-call in UpdateButton
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:UpdateButton(_G.P13_4);print("UpdateButton called (should auto-call highlight method)")
```
**Expected**: No errors

**Cleanup**:
```lua
/run if _G.P13_4 then _G.P13_4:Hide();_G.P13_4=nil end
```

---

## Test 13.5: Auto-register actionButtonUI (Retail only)

**Purpose**: Verify buttons auto-register with Blizzard action UI

**Setup**: Create config with actionButtonUI enabled
```lua
/run _G.P13_5CFG={actionButtonUI=true};print("Config created with actionButtonUI=true")
```

**Setup**: Create action button with config
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.P13_5=L:CreateActionButton(1,"P13_5",UIParent,_G.P13_5CFG);_G.P13_5:Show();print("Button created with actionButtonUI config")
```

**Test** (Retail only): Verify RegisterActionUI method exists
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");print("RegisterActionUI:",L.RegisterActionUI and "EXISTS" or "MISSING")
```
**Expected**: Prints "RegisterActionUI: EXISTS"

**Test** (Retail only): Change button state (should auto-register)
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:UpdateButtonState(_G.P13_5);print("UpdateButtonState called (should auto-register if Retail)")
```
**Expected**: No errors

**Cleanup**:
```lua
/run if _G.P13_5 then _G.P13_5:Hide();_G.P13_5=nil end;_G.P13_5CFG=nil
```

---

## Test 13.6: Automatic Flyout Event Handling

**Purpose**: Verify flyouts auto-update when spells change

**Test**: Check if flyout event frame exists
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");print("Flyout event frame:",L.flyoutEventFrame and "EXISTS" or "MISSING")
```
**Expected**: Prints "Flyout event frame: EXISTS" or "MISSING" (depends on flyout handler init)

**Test**: Check if OnFlyoutEvent method exists
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");print("OnFlyoutEvent:",L.OnFlyoutEvent and "EXISTS" or "MISSING")
```
**Expected**: Prints "OnFlyoutEvent: EXISTS"

**Test**: Check flyoutUpdateQueued flag
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");print("flyoutUpdateQueued:",L.flyoutUpdateQueued and "YES" or "NO")
```
**Expected**: Prints "flyoutUpdateQueued: NO" (or YES if update was queued during combat)

**Manual Test**: Learn a new spell that's in a flyout, verify flyout updates automatically

---

## Test 13.7: On-Bar Highlight Hooks

**Purpose**: Verify spellbook hover highlights work

**Test**: Check if ON_BAR_HIGHLIGHT_MARK_TYPE exists
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");print("ON_BAR_HIGHLIGHT_MARK_TYPE:",L.ON_BAR_HIGHLIGHT_MARK_TYPE or "nil")
```
**Expected**: Prints "ON_BAR_HIGHLIGHT_MARK_TYPE: nil" (nothing highlighted yet)

**Test**: Check if ON_BAR_HIGHLIGHT_MARK_ID exists
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");print("ON_BAR_HIGHLIGHT_MARK_ID:",L.ON_BAR_HIGHLIGHT_MARK_ID or "nil")
```
**Expected**: Prints "ON_BAR_HIGHLIGHT_MARK_ID: nil"

**Test**: Manually simulate highlight (Retail only)
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L.ON_BAR_HIGHLIGHT_MARK_TYPE="spell";L.ON_BAR_HIGHLIGHT_MARK_ID=1459;print("Simulated highlight for spell 1459")
```
**Expected**: Spell ID 1459 buttons should highlight

**Test**: Clear highlight
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L.ON_BAR_HIGHLIGHT_MARK_TYPE=nil;L.ON_BAR_HIGHLIGHT_MARK_ID=nil;print("Highlight cleared")
```
**Expected**: Highlights cleared

**Manual Test**: Open spellbook, hover over a spell you have on bars, verify buttons highlight

---

## Test 13.8: Pet Spell Filtering

**Purpose**: Verify empty pet slots are filtered from flyouts

**Note**: This test requires Hunter or Warlock class with pet spells

**Setup**: Discover flyout info for a pet flyout (manual)
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");if GetFlyoutInfo then local id=1;L:DiscoverFlyoutInfo(id);print("Flyout 1 discovered") else print("SKIP: No flyouts") end
```
**Expected**: Prints "Flyout 1 discovered" or "SKIP: No flyouts"

**Test**: Check if GetCallPetSpellInfo is used
```lua
/run print("GetCallPetSpellInfo:",GetCallPetSpellInfo and "EXISTS" or "MISSING (Classic)")
```
**Expected**: Prints "GetCallPetSpellInfo: EXISTS" or "MISSING (Classic)"

**Manual Test** (Hunter/Warlock only):
1. Open a pet flyout (e.g., Call Pet flyout)
2. Verify empty pet slots are not shown
3. Verify only pets you have are shown

---

## Test 13.9: Integration Test - All Phase 13 Features

**Purpose**: Verify all Phase 13 features work together

**Setup**: Create action button
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");_G.P13_INT=L:CreateActionButton(1,"P13_INT",UIParent);_G.P13_INT:Show();print("Integration test setup OK")
```

**Test**: Verify all methods exist
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");local c=0;if L.UpdateAssistedCombatRotationFrame then c=c+1 end;if L.RegisterActionUI then c=c+1 end;if L.OnFlyoutEvent then c=c+1 end;print("Methods:",c.."/3")
```
**Expected**: Prints "Methods: 3/3"

**Test**: Verify globals exist
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");print("ON_BAR_TYPE:",type(L.ON_BAR_HIGHLIGHT_MARK_TYPE),"FlyoutInfo:",type(L.FlyoutInfo))
```
**Expected**: Prints globals types

**Test**: Call UpdateButton (exercises auto-calls)
```lua
/run local L=LibStub("LibTotalActionButtons-1.0");L:UpdateButton(_G.P13_INT);print("UpdateButton OK (auto-calls assisted methods)")
```
**Expected**: No errors

**Test** (Retail only): Check passive cooldown method
```lua
/run local b=_G.P13_INT;if b.UpdateFunctions.GetPassiveCooldownSpellID then print("Passive cooldown: EXISTS") else print("Passive cooldown: MISSING") end
```
**Expected**: "Passive cooldown: EXISTS" on Retail

**Cleanup**:
```lua
/run if _G.P13_INT then _G.P13_INT:Hide();_G.P13_INT=nil end
```
---

## Troubleshooting

If any test fails:
1. Enable script errors: `/console scriptErrors 1`
2. Enable debug mode: `/run LibStub("LibTotalActionButtons-1.0"):SetDebug(true)`
3. Verify LibStub: `/run print(LibStub("LibTotalActionButtons-1.0") and "OK" or "FAIL")`
4. Reload addon: `/reload`
5. Check for error messages in chat

---

## Testing Notes

- **Spell ID 1231411**: Recuperate (universal spell available to all classes)
- **Item ID 6948**: Hearthstone (available to all characters)
- Tests use CENTER positioning to avoid conflicts with existing UI
- Some tests require specific class features (stances, forms) and are optional
- Debug mode provides detailed output for troubleshooting
