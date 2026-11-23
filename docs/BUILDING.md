# Building

Every export goes through the Makefile, which runs Godot headless against `game/`. `make help` lists all targets.

## Prerequisites

- Godot 4.6.3 on the `PATH` as `godot`, or pass `GODOT_BIN=/path/to/godot`.
- Godot export templates for 4.6.3 (Editor > Manage Export Templates).
- Android: a JDK and the Android SDK, set in the Godot editor under Editor Settings > Export > Android. `adb` on the `PATH` (or `ADB=...`) for `make install-android`.
- iOS: macOS with Xcode signed in to your Apple ID, and `DEVELOPMENT_TEAM` in `keys/ios.properties` (see [iOS](#ios)).

Every export target runs `make import` first, so a fresh checkout needs no extra step.

## Android

```sh
make version          # print the version name and code the APK will carry, e.g. 0.1.0 (1)
make android          # debug APK
make android-release  # release APK signed with keys/release.properties (see below)
make install-android  # install the debug APK of the current version on the connected device
```

Both APKs land in `builds/android/` and are named

```
paper-plastic-pew-v<version>-<versionCode>-<debug|release>.apk
```

for example `paper-plastic-pew-v0.1.0-1-debug.apk`. The debug APK uses the `Android` preset (arm64 and x86_64, so it also runs on emulators); the release APK uses the `Android Release (arm64)` preset (arm64 only, exported unsigned and signed afterwards, see [Signing](#signing)).

Run one Godot export at a time, also across projects: parallel exports share Godot's temporary APK in its global cache and fail with "Could not unzip temporary unaligned APK" or produce a broken APK.

### Version name and code

The single source of truth is the `Android` preset in `game/export_presets.cfg`: `version/name` (shown to users) and `version/code` (the integer Android uses to order updates). The Makefile reads both from that preset's options section with `awk`, and stops with an error if it cannot find them. To release a new version, change those two fields (in the editor's export dialog or the file) and raise the code every time a build ships.

The `Android Release (arm64)` and `Android Debug (arm64)` presets carry their own copies of both fields; keep them in sync. `make android-release` stops if the release preset's version differs from the `Android` preset's, since the file name and the manifest would disagree.

### Signing

**Debug.** The preset's debug keystore fields are empty, so Godot signs with the editor's own debug keystore (Editor Settings > Export > Android > Debug Keystore), which it creates automatically. Nothing to set up.

**Release.** `make android-release` exports the unsigned `Android Release (arm64)` preset and then runs `tools/sign_apk.py`, which aligns it with `zipalign` (16 KB pages on build-tools 35+) and signs it with `apksigner` using `keys/release.properties` (git-ignored; copy `keys/release.properties.example`):

```properties
storeFile=release.jks
storePassword=...
keyAlias=key0
keyPassword=...
```

- `storeFile` is relative to `keys/`.
- The file follows Java Properties rules: a literal backslash is written `\\`; other characters (`= : # ! $`, quotes) go as they are, without quotes.
- The passwords reach `apksigner` through environment variables and are never printed.

Godot is not left to sign the release itself because it passes the keystore password through a shell: a password containing shell characters (such as `$`, `!`, `|`, `\`, `"`, `` ` ``, `&`, `<`, `>`) makes its export fail with "Release Username and/or Password is invalid" or a shell syntax error. The script needs Python 3 and the Android SDK build-tools (found through `ANDROID_HOME`, `ANDROID_SDK_ROOT` or `~/Library/Android/sdk`).

Never commit a keystore, its passwords, or `export_credentials.cfg`.

## iOS

`make ipa` writes `builds/ios/paper-plastic-pew-v<version>-<build>-release.ipa`, signed through Xcode:

1. Godot exports the iOS preset as an Xcode project (release template).
2. `xcodebuild` archives it in Release and exports the IPA with automatic signing.

- **Team:** `DEVELOPMENT_TEAM` in `keys/ios.properties` (git-ignored; copy `keys/ios.properties.example`), or `TEAM=<id>`. `tools/export_ipa.sh` writes it into the iOS preset only for the export, together with `application/export_project_only=true`, and always restores `game/export_presets.cfg` afterwards, so the team id never reaches git.
- **Version:** `application/short_version` and `application/version` in the `iOS` preset; keep them equal to the Android preset's `version/name` and `version/code`.
- **Export method:** `IPA_METHOD=debugging` (default with a free personal team), `release-testing` (Ad Hoc) or `app-store-connect` (default with a paid team). A free personal team only allows `debugging`: the IPA installs on your own registered devices and stops opening after 7 days. Ad Hoc, TestFlight and the App Store need the paid Apple Developer Program.

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
