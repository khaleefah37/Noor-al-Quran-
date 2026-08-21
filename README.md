# Noor Al-Quran

Flutter Android test app for Surah Al-Fatihah with:
- Arabic verses
- Play/pause/seek audio
- Local offline audio caching
- Admin MP3 file selection
- GitHub Actions Android APK build

## Admin PIN
`noor2026`

## Build locally
```bash
flutter pub get
flutter analyze
flutter build apk --release
```

## GitHub Actions
The workflow at `.github/workflows/build-apk.yml` builds and uploads `Noor-Al-Quran-APK`.
