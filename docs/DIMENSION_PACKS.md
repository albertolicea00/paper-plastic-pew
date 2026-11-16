# Dimension packs

A dimension is a folder in `game/dimensions/<id>/`. The core finds every folder that contains a `pack.json`; adding a dimension never requires a change in `game/core/` or `game/ui/`.

A pack changes how the game looks, moves, sounds and feels. It never changes collision, hitboxes, speeds or rules: those are shared so a shift can happen mid-fight.

## Files

| File | Required | Purpose |
| --- | --- | --- |
| `pack.json` | yes | Identity, palette, material setup, HUD theme, feel |
| `*.gdshader` | no | Surface, outline and overlay shaders named in `pack.json` |
| `animator.gd` | no | Animation language, extends `DimensionAnimator` |
| `builder.gd` | no | Shapes of characters, props, pickups, bullets and scenery, extends `DimensionBuilder` |
| `arenas.json` | no | Arenas of its own, used when a whole match stays in this dimension |
| `font.ttf` / `font.otf` | no | HUD and menu font, found by name |
| `audio/<event>.ogg` or `.wav` | no | Sound overrides, found by name |

## pack.json

```json
{
	"id": "anime",
	"name": "Anime / Manga",
	"family": "Paper",
	"order": 1,
	"tagline": "Ink, speed lines and impact frames",
	"palette": {"floor": "#e9e6df", "ink": "#12131a"},
	"environment": {"ambient": "#ffffff", "ambient_energy": 0.45, "light": "#ffffff", "light_energy": 1.0, "light_pitch": -58, "light_yaw": -35, "shadows": true},
	"surface_shader": "surface.gdshader",
	"surface_params": {"bands": 3.0, "shade": "@ink"},
	"roles": {
		"floor": {"shader": "floor.gdshader", "params": {"grain": 0.2}},
		"character": {"outline_width": 0.04}
	},
	"outline": {"width": 0.035, "color": "@ink", "shader": "", "params": {}},
	"overlay": {"shader": "overlay.gdshader", "params": {"strength": 0.5}},
	"animator": "animator.gd",
	"builder": "builder.gd",
	"names": {"blaster": "Ink Brush", "grunt": "Sketch", "boss": "Editor-in-Chief"},
	"hud": {"radius": 2, "border": 3, "shadow": 5, "tilt": 2.0, "uppercase": true, "font_scale": 1.0},
	"feel": {"hitstop": 0.05, "shake": 1.3}
}
```

Every block except `id` is optional; defaults live in `game/core/dimension_pack.gd`.

**Parameter values.** In `surface_params`, `roles.*.params`, `outline.params` and `overlay.params`: `"#rrggbb"` is a colour, `"@key"` is a palette colour, a `.png/.jpg/.webp/.svg` path relative to the pack is a texture, and an array of 2 to 4 numbers is a vector.

**Palette keys.** `bg floor floor_alt wall prop player player_accent grunt runner tank boss bot weapon ink bullet_player bullet_enemy pickup_health pickup_ammo flash ui_bg ui_fg ui_accent ui_danger`. Keep characters, bullets and pickups readable against the floor in every pack: the layout is shared, so contrast is gameplay.

## Surface shaders

A surface shader is a normal `shader_type spatial` shader. The only contract is one uniform:

```glsl
uniform vec4 albedo : source_color;
```

The core sets `albedo` per object from the palette. One material is shared by all objects with the same role and colour.

Roles: `floor`, `wall`, `prop`, `character`, `weapon`, `bullet` (drawn through a MultiMesh), `pickup`, `fx`, `flash` (hit flash; unshaded white unless the pack defines the role). Use `roles` to give a role its own shader or parameters.

Outlines are an inverted hull added as `next_pass` (`game/core/shaders/outline.gdshader`, uniforms `ink` and `width`). `outline.width` applies to every role except `floor`, `bullet`, `fx` and `flash`; `roles.<role>.outline_width` overrides it, and `0` removes it. A pack may supply its own outline shader with the same two uniforms.

The game runs on the GL Compatibility renderer on phones. Avoid screen and depth texture reads in surface shaders, keep texture lookups low, and prefer procedural patterns in world or screen space.

## Overlay shader

`overlay.shader` is a `shader_type canvas_item` shader drawn on a full-screen rectangle over the 3D view and under the HUD. Use it for halftone dots, speed lines, paper grain or vignettes. Output mostly transparent pixels and do not read the screen texture.

The core sets these uniforms every frame when the shader declares them:

| Uniform | Meaning |
| --- | --- |
| `float impact` | 0 to 1 pulse on dashes, hits taken and kills; decays in about 0.3 s |
| `float shift` | 1 to 0 during the flash that follows a dimension shift |

## Animator

