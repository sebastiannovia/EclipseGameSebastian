STRATOS – Original Sound Effects Pack v1
========================================

Original procedural sound effects created specifically for STRATOS – Portal Run.
No third-party samples, copyrighted game audio, dialogue, or background music are included.

FORMAT
------
- WAV, PCM 16-bit, 48,000 Hz, stereo.
- Short one-shot effects are in `sfx/`.
- Seam-loop ambience is in `loops/`.
- `preview/STRATOS_SFX_AUDITION.wav` contains a sequential audition montage with short gaps.
- `manifest.json` lists duration and loop status for every WAV.

ONE-SHOT EFFECTS
----------------
Player:
- player_jump.wav — compact suit-assisted jump lift.
- player_footstep_01.wav / player_footstep_02.wav — alternating padded boot contacts; vary them while running.
- player_land_soft.wav — ordinary short landing.
- player_land_heavy.wav — higher-impact landing / hard fall recovery.
- player_respawn.wav — soft reverse shimmer and stable re-entry pulse.

Grapple:
- grapple_launch.wav — cable launcher / hook firing.
- grapple_attach.wav — metallic magnetic catch confirmation.
- grapple_miss.wav — short failed-hook flick.
- grapple_release.wav — elastic cable release and retained-momentum cue.

Creatures:
- sky_skimmer_chirp.wav — short airy Sky Skimmer call.

Collectibles:
- coin_pickup.wav — bright ascending coin chime.
- special_coin_pickup.wav — longer, richer crystalline reward.

Portals / game state:
- portal_enter.wav — cool, airy transition into the portal.
- portal_exit.wav — warmer emergence/exit whoosh.
- level_complete.wav — short five-note completion fanfare.
- ui_confirm.wav — quiet interface / tutorial confirmation click.

LOOPING AMBIENCE
----------------
- grapple_swing_loop.wav — subtle rope tension and moving air while attached/swinging.
- sky_skimmer_flap_loop.wav — soft wing beats while a Sky Skimmer is nearby/on screen.
- portal_ambient_loop.wav — low magical portal hum.
- waterfall_loop.wav — continuous water rush with fine droplets; attach to existing waterfall instances.
- floating_island_wind_loop.wav — distant open-air atmosphere; keep very quiet.

MIXING GUIDANCE
---------------
- Create separate Godot Audio Buses: Master, SFX, Ambience.
- Send one-shots to SFX, and long loops to Ambience.
- Start Ambience around -18 to -24 dB relative to one-shots.
- Keep footstep playback tied to actual movement/grounded state, not a repeating timer while airborne.
- Alternate footstep_01 and footstep_02; pitch variation should be very subtle (±2–3%).
- Do not play both land sounds for the same landing. Choose soft/heavy based on impact speed.
- Start grapple_swing_loop only while attached; stop/fade it on release, detach or respawn.
- Loop creature flaps only when audible/relevant; do not create a constant loud wing loop for every off-screen creature.
- Portal, waterfall and wind loops should be spatially or globally balanced so they do not mask player feedback.
- Coin pickup should be short and clear; special coin should stand out without being painfully loud.
- Clamp the combined mix to avoid clipping when multiple effects overlap.

INTEGRATION SAFETY
------------------
This pack contains audio assets only. It does not modify any scenes, scripts, input mappings, player physics, grapple behaviour, collectibles, portals, level layout, or HUD.
The agent must inspect existing project paths and event signals before wiring sounds. Do not invent new gameplay states just to trigger sounds.
