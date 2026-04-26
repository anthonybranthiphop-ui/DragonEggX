# App device build report

**Date:** 2026-04-26

## Scheme used

- **DragonEggX** (only scheme listed by `xcodebuild -list -project DragonEggX.xcodeproj`)

## Generic iOS device build

- **Result:** **PASS** (`** BUILD SUCCEEDED **` when `xcodebuild` wrote output to a file with no shell pipe; piping to `tail` can yield `** BUILD INTERRUPTED **` due to SIGPIPE and must not be used to judge success.)
- **SDK / destination:** `generic/platform=iOS` (iPhoneOS SDK 26.4, `Debug-iphoneos` product)
- **Derived data:** CLI build used  
  `XcodeBuildData/DerivedData-iOS-Device`  
  A first attempt targeting `XcodeBuildData/DerivedData` failed with **“database is locked”** (likely a concurrent or stuck build using the same path). If you see that error, wait for any other `xcodebuild` to finish or use a fresh `-derivedDataPath` directory.
- **Signing (from successful log):** Apple Development identity and iOS Team Provisioning Profile `*` for the app bundle and embedded binaries.

**Exact command that succeeded (no pipeline on stdout):**

```bash
cd /Volumes/SharedDrive_APFS/Xcode/DragonEggX/DragonEggX

xcodebuild \
  -project DragonEggX.xcodeproj \
  -scheme DragonEggX \
  -destination 'generic/platform=iOS' \
  -derivedDataPath XcodeBuildData/DerivedData-iOS-Device \
  build > /tmp/dragoneggx-nopipe.log 2>&1
```

You may switch `-derivedDataPath` back to `XcodeBuildData/DerivedData` if that folder is not locked.

## Compile errors fixed

- **None.** The project already compiled; no source edits were required for this device build.

## Files changed in repo (this pass)

- **This report only:** `docs/APP_DEVICE_BUILD_REPORT.md`  
- No Swift, assets, XLSX, or project file edits for compilation.

## Notes (non-simulator)

- `xcodebuild -list` may print CoreSimulator / SimDeviceSet warnings on your machine; that does not affect a **generic/platform=iOS** build. No simulator runtimes or `simctl` were used for this report.

## Next steps in Xcode (physical iPhone)

1. Open **`/Volumes/SharedDrive_APFS/Xcode/DragonEggX/DragonEggX/DragonEggX.xcodeproj`** in Xcode.
2. Connect your iPhone with USB (or use trusted wireless debugging if you already paired it).
3. In the toolbar, set the run destination to **your iPhone** (not “Any iOS Device” if you need install debugging—pick the named device).
4. Select the **DragonEggX** scheme.
5. **Product → Run** (⌘R), or click Run.
6. If prompted on the phone: **Settings → General → VPN & Device Management** (or **Device Management**) → trust the developer app if this is the first install for that team.

If code signing issues appear in Xcode, use **Signing & Capabilities** for the DragonEggX target: choose your **Team** and let Xcode manage signing, or match the same Apple Development / provisioning setup the CLI used.

## Product path (optional)

Built app from the successful CLI run:

`XcodeBuildData/DerivedData-iOS-Device/Build/Products/Debug-iphoneos/DragonEggX.app`
