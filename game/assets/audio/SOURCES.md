# Audio sources

Every file is CC0 1.0 (public domain dedication). Paths are relative to `game/`. "copy" means the original file is shipped unchanged; otherwise the listed ffmpeg audio filter was applied and the result written as mono 44.1 kHz 16-bit WAV (`ffmpeg -i <original> -af "<filter>" -ac 1 -ar 44100 -c:a pcm_s16le <file>`).

Kenney packs are downloaded from the "Download" button on each pack page; the audio is in the archive's `Audio/` folder.

## Sound effects

| File | Original | Pack | Author | Licence | URL | Processing |
| --- | --- | --- | --- | --- | --- | --- |
| `assets/audio/shot.ogg` | `laserSmall_000.ogg` | Sci-Fi Sounds (1.0) | Kenney | CC0 | https://kenney.nl/assets/sci-fi-sounds | copy |
| `assets/audio/rapid.wav` | `laserSmall_001.ogg` | Sci-Fi Sounds (1.0) | Kenney | CC0 | https://kenney.nl/assets/sci-fi-sounds | `volume=-3dB` |
| `assets/audio/scatter.wav` | `laserLarge_001.ogg` | Sci-Fi Sounds (1.0) | Kenney | CC0 | https://kenney.nl/assets/sci-fi-sounds | `atrim=0:0.5,afade=t=out:st=0.35:d=0.15` |
| `assets/audio/launch.wav` | `thrusterFire_000.ogg` | Sci-Fi Sounds (1.0) | Kenney | CC0 | https://kenney.nl/assets/sci-fi-sounds | `atrim=0:0.6,afade=t=out:st=0.3:d=0.3,volume=2dB` |
| `assets/audio/enemy_shot.wav` | `laserRetro_003.ogg` | Sci-Fi Sounds (1.0) | Kenney | CC0 | https://kenney.nl/assets/sci-fi-sounds | `volume=-9dB` |
| `assets/audio/boss_shot.ogg` | `laserLarge_004.ogg` | Sci-Fi Sounds (1.0) | Kenney | CC0 | https://kenney.nl/assets/sci-fi-sounds | copy |
| `assets/audio/explosion.ogg` | `lowFrequency_explosion_001.ogg` | Sci-Fi Sounds (1.0) | Kenney | CC0 | https://kenney.nl/assets/sci-fi-sounds | copy |
| `assets/audio/die.wav` | `explosionCrunch_000.ogg` | Sci-Fi Sounds (1.0) | Kenney | CC0 | https://kenney.nl/assets/sci-fi-sounds | `atrim=0:0.55,afade=t=out:st=0.4:d=0.15,volume=-2dB` |
| `assets/audio/shift.wav` | `forceField_000.ogg` | Sci-Fi Sounds (1.0) | Kenney | CC0 | https://kenney.nl/assets/sci-fi-sounds | `volume=-2dB` |
| `assets/audio/hit.ogg` | `impactGeneric_light_000.ogg` | Impact Sounds | Kenney | CC0 | https://kenney.nl/assets/impact-sounds | copy |
| `assets/audio/hurt.ogg` | `impactPunch_heavy_002.ogg` | Impact Sounds | Kenney | CC0 | https://kenney.nl/assets/impact-sounds | copy |
| `assets/audio/dash.wav` | `phaseJump2.ogg` | Digital Audio | Kenney | CC0 | https://kenney.nl/assets/digital-audio | `volume=-3dB` |
| `assets/audio/pickup.ogg` | `powerUp2.ogg` | Digital Audio | Kenney | CC0 | https://kenney.nl/assets/digital-audio | copy |
| `assets/audio/wave.wav` | `twoTone1.ogg` | Digital Audio | Kenney | CC0 | https://kenney.nl/assets/digital-audio | `volume=-2dB` |
| `assets/audio/clear.wav` | `threeTone1.ogg` | Digital Audio | Kenney | CC0 | https://kenney.nl/assets/digital-audio | `volume=-3dB` |
| `assets/audio/boss.wav` | `lowThreeTone.ogg` | Digital Audio | Kenney | CC0 | https://kenney.nl/assets/digital-audio | `volume=-3dB` |
| `assets/audio/win.wav` | `zapThreeToneUp.ogg` | Digital Audio | Kenney | CC0 | https://kenney.nl/assets/digital-audio | `volume=-4dB` |
| `assets/audio/lose.wav` | `zapThreeToneDown.ogg` | Digital Audio | Kenney | CC0 | https://kenney.nl/assets/digital-audio | `volume=-5dB` |
| `assets/audio/swap.ogg` | `switch_003.ogg` | Interface Sounds | Kenney | CC0 | https://kenney.nl/assets/interface-sounds | copy |
| `assets/audio/heartbeat.ogg` | `heartbeat_fast_0.wav` | Heartbeat sounds | bart | CC0 | https://opengameart.org/content/heartbeat-sounds | converted to OGG Vorbis (`-c:a vorbis -q:a 4`) |
| `dimensions/clay/audio/hit.wav` | `impactSoft_medium_000.ogg` | Impact Sounds | Kenney | CC0 | https://kenney.nl/assets/impact-sounds | `volume=-3dB` |
| `dimensions/clay/audio/die.ogg` | `slime_000.ogg` | Sci-Fi Sounds (1.0) | Kenney | CC0 | https://kenney.nl/assets/sci-fi-sounds | copy |

## Music

| File | Original | Title / pack | Author | Licence | URL | Processing |
| --- | --- | --- | --- | --- | --- | --- |
| `dimensions/anime/audio/music.ogg` | `Action3 - Preparing For Battle.ogg` in `JRPG Music Pack #5 [Action] by Juhani Junkala.zip` | JRPG Pack 5 Action | Juhani Junkala (SubspaceAudio) | CC0 | https://opengameart.org/content/jrpg-pack-5-action | copy |
| `dimensions/cartoon/audio/music.ogg` | `carnivalrides.ogg` | Carnival Rides | Écrivain | CC0 | https://opengameart.org/content/carnival-rides | copy |
| `dimensions/clay/audio/music.ogg` | `WereWasI_0.ogg` | Where was I? | yd | CC0 | https://opengameart.org/content/where-was-i | copy |
| `dimensions/blocks/audio/music.ogg` | `Children's March Theme.ogg` in `childrens_march_theme.zip` | Children's March Theme | Cleyton Kauffman | CC0 | https://opengameart.org/content/childrens-march-theme | copy |
| `dimensions/pixel/audio/music.ogg` | `8BitBattleLoop.ogg` | 8-Bit Battle Loop | Wolfgang_ | CC0 | https://opengameart.org/content/8-bit-battle-loop | copy |
| `dimensions/stick/audio/music.ogg` | `forest_loop.ogg` | Ukulele Forest (Beginning, Loop and End) | StarNinjas | CC0 | https://opengameart.org/content/ukulele-forest-beginning-loop-and-end | copy |
| `assets/audio/music.ogg` | `8bit attempt.ogg` | Summer Park - 8bit tune (loop) | Scribe (Daniel Stephens) | CC0 | https://opengameart.org/content/summer-park-8bit-tune-loop | copy |
| `assets/audio/menu.ogg` | `Ambient-Loop-isaiah658_0.ogg` | Ambient Relaxing Loop | isaiah658 | CC0 | https://opengameart.org/content/ambient-relaxing-loop | copy |
