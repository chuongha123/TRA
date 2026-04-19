# Hướng Dẫn Cài Đặt & Chạy Dự Án

## 📋 Yêu Cầu Hệ Thống

### Phần Mềm Cần Thiết
- **Flutter SDK**: Version 3.11 trở lên
- **Dart SDK**: Version 3.0 trở lên (đi kèm Flutter)
- **Android Studio**: 2022.1 trở lên (cho Android)
- **Xcode**: 14.0 trở lên (cho iOS - chỉ trên macOS)
- **VS Code**: Tùy chọn (nếu không dùng Android Studio)
- **Git**: Để clone repository

### Thiết Bị
- **Android**: API level 21 (Android 5.0) trở lên
- **iOS**: iOS 12.0 trở lên
- **Web**: Chrome, Firefox, Safari, Edge
- **RAM**: Tối thiểu 4GB (khuyến nghị 8GB+)
- **Storage**: 5GB trống

---

## 🔧 Cài Đặt Flutter

### Windows

1. **Tải Flutter SDK**
```bash
https://docs.flutter.dev/get-started/install/windows
```

2. **Giải nén và thêm vào PATH**
```
C:\src\flutter\bin
```

3. **Kiểm tra cài đặt**
```bash
flutter doctor
```

### macOS

1. **Tải Flutter SDK**
```bash
cd ~/development
curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_3.x.x-stable.zip
unzip flutter_macos_3.x.x-stable.zip
```

2. **Thêm vào PATH**
```bash
export PATH="$PATH:`pwd`/flutter/bin"
```

3. **Kiểm tra**
```bash
flutter doctor
```

### Linux

1. **Tải và giải nén**
```bash
cd ~/development
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.x.x-stable.tar.xz
tar xf flutter_linux_3.x.x-stable.tar.xz
```

2. **Thêm vào PATH**
```bash
export PATH="$PATH:`pwd`/flutter/bin"
```

---

## 📦 Setup Dự Án

### 1. Clone Repository

```bash
# Nếu có Git repository
git clone https://github.com/yourusername/smart-home-iot.git
cd smart-home-iot

# Hoặc nếu có folder local
cd path/to/Tra
```

### 2. Cài Đặt Dependencies

```bash
# Tải tất cả packages
flutter pub get

# Nếu gặp lỗi, thử clean trước
flutter clean
flutter pub get
```

### 3. Kiểm Tra Cấu Hình

```bash
# Kiểm tra Flutter environment
flutter doctor -v

# Liệt kê các thiết bị có thể chạy
flutter devices
```

---

## ▶️ Chạy Ứng Dụng

### Development Mode

**Trên Android Emulator:**
```bash
# Khởi động emulator từ Android Studio
# Hoặc dùng command line
emulator -avd Pixel_5_API_31

# Run app
flutter run
```

**Trên iOS Simulator (macOS only):**
```bash
# Mở simulator
open -a Simulator

# Run app
flutter run
```

**Trên Web:**
```bash
flutter run -d chrome
```

**Trên Device thật:**
```bash
# Enable USB debugging trên device
# Kết nối device qua USB
flutter devices
flutter run
```

### Hot Reload & Hot Restart

Khi app đang chạy:
- **Hot Reload**: Nhấn `r` - Reload UI mà không mất state
- **Hot Restart**: Nhấn `R` - Restart app hoàn toàn
- **Quit**: Nhấn `q`

---

## 🏗️ Build Release

### Android APK

```bash
# Build APK
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk

# Build APK split per ABI (giảm size)
flutter build apk --split-per-abi
```

### Android App Bundle (AAB)

```bash
# Build AAB cho Google Play Store
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS

```bash
# Build iOS (chỉ trên macOS)
flutter build ios --release

# Sau đó mở Xcode để archive và upload
open ios/Runner.xcworkspace
```

### Web

```bash
# Build web
flutter build web --release

