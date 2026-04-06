# pixel_to_pdf

A comprehensive attachment picker and document scanner for Flutter.

## Features

- **Document Scanning**: Native document scanning with automatic edge detection and cropping.
- **Camera**: Take photos directly from the app.
- **Gallery Picker**: Pick images from the gallery (single or multi-select).
- **File Picker**: Pick any file from the device storage.
- **Image Cropping**: Integrated image cropping using `image_cropper`.
- **PDF Generation**: Automatically converts scanned documents into PDF files.

## Installation

Add `pixel_to_pdf` to your `pubspec.yaml`:

```yaml
dependencies:
  pixel_to_pdf: ^1.0.0
```

### Android Setup

1. Add the following permissions to your `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
```
2. Your `minSdkVersion` must be at least **21**.

### iOS Setup

1. Add the following keys to your `Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>We need access to your camera to scan documents and take photos.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to pick images.</string>
```
2. Your deployment target must be at least **iOS 13.0**.

## Usage

```dart
import 'package:pixel_to_pdf/pixel_to_pdf.dart';

final results = await AttachmentStudio.show(
  context,
  config: AttachmentConfig(
    uiStyle: AttachmentUIStyle.bottomSheet,
    allowMultiple: true,
  ),
);
```

## Testing Locally

To test this package locally:
```yaml
dependencies:
  pixel_to_pdf:
    path: ../pixel_to_pdf
```

## Publishing to pub.dev

1. Check for issues: `flutter pub publish --dry-run`
2. Publish: `flutter pub publish`
