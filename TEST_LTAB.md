# LibTotalActionButtons Test Suite

Comprehensive testing for all phases of LibTotalActionButtons implementation.

---

## Phase 1: Foundation & Core Systems

### Test 1.1: Verify LibStub Registration
```lua
/run local LAB = LibStub("LibTotalActionButtons-1.0", true); print("LibStub:", LAB and "SUCCESS" or "FAILED")
```

### Test 1.2: Check Version Detection
```lua
/run local LAB = LibStub("LibTotalActionButtons-1.0"); print("Version:", LAB.VERSION_STRING); print("WoW Type:", LAB.VERSION_INFO.detectedVersion)
```

### Test 1.3: Verify API Compatibility Wrappers
```lua
/run local LAB = LibStub("LibTotalActionButtons-1.0"); print("Retail APIs:", LAB.Compat.GetActionCharges and "Available" or "Wrapped"); print("C_ActionBar:", LAB.Compat.C_ActionBar and "OK" or "MISSING")
```

### Test 1.4: Enable Debug Mode
```lua
/run local LAB = LibStub("LibTotalActionButtons-1.0"); LAB:SetDebug(true)
```

### Test 1.5: Test Parameter Validation
**First, enable script errors**:
```lua
/console scriptErrors 1
```

**Then run the test**:
```lua
/run local LAB = LibStub("LibTotalActionButtons-1.0"); LAB:SetDebug(true); LAB:CreateButton(nil, "Test", UIParent)
```
**Expected**: RED Lua error message in chat: "LibTotalActionButtons: CreateButton: actionID is required!"

### Test 1.6: Test Button Creation
**Step 1: Clean up any existing test button**:
```lua
/run if _G.Phase1TestButton then _G.Phase1TestButton:Hide(); _G.Phase1TestButton:SetParent(nil); _G.Phase1TestButton = nil; end
```

**Step 2: Create the button**:
```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); LAB:SetDebug(true); _G.TestBtn = LAB:CreateButton(1, 'Phase1TestButton', UIParent)
```

**Step 3: Position and size the button**:
```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); if _G.TestBtn then _G.TestBtn:SetPoint('CENTER'); LAB:SetButtonSize(_G.TestBtn, 40, 40); _G.TestBtn:Show(); print('SUCCESS') else print('FAILED') end
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
/run local LAB = LibStub("LibTotalActionButtons-1.0"); for k,v in pairs(LAB.ButtonType) do print(k..":", v) end
```
**Expected**: Print all button types (ACTION, SPELL, ITEM, MACRO, CUSTOM, EMPTY)

### Test 2.2: Test Action Button
**Step 1: Create action button**:
```lua
/run local LAB = LibStub("LibTotalActionButtons-1.0"); LAB:SetDebug(true); _G.TestActionBtn = LAB:CreateButton(1, "Phase2ActionButton", UIParent)
```

**Step 2: Position and verify**:
```lua
/run local LAB = LibStub("LibTotalActionButtons-1.0"); local btn = _G.TestActionBtn; if btn then btn:SetPoint("CENTER", -150, 0); LAB:SetButtonSize(btn, 40, 40); btn:Show(); print("Type:", btn.buttonType); print("Has UpdateFunctions:", btn.UpdateFunctions and "YES" or "NO") else print("FAILED") end
```

**Expected**: Button at left-center, Type: "action", Has UpdateFunctions: YES

### Test 2.3: Test Spell Button
**Step 1: Create spell button**:
```lua
/run local LAB = LibStub("LibTotalActionButtons-1.0"); LAB:SetDebug(true); _G.TestSpellBtn = LAB:CreateSpellButton(1231411, "Phase2SpellButton", UIParent)
```

**Step 2: Position and size**:
```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); local btn = _G.TestSpellBtn; if btn then btn:SetPoint('CENTER', -50, 0); LAB:SetButtonSize(btn, 40, 40); btn:Show() end
```

**Step 3: Verify**:
```lua
/run local btn = _G.TestSpellBtn; if btn then print('Type:', btn.buttonType); print('SpellID:', btn.buttonAction) else print('FAILED') end
```

**Expected**: Shows spell icon, Type: "spell", SpellID: 1231411