# Output: build/web/
# Deploy folder này lên hosting
```

---

## 🐛 Troubleshooting

### Lỗi "Flutter SDK not found"

**Giải pháp:**
```bash
# Kiểm tra PATH
echo $PATH  # macOS/Linux
echo %PATH% # Windows

# Thêm Flutter vào PATH
# Windows: System Properties > Environment Variables
# macOS/Linux: Thêm vào ~/.bashrc hoặc ~/.zshrc
export PATH="$PATH:/path/to/flutter/bin"
```

### Lỗi "Waiting for another flutter command to release the startup lock"

**Giải pháp:**
```bash
# Xóa lock file
rm flutter/bin/cache/lockfile  # macOS/Linux
del flutter\bin\cache\lockfile # Windows
```

### Lỗi "Gradle build failed"

**Giải pháp:**
```bash
# Clean project
flutter clean
cd android
./gradlew clean  # macOS/Linux
gradlew clean    # Windows
cd ..
flutter pub get
flutter run
```

### Lỗi "CocoaPods not installed" (iOS)

**Giải pháp:**
```bash
# Install CocoaPods
sudo gem install cocoapods
pod setup

# Reinstall pods
cd ios
pod install
cd ..
flutter run
```

### Lỗi "version solving failed"

**Giải pháp:**
```bash
# Update Flutter
flutter upgrade

# Sau đó
flutter clean
flutter pub get
```

---

## ⚙️ Cấu Hình Project

### 1. Đổi Package Name

**Android** (`android/app/build.gradle`):
```gradle
defaultConfig {
    applicationId "com.yourcompany.smarthome"
    ...
}
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>CFBundleIdentifier</key>
<string>com.yourcompany.smarthome</string>
```

### 2. Đổi App Name

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<application
    android:label="Smart Home"
    ...>
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>CFBundleName</key>
<string>Smart Home</string>
```

### 3. Đổi App Icon

```bash
# Sử dụng flutter_launcher_icons package
flutter pub add flutter_launcher_icons

# Cấu hình trong pubspec.yaml
flutter_icons:
  android: true
  ios: true
  image_path: "assets/icon/app_icon.png"

# Generate icons
flutter pub run flutter_launcher_icons
```

### 4. Cấu Hình API URL

Chỉnh sửa `lib/constants/app_constants.dart`:
```dart
static const String apiBaseUrl = 'YOUR_API_URL';
static const String websocketUrl = 'YOUR_WEBSOCKET_URL';
```

---

## 📱 Testing

### Unit Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/models/device_test.dart

# Run with coverage
flutter test --coverage
```

### Widget Tests

```bash
flutter test test/widgets/device_card_test.dart
```

### Integration Tests

```bash
flutter test integration_test/app_test.dart
```

---

## 🚢 Deployment

### Google Play Store

1. Tạo keystore:
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

2. Cấu hình signing trong `android/key.properties`

3. Build và upload:
```bash
flutter build appbundle --release
```

### Apple App Store

1. Mở Xcode và archive
2. Validate app
3. Upload to App Store Connect

### Web Hosting

```bash
# Build
flutter build web --release

# Deploy build/web/ folder lên:
# - Firebase Hosting
# - Netlify
# - Vercel
# - GitHub Pages
```

---

## 📚 Additional Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Documentation](https://dart.dev/guides)
- [Material Design 3](https://m3.material.io/)
- [ESP32 Documentation](https://docs.espressif.com/projects/esp-idf/)

---

## 🆘 Hỗ Trợ

Nếu gặp vấn đề:
1. Kiểm tra `flutter doctor` trước
2. Xem [GitHub Issues](https://github.com/flutter/flutter/issues)
3. Tham gia [Flutter Discord](https://discord.gg/flutter)
4. Đăng câu hỏi trên [StackOverflow](https://stackoverflow.com/questions/tagged/flutter)

---

**Happy Coding! 🎉**
