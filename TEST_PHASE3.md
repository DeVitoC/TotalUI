# Phase 3 Testing Script - State Management System

## In-Game Test Commands

Copy and paste these commands into WoW to test Phase 3 implementation (State Management):

### Test 1: Basic State Setup and Switching
**Step 1: Create button**:
```lua
/run local LAB = LibStub("LibTotalActionButtons-1.0"); LAB:SetDebug(true); _G.TestStateBtn = LAB:CreateButton(1, "Phase3StateButton", UIParent)
```

**Step 2: Position and size**:
```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); local btn = _G.TestStateBtn; if btn then btn:SetPoint("CENTER"); LAB:SetButtonSize(btn, 44, 44); btn:Show() end
```

**Step 3: Set up multiple states**:
```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); local btn = _G.TestStateBtn; LAB:SetState(btn, 0, "action", 1); print("State 0 set to action 1")
```

```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); local btn = _G.TestStateBtn; LAB:SetState(btn, 1, "spell", 1231411); print("State 1 set to spell")
```

```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); local btn = _G.TestStateBtn; LAB:SetState(btn, 2, "item", 6948); print("State 2 set to item (hearthstone)")
```

**Step 4: Test state switching**:
```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); LAB:UpdateState(_G.TestStateBtn, 0); print("Switched to state 0 - should show action 1")
```

```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); LAB:UpdateState(_G.TestStateBtn, 1); print("Switched to state 1 - should show spell")
```

```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); LAB:UpdateState(_G.TestStateBtn, 2); print("Switched to state 2 - should show hearthstone")
```

**Expected**:
- Button changes icon and type when switching states
- State 0 shows action bar slot 1 icon
- State 1 shows spell icon
- State 2 shows hearthstone icon

---

### Test 2: Query State Information
**Step 1: Get current state**:
```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); local state = LAB:GetState(_G.TestStateBtn); print("Current state:", state)
```

**Step 2: Get specific state info**:
```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); local type, action = LAB:GetState(_G.TestStateBtn, 1); print("State 1:", type, action)
```

```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); local type, action = LAB:GetState(_G.TestStateBtn, 2); print("State 2:", type, action)
```

**Step 3: Get action for current state**:
```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); local type, action = LAB:GetAction(_G.TestStateBtn); print("Current action:", type, action)
```

**Expected**:
- Current state returns the active state number
- Querying specific states returns their type and action
- GetAction returns the current state's type and action

---

### Test 3: State Fallback Behavior
**Step 1: Switch to undefined state**:
```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); LAB:UpdateState(_G.TestStateBtn, 99); print("Switched to undefined state 99")
```

**Step 2: Check what shows**:
```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); local type, action = LAB:GetAction(_G.TestStateBtn); print("Shows:", type, action)
```

**Expected**:
- Should fall back to state 0 (action 1)
- Button still displays something (not empty)

---

### Test 4: Clear States
**Step 1: Clear all states**:
```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); LAB:ClearStates(_G.TestStateBtn); print("Cleared all states")
```

**Step 2: Verify cleared**:
```lua
/run local btn = _G.TestStateBtn; print("State 0:", btn.stateTypes and btn.stateTypes["0"] or "nil"); print("State 1:", btn.stateTypes and btn.stateTypes["1"] or "nil")
```

**Expected**:
- State tables are empty
- Button resets to default appearance

---

### Test 5: Paging Support
**Step 1: Create new button with paging states**:
```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); _G.TestPageBtn = LAB:CreateButton(1, "Phase3PageButton", UIParent); local btn = _G.TestPageBtn; btn:SetPoint("CENTER", -100, 0); LAB:SetButtonSize(btn, 44, 44); btn:Show()
```

**Step 2: Configure page states (set up 6 pages)**:
```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); local btn = _G.TestPageBtn; for i=1,6 do LAB:SetState(btn, tostring(i), "action", i) end; print("Configured 6 page states")
```

**Step 3: Enable paging**:
```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); LAB:EnablePaging(_G.TestPageBtn, true); print("Paging enabled")
```

**Step 4: Manually change page (simulated)**:
```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); LAB:OnPageChanged(2); print("Simulated page change to 2")
```

```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); LAB:OnPageChanged(3); print("Simulated page change to 3")
```

**Expected**:
- Button updates when page changes
- Shows correct action for each page

---

