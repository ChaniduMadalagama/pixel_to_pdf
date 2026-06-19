## 1.0.8

* **Features**: Added `photosOnly` property to `AttachmentConfig` to allow restricting file pickers to image files only.

## 1.0.7

* **Bug Fixes**: Fixed image compression quality issues.
* **Maintenance**: Fixed memory leak in iOS platform by properly disposing of platform views.

## 1.0.6

* **Features**: Added `maxImageCount` and `maxFileCount` to `AttachmentConfig` to limit selection counts.
* **Enhancement**: Added multi-selection support for the file picker.
* **Platform**: Implemented native selection limits for iOS (PHPicker) and enforced limits in Dart for Android.
* **Bug Fixes**: Fixed result handling in Android to correctly return lists for multi-selection.

## 1.0.5

* **Enhancement**: Added Swift Package Manager (SPM) support for iOS, improving package resolution and pub.dev compatibility.

## 1.0.4

* **Maintenance**: Cleaned up internal debugging logs and library declarations to follow high-quality Dart conventions.
* **Features**: Added support for a custom `builder` in `PixelToPdf.show` for fully personalized acquisition UIs.
* **Bug Fixes**: Finalized iOS memory stability improvements for high-resolution scanning.

## 1.0.3

## 1.0.2

* **Documentation**: Completed documentation for all public widgets and members.
* **Example**: Fully restored the package example app with a comprehensive demonstration UI.
* **API**: Exported `AttachmentThumbnailWidget` and `AttachmentViewer` for public use.

## 1.0.1

* **Documentation**: Added comprehensive public API documentation across the entire package. Improved Pub.dev score.

## 1.0.0

* Initial release of `pixel_to_pdf`.
* **Native Document Scanning**: High-quality document capture via Google ML Kit.
* **Photo Capture**: Direct camera integration with auto-stabilization for iOS transitions.
* **Gallery & File Pickers**: Support for single and multi-selection of images and documents.
* **Integrated Cropper**: Customizable image cropping with native layout fixes for both Android and iOS.
* **Aesthetic UI**: Premium bottom sheet picker with dynamic Safe Area padding for Android Navigation bars.
* **PDF Engine**: Automatic conversion of scanned images into professional PDF files.
