# Architecture

## Layout

```
game/
  core/          dimension-agnostic gameplay
    main.gd            entry point, menu <-> match, developer arguments
    match.gd           one play session: arena, actors, camera, pickups
    director.gd        rules per mode: survival, shift, campaign, skirmish
    actor.gd           base for anything that moves, shoots and takes damage
    player.gd enemy.gd twin-stick player; AI for enemies, bosses and bots
    projectiles.gd     every bullet, swept on the CPU, two MultiMesh draws
    arena.gd           builds an arena from data/arenas.json
    twin_input.gd      mouse + keyboard, gamepad and touch as one twin stick
    dimensions.gd      pack registry and the live style switch
    dimension_pack.gd  one loaded pack: palette, materials, theme, feel
    dimension_animator.gd  base animation language
    character_rig.gd   procedural character parts and animation state
    vfx.gd sfx.gd      particles, shake, overlay, flash; sound by event name
    smoke.gd           headless gameplay check
    data/              weapons, enemies and arenas as JSON
  ui/            HUD, touch sticks, workbench menu
  dimensions/    one folder per visual dimension (see DIMENSION_PACKS.md)
tools/check.py   headless checks
```

## How a dimension shift works

Everything visual registers with `Dimensions.style(node, role, palette_key)`. A shift sets the active pack and reassigns one shared material per role and colour to every registered node, swaps the environment light, the screen overlay, the HUD theme, the music and the animator. Nothing is spawned, freed or loaded, and collision never changes, so the fight continues on the same frame.

All packs load at start-up. When a match starts, one tiny mesh per pack shader is drawn for a few frames so shaders compile before the first shift instead of during it.

Animators are stateless: every frame they rebuild a pose from the rig's rest pose and its state fields (walk phase, recoil, hurt, dash, spawn, death). Swapping the animator between two frames therefore needs no blending.

## Decisions on the open questions

These were listed as open in the initial brief. The slice had to pick something to exist; each is cheap to revisit.

**Rendering pipeline: 3D top-down with stylized shaders.** The three options in plain terms:

| | 3D + shaders (chosen) | Pure 2D sprites | Hybrid: 3D world, 2D billboard characters |
| --- | --- | --- | --- |
| New dimension costs | shaders + animator + palette | a full redraw of every sprite and animation | sprites for characters, shaders for the world |
| Real-time shift | swap materials, instant | swap whole sprite sets, memory heavy | both |
| Look | 2D-styled, still reads as 3D up close | most authentic 2D | authentic characters, mixed world |
| Phone cost | low: simple shaders, few draws | lowest | low |
| Art needed | none to start (procedural) | a lot, per dimension | a lot, per dimension |

3D + shaders is the only option where a growing roster stays affordable and where one layout can shift instantly, which is the hook. The pack format leaves room for the hybrid later: a pack could supply cutout billboards for characters (Papercraft, Cardboard) without touching gameplay.

**Shift implementation.** Shared collision and layout, per-dimension materials, everything preloaded, shaders warmed at match start (above).

**Assets and audio.** Characters, arenas and effects are procedural. Sound and fonts are free third-party files (CC0 audio, OFL fonts) credited in `CREDITS.txt`.

**Package size.** Packs are shaders, a script, JSON, one font and one music track: well under 5 MB each, so all v1 dimensions ship in the base build. Split `.pck` downloads are not needed yet.

## Not done yet

- Play on a physical phone or tablet; frame rate on mobile GPUs is unmeasured.
- Local multiplayer, online multiplayer (deferred), settings screen, per-dimension enemy and arena variants.
- Store availability of `com.paper.plastic.pew` and signing for Android and iOS.
