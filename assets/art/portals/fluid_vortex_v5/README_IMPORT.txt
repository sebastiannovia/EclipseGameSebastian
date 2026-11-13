STRATOS – Fluid Vortex Only v5
================================

This package replaces the previous portal animation, which looked like a small rectangular image rotating as a flat photograph.

The new animation is an arch-shaped portal interior field, not a rotating full-frame picture.

STATIC PORTAL FRAMES
--------------------
- entry/frame_static/entry_frame_static_no_core.png
- exit/frame_static/exit_frame_static_no_core_mirrored.png

These preserve the stone architecture, moss, banners, crystals and threshold, but remove the old baked-in vortex from the arch opening. The exit frame is horizontally mirrored so the exit architecture faces left.

VORTEX FRAMES
-------------
- entry/vortex_frames/entry_vortex_00.png ... entry_vortex_07.png
- exit/vortex_frames/exit_vortex_00.png ... exit_vortex_07.png
- Each PNG is 256x192 and uses the same arch-shaped alpha mask.
- Visible pixels exist only inside the arched portal aperture.
- All eight alpha masks are pixel-identical; only the inner vortex energy pattern and glints change.
- Entry uses cyan/blue flow.
- Exit uses gold/orange flow with opposite directional movement.

SPRITESHEETS
------------
- entry/entry_vortex_8f_256x192.png
- exit/exit_vortex_8f_256x192.png
Each is a horizontal strip with 8 cells of 256x192.

ANIMATION
---------
Use AnimatedSprite2D for the vortex only:
- 8 frames.
- 8 FPS initially (can tune 8–10 FPS).
- Loop enabled.
- No rotation on the AnimatedSprite2D, parent, portal root, or stone frame.
- No scale/position changes between frames.
- The sprite uses the same 256x192 canvas and origin as the static stone frame.

REQUIRED DRAW ORDER
-------------------
1. Optional dark backplate / portal recess (static).
2. AnimatedSprite2D vortex (only moving layer).
3. Static Sprite2D stone frame (topmost; must never animate).

Do not use the previous v4 vortex frames. They looked like a small floating image turning inside the opening.
Do not rotate the full sprite. This is a flow animation within a fixed arch-shaped mask.

PREVIEWS
--------
- preview/entry_vortex_only_animation.gif
- preview/exit_vortex_only_animation.gif
- preview/fixed_frame_contact_sheet.png

All previews composite the animated core underneath the fixed stone frame.

Import settings:
- Filter: Nearest.
- Mipmaps: Off.
- Compression: Lossless.
- Preserve alpha.
- No sprite-sheet frame scaling.

No gameplay collision, trigger or portal state logic is included or changed by these assets.
