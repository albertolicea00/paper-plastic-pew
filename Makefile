.DEFAULT_GOAL := help

GODOT_BIN ?= godot
PYTHON ?= python3
ADB ?= adb

PROJECT := game
ANDROID_APK := builds/android/paper-plastic-pew-debug.apk
ANDROID_RELEASE_APK := builds/android/paper-plastic-pew-release.apk
IOS_ZIP := builds/ios/paper-plastic-pew.zip
MACOS_ZIP := builds/macos/paper-plastic-pew.zip
DIMENSION ?= anime
MODE ?= survival

.PHONY: help import run touch shift check capture captures android android-release \
	install-android ios macos windows linux clean

help:
	@printf '%s\n' \
	  'make import           Import Godot resources' \
	  'make run              Run the desktop game' \
	  'make touch            Run with touch controls visible' \
	  'make shift            Jump straight into Multiverse Shift mode' \
	  'make check            Run the headless gameplay checks' \
	  'make capture          Save builds/captures/$$DIMENSION.png (DIMENSION=anime MODE=survival)' \
	  'make captures         Capture every dimension' \
	  'make android          Export the Android debug APK' \
	  'make android-release  Export a release APK (requires release signing)' \
	  'make install-android  Install the debug APK via ADB' \
	  'make ios              Export the iOS project once signing is configured' \
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
	  --dimension=$(DIMENSION) --mode=$(MODE) --arena=crossroads --capture-after=7

captures:
	for folder in $(PROJECT)/dimensions/*/; do $(MAKE) capture DIMENSION=$$(basename $$folder); done

android: import
	mkdir -p "$(dir $(ANDROID_APK))"
	"$(GODOT_BIN)" --headless --path "$(PROJECT)" --export-debug Android "$(CURDIR)/$(ANDROID_APK)"

android-release: import
	mkdir -p "$(dir $(ANDROID_RELEASE_APK))"
	"$(GODOT_BIN)" --headless --path "$(PROJECT)" --export-release Android "$(CURDIR)/$(ANDROID_RELEASE_APK)"

install-android:
	@test -f "$(ANDROID_APK)" || { printf '%s\n' 'Debug APK missing. Run make android first.' >&2; exit 1; }
	"$(ADB)" install -r "$(ANDROID_APK)"

ios: import
	mkdir -p "$(dir $(IOS_ZIP))"
	"$(GODOT_BIN)" --headless --path "$(PROJECT)" --export-debug iOS "$(CURDIR)/$(IOS_ZIP)"

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
