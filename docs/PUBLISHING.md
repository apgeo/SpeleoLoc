# Publishing SpeleoLoc — App Store Versioning Guide

This guide answers common versioning questions when preparing SpeleoLoc (or any Flutter app) for publication on Google Play and the Apple App Store.

---

## Can I publish a version smaller than 1.0.0?

### 1. Google Play (Android)

**Yes — pre-1.0.0 version names are fully supported.**

Google Play distinguishes between two version fields that are set in `pubspec.yaml` (Flutter maps them automatically):

| Flutter field | Android field | Requirement |
|---|---|---|
| `version name` (e.g. `0.2.5`) | `versionName` | Any human-readable string; no minimum value |
| `build number` (e.g. `+150`) | `versionCode` | A **positive integer**; must increase with every upload |

Google Play only enforces that the `versionCode` integer is strictly greater than the previously uploaded build. The `versionName` string is purely informational (shown to users) and has no format restriction — `0.2.5`, `0.1.1`, or even `alpha` are all accepted.

**Example** — the current `pubspec.yaml` entry:

```yaml
version: 0.1.1+150
```

maps to `versionName = "0.1.1"` and `versionCode = 150`, which is a perfectly valid Google Play release.

**Key points:**
- No policy requires version ≥ 1.0.0.
- Increment `versionCode` (`+N`) with every build you upload; you cannot reuse or decrease it.
- Semantic versioning (`MAJOR.MINOR.PATCH`) is a convention, not a store requirement.

---

### 2. App Store (iOS / Apple)

**Yes — pre-1.0.0 version strings are accepted by the App Store.**

Apple uses two separate version fields, both sourced from `pubspec.yaml` in a Flutter project:

| Flutter field | iOS field | Requirement |
|---|---|---|
| `version name` (e.g. `0.2.5`) | `CFBundleShortVersionString` | Three period-separated non-negative integers (e.g. `0.2.5`); shown as the "Version" in App Store Connect |
| `build number` (e.g. `+150`) | `CFBundleVersion` | One or more period-separated non-negative integers (e.g. `150`); must increase with every TestFlight/App Store upload for the same version |

Apple requires that `CFBundleShortVersionString` follows the `X.Y.Z` format (three numeric components), but **does not require that the first component be ≥ 1**. Values like `0.2.5` or `0.1.1` are valid.

**Example** — the current `pubspec.yaml` entry:

```yaml
version: 0.1.1+150
```

maps to `CFBundleShortVersionString = "0.1.1"` and `CFBundleVersion = "150"`, which App Store Connect accepts.

**Key points:**
- The version string must be `X.Y.Z` with numeric components; `0.x.y` is fine.
- `CFBundleVersion` (build number) must increase for every build submitted to TestFlight or App Store Connect. It resets only if you switch to an entirely new version string.
- Apple may ask users whether they want to update from `0.x` to `1.0` — consider user-facing expectations when planning your public versioning strategy, even though the store has no hard rule.

---

## Summary table

| | Google Play | App Store |
|---|---|---|
| Pre-1.0.0 version allowed? | ✅ Yes | ✅ Yes |
| Version name format | Any string | `X.Y.Z` (numeric) |
| Build / version code must increase? | ✅ Yes (`versionCode`) | ✅ Yes (`CFBundleVersion`) |
| Where set in Flutter | `pubspec.yaml` `version:` | `pubspec.yaml` `version:` |

---

## Flutter `pubspec.yaml` version format recap

```yaml
version: MAJOR.MINOR.PATCH+BUILD_NUMBER
#         └─ version name ─┘ └─ build ─┘
# Example:
version: 0.2.5+42
```

- **`MAJOR.MINOR.PATCH`** becomes `versionName` (Android) / `CFBundleShortVersionString` (iOS).
- **`BUILD_NUMBER`** becomes `versionCode` (Android) / `CFBundleVersion` (iOS).
- Both stores require `BUILD_NUMBER` to increase monotonically with each upload.

For more details see:
- [Android versioning](https://developer.android.com/studio/publish/versioning)
- [iOS CFBundleShortVersionString / CFBundleVersion](https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CoreFoundationKeys.html)
- [Flutter build versioning](https://flutter.dev/to/build-name-and-number)
