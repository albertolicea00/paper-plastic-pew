# Project instructions

- Use English for all game UI, prompts, controls, display names, code, comments and documentation.
- Title: `Paper, Plastic, Pew!`. Slug: `paper-plastic-pew`. Android application ID and iOS bundle identifier: `com.paper.plastic.pew`.
- Godot 4.6, GL Compatibility renderer, one shared project in `game/` for Android, iOS and desktop.
- `game/core/` holds dimension-agnostic gameplay; `game/ui/` the HUD, touch controls and menu; `game/dimensions/<id>/` one folder per visual dimension. A new dimension must not require changes outside its own folder. See `docs/ARCHITECTURE.md` and `docs/DIMENSION_PACKS.md`.
- Dimensions change look, animation, sound and feel only. Collision, hitboxes, speeds and rules are shared so a shift can happen mid-fight.
- `../doodleshooter-port` is a separate, archived project: read it for reference, never modify it, and do not copy its Doodle assets, maps or attribution.
- Third-party material must be free to use (CC0 audio, OFL fonts) and listed in `CREDITS.txt` (mirrored to `game/CREDITS.txt` so it ships). Never invent authors or sources.
- Run `make check` after gameplay changes. Headless checks prove logic only; look at `make capture` output before claiming anything visual. Device play is unverified until someone plays on a device.
- Commits: Conventional Commits, small and scoped, no co-author trailers.
- Online multiplayer is deferred to a later phase. Do not invent signing credentials or store listings.
