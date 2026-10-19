# Magnet Shift implementation plan

Goal: deliver a small Windows prototype demonstrating attraction, momentum and release timing.
Spec: docs/design.md. Tech: Godot 4.7.2 / GDScript / Compatibility renderer.

- [x] Controller: tests reproduced absent attraction and early-held-input issue; final tests pass.
- [x] Course: three gaps, anchors, cores, receiver, camera, UI and audio; state and airborne-win tests pass.
- [x] Tune: input-only replay completes course; rendered frames inspected; independent review issues corrected.
- [x] Deliver: standalone Windows startup and render checked; source archive, credits, instructions and 30-second clip prepared.

Rulings: attraction is an acceleration field rather than a rope constraint. Held E auto-acquires when entering valid range; an existing latch stays fixed until release or obstruction/range loss. Solid foreground supports use physics bodies; skyline remains decorative. Target rays stop at the field surface to avoid its own hanging rod. Human difficulty/feel is left for the owner's playtest.

Review focus: never snap or reset momentum on release; no targeting through solids; no changing target silently while latched; no floor requirement at exit; restart cancels beam and collected-core effects; tests must not pollute human best-time records.

Execution: inline under the owner's existing end-to-end delegation; review after a playable vertical slice. Separate copied workspace, no edits to the first prototype.
