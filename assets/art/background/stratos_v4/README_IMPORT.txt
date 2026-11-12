STRATOS – Background v4
=======================

This pack uses the higher-quality, clean environment illustration from the STRATOS art direction.
It contains no HUD, no player, no coins, and no grapple marker.

BACKGROUND:
- background/stratos_background_master.png — 1672x941 master.
- background/stratos_background_640x360.png — internal viewport version.
- background/stratos_background_1280x720.png — 2x internal version.
- preview/stratos_background_preview_1920x1080.png — output-size preview.

The background includes painted depth (near arches, floating islands, distant ruins, sunset clouds and mist).
It is a single coherent environment illustration, not five independently painted parallax layers.
Use it as one background Parallax2D layer with a restrained scroll factor if appropriate. Do not fabricate five layers by duplicating/cropping the same picture.
This pack intentionally prioritises matching the high-detail Sky Skimmer and grass platform artwork over using the low-quality procedural v2/v3 layer strips.

ANIMATED WATER:
- waterfall/waterfall_loop_8f_64x256.png
- Horizontal spritesheet: 8 frames, each 64x256.
- The sprite is extracted from the waterfall style in the same background illustration; the inner water highlights shift downward in a seamless 8-frame loop.
- Suggested SpriteFrames: Hframes=8, Vframes=1, animation speed 8 FPS, loop enabled.
- Individual frame PNGs are included for inspection.
- preview/waterfall_loop_preview.gif shows the animation.

WATERFALL INTEGRATION:
Create `res://scenes/environment/Waterfall.tscn` with one AnimatedSprite2D using the supplied sprite sheet.
Expose a visual height/scale property if useful; use proportional scaling and do not squash width.
Place animated instances directly over every painted waterfall in the background so the moving sprite replaces the static stream pixels.
Approximate source-image locations are provided in waterfall/waterfall_placement_reference.json.
When background is displayed at 640x360, convert source coordinates using scale factor 640/1672 (approximately 0.383).
The actual world positions depend on how the project positions/scales the background node; calculate from its transform rather than assuming screen coordinates.
Do not add collision shapes to waterfalls.

IMPORT:
- Filter: Nearest.
- Mipmaps: Off.
- Repeat: Disabled.
- Compression: Lossless.
- Preserve alpha.

PRESERVATION:
Do not change player, Sky Skimmer, platforms, collision geometry, collectibles, HUD, tutorial, portals, controls, camera follow logic, or level layout.
Do not place unrelated scenery or collectibles.
Do not make Git commits.