### Test 2.4: Test Item Button (Hearthstone)
**Step 1: Create item button**:
```lua
/run local LAB = LibStub("LibTotalActionButtons-1.0"); LAB:SetDebug(true); _G.TestItemBtn = LAB:CreateItemButton(6948, "Phase2ItemButton", UIParent)
```

**Step 2: Position and verify**:
```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); local btn = _G.TestItemBtn; if btn then btn:SetPoint("CENTER", 50, 0); LAB:SetButtonSize(btn, 40, 40); btn:Show(); print("Type:", btn.buttonType); print("ItemID:", btn.buttonAction) end
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
/run local LAB = LibStub("LibTotalActionButtons-1.0"); if GetNumMacros() > 0 then LAB:SetDebug(true); _G.TestMacroBtn = LAB:CreateMacroButton(1, "Phase2MacroButton", UIParent); local btn = _G.TestMacroBtn; btn:SetPoint("CENTER", 150, 0); LAB:SetButtonSize(btn, 40, 40); btn:Show(); print("Type:", btn.buttonType) else print("No macros available") end
```

**Expected** (if macros exist): Shows macro icon, Type: "macro"

### Test 2.6: Test Custom Button Type
**Step 1: Create custom UpdateFunctions**:
```lua
/run _G.CustomUpdateFuncs = { HasAction = function() return true end, GetActionTexture = function() return "Interface\\Icons\\INV_Misc_QuestionMark" end, GetActionText=function() return "Custom" end, GetActionCount=function() return 0 end, GetActionCharges=function() return nil end, IsInRange=function() return nil end, IsUsableAction=function() return true,false end, IsCurrentAction=function() return false end, IsAutoRepeatAction=function() return false end, IsAttackAction=function() return false end, IsEquippedAction=function() return false end, IsConsumableAction=function() return false end, GetCooldown=function() return 0,0,0 end, GetLossOfControlCooldown=function() return nil end, GetSpellId=function() return nil end }
```

**Step 2: Create custom button**:
```lua
/run local LAB = LibStub("LibTotalActionButtons-1.0"); LAB:SetDebug(true); _G.TestCustomBtn = LAB:CreateCustomButton(999, "Phase2CustomButton", UIParent, nil, _G.CustomUpdateFuncs); local btn = _G.TestCustomBtn; btn:SetPoint("CENTER", 0, -80); LAB:SetButtonSize(btn, 40, 40); btn:Show(); print("Type:", btn.buttonType)
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
/run local LAB = LibStub("LibTotalActionButtons-1.0"); LAB:SetDebug(true); _G.TestStateBtn = LAB:CreateButton(1, "Phase3StateButton", UIParent); local btn = _G.TestStateBtn; btn:SetPoint("CENTER"); LAB:SetButtonSize(btn, 44, 44); btn:Show()
```

**Step 2: Set up multiple states**:
```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); local btn = _G.TestStateBtn; LAB:SetState(btn, 0, "action", 1); LAB:SetState(btn, 1, "spell", 1231411); LAB:SetState(btn, 2, "item", 6948); print("Configured 3 states")
```

**Step 3: Test state switching**:
```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); LAB:UpdateState(_G.TestStateBtn, 0); print("State 0 - action slot 1")
```

```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); LAB:UpdateState(_G.TestStateBtn, 1); print("State 1 - spell")
```

```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); LAB:UpdateState(_G.TestStateBtn, 2); print("State 2 - hearthstone")
```

**Expected**: Button changes icon when switching states (action → spell → item)

### Test 3.2: Query State Information
**Get current state**:
```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); local state = LAB:GetState(_G.TestStateBtn); print("Current state:", state)
```

**Get specific state info**:
```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); local type, action = LAB:GetState(_G.TestStateBtn, 1); print("State 1:", type, action)
```

**Expected**: Returns correct state numbers and configured types/actions

### Test 3.3: State Fallback Behavior
**Switch to undefined state**:
```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); LAB:UpdateState(_G.TestStateBtn, 99); local type, action = LAB:GetAction(_G.TestStateBtn); print("Fallback shows:", type, action)
```

**Expected**: Falls back to state 0 (action 1)

### Test 3.4: Clear States
**Clear all states**:
```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); LAB:ClearStates(_G.TestStateBtn); local btn = _G.TestStateBtn; print("State 0:", btn.stateTypes["0"] or "nil"); print("State 1:", btn.stateTypes["1"] or "nil")
```

