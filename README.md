# Paper, Plastic, Pew!

A multiverse top-down twin-stick shooter where arenas, art direction, and character animation shift across a growing roster of **Paper** and **Plastic** visual dimensions.

> **Status:** Playable vertical slice on desktop. Five dimensions (Anime / Manga, Cartoon / Comic, Clay / Plasticine, Plastic Blocks, Pixel Art) — each with its own shapes, shaders, animation, arenas, music and HUD theme — plus four modes, three camera views and real-time dimension shifts. Not yet played on a phone; Android and iOS exports are configured but unbuilt.

## Run

Install Godot 4.6.3 and run from the repository root:

```sh
make run      # desktop: WASD or arrows to move, mouse to aim and fire, Space to dash, Q to swap weapon, Esc to pause
make touch    # same, with the dual touch sticks visible
make shift    # straight into Multiverse Shift mode
make check    # headless gameplay checks
make help     # every target, including exports and captures
```

A gamepad works as a twin stick: left stick moves, right stick aims and fires.

The Godot project lives in `game/`. `docs/ARCHITECTURE.md` explains the structure and `docs/DIMENSION_PACKS.md` how to add a dimension. Third-party audio and fonts are listed in `CREDITS.txt`.

## Why Paper, Plastic, Pew!?

The core hook of **Paper, Plastic, Pew!** is visual and tactile variety. Instead of locking the entire game into one art direction, every dimension transforms how the world looks **and** how characters move—combining 2D-styled art inside 3D arenas, custom lighting, and distinct animation languages while keeping tight, responsive twin-stick controls across mobile and desktop.

## Visual & Animation Dimensions

Built around a modular **Dimension Pack** architecture so new styles can be added over time:

### Core Dimensions (v1)
1. **Anime / Manga** *(Paper)*
   - **Look:** Cel-shading, crisp ink outlines, speed lines, and stylized 2D-in-3D VFX.
   - **Animation:** Snappy pose-to-pose timing, dramatic dash/recoil poses, and impact frames.
2. **Cartoon / Comic** *(Paper)*
   - **Look:** Bold outlines, saturated comic palettes, halftone textures, and expressive 2D-in-3D staging.
   - **Animation:** Classic squash-and-stretch rubber-hose motion, bouncy exaggeration, and comic slapstick energy.
3. **Clay / Plasticine** *(Plastic)*
   - **Look:** Matte hand-sculpted clay materials with tactile surface imperfections.
   - **Animation:** Subtle stop-motion stepped-frame character motion over smooth 60+ fps gameplay.

### Planned / Expanding Roster
4. **Paper Cutout** *(Paper)* — Flat, layered paper-puppet characters and props with rigid pivoting limbs and snappy stepped movement.
5. **Papercraft / Origami** *(Paper)* — Folded paper and cardstock cutouts in 3D space with crisp creases and soft diorama shadows.
6. **Cardboard** *(Paper)* — DIY cardboard-box arenas, tape seams, and marker-drawn details.
7. **Plastic Blocks** *(Plastic)* — Interlocking toy-brick worlds with snap-together geometry and breakable pieces.

## Core Gameplay

- **Perspective & Controls:** Top-down twin-stick shooter (dual virtual sticks on mobile; mouse + keyboard or gamepad on desktop).
- **Single-Dimension Play:** Pick any individual world/style to play through themed arenas, enemies, and bosses.
- **Multiverse Shift Mode (Sudden Style-Switching):** A dedicated mode where **all styles are in play** and the active dimension **snaps/shifts suddenly mid-match** (by timer, wave, or portal/event), forcing you to adapt on the fly as the whole world, animation, and feel transform in an instant.

## Game Modes

- **Single-Player:** Wave survival, dimension-based campaign progression, and boss encounters.
- **Offline / Local:** Skirmishes with AI bots (and local multiplayer where supported).
- **Online PvP / Co-op *(Later Phase)*:** Planned after the core single-player and offline experience is complete.

## Platforms & Language

- **Platforms:** Android, iOS, and PC/Desktop
- **Language:** English
