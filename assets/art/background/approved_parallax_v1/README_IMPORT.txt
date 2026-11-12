STRATOS – APPROVED PARALLAX BACKGROUND PACK v1
=================================================

This is the consolidated delivery of the five individually approved background illustrations for STRATOS – Portal Run.

CONTENTS
--------

layers/
- L1_sky_sunset_640x360.png
- L2_distant_clouds_640x360.png and 1280x720.png
- L3_distant_islands_640x360.png and 1280x720.png
- L4_midground_islands_640x360.png and 1280x720.png
- L5_foreground_mist_640x360.png and 1280x720.png

originals/
- The original high-resolution PNG for each approved illustration.

preview/
- Progressive composition previews showing the approved layers together.
- Transparency preview for L5.

APPROVED ORDER AND STARTING PARALLAX
------------------------------------

Back to front:
1. L1_sky_sunset — Parallax2D scroll_scale.x = 0.00
2. L2_distant_clouds — Parallax2D scroll_scale.x = 0.10
3. L3_distant_islands — Parallax2D scroll_scale.x = 0.25
4. L4_midground_islands — Parallax2D scroll_scale.x = 0.45
5. L5_foreground_mist — Parallax2D scroll_scale.x = 0.60

These are starting values. Tune them to the existing camera movement and the real level length.

IMPORTANT ART / INTEGRATION RULES
---------------------------------

- These are five independent image assets, not crops from the previous v4 master.
- Preserve the PNG alpha on L2-L5.
- L1 is the opaque sky base.
- Do not apply colour-key transparency, masks, inpainting or automatic cut-outs.
- Do not slice any of these images into fragments.
- Do not flatten the five layers into a single image.
- Do not fabricate extra planes by duplicating or cropping these images.
- Do not stretch any layer disproportionately.
- Use Nearest filtering, mipmaps off, repeat disabled, lossless compression.
- At the current 640x360 internal viewport, use the 640x360 versions for the initial integration.
- The 1280x720 versions are provided as optional 2x alternatives for L2-L5.
- The illustrations are approved individually but are not guaranteed seamless horizontally. Do not loop/repeat blindly; first verify the camera travel and edges. Preserve the original coherent composition.

WATERFALLS
----------

The project already has working animated waterfall scenes/instances from the approved v4 stage.

Do NOT replace them with static water, regenerate them, or add duplicate animation assets from this pack (none are included).

Keep existing waterfall animations and parent each waterfall to the corresponding L4 midground island/parallax transform so it moves at exactly the same parallax speed as its island. Preserve their current animation, scale and placement wherever possible. Reposition only as required to align them with the L4 artwork.

VISUAL HIERARCHY
----------------

The foreground gameplay must remain readable:
1. Player and Sky Skimmer.
2. Playable platforms and route.
3. Collectibles and interactive objects.
4. L4 midground islands.
5. L3 distant islands.
6. L2 clouds.
7. L1 sky.
8. L5 foreground mist is atmospheric; keep its alpha restrained (start around 0.55–0.65) and render it behind the player/gameplay objects if it would otherwise obscure them.

STRICT PRESERVATION
-------------------

Do not modify player physics, grapple, Sky Skimmer behaviour, platform sprites/collisions, collectibles, HUD, tutorial, portals, controls, camera follow behaviour, level geometry or route layout.

Use Godot 4.7.2. Preserve internal resolution 640x360, output resolution 1920x1080, and Nearest filtering.

The agent must inspect actual current project state before editing. Do not assume old scene/node paths or replace already working waterfall resources.

Do not claim runtime verification unless the project is actually run in Godot 4.7.2 and camera movement is inspected.

No bots, automated full-level gameplay simulations, Git commits or unrelated refactoring.
