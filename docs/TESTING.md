# Dragon Egg X — testing (macOS and iOS)

## Windows

This app is **Swift + SwiftUI** for **iOS and macOS** only. There is **no Windows executable** in this repository. You cannot run or meaningfully “QA” the native `.app` on Windows without:

- a **Mac** (local or remote) to build and run Xcode, or
- **CI** (e.g. GitHub Actions **macos** runner) to run `xcodebuild` and simulators, or
- a **different product** (e.g. web or Unity) if a Windows client is a goal.

Use this document for **macOS and iOS Simulator / device** only.

---

## Automated: bundle sanity

From the project root (folder containing `DragonEggX.xcodeproj`):

```bash
./scripts/verify_app_bundle.sh
```

This builds for **macOS** and checks that key summon/ULR media files are present under `.../DragonEggX.app/Contents/Resources/`. It does **not** replace visual QA of video playback.

---

## Manual matrix (each release or after media/project changes)

### macOS

1. In Xcode, scheme **DragonEggX**, run destination **My Mac** (or `xcodebuild` with `platform=macOS`).
2. **Summon** tab: tap **Summon (random demo)**. Confirm tier MP4 plays in the panel, then a **Pulled** card appears. Repeat **10+** times, including the **same** rarity back-to-back (no crash, video restarts each time).
3. **Collection** tab: open a few fighters; first ten catalog entries are ULR with `ULR_Asset_Slot` — confirm art shows when applicable.
4. **Team** tab: fill slots, return to **Battle** tab: party names list (smoke only).
5. If audio is inaudible, check system volume; iOS has separate **silent switch** (see iOS below).

### iOS (Simulator or device)

1. Run on an **iPhone** simulator or a **physical** device.
2. Repeat the same **Summon** / **Collection** / **Team** / **Battle** checks as on Mac.
3. **Simulator** video can differ from device (frame drops, GL); use a **device** for final VFX sign-off.
4. For **audio with hardware mute** on, use **Control Center** to confirm volume, or set `AVAudioSession` in app if you require playback in “silent” mode (not configured by default).

### Optional: stress

- Rapid tab switching while a summon is running (should be blocked by `isAnimating` + guard).
- After changing `Eternal_Summon_Assets`, re-run `xcodegen generate` and `./scripts/verify_app_bundle.sh`.

---

## What automated checks do *not* cover

- “Video is actually playing” (frames visible): requires **visual** inspection or a screenshot/record step.
- **Turn-based battle** (6v6, damage, win): not implemented in the app shell; see [BATTLE_ROADMAP.md](BATTLE_ROADMAP.md).

---

## Command-line build (no Xcode UI)

**macOS**

```bash
xcodebuild -scheme DragonEggX -destination "platform=macOS" -configuration Debug build
```

**iOS (device/sim generic)**

```bash
xcodebuild -scheme DragonEggX -destination "generic/platform=iOS" -configuration Debug build
```

Use a **signed** run destination for on-device install.
