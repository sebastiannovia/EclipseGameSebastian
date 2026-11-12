STRATOS – Seamless Mirror Parallax Tiles v1
=============================================

Purpose:
A reliable coverage fix using the already approved L2-L5 artwork. This pack does not introduce new scenery or redesign L4.

L1 is copied unchanged:
- layers/L1_sky_sunset_640x360.png
- Keep scroll_scale.x = 0.00.
- Do not repeat it; it remains screen-fixed.

L2-L5 are 1280x360 mirror tiles:
- layers/L2_mirror_tile_1280x360.png
- layers/L3_mirror_tile_1280x360.png
- layers/L4_mirror_tile_1280x360.png
- layers/L5_mirror_tile_1280x360.png

How these tiles were built:
- The approved 640x360 illustration is preserved exactly in the first 640 pixels.
- The second 640 pixels are a horizontal mirror of that same approved image.
- The full 1280px tile can then be repeated at its exact width.
- This guarantees matching pixel/alpha values at the midpoint and tile-wrap edges; no cropping, stretching, colour-keying or inpainting was used.
- The visual content is mirrored, not a new panorama. This is an intentional short-term production fallback to eliminate hard seams while keeping the approved art and all five waterfall anchors intact.

Recommended Godot 4.7.2 Parallax2D settings:
- L1: scroll_scale = (0.00, 0.00); repeat_size = (0, 0).
- L2: scroll_scale = (0.06, 0.00); repeat_size = (1280, 0).
- L3: scroll_scale = (0.12, 0.00); repeat_size = (1280, 0).
- L4: scroll_scale = (0.18, 0.00); repeat_size = (1280, 0).
- L5: scroll_scale = (0.24, 0.00); repeat_size = (1280, 0).

All Parallax2D children must start from the same canvas origin:
- Sprite2D texture centered = false (or equivalent top-left alignment).
- Sprite2D position = (0, 0) if using top-left alignment.
- Do not mix centered and top-left origins.
- Ensure the 1280x360 image covers x=[0,1280), y=[0,360) in the Parallax2D repeat canvas.

Critical Waterfall handling:
- The first 640px of L4 is unchanged, so the five existing waterfall anchors on the original composition remain at their existing positions.
- The mirrored half contains a mirrored copy of the L4 artwork. To keep its waterfalls animated too, create a second set of the existing Waterfall scene instances at mirrored local X positions:
  x_mirror = 1280 - x_original
  Keep the same Y and scale; set flip_h only if the waterfall artwork has directional asymmetry.
- Keep the original five instances unchanged.
- Do not alter the five original waterfall positions:
  (262,99), (434,124), (400,176), (561,218), (557,311).
- Because Parallax2D repeats its child CanvasItems with repeat_size, verify that animated waterfall children repeat together with L4. If the engine repeats the animated child as part of the Parallax2D, do not add duplicate instances unnecessarily. Test this in Godot before deciding.

Texture import:
- Filter: Nearest.
- Mipmaps: Off.
- Repeat: Disabled at texture import level (Parallax2D controls scene repetition).
- Compression: Lossless.
- Preserve alpha on L2-L5.

Limitations:
- Mirror repetition is a reliable seam-free fallback, but it creates reflected scenery motifs. It is not a bespoke full-length panorama.
- Inspect the middle and end of the level for obvious mirrored repetition. If the reflected arrangement is too noticeable, keep this pack as the working functional version and schedule unique panorama artwork as a later polish task rather than re-breaking the background.

Strict preservation:
- Do not modify player, Sky Skimmer, movement, grapple, gameplay platform positions/collisions, collectibles, HUD, tutorial, portals, camera follow logic or level geometry.
- Preserve internal resolution 640x360 and output 1920x1080.
- Do not make Git commits.
