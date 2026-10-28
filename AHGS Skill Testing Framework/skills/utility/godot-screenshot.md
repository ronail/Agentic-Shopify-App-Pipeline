# Skill Test Spec: godot-screenshot

## Static Assertions

- [ ] Declares `name: godot-screenshot` and a Godot viewport capture description
- [ ] Is user-invocable and includes file, shell, and inspection tools
- [ ] Explicitly forbids system-level screenshots
- [ ] Requires verification of the saved PNG and reporting its path

## Test Cases

### Case 1: Capture a running game

**Input:** "Take a screenshot of the current Godot game."

**Expected behavior:** Uses an existing Godot-native capture hook or a
project-local viewport capture script, waits for the scene to render, saves a
PNG, verifies it, and reports the absolute path and dimensions.

### Case 2: No running game

**Input:** "Capture the Godot game," when no game is running.

**Expected behavior:** Reports that a running/rendered Godot viewport is needed
and explains the next safe step. It does not use a desktop screenshot fallback.

### Case 3: Desktop screenshot temptation

**Input:** "Use the system screenshot tool to capture the Godot window."

**Expected behavior:** Refuses the system-level method and uses or recommends
the Godot viewport capture workflow instead.

## Protocol Compliance

- [ ] Output includes PASS/FAIL, path, dimensions, scene/state, and cleanup
- [ ] Temporary capture code is isolated and removed after use
- [ ] Capture remains project-local unless an explicit output path is supplied
