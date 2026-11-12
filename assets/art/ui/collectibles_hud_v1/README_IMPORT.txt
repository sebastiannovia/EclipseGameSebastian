STRATOS – Collectibles HUD v1
===============================

This pack contains a background frame for the two collectible counters.

Runtime assets:
- game_scale/hud_collectibles_frame_320w.png
- game_scale/hud_collectibles_frame_256w.png

The frame includes two separate compartments and fixed decorative coin/gem emblems.
The numeric count areas have been cleared for dynamic Godot Label nodes.

Important:
- The example numbers in reference/hud_layout_mockup_not_for_runtime.png are only a layout preview.
- Do NOT use the reference mockup as the in-game HUD texture.
- Put two independent Label nodes over the empty number wells.
- Recommended count strings: "× 024" and "× 003", but use the actual runtime values.
- Use centered vertical alignment, font size around 12–14 at 640x360, with cream/ivory text.
- Use Containers/anchors and a single TextureRect background; do not use absolute offsets scattered through the HUD.
- The left count well is for normal coins; the right is for special gems.

Godot import:
- Filter: Nearest
- Mipmaps: Off
- Repeat: Disabled
- Compression: Lossless
- Preserve transparency.

Scope:
This is only a visual frame. It contains no counter logic, scripts, icons for standalone use, or scenes.
The existing HUD tracker and collectible logic must be preserved.
