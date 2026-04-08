import 'dart:io';

/// Defines the category of an acquired attachment.
enum AttachmentType { 
  /// A photographic or pickable image file.
  image, 
  /// A Portable Document Format file.
  pdf, 
  /// A generic file type.
  file 
}

/// Represents the available acquisition features in the picker.
enum AttachmentFeature { 
  /// Native document scanning with automatic edge detection.
  scanDoc, 
  /// Direct camera capture.
  takePhoto, 
  /// Picking images from the device gallery.
  fromGallery, 
  /// Picking files from the device storage.
  fromFiles 
}

/// Defines the presentation style of the attachment picker.
enum AttachmentUIStyle { 
  /// Renders as a standard bottom sheet.
  bottomSheet, 
  /// Renders as a centered dialog.
  dialog, 
  /// Indicates a custom implementation using the raw service.
  custom 
}

/// Represents the result of a successful attachment acquisition.
class AttachmentResult {
  /// Creates a new [AttachmentResult].
  const AttachmentResult({
    required this.path,
    required this.type,
    required this.name,
    this.sizeBytes,
  });

  /// The absolute local filesystem path to the attachment.
  final String path;

  /// The category of the attachment (image, pdf, or file).
  final AttachmentType type;

  /// The display name of the file (including extension).
  final String name;

  /// The size of the file in bytes, if available.
  final int? sizeBytes;

  /// Convenience getter to access the [File] object for the attachment.
  File get file => File(path);

  /// Returns a human-readable string representation of the file size.
  String get humanSize {
    if (sizeBytes == null) return '';
    final kb = sizeBytes! / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }
}
