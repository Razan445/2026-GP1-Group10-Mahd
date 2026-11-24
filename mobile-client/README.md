# Mahd Mobile Application

This folder contains the Flutter mobile application for **Mahd**, an intelligent infant monitoring system.

## Application Development Team (UI & Firebase)

- **Razan:** Main user interfaces, monitoring features, and reports.
- **Gharsah:** Settings, additional features, and Firebase integration.

## Technologies

- Flutter and Dart
- Firebase Authentication and Cloud Firestore
- Microphone-based audio monitoring
- Local notifications
- Experimental on-device ONNX inference for cry-cause classification

## Running the Application

1. Install Flutter and set up an Android emulator or connect an Android device.
2. Open a terminal in the `mobile-client` folder.
3. Install the dependencies:

   ```bash
   flutter pub get
   ```

4. Run the application:

   ```bash
   flutter run
   ```

   To select a specific device, use `flutter devices` followed by `flutter run -d <device-id>`.

> **Note:** You can preview the user interface using `flutter run -d chrome`, but microphone monitoring and native ONNX inference require a supported native platform. Use an Android emulator or physical device for audio-related testing.

## Current Development Status

The mobile interface, monitoring controls, Firebase integration, and several app features are implemented. The ONNX cry-cause classifier is currently integrated for **debug testing only**. The full cry-detection and cause-classification pipeline has not yet been integrated. Raspberry Pi hardware integration is planned for a later phase.
