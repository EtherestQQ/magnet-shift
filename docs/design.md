# Magnet Shift

Second independent Godot portfolio prototype, mechanically distinct from Aether Dash. The owner requested another mechanic and previously delegated implementation decisions end to end.

Hold E to latch a highlighted magnetic anchor; radial acceleration pulls the player toward it while gravity and tangential momentum remain active. Release E to carry the current velocity into a jump. Magnetic attraction is not a rope constraint or a teleport. Anchors have a finite range and solid scenery blocks targeting.

One compact industrial course, three main gaps, three collectible energy cores, and an exit that unlocks after collection. A/D moves along the course, W/S adjusts depth, Space jumps. Air control is weaker than grounded control. Auto-selection favors a visible anchor ahead; the current anchor remains fixed while holding E. Fall/R resets the complete run. Escape pauses; reduced motion option; no dash, double jump, combat, checkpoint or account services.

Visual direction: warm brass gantries against teal fog, mint magnetic anchors, orange power cores, a visible attraction beam and simple mechanical scenery. Camera presents a three-quarter side view so acceleration, swing and release are readable. English UI for the portfolio audience.

Acceptance: attachment only within range and line of sight; holding attraction changes velocity toward anchor; release itself preserves velocity; restart clears target/momentum/progress; all cores required; airborne entry at exit wins; pause/restart input remains usable; real-input physics replay completes the course; independent Windows build starts and renders without missing dependencies.

Use a separate project and user-data namespace. Preserve Aether Dash and its published repository. Reuse only Kenney character/animation/sounds with credits. Work is AI-assisted and must be described honestly. No public publication of this prototype until reviewed.
