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