**Expected**: State tables are empty

### Test 3.5: Paging Support
**Create and configure paging button**:
```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); _G.TestPageBtn = LAB:CreateButton(1, "Phase3PageButton", UIParent); local btn = _G.TestPageBtn; btn:SetPoint("CENTER", -100, 0); LAB:SetButtonSize(btn, 44, 44); btn:Show(); for i=1,6 do LAB:SetState(btn, tostring(i), "action", i) end; LAB:EnablePaging(btn, true); print("Paging enabled with 6 states")
```

**Test page changes**:
```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); LAB:OnPageChanged(2); print("Page 2")
```

```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); LAB:OnPageChanged(3); print("Page 3")
```

**Expected**: Button updates icon when page changes

### Test 3.6: Mixed Button Types in States
**Create button with mixed types**:
```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); _G.TestMixedBtn = LAB:CreateButton(1, "Phase3MixedButton", UIParent); local btn = _G.TestMixedBtn; btn:SetPoint("CENTER", 0, -100); LAB:SetButtonSize(btn, 44, 44); btn:Show(); LAB:SetState(btn, "0", "action", 1); LAB:SetState(btn, "1", "spell", 1231411); LAB:SetState(btn, "2", "item", 6948); print("Mixed states configured")
```

**Test state 0 (action)**:
```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); LAB:UpdateState(_G.TestMixedBtn, "0"); print("State 0 - click to test action")
```
**Click the button - should use action slot**

**Test state 1 (spell)**:
```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); LAB:UpdateState(_G.TestMixedBtn, "1"); print("State 1 - click to test spell")
```
**Click the button - should cast Recuperate**

**Test state 2 (item)**:
```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); LAB:UpdateState(_G.TestMixedBtn, "2"); print("State 2 - click to test item")
```
**Click the button - should use hearthstone**

**Expected**: Visual updates AND click behavior changes for each state

### Test 3.7: Cleanup Phase 3 Buttons
```lua
/run local buttons = {"TestStateBtn", "TestPageBtn", "TestStanceBtn", "TestMixedBtn"}; for _, name in ipairs(buttons) do local btn = _G[name]; if btn then btn:Hide(); btn:SetParent(nil); _G[name] = nil; print("Removed "..name) end end
```

---

## Expected Results Summary

### Phase 1
✅ LibStub registration works
✅ Version detection correct
✅ API wrappers present
✅ Parameter validation produces clear errors
✅ Buttons create successfully
✅ All button elements present

### Phase 2
✅ All button types available
✅ Action, Spell, Item, Macro buttons functional
✅ Custom buttons accept UpdateFunctions
✅ All buttons have correct buttonType
✅ Buttons clickable and functional

### Phase 3
✅ States set and queried correctly
✅ Button switches between states
✅ State fallback works
✅ Clear states resets button
✅ Paging support functional
✅ Mixed button types work
✅ Click behavior changes with state

