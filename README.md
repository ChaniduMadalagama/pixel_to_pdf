# pixel_to_pdf

A comprehensive attachment picker and document scanner for Flutter. Supports camera, gallery, file picking, and native document scanning with cropping.

## Features

- **Document Scanning**: Native document scanning with automatic edge detection and cropping (via Google ML Kit).
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

1. **Min SDK**: Requires at least **API 21**.
2. **Permissions**: Add this to your `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
```
3. **Image Cropper**: To support image cropping, you must register the `UCropActivity` in your `AndroidManifest.xml`:
```xml
<activity
    android:name="com.yalantis.ucrop.UCropActivity"
    android:screenOrientation="portrait"
    android:theme="@style/Theme.AppCompat.Light.NoActionBar"/>
```
> [!NOTE]
> The package handles `FileProvider` internally using the authority `${applicationId}.pixel_to_pdf.fileprovider`. No manual FileProvider setup is required unless there is a naming conflict.

### iOS Setup

1. **Deployment Target**: Requires at least **iOS 14.0**.
2. **Permissions**: Add the following keys to your `Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>We need access to your camera to scan documents and take photos.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to select images.</string>
```

## Usage

```dart
import 'package:pixel_to_pdf/pixel_to_pdf.dart';

final results = await PixelToPdf.show(
  context,
  config: AttachmentConfig(
    uiStyle: AttachmentUIStyle.bottomSheet,
    features: [
      AttachmentFeature.scanDoc,
      AttachmentFeature.takePhoto,
      AttachmentFeature.fromGallery,
      AttachmentFeature.fromFiles,
    ],
  ),
);
```

## Local Development

To test this package locally:
```yaml
dependencies:
  pixel_to_pdf:
    path: ../pixel_to_pdf
```

## Publishing

1. Check for issues: `flutter pub publish --dry-run`
2. Publish: `flutter pub publish`