### Test 6: Stance Support (Class-Dependent)
**Note**: This test requires a class with stances (Warrior, Druid, Priest, etc.)

**Step 1: Create stance button**:
```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); _G.TestStanceBtn = LAB:CreateButton(1, "Phase3StanceButton", UIParent); local btn = _G.TestStanceBtn; btn:SetPoint("CENTER", 100, 0); LAB:SetButtonSize(btn, 44, 44); btn:Show()
```

**Step 2: Configure stance states**:
```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); local btn = _G.TestStanceBtn; LAB:SetState(btn, "0", "action", 1); LAB:SetState(btn, "1", "action", 13); LAB:SetState(btn, "2", "action", 25); print("Configured stance states")
```

**Step 3: Enable stance switching**:
```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); LAB:EnableStanceState(_G.TestStanceBtn, true); print("Stance switching enabled")
```

**Step 4: Change stance and test**:
- Change your stance/form in-game
- Run this to manually trigger update:
```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); LAB:OnStanceChanged(); print("Stance changed")
```

**Expected** (if you have stances):
- Button updates when stance changes
- Shows correct action for current stance

---

### Test 7: Mixed Button Types in States
**Step 1: Create button with mixed types**:
```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); _G.TestMixedBtn = LAB:CreateButton(1, "Phase3MixedButton", UIParent); local btn = _G.TestMixedBtn; btn:SetPoint("CENTER", 0, -100); LAB:SetButtonSize(btn, 44, 44); btn:Show()
```

**Step 2: Set up different types**:
```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); local btn = _G.TestMixedBtn; LAB:SetState(btn, "0", "action", 1)
```

```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); local btn = _G.TestMixedBtn; LAB:SetState(btn, "1", "spell", 1231411)
```

```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); local btn = _G.TestMixedBtn; LAB:SetState(btn, "2", "item", 6948)
```

**Step 3a: Switch to state 0 (action)**:
```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); LAB:UpdateState(_G.TestMixedBtn, "0"); print("State 0 - should show action slot 1")
```

**Step 3b: Click the button** - it should use whatever is in action slot 1

**Step 3c: Switch to state 1 (spell)**:
```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); LAB:UpdateState(_G.TestMixedBtn, "1"); print("State 1 - should show spell")
```

**Step 3d: Click the button** - it should cast the Recuperate spell

**Step 3e: Switch to state 2 (item)**:
```lua
/run local LAB = LibStub('LibTotalActionButtons-1.0'); LAB:UpdateState(_G.TestMixedBtn, "2"); print("State 2 - should show hearthstone")
```

**Step 3f: Click the button** - it should use your hearthstone

**Expected**:
- State 0: Shows action slot icon, uses action when clicked
- State 1: Shows spell icon, casts spell when clicked
- State 2: Shows hearthstone icon, uses hearthstone when clicked

---

### Test 8: Cleanup All Phase 3 Buttons
```lua
/run local buttons = {"TestStateBtn", "TestPageBtn", "TestStanceBtn", "TestMixedBtn"}; for _, name in ipairs(buttons) do local btn = _G[name]; if btn then btn:Hide(); btn:SetParent(nil); _G[name] = nil; print("Removed "..name) end end
```

**Expected**: All test buttons removed

---

## Expected Results

✅ **States can be set and queried**
✅ **Button switches between states correctly**
✅ **State fallback to state 0 works**
✅ **Clear states resets button**
✅ **Paging support functional**
✅ **Stance support functional** (class-dependent)
✅ **Mixed button types work in different states**
✅ **No Lua errors during state operations**

## Troubleshooting

If any test fails:
1. Check for Lua errors: `/console scriptErrors 1`
2. Verify debug output is showing
3. Check button exists: `/run print(_G.TestStateBtn)`
4. Verify state system: `/run local btn=_G.TestStateBtn; if btn then for k,v in pairs(btn.stateTypes or {}) do print("State", k, v, btn.stateActions[k]) end end`

## Phase 3 Completion Checklist

- [ ] Basic state setup and switching works
- [ ] State queries return correct information
- [ ] State fallback behavior correct
- [ ] Clear states works
- [ ] Paging support functional
- [ ] Stance support functional (if applicable)
- [ ] Mixed button types in states work
- [ ] No Lua errors
- [ ] All tests passing

Once all tests pass, Phase 3 is complete and we can proceed to Phase 4 (Visual Enhancements)!
