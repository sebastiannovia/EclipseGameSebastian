STRATOS – Normal Coin v1
========================

A standalone normal-coin animation pack for Godot.

Files:
- game_scale_32/coin_spin_8f_32x32.png
  Horizontal sprite strip: 8 frames, each 32x32. Total size 256x32.
  Recommended for the current 640x360 game and the existing CoinPickup drawing approach.
- game_scale_64/coin_spin_8f_64x64.png
  Horizontal sprite strip: 8 frames, each 64x64. Total size 512x64.
  Use only if the coin needs a larger on-screen size.
- frames_32/ and frames_64/
  Individual animation frames.
- source/
  Original generated sheet, retained for reference.
- PREVIEW_coin_animation.png
  Preview of the eight frames.

Suggested Godot import:
- Filter: Nearest
- Mipmaps: Off
- Repeat: Disabled
- Compression: Lossless
- Transparency: enabled

For CoinPickup.gd using the 32x32 strip:
- Set COIN_SHEET to coin_spin_8f_32x32.png.
- Frame count: 8.
- Frame region: 32x32.
- Frame index: int(floor(_elapsed * animation_speed * 8.0)) % 8.

Keep the animation subtle. No bloom, glow, or extra pickup particles are included in this pack.
