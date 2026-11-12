STRATOS – Entry & Exit Portals – Visual v1
============================================

Two matching RGBA portal visual assets extracted as individual objects from the approved portal concept artwork.

For each portal:
- `portal_<name>_full.png`: complete static portal visual.
- `portal_<name>_frame.png`: stone arch, banners, moss, crystals and footing with a transparent aperture.
- `portal_<name>_core.png`: matching aperture/vortex overlay, aligned to the frame.
- `*_160px.png`: recommended initial game-size set.
- `*_320px.png`: 2x high-resolution set.

Visual design:
- Entry: cyan/blue vortex, cyan crystals, purple stone arch, moss and gold runes.
- Exit: amber/gold vortex, warm crystals, purple stone arch, red banners and moss.

Recommended Godot setup:
- Use frame Sprite2D behind core Sprite2D.
- Both sprites have matching origins and dimensions; do not offset them independently.
- Add a subtle ShaderMaterial to the core only (slow UV rotation or radial swirl) for idle motion.
- Optional mild emission/pulse may be applied to the core, but do not add strong bloom.
- Nearest filtering, mipmaps off, lossless compression, preserve alpha.

STRICT GAMEPLAY PRESERVATION:
- Replace only existing visual textures in the current entry/exit portal scenes.
- Preserve existing Area2D, CollisionShape2D, collision layers/masks, signal connections, spawn logic, exit/victory trigger, scene transitions, restart behaviour and node transforms.
- Do not move either portal or change its gameplay collision footprint.
- Check whether the small stone/grass footing aligns with the existing platform; adjust only the visual node if required.
- Do not introduce new gameplay triggers or transitions.
- The existing portal scenes should remain responsible for gameplay logic.
