# Recorder Mobile (Flutter)

Mobile audio recording app for reading CSV-sourced transcriptions and saving numbered recordings (1..N) with timestamps, inspired by your Streamlit web app.

## Features
- Load a CSV from the device (via file picker)
- Detects `transcription` or `transcriptions` column
- Edit text per row and save back into the CSV (a local copy stored in app storage)
- Record audio per row and save as `1.wav`, `2.wav`, ... in a date-based folder
- Writes a `timestamp` column for each saved recording in GMT+7

## Prerequisites
- Install Flutter: see Flutter install docs: `https://docs.flutter.dev/get-started/install`
- iOS: Xcode + CocoaPods, Android: Android Studio + SDK

## Project Setup
```bash
cd recorder_mobile
# Generate missing Flutter scaffolding (android/ ios/ web/ etc.)
flutter create .
flutter pub get
```

## Run
```bash
flutter run
```

## Platform Permissions

### Android
Add to `android/app/src/main/AndroidManifest.xml` inside the `<manifest>` tag:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

If you plan to save outside app storage, also handle scoped storage. This app saves inside app documents, so no extra storage permission is required.

### iOS
Add to `ios/Runner/Info.plist`:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>We use the microphone to record your voice for transcriptions.</string>
```

## File Locations
- Local CSV copy: `<documents>/csvs/<your_csv_name>.csv`
- Audio files: `<documents>/audio_recordings/<DD_MM_YYYY>_transcriptions/<n>.wav`

## Notes
- On load, the app scans the audio folder and resumes from the next file number.
- The CSV is copied into app storage and modified there; the original is left untouched.
- Timezone is set to GMT+7 (Jakarta) for timestamps. 