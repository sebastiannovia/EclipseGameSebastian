STRATOS – Background v1
=======================

This is the first background-art pass for STRATOS – Portal Run.

Files:
- source/bg_skylands_master.png
  Original generated master artwork (1672x941).
- game_scale/bg_skylands_640x360.png
  Recommended initial game texture, resized with Nearest to the game's 640x360 internal resolution.
- game_scale/bg_skylands_640x360_smooth.png
  Alternative downsample using Lanczos, included only for visual comparison.
- preview/bg_skylands_preview_1920x1080.png
  Exact 3x nearest-neighbour preview for the game's 1920x1080 output.

Style:
- Violet twilight sky.
- Warm orange/pink sunset clouds.
- Floating islands and waterfalls.
- Ancient ruins, arches and distant bridges.
- Turquoise crystal accents.
- No characters, UI, foreground gameplay platforms, or text.

Recommended Godot import:
- Filter: Nearest.
- Mipmaps: Off.
- Repeat: Disabled.
- Compression: Lossless.
- Use bg_skylands_640x360.png first.

Important integration note:
This first pass is a single composed backdrop, not a set of separately painted parallax layers.
Use it as one background element while preserving the existing camera and gameplay.
Do not duplicate the same full image across multiple Parallax2D layers.
A true separated cloud/island parallax pass can be prepared after this background is visually approved.

Do not change player, platforms, collision geometry, collectibles, HUD, tutorial, portals, camera behaviour or level layout when integrating this asset.
