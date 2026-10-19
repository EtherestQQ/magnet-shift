# Verification — 19 October 2026

Engine: Godot 4.7.2, Compatibility renderer. Windows x86-64.

Controller tests: radial acceleration; exact velocity unchanged by release itself; range rejection; solid obstruction rejection; held E acquires when entering range; own hanger does not incorrectly block the field surface; reset clears field and velocity.

Course tests: actual body overlap collects once; reset restores cores/progress/timer/momentum; foreground gantry has collision; pause freezes time; Escape resumes; R restarts while paused; receiver accepts a player moving through it in the air after all cores; win clears beam; restart after win restores controls.

Input-only replay: all three cores acquired and all gaps crossed using movement, jump, attraction and release. First two platforms landed; final receiver accepts airborne entry. Approximately 9.05 seconds. No player position/velocity overrides during traversal.

Windows export starts with exit code 0. The exported executable also recorded a startup movie without missing-resource errors. Character, texture and UI were inspected from that movie. Source gameplay was rendered at 1280×720 / 60 FPS.

Independent review identified early-held E failing to acquire and foreground supports lacking colliders. Both reproduced and corrected. Foreground colliders initially blocked the anchor's center endpoint; targeting its visible surface fixed that, with a regression test. Headless runs skip audio playback; rendered and Windows runs retain audio.

Limits: automated tests do not establish human game feel. Owner playtest and publication are outstanding. Aether Dash and its GitHub repo were not changed by this prototype.
