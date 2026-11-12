STRATOS – Animated Integrated Portals v2
==========================================

Two separate animated portal assets, rebuilt from scratch for direct placement on existing gameplay platforms.

ENTRY:
- entry/portal_entry_4f_256x192.png
- 4 frames, horizontal strip.
- Individual frames in entry/frames/.
- Cyan/blue vortex, violet stone arch, purple banners, blue crystals.

EXIT:
- exit/portal_exit_4f_256x192.png
- 4 frames, horizontal strip.
- Individual frames in exit/frames/.
- Golden/orange vortex, violet stone arch, crimson banners, magenta crystals.
- Horizontally mirrored relative to the entry portal so its asymmetric details face the opposite direction.

Frame format:
- 256x192 pixels per frame.
- RGBA PNG, transparent background.
- 4 frames, intended 8 FPS looping animation (125 ms per frame).
- The frame canvas is bottom-aligned; the stone threshold sits at y=192.
- No floating island or rocky underside. The narrow stone threshold and side crystal/grass details sit directly on the existing platform surface.

Visual cleanup:
- Removed low-alpha fringe and isolated transparency specks.
- Removed saturated red generation fringe.
- Preserved the actual stone, banners, moss, crystals and portal cores.
- No rectangular background, no presentation labels, no decorative black frame.

Godot import:
- Filter: Nearest.
- Mipmaps: Off.
- Repeat: Disabled.
- Compression: Lossless.
- Preserve alpha.

Godot SpriteFrames:
- Create SpriteFrames animations "idle" with 4 frames each.
- FPS: 8.
- Loop: true.
- Use AnimatedSprite2D.
- Entry: flip_h = false.
- Exit: flip_h = true is already baked into the exported exit PNGs; do not flip it again.

Platform integration:
- Align the bottom of each 256x192 frame to the top surface of the existing platform.
- Do not add any portal-owned floating platform or CollisionShape2D ground.
- Existing gameplay platform is the only ground.
- Keep the existing portal Area2D, trigger shape, entry spawn, exit victory logic and scripts.
- Visual sprites should be children of the existing portal scene; do not replace gameplay logic.

Animation:
- The stone arch remains visually stable across frames.
- The vortex changes between frames to create a continuous swirl.
- Keep the animation subtle and loop at 8 FPS.