### Phase 4 (Retail features may not apply to Classic)
✅ Charge cooldowns display separately
✅ Proc glows show/hide correctly
✅ New action highlights appear
✅ Equipped items show green border
✅ LoC cooldowns show red swipe

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
/run local LAB = LibStub("LibTotalActionButtons-1.0"); LAB.RegisterCallback(_G.TestCallbacks, "OnButtonCreated", "OnCreated"); print("Callback registered")
```

**Expected**:
- Message confirms callback registered
- No errors

### Test OnButtonCreated callback

**Script**:
```lua
/run local LAB = LibStub("LibTotalActionButtons-1.0"); local btn = LAB:CreateButton(5, "TestButton7_1", UIParent); btn:SetSize(36, 36); btn:SetPoint("CENTER", 0, 0); btn:Show(); _G.T71 = btn; print("Button created")
```

**Expected**:
- Message "Callback: OnButtonCreated" appears from the callback registered above
- Button visible at center of screen

**Cleanup**:
```lua
/run if _G.T71 then _G.T71:Hide();_G.T71:SetParent(nil);_G.T71=nil end; local LAB=LibStub("LibTotalActionButtons-1.0"); LAB.UnregisterCallback(_G.TestCallbacks,"OnButtonCreated"); _G.TestCallbacks=nil
```

### Test OnButtonUpdate callback

**Create callback and register**:
```lua
/run local LAB = LibStub("LibTotalActionButtons-1.0"); _G.UpdateCount = 0; _G.TestCB2 = {}; _G.TestCB2.OnUpdate = function(self, event, button) _G.UpdateCount = _G.UpdateCount + 1 end; LAB.RegisterCallback(_G.TestCB2, "OnButtonUpdate", "OnUpdate")
```

**Create button**:
```lua
/run local LAB = LibStub("LibTotalActionButtons-1.0"); local btn = LAB:CreateButton(1, "TestButton7_1b", UIParent); btn:SetSize(36, 36); btn:SetPoint("CENTER", 0, 0); btn:Show(); _G.T71b = btn; print("Update callbacks: " .. _G.UpdateCount)
```

**Expected**:
- Message shows update count > 0 (at least 1 from initial update)
- Button visible

**Cleanup**:
```lua
/run if _G.T71b then _G.T71b:Hide();_G.T71b:SetParent(nil);_G.T71b=nil end; local LAB=LibStub("LibTotalActionButtons-1.0"); LAB.UnregisterCallback(_G.TestCB2,"OnButtonUpdate"); _G.UpdateCount=nil; _G.TestCB2=nil
```

### Test OnButtonContentsChanged callback

**Create callback**:
```lua
/run _G.TestCB3 = {}; _G.TestCB3.OnChange = function(self, event, button) print("Contents changed!") end; local LAB = LibStub("LibTotalActionButtons-1.0"); LAB.RegisterCallback(_G.TestCB3, "OnButtonContentsChanged", "OnChange")
```

**Create button**:
```lua
/run local LAB = LibStub("LibTotalActionButtons-1.0"); local btn = LAB:CreateButton(1, "TestButton7_1c", UIParent); btn:SetSize(36, 36); btn:SetPoint("CENTER", 0, 0); btn:Show(); _G.T71c = btn
```

**Expected**:
- Button visible with action 1 contents
- Try removing/adding an ability to action slot 1 to trigger callback

**Cleanup**:
```lua
/run if _G.T71c then _G.T71c:Hide();_G.T71c:SetParent(nil);_G.T71c=nil end; local LAB=LibStub("LibTotalActionButtons-1.0"); LAB.UnregisterCallback(_G.TestCB3,"OnButtonContentsChanged"); _G.TestCB3=nil
```

### Test OnButtonEnter/Leave callbacks

**Create callback object**:
```lua
/run _G.TestCB4 = {}; _G.TestCB4.OnEnter = function(self, event, button) print("Mouse entered") end; _G.TestCB4.OnLeave = function(self, event, button) print("Mouse left") end
```

**Register callbacks**:
```lua
/run local LAB = LibStub("LibTotalActionButtons-1.0"); LAB.RegisterCallback(_G.TestCB4, "OnButtonEnter", "OnEnter"); LAB.RegisterCallback(_G.TestCB4, "OnButtonLeave", "OnLeave")
```

**Create button**:
```lua
/run local LAB = LibStub("LibTotalActionButtons-1.0"); local btn = LAB:CreateButton(1, "TestButton7_1d", UIParent); btn:SetSize(36, 36); btn:SetPoint("CENTER", 0, 0); btn:Show(); _G.T71d = btn
```

**Expected**:
- Button visible
- Moving mouse over button prints "Mouse entered"
- Moving mouse away prints "Mouse left"

**Cleanup**:
```lua
/run if _G.T71d then _G.T71d:Hide();_G.T71d:SetParent(nil);_G.T71d=nil end; local LAB=LibStub("LibTotalActionButtons-1.0"); LAB.UnregisterCallback(_G.TestCB4,"OnButtonEnter"); LAB.UnregisterCallback(_G.TestCB4,"OnButtonLeave"); _G.TestCB4=nil
```

### Test OnButtonStateChanged callback

**Create callback object**:
```lua
/run _G.TestCB5 = {}; _G.TestCB5.OnStateChange = function(self, event, button, newState, oldState) print("State: " .. tostring(oldState) .. " -> " .. tostring(newState)) end
```

**Register callback**:
```lua
/run local LAB = LibStub("LibTotalActionButtons-1.0"); LAB.RegisterCallback(_G.TestCB5, "OnButtonStateChanged", "OnStateChange")
```

**Create button and set state 0**:
```lua
/run local LAB = LibStub("LibTotalActionButtons-1.0"); local btn = LAB:CreateButton(1, "TestButton7_1e", UIParent); btn:SetSize(36, 36); btn:SetPoint("CENTER", 0, 0); LAB:SetState(btn, "0", "action", 1); btn:Show(); _G.T71e = btn
```

**Expected**:
- Button visible with action slot 1

**Enable debug mode**:
```lua
/run local LAB = LibStub("LibTotalActionButtons-1.0"); LAB:SetDebug(true)
```

**Set state 1 and change state**:
```lua
/run local LAB = LibStub("LibTotalActionButtons-1.0"); LAB:SetState(_G.T71e, "1", "spell", 133); LAB:UpdateState(_G.T71e, "1")
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
/run if _G.T71e then _G.T71e:Hide();_G.T71e:SetParent(nil);_G.T71e=nil end; local LAB=LibStub("LibTotalActionButtons-1.0"); LAB:SetDebug(false); LAB.UnregisterCallback(_G.TestCB5,"OnButtonStateChanged"); _G.TestCB5=nil
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
/run local LAB = LibStub("LibTotalActionButtons-1.0"); local btn = LAB:CreateButton(1, "TestButton7_2", UIParent); btn:SetSize(36, 36); btn:SetPoint("CENTER", 0, 0); btn:Show(); LAB:AddToMasque(btn); _G.T72 = btn
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
/run if _G.T72 then local LAB = LibStub("LibTotalActionButtons-1.0"); LAB:RemoveFromMasque(_G.T72); _G.T72:Hide(); _G.T72:SetParent(nil); _G.T72=nil end
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
/run local LAB = LibStub("LibTotalActionButtons-1.0"); _G.T73 = LAB:CreateButton(1, "TestButton7_3", UIParent); _G.T73:SetSize(36, 36); _G.T73:SetPoint("CENTER", 0, 0); _G.T73:Show()
```

**Enable LibKeyBound**:
```lua
/run local LAB = LibStub("LibTotalActionButtons-1.0"); LAB:EnableKeyBound(_G.T73); print("LibKeyBound enabled: " .. tostring(_G.T73._libKeyBoundEnabled))
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
/run if _G.T73 then local LAB = LibStub("LibTotalActionButtons-1.0"); LAB:DisableKeyBound(_G.T73); _G.T73:Hide(); _G.T73:SetParent(nil); _G.T73=nil end
```

---

## Test 7.4: Action UI Registration (Retail Only)

**Note**: The `C_ActionBar.SetActionUIButton` API was removed or never publicly available in modern Retail WoW. This test verifies the graceful fallback behavior.

### Test Action UI registration availability

**Script**:
```lua
/run local LAB = LibStub("LibTotalActionButtons-1.0"); if LAB.WoWRetail and C_ActionBar and C_ActionBar.SetActionUIButton then print("Action UI registration available") else print("Action UI registration not available (Classic or API missing)") end
```

**Expected**:
- Message shows "Action UI registration not available (Classic or API missing)"
- This is normal - the API is not publicly available in current WoW versions

### Test registering action button (verifies graceful fallback)

**Create button**:
```lua
/run local LAB = LibStub("LibTotalActionButtons-1.0"); _G.T74 = LAB:CreateButton(1, "TestButton7_4", UIParent); _G.T74:SetSize(36, 36); _G.T74:SetPoint("CENTER", 0, 0); _G.T74:Show()
```

**Register with Action UI system**:
```lua
/run local LAB = LibStub("LibTotalActionButtons-1.0"); LAB:RegisterActionUI(_G.T74); print("Action UI registered: " .. tostring(_G.T74._actionUIRegistered))
```

**Expected**:
- Button visible and functional
- Message shows "Action UI registered: nil" (API not available)
- No errors - RegisterActionUI gracefully returns when API missing
- Button works normally even without registration

**Cleanup**:
```lua
/run if _G.T74 then local LAB = LibStub("LibTotalActionButtons-1.0"); LAB:UnregisterActionUI(_G.T74); _G.T74:Hide(); _G.T74:SetParent(nil); _G.T74=nil end
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
