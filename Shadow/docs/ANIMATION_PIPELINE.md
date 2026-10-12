# 《影》动画制作流程

This build follows the video-first workflow in `GAME_PRODUCTION_PLAYBOOK.md`. Three 16:9 chroma-green static character references establish the hero, blade guard, and gunner identities. Every continuous motion is generated as a separate reference-guided video with a locked orthographic side view, fixed framing, no camera motion, and no scene cuts. Raw references, MP4 files, extracted PNGs, and processing previews remain outside the Godot project and are not shipped.

| Actor | Runtime states | Source | Runtime frames |
|---|---|---|---:|
| Hero | Idle, run, jump, attack, defeat | One static reference plus four reference-guided videos | 50 |
| Blade guard | Idle, run, attack, defeat | One static reference plus three reference-guided videos | 38 |
| Gunner | Idle, walk, shoot, shutdown | One static reference plus three reference-guided videos | 38 |

The project-local command `ZERO_HOUR_ART_SOURCE=/path/to/sources tools/art_pipeline/process_zero_hour_animations.sh` scales the source clips, trims the selected motion intervals, extracts at fixed frame rates, removes the chroma background, calculates one union crop per action, places every frame on a shared 192×192 canvas with a common foot baseline, writes alpha-preserving WebP files, generates literal GDScript preloads, and applies Web-sized Godot import compression. The checked-in `scripts/animation_frames.gd` references all 126 runtime frames with literal `preload()` paths so the Web exporter cannot omit them.

Gameplay state selects the frame set rather than modifying actor geometry procedurally. Run and walk loop by animation time; jump maps frame selection to vertical velocity; hero slash, blade attack, and gunner fire use normalized one-shot phases; defeat plays forward into the rewind window. Damage and projectile events occur after the readable anticipation phase, aligning collision timing with the animation instead of firing at input start.

Verification covers frame-count bounds, title/game boot, movement, focus, slash, defeat, rewind, room completion, persistence, replay, fixed-frame layouts, deterministic visual captures, PCK contents, exported-pack boot, and final PCK size. Per the standing project requirement, current iterations do not use browser self-testing.
