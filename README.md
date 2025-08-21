# 🎙️ Recorder for Dira - Audio Recording App

A Flutter mobile application designed for recording audio transcriptions from CSV files. Perfect for language learning, speech therapy, or any project requiring audio recordings with text transcriptions.

## ✨ Features

- **📱 Cross-Platform**: Works on Android, iOS, macOS, and Web
- **📊 CSV Integration**: Load and manage transcription files easily
- **🎙️ Audio Recording**: High-quality audio recording with preview
- **📝 Text Editing**: Edit transcriptions before recording
- **🔄 Progress Tracking**: Visual progress indicator for recording sessions
- **📁 File Management**: Organize recordings by transcription number
- **🎯 Batch Processing**: Record multiple transcriptions in sequence
- **💾 Auto-Save**: Automatic saving of recordings and text changes

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / Xcode (for mobile development)
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/recorder-mobile.git
   cd recorder-mobile
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## 📱 How to Use

### 1. **Load CSV File**
- Click "Load CSV" button
- Select a CSV file with format: `DD_MM_YYYY_name_transcriptions.csv`
- The app will automatically detect transcription columns

### 2. **Edit Transcriptions**
- Review and edit transcription text if needed
- Click "Save Text" to save changes

### 3. **Record Audio**
- Click "Record" button to start recording
- Speak the transcription text clearly
- Click "Stop" when finished
- Use "Preview" to listen to your recording

### 4. **Navigate & Continue**
- Use "Previous" and "Next" buttons to navigate
- Progress bar shows completion status
- Recordings are automatically saved with numbered filenames

## 📊 CSV Format Requirements

Your CSV file must contain one of these column names:
- `transcriptions` (preferred)
- `transcription`

### Example CSV Structure:
```csv
id,transcriptions,notes
1,"Hello, how are you today?","Basic greeting"
2,"The weather is beautiful today.","Weather description"
3,"I love learning new languages.","Language learning"
```

## 🏗️ Building the App

### Android APK
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# Split APKs by architecture
flutter build apk --split-per-abi --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## 📁 Project Structure

```
recorder_mobile/
├── lib/                    # Dart source code
│   └── main.dart          # Main application file
├── android/               # Android configuration
├── ios/                   # iOS configuration
├── assets/                # App assets (logo, etc.)
├── web/                   # Web configuration
├── macos/                 # macOS configuration
└── pubspec.yaml           # Dependencies and configuration
```

## 🔧 Dependencies

- **flutter**: Core Flutter framework
- **record**: Audio recording functionality
- **audioplayers**: Audio playback
- **csv**: CSV file parsing
- **file_picker**: File selection
- **path_provider**: File system access
- **share_plus**: File sharing
- **open_filex**: File opening

## 📱 Supported Platforms

- ✅ Android (API 21+)
- ✅ iOS (12.0+)
- ✅ macOS (10.14+)
- ✅ Web (Chrome, Firefox, Safari, Edge)

## 🎯 Use Cases

- **Language Learning**: Record pronunciation of foreign words
- **Speech Therapy**: Practice speech exercises
- **Podcast Production**: Record script readings
- **Voice Acting**: Practice character voices
- **Research**: Collect speech samples
- **Education**: Create audio lessons

## 🚀 Deployment

### Android APK Distribution

#### Option 1: Google Play Store (Recommended)
- Create developer account at [Google Play Console](https://play.google.com/console)
- Upload signed APK or AAB file
- Follow Google's publishing guidelines

#### Option 2: Direct APK Distribution
- Build release APK: `flutter build apk --release`
- Upload to file sharing services:
  - **Google Drive**: Share via link
  - **Dropbox**: Public folder sharing
  - **GitHub Releases**: Attach to releases
  - **Firebase App Distribution**: For testing

#### Option 3: Alternative App Stores
- **F-Droid**: Open source app store
- **Amazon Appstore**: For Fire devices
- **Huawei AppGallery**: For Huawei devices

### iOS Distribution
- **App Store**: Through Apple Developer Program
- **TestFlight**: For beta testing
- **Enterprise**: For internal company distribution

## 🔐 Security & Permissions

### Required Permissions
- **Microphone**: For audio recording
- **Storage**: For saving audio files
- **File Access**: For CSV loading

### Privacy
- No data is sent to external servers
- All recordings are stored locally
- CSV data is processed locally only

## 🐛 Troubleshooting

### Common Issues

#### Audio Not Recording
- Check microphone permissions
- Ensure device supports audio recording
- Try restarting the app

#### CSV Not Loading
- Verify CSV format and column names
- Check file encoding (should be UTF-8)
- Ensure file is not corrupted

#### Build Errors
- Run `flutter clean`
- Delete `build/` and `.dart_tool/` folders
- Run `flutter pub get` again

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Commit changes: `git commit -m 'Add feature'`
4. Push to branch: `git push origin feature-name`
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Contributors to the open-source packages used
- Community members for feedback and suggestions

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/recorder-mobile/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/recorder-mobile/discussions)
- **Email**: your.email@example.com

---

**Made with ❤️ using Flutter**

*Version: 1.0.0 | Last Updated: August 2024*
