.DEFAULT_GOAL := help

GODOT_BIN ?= godot
PYTHON ?= python3
ADB ?= adb

PROJECT := game
# Version name and code come from the "Android" preset in game/export_presets.cfg.
# $(call ANDROID_PRESET_FIELD,<field>[,<preset name>]) reads one option of one preset.
ANDROID_PRESET_FIELD = $(shell awk -v field='$(1)' -v preset='name="$(or $(2),Android)"' ' \
	/^\[preset\.[0-9]+\]$$/ { section = $$0; gsub(/[][]/, "", section) } \
	$$0 == preset { target = section ".options" } \
	/^\[/ { current = $$0; gsub(/[][]/, "", current) } \
	current == target && index($$0, field "=") == 1 { value = substr($$0, length(field) + 2); gsub(/"/, "", value); print value; exit } \
	' "$(PROJECT)/export_presets.cfg")
VERSION := $(call ANDROID_PRESET_FIELD,version/name)
VERSION_CODE := $(call ANDROID_PRESET_FIELD,version/code)
ifeq ($(strip $(VERSION)$(VERSION_CODE)),)
$(error Could not read version/name and version/code from the Android preset in $(PROJECT)/export_presets.cfg)
endif
# The release APK comes from its own preset, which keeps its own copy of both fields.
RELEASE_PRESET := Android Release (arm64)
RELEASE_VERSION := $(call ANDROID_PRESET_FIELD,version/name,$(RELEASE_PRESET)) ($(call ANDROID_PRESET_FIELD,version/code,$(RELEASE_PRESET)))
ANDROID_APK := builds/android/paper-plastic-pew-v$(VERSION)-$(VERSION_CODE)-debug.apk
ANDROID_RELEASE_APK := builds/android/paper-plastic-pew-v$(VERSION)-$(VERSION_CODE)-release.apk
ANDROID_RELEASE_UNSIGNED := $(ANDROID_RELEASE_APK:.apk=-unsigned.apk)
IOS_ZIP := builds/ios/paper-plastic-pew.zip
MACOS_ZIP := builds/macos/paper-plastic-pew.zip
MACOS_DMG := builds/macos/paper-plastic-pew-v$(VERSION)-$(VERSION_CODE)-release.dmg
WINDOWS_EXE := builds/windows/paper-plastic-pew-v$(VERSION)-$(VERSION_CODE)-release.exe
DIMENSION ?= anime
MODE ?= survival
VIEW ?= top

.PHONY: ipa dmg exe help import run touch shift check capture captures android android-release \
	install-android version ios macos windows linux clean

help:
	@printf '%s\n' \
	  'make import           Import Godot resources' \
	  'make run              Run the desktop game' \
	  'make touch            Run with touch controls visible' \
	  'make shift            Jump straight into Multiverse Shift mode' \
	  'make check            Run the headless gameplay checks' \
	  'make capture          Save builds/captures/$$DIMENSION.png (DIMENSION=anime MODE=survival)' \
	  'make captures         Capture every dimension' \
	  'make android          Export builds/android/paper-plastic-pew-v<version>-<code>-debug.apk' \
	  'make android-release  Export the matching -release.apk signed with keys/release.properties' \
	  'make install-android  Install the debug APK of the current version via ADB' \
	  'make version          Print the Android version name and code' \
	  'make ipa              Export the signed iOS IPA (team from keys/ios.properties)' \
	  'make ios              Export the iOS project once signing is configured' \
	  'make dmg              Export builds/macos/paper-plastic-pew-v<version>-<code>-release.dmg' \
	  'make exe              Export builds/windows/paper-plastic-pew-v<version>-<code>-release.exe' \
	  'make macos | windows | linux   Export a desktop build' \
	  'make clean            Remove the Godot import cache and exported packages'

import:
	"$(GODOT_BIN)" --headless --path "$(PROJECT)" --editor --import --quit

run: import
	"$(GODOT_BIN)" --path "$(PROJECT)"

touch: import
	"$(GODOT_BIN)" --path "$(PROJECT)" -- --touch

shift: import
	"$(GODOT_BIN)" --path "$(PROJECT)" -- --mode=shift

check:
	GODOT_BIN="$(GODOT_BIN)" "$(PYTHON)" tools/check.py

capture:
	mkdir -p builds/captures
	"$(GODOT_BIN)" --path "$(PROJECT)" --resolution 1280x720 -- --capture="$(CURDIR)/builds/captures/$(DIMENSION).png" \
	  --dimension=$(DIMENSION) --mode=$(MODE) --arena=crossroads --view=$(VIEW) --mute --capture-after=7

