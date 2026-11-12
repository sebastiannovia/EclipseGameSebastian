STRATOS – Parallax Background v3
================================

This pack replaces the earlier v2 layers because the previous layers were extracted from mockup previews and had transparency artefacts/cropped water.

BACKGROUND LAYERS (all 1280x360, separate PNGs):
- L1_sky_sun.png: fully opaque sky, sun and subtle stars. Suggested parallax 0.00.
- L2_clouds_far.png: transparent distant cloud groups. Suggested 0.10.
- L3_islands_far.png: transparent distant island silhouettes/ruins. Suggested 0.25.
- L4_islands_mid.png: transparent complete midground islands, no baked waterfalls. Suggested 0.45.
- L5_mist_low.png: transparent low cloud/mist groups. Suggested 0.60.

ANIMATED WATER:
- waterfall_body_8f_32x32.png: 8-frame horizontally arranged body animation. Each 32x32 frame is vertically tileable. Use as repeated middle sections.
- waterfall_top_8f_48x24.png: 8-frame top spill cap.
- waterfall_splash_8f_64x24.png: 8-frame lower splash.
- river_surface_8f_64x16.png: 8-frame small horizontal current strip for water flowing along island tops.

Waterfall assembly:
- Create a reusable Waterfall.tscn with AnimatedSprite2D nodes for top, repeated body segments, and splash.
- Each node uses the relevant spritesheet as 8-frame SpriteFrames at 8 FPS, loop enabled.
- Expose `body_segments` as an editable property or a clear child segment structure so each waterfall can have the correct length.
- Keep the top cap attached to the island edge; body segments repeat without gaps; splash stays at the bottom.
- Do not stretch the waterfall body vertically; repeat 32px body segments.
- The river surface strip can be used on small island ledges where water flows horizontally.
- All water sprites have transparent backgrounds outside the water itself.

IMPORTANT:
- These are independent art resources, not a presentation board.
- Do not extract sprites from README or preview images.
- Do not embed waterfalls in L4: place the Waterfall.tscn separately on top of the midground island layer, so waterfalls can be animated and extended without being clipped by the layer's bounds.
- Ensure every waterfall's body length is set to match the distance from island lip to its visible endpoint; do not crop them at arbitrary layer boundaries.
- The `preview/` folder is not a runtime asset.

Godot import:
- Filter Nearest.
- Mipmaps Off.
- Repeat Disabled.
- Compression Lossless.
- Preserve PNG alpha.

Parallax speeds are starting values; tune them to the project's camera direction and level length.
Keep all gameplay platforms, player, Sky Skimmer, collectibles and HUD in front of all backdrop layers.
