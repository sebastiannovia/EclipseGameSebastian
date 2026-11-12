STRATOS – Grass Platform Art Pack v1
====================================

Scope: grass-topped stone platform sprites only. No coins, HUD, portals, tutorial or background assets are included.

The sprites were extracted as individual transparent PNGs from the generated platform concept sheet, cleaned to hard pixel-art transparency, reduced to a coherent 40-colour palette per sprite, and supplied in two sizes.

Folders:
- source_2x/: larger source sprites.
- game_scale/: 50% nearest-neighbour versions intended as the first integration choice for the 640x360 game viewport.

Assets:
- platform_grass_long.png
- platform_grass_medium.png
- platform_grass_small.png
- platform_grass_slope_rising.png
- platform_grass_slope_falling.png

Godot import recommendations:
- Filter: Nearest
- Mipmaps: Disabled
- Repeat: Disabled
- Compression: Lossless

Integration constraints:
- Use only these platform visuals in this pass.
- Do not touch player, creatures, coins, HUD, portals, tutorial or background.
- Preserve all existing platform instance positions and collision geometry.
- Align each sprite's top grass surface to the existing collision top; adjust only the visual sprite offset if needed.
- Do not alter platform collider dimensions or player collision in this visual-only pass.
- Test representative platform scenes in Godot at 640x360 before replacing all instances.

PREVIEW_grass_platforms.png is for viewing only; do not import it as a game asset.