captures:
	for folder in $(PROJECT)/dimensions/*/; do $(MAKE) capture DIMENSION=$$(basename $$folder); done

android: import
	mkdir -p "$(dir $(ANDROID_APK))"
	"$(GODOT_BIN)" --headless --path "$(PROJECT)" --export-debug Android "$(CURDIR)/$(ANDROID_APK)"

# Godot cannot sign with passwords that contain shell characters, so it exports the unsigned
# "Android Release (arm64)" preset and tools/sign_apk.py signs it with keys/release.properties.
android-release: import
	mkdir -p "$(dir $(ANDROID_RELEASE_APK))"
	@test "$(RELEASE_VERSION)" = "$(VERSION) ($(VERSION_CODE))" || { printf '%s\n' 'The "$(RELEASE_PRESET)" preset is $(RELEASE_VERSION), the Android preset $(VERSION) ($(VERSION_CODE)). Make them match.' >&2; exit 1; }
	"$(GODOT_BIN)" --headless --path "$(PROJECT)" --export-release "$(RELEASE_PRESET)" "$(CURDIR)/$(ANDROID_RELEASE_UNSIGNED)"
	"$(PYTHON)" tools/sign_apk.py "$(ANDROID_RELEASE_UNSIGNED)" "$(ANDROID_RELEASE_APK)" keys/release.properties
	rm -f "$(ANDROID_RELEASE_UNSIGNED)"

version:
	@printf '%s (%s)\n' "$(VERSION)" "$(VERSION_CODE)"

install-android:
	@test -f "$(ANDROID_APK)" || { printf '%s\n' '$(ANDROID_APK) missing. Run make android first.' >&2; exit 1; }
	"$(ADB)" install -r "$(ANDROID_APK)"

# Signed IPA from the iOS preset: builds/ios/paper-plastic-pew-v<version>-<build>-release.ipa.
# Team from keys/ios.properties; IPA_METHOD=debugging|release-testing|app-store-connect.
ipa: import
	GODOT_BIN="$(GODOT_BIN)" tools/export_ipa.sh "$(PROJECT)" paper-plastic-pew

ios: import
	mkdir -p "$(dir $(IOS_ZIP))"
	"$(GODOT_BIN)" --headless --path "$(PROJECT)" --export-debug iOS "$(CURDIR)/$(IOS_ZIP)"

# The macOS and Windows presets keep their own copies of the version: macOS short_version and
# version (build) must be <version> and <code>, Windows file/product_version <version>.<code>.
MACOS_VERSION := $(call ANDROID_PRESET_FIELD,application/short_version,macOS) ($(call ANDROID_PRESET_FIELD,application/version,macOS))
WINDOWS_VERSION := $(call ANDROID_PRESET_FIELD,application/file_version,Windows Desktop)/$(call ANDROID_PRESET_FIELD,application/product_version,Windows Desktop)

# Release desktop builds named like the APKs. The .dmg is ad-hoc signed by Godot (no Developer ID),
# not notarized; see the docs for opening it on another Mac (Gatekeeper). The .exe embeds the .pck.
dmg: import
	@test "$(MACOS_VERSION)" = "$(VERSION) ($(VERSION_CODE))" || { printf '%s\n' 'The macOS preset is $(MACOS_VERSION), the Android preset $(VERSION) ($(VERSION_CODE)). Make them match.' >&2; exit 1; }
	mkdir -p "$(dir $(MACOS_DMG))"
	"$(GODOT_BIN)" --headless --path "$(PROJECT)" --export-release macOS "$(CURDIR)/$(MACOS_DMG)"

exe: import
	@test "$(WINDOWS_VERSION)" = "$(VERSION).$(VERSION_CODE)/$(VERSION).$(VERSION_CODE)" || { printf '%s\n' 'The Windows preset file/product_version is $(WINDOWS_VERSION); expected $(VERSION).$(VERSION_CODE) for both.' >&2; exit 1; }
	mkdir -p "$(dir $(WINDOWS_EXE))"
	"$(GODOT_BIN)" --headless --path "$(PROJECT)" --export-release "Windows Desktop" "$(CURDIR)/$(WINDOWS_EXE)"

macos: import
	mkdir -p "$(dir $(MACOS_ZIP))"
	"$(GODOT_BIN)" --headless --path "$(PROJECT)" --export-debug macOS "$(CURDIR)/$(MACOS_ZIP)"

windows: import
	mkdir -p builds/windows
	"$(GODOT_BIN)" --headless --path "$(PROJECT)" --export-debug "Windows Desktop" "$(CURDIR)/builds/windows/paper-plastic-pew.exe"

linux: import
	mkdir -p builds/linux
	"$(GODOT_BIN)" --headless --path "$(PROJECT)" --export-debug Linux "$(CURDIR)/builds/linux/paper-plastic-pew.x86_64"

clean:
	rm -rf "$(PROJECT)/.godot" builds/android builds/ios builds/macos builds/windows builds/linux builds/captures
