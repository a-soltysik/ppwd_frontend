# ppwd_frontend

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Release installation guide
1. Install flutter
2. Install android studio with **ndk 25.2.9519653**
3. Turn on developer options on yor mobile device and allow USB debugging
4. Turn on developer mode on your PC `start ms-settings:developers`
5. Confirm your connection with the device by running `flutter devices`
6. Run `flutter build apk --release` from the project's source folder
7. Run `adb install build\app\outputs\flutter-apk\app-release.apk` (located *C:\Users\<your_username>\AppData\Local\Android\Sdk\platform-tools\adb.exe*)
