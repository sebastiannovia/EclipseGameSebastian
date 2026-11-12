STRATOS – Parallax Background v2
=================================

Five separate PNG layers, 1280x360, for Godot 4.7.2.
- L1_sky_sun.png: clean opaque sky and sunset. Suggested Parallax2D scroll_scale.x = 0.00.
- L2_clouds_far.png: transparent distant clouds. Suggested x = 0.10.
- L3_islands_far.png: transparent far islands/ruins. Suggested x = 0.25.
- L4_islands_mid.png: transparent mid-distance islands/ruins/waterfalls. Suggested x = 0.45.
- L5_mist_low.png: transparent low mist/cloud bank. Suggested x = 0.60.

Previews: preview/parallax_composite_640x360.png and preview/parallax_composite_1280x360.png.
The transparent overlay layers were separated from the independent layer previews with local-background removal. Presentation borders and labels are excluded.

Import: Filter Nearest; Mipmaps Off; Repeat Disabled; Compression Lossless.
Use one Sprite2D under each separate Parallax2D. Width 1280 covers two 640px viewports; enable horizontal mirroring/repetition only if camera travel exceeds it.
Do not change camera follow, controls, player, creatures, platforms, collisions, collectibles, HUD, tutorial or level layout. Keep gameplay objects in front of all background layers.
