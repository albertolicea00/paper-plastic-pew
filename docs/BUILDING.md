# Building

Every export goes through the Makefile, which runs Godot headless against `game/`. `make help` lists all targets.

## Prerequisites

- Godot 4.6.3 on the `PATH` as `godot`, or pass `GODOT_BIN=/path/to/godot`.
- Godot export templates for 4.6.3 (Editor > Manage Export Templates).
- Android: a JDK and the Android SDK, set in the Godot editor under Editor Settings > Export > Android. `adb` on the `PATH` (or `ADB=...`) for `make install-android`.
- iOS: macOS with Xcode, and a team and provisioning profile set in the iOS preset. Not configured yet.

Every export target runs `make import` first, so a fresh checkout needs no extra step.

## Android

```sh
make version          # print the version name and code the APK will carry, e.g. 0.1.0 (1)
make android          # debug APK
make android-release  # release APK, needs a release keystore (see below)
make install-android  # install the debug APK of the current version on the connected device
```

Both APKs land in `builds/android/` and are named

```
paper-plastic-pew-v<version>-<versionCode>-<debug|release>.apk
```

for example `paper-plastic-pew-v0.1.0-1-debug.apk`. Both use the `Android` export preset; only the debug or release flag differs.

### Version name and code

The single source of truth is the `Android` preset in `game/export_presets.cfg`: `version/name` (shown to users) and `version/code` (the integer Android uses to order updates). The Makefile reads both from that preset's options section with `awk`, and stops with an error if it cannot find them. To release a new version, change those two fields (in the editor's export dialog or the file) and raise the code every time a build ships.

The `Android Release (arm64)` and `Android Debug (arm64)` presets carry their own copies of both fields. The Makefile does not use those presets; if you export them from the editor, keep their version fields in sync by hand.

### Signing

**Debug.** The preset's debug keystore fields are empty, so Godot signs with the editor's own debug keystore (Editor Settings > Export > Android > Debug Keystore), which it creates automatically. Nothing to set up.

**Release.** Release signing is not wired into this repository. The Makefile passes no keystore, the release keystore fields are not stored in `export_presets.cfg`, and nothing reads `keys/release.properties` (it is only listed in `.gitignore`). `make android-release` succeeds only if Godot finds a release keystore through one of its own mechanisms:

1. Environment variables, read by Godot at export time and taking precedence over the preset:

   ```sh
   GODOT_ANDROID_KEYSTORE_RELEASE_PATH=/absolute/path/to/release.jks \
   GODOT_ANDROID_KEYSTORE_RELEASE_USER=<key alias> \
   GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD='<password>' \
   make android-release
   ```

   The values are used verbatim; the only escaping is your shell's quoting (single quotes keep `$`, `\` and spaces literal). Use an absolute path.

2. The editor's export dialog (Project > Export > Android > Keystore > Release, User, Password). Godot keeps those fields out of `export_presets.cfg` and writes them to `game/.godot/export_credentials.cfg`, which is git-ignored. `make clean` deletes `game/.godot/`, so it also deletes these saved credentials; prefer the environment variables.

If a `keys/release.properties` loader is added later, document its format here. Should it be parsed as Java Properties, `\` is an escape character there, so a literal backslash in a path or password has to be written `\\`.

Never commit a keystore, its passwords, or `export_credentials.cfg`.

## Other platforms

These use fixed, unversioned names:

| Command | Output |
| --- | --- |
| `make ios` | `builds/ios/paper-plastic-pew.zip` (Xcode project, needs iOS signing in the preset) |
| `make macos` | `builds/macos/paper-plastic-pew.zip` |
| `make windows` | `builds/windows/paper-plastic-pew.exe` |
| `make linux` | `builds/linux/paper-plastic-pew.x86_64` |

All of them are debug exports.

## Cleaning

`make clean` removes the Godot import cache (`game/.godot/`, including saved export credentials) and every folder under `builds/` that the Makefile writes, so old APKs with other version names go too.
