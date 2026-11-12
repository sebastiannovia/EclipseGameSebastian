STRATOS – Portal Run | Art Asset Pack
=====================================

These are actual individual PNG resources, not the concept-board image.

Contents:
- background/: 640x360 native background, 1920x1080 nearest-upscaled background, transparent parallax cloud/island layers.
- terrain/: 32x32 modular terrain atlas and reusable floating platform prefabs.
- collectibles/: 6-frame horizontal coin and gem strips.
- effects/: 8-frame horizontal pickup effect strips.
- portals/: individual blue entry and orange exit portal art.
- props/: 8x4 atlas of 64x64 decorative props.
- ui/: decorative tutorial sign frame (text should be rendered with Godot Label nodes), HUD frames, icons.

Godot import recommendations:
- Filter: Nearest
- Mipmaps: Off
- Repeat: Disabled
- Compression: Lossless for pixel art
- Sprite sheet Hframes: coin=6, gem=6; pickup effects=8.
- Terrain atlas cells: 32x32.
- Props atlas cells: 64x64.

Important:
- These PNGs are visual resources. The agent must integrate them into the existing scenes and preserve all existing collision shapes, gameplay scripts, collectible logic, controls, camera, portals and level geometry.
- Do not place any new coins or special collectibles in Level_01.
- Tutorial sign text should remain native Godot text, not be baked into the frame image.
- Background can be used as one full backdrop or separated into parallax layers.
