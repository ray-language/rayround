# RayRound — common tasks. `make` (or `make help`) lists them.

APP     := RayRound
IOS     := $(APP)-ios
ANDROID := $(APP)-android

.DEFAULT_GOAL := help
.PHONY: help run dev dev-device test test-native check-page icon demo sounds bundle-macos bundle-ios ios-lib ios-lib-sim ios-libs ios-sim-build bundle-android android-apk bundle-ios-dev bundle-android-dev

help: ## List the targets
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "} {printf "  %-16s %s\n", $$1, $$2}'

run: ## Desktop window (the page from www/, the clock and the sounds from the program)
	ray run

dev: ## Same, restarting on changes
	ray dev

dev-device: ## Push the program to the phone's development shell on every change
	ray dev --device

# The audio output is a real-time null sink under test: no sound card, the clock still runs.
TEST_ENV := RAY_AUDIO_SINK=null RAY_UI_BACKEND=headless

test: ## Tests: the plan, the sounds, the engine, the page protocol
	$(TEST_ENV) ray test

test-native: ## The same tests as native binaries
	$(TEST_ENV) ray test --native

check-page: ## ray-elements' checker over the page (after `ray fetch`)
	node node_modules/@raylang/elements/check/cli.js check www/

icon: ## Render assets/icon.png and www/icon.png
	ray build --native --release scripts/make-icon.ray -o .make-icon && ./.make-icon && rm -f .make-icon

demo: ## A 30-second session on this machine's speakers
	ray run scripts/demo.ray

sounds: ## Write the sounds as WAV files into sounds/
	mkdir -p sounds && ray run scripts/render-sounds.ray -- sounds

# ---- macOS ----

bundle-macos: ## Build RayRound.app
	ray bundle

# ---- iOS ----

bundle-ios: ## (Re)generate the Xcode project in RayRound-ios/ (device + simulator libraries)
	ray bundle --ios

ios-lib: ## Rebuild the iPhone static library after a change (Xcode project untouched)
	ray build --native --lib --release --target aarch64-apple-ios -o $(IOS)/libs/libray_app.a

ios-lib-sim: ## Rebuild the simulator static library
	ray build --native --lib --release --target aarch64-apple-ios-sim -o $(IOS)/libs-sim/libray_app.a

ios-libs: ios-lib ios-lib-sim ## Both libraries

ios-sim-build: ios-lib-sim ## Build the app for the simulator (unsigned)
	cd $(IOS) && xcodebuild -project $(APP).xcodeproj -target $(APP) -sdk iphonesimulator \
		-configuration Debug build CODE_SIGNING_ALLOWED=NO

# ---- Android ----

bundle-android: ## (Re)generate the Gradle project in RayRound-android/ (arm64)
	ray bundle --android --android-abi arm64

android-apk: ## Build the debug APK from RayRound-android/
	cd $(ANDROID) && gradle assembleDebug

# ---- Live development (development shell, id org.raylang.rayround.dev) ----

bundle-ios-dev: ## Xcode project of the development shell in RayRound-dev-ios/
	ray bundle --ios --dev

bundle-android-dev: ## Gradle project of the development shell in RayRound-dev-android/ (arm64)
	ray bundle --android --dev --android-abi arm64