```gdscript
extends DimensionAnimator

func animate(rig: CharacterRig, delta: float) -> void:
	# Stop motion: hold poses at 12 frames per second.
	pose(rig, snappedf(rig.clock, 1.0 / 12.0), snappedf(rig.phase, 0.5))

func pose(rig: CharacterRig, time: float, phase: float) -> void:
	rig.reset()
	walk(rig, phase, 1.0)
	...
```

`animate()` runs once per frame for every character. Rules:

- Call `rig.reset()` first and build the pose from rest. Keep no state in the animator: a shift swaps animators between two frames.
- Touch only the rig and its parts. The actor node (position, facing, collision) belongs to gameplay.
- Scale the whole character with `rig.squash(factor)`, never `rig.scale` directly, so boss and runner sizes survive.

Rig state you can read: `clock` (seconds alive), `phase` (walk cycle angle), `speed_ratio` (0 to about 1), `move_local` (movement direction relative to facing; forward is -Z), `recoil`, `hurt`, `dash` (each 1 decaying to 0), `spawn` (0 rising to 1), `death` (0 rising to 1), `dead`, `variation` (random 0 to 1 per character).

Parts: `body`, `head`, `visor`, `hand_l`, `hand_r`, `foot_l`, `foot_r`, and when present `weapon`, `horn_l`, `horn_r`. Helpers `rig.move(part, offset)`, `rig.turn(part, euler)` and `rig.stretch(part, factor)` ignore missing parts. The base class offers `walk()`, `lean()`, `kick()` and `life_scale()` to compose.

## Builder: shapes of its own

`builder.gd` extends `DimensionBuilder` (`game/core/dimension_builder.gd`) and decides what things are made of in this dimension. Override any of:

| Function | Builds |
| --- | --- |
| `character(rig, look, kind)` | a character, with `rig.add_part(name, mesh, position, palette_key, role, euler)` |
| `block(holder, extent, shape, role, color_key)` | the look of one arena block (wall or prop) |
| `pickup(holder, what)` | a pickup: `health`, `scatter`, `rapid` or `launcher` |
| `bullet_mesh()` | the bullet mesh (unit size, flies along -Z) |
| `decorate(holder, arena)` | scenery without collision around the arena |

Rules:

- Shapes are visual only; collision is shared. A character fits a capsule of radius 0.45 and height 1.8 before `look.scale`; a block stays inside its `extent` footprint (height is free); scenery stays outside the playfield or flat on the floor.
- Characters must have the parts `body`, `head`, `hand_l`, `hand_r`, `foot_l`, `foot_r`, plus `weapon` unless `look.weapon` is false. The weapon sits in the right hand and points along -Z: the weapon view shows only `weapon` and `hand_r`. Extra parts with any names are welcome, and the pack's own animator may move them.
- `kind` is `player`, `grunt`, `runner`, `tank`, `boss` or `bot`. Give each a silhouette that reads at a glance from above, from behind and at eye level: the three camera views.
- A shift rebuilds every shape on the same frame. Get meshes through `box()`, `sphere()`, `capsule()`, `cylinder()`, `cone()` or `shared(key, callable)`, which cache them; never create a new mesh per call. Add nodes with `add(parent, mesh, position, role, palette_key, euler)`.
- Keep no reference to the pack in the builder; use `Dimensions.hub.active` if you need it.

`names` in `pack.json` renames weapons (`blaster scatter rapid launcher`) for the HUD.

`arenas.json` uses the format of `game/core/data/arenas.json`. Survival and skirmish pick from it; Multiverse Shift and Campaign use the shared arenas because the layout must be the same in every dimension.

## HUD theme and feel

The HUD layout is fixed. `hud` changes panel corner `radius`, `border` width, drop `shadow` offset, `tilt` in degrees, `uppercase` text and `font_scale`; colours come from the `ui_*` and `ink` palette keys.

`feel.hitstop` is the freeze in seconds when the player scores a kill (bosses triple it). `feel.shake` multiplies camera shake.

## Desk object

The main menu is a workbench with one object per pack. The optional `desk` block picks it:

```json
"desk": {"object": "sketchbook", "cover": "@wall", "pages": "@floor", "art": "@prop", "accent": "@ui_accent", "scale": 1.0}
```

`object` is one of `sketchbook comic book sheets box figure lump blocks`; colours are palette keys. Without the block the menu picks an object from `family` (Paper: book-like, Plastic: sculpted). The object is drawn with the pack's own materials.

## Sound

Events: `shot scatter rapid launch enemy_shot boss_shot explosion hit hurt die dash swap pickup wave clear boss shift win lose music`. A file in the pack's `audio/` folder overrides `game/assets/audio/` for that event while the dimension is active. `music` loops and crossfades on a shift.

## Checking a pack

```sh
make check                                  # headless: every pack loads and survives shifts
make capture DIMENSION=anime                # saves builds/captures/anime.png from a live match
godot --path game -- --mode=shift           # play with random shifts
```
