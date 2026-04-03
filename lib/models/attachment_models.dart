import 'dart:io';

enum AttachmentType { image, pdf, file }

enum AttachmentFeature { scanDoc, takePhoto, fromGallery, fromFiles }

enum AttachmentUIStyle { bottomSheet, dialog, custom }

class AttachmentResult {
  const AttachmentResult({
    required this.path,
    required this.type,
    required this.name,
    this.sizeBytes,
  });

  final String path;
  final AttachmentType type;
  final String name;
  final int? sizeBytes;

  File get file => File(path);

  String get humanSize {
    if (sizeBytes == null) return '';
    final kb = sizeBytes! / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }
}
