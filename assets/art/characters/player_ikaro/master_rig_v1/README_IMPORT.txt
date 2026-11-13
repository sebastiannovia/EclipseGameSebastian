STRATOS – IKARO Astronaut Master + Rig Starter v1
=================================================

This package provides one consistent master character illustration and overlapping cutout parts derived from that exact image. It is a foundation for the player visual rig, not a finished animation pack.

MASTER
------
- master/IKARO_astronaut_master_right.png (213x415, RGBA)
- master/IKARO_astronaut_master_right_2x.png (nearest-neighbour 2x)
- The character faces right, in a slight 3/4 side profile. It preserves the IKARO white/grey/orange maintenance suit, black visor, backpack, gloves and boots.
- The master art is extracted from the large character render, with background removed and 8px transparent padding. No new animation frames are fabricated from it.

RIG PARTS
---------
- 11 individual PNG cutouts in rig_parts/.
- All are derived from the same source image and share its pixel scale.
- Joints overlap so rigid pieces can rotate without immediately exposing transparent gaps.
- rig_parts/rig_metadata.json gives crop boxes, pivot coordinates and Bone2D-relative Sprite2D offsets.
- Reassembled visible RGB pixels match the master exactly: True. All opaque master pixels are covered by at least one rig part: True.

RECOMMENDED APPROACH
--------------------
Use a HYBRID animation workflow:
1. Build the neutral pose from these parts and verify it matches the master.
2. Skeleton2D/Bone2D + rigid Sprite2D parts for idle breathing, small arm/body adjustments and swing pose control.
3. Hand-authored key poses / sprite replacements for run, jump, fall and land. A pure cutout rig will look mechanical when running and may expose hidden anatomy behind bent joints.
4. One AnimationTree or explicit state machine for transitions. Avoid crossfading two transparent full-body sprites because that produces ghosting.
5. Snap final visual positions to the pixel grid; nearest filtering, mipmaps off, no fractional scaling.

LIMITATIONS
-----------
- This is one master pose; pixels hidden behind the limbs are not present. Joint overlaps reduce gaps but do not invent unseen anatomy. The agent must inspect deformation before producing full cycles, and may need small replacement patches/key poses.
- The rig parts are a starting cutout layout. Do not animate all parts at once without first verifying the neutral reassembly.
- The frame canvas is 213x415; keep a shared foot baseline and do not scale individual parts independently.

No Godot scene or gameplay script is included. The implementing agent should inspect the actual Player scene and preserve its collision/physics/grapple implementation.
