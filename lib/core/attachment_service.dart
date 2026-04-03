import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/attachment_models.dart';

class AttachmentStudioService {
  AttachmentStudioService._();
  static final AttachmentStudioService instance = AttachmentStudioService._();

  static const _channel = MethodChannel('attachment_studio/scanner');

  // ── Document Scanning ───────────────────────────────────────────────────

  /// Launches the native document scanner and returns a single PDF file.
  Future<AttachmentResult?> scanDocument() async {
    try {
      final result = await _channel.invokeMethod('scanDocument');
      if (result != null && result is List) {
        final images = List<String>.from(result);
        if (images.isNotEmpty) {
          final pdfFile = await buildPdf(images);
          return _resultFromPath(pdfFile.path);
        }
      }
      return null;
    } catch (e) {
      debugPrint('AttachmentStudioService: scanDocument error: $e');
      return null;
    }
  }

  // ── Camera ─────────────────────────────────────────────────────────────

  Future<AttachmentResult?> takePhoto({bool enableCropping = true}) async {
    try {
      final String? path = await _channel.invokeMethod('takeImage');
      if (path == null) return null;

      final file = enableCropping ? await cropImage(path) : File(path);
      return file != null ? _resultFromPath(file.path) : null;
    } catch (e) {
      debugPrint('AttachmentStudioService: takePhoto error: $e');
      return null;
    }
  }

  // ── Gallery ────────────────────────────────────────────────────────────

  Future<AttachmentResult?> pickImage({bool enableCropping = true}) async {
    try {
      final String? path = await _channel.invokeMethod('pickImage');
      if (path == null) return null;

      final file = enableCropping ? await cropImage(path) : File(path);
      return file != null ? _resultFromPath(file.path) : null;
    } catch (e) {
      debugPrint('AttachmentStudioService: pickImage error: $e');
      return null;
    }
  }

  Future<List<AttachmentResult>> pickMultiFromGallery() async {
    try {
      final List? results = await _channel.invokeMethod('pickMultiImage');
      if (results == null) return [];
      return results.map((e) => _resultFromPath(e.toString())).toList();
    } catch (e) {
      debugPrint('AttachmentStudioService: pickMultiImage error: $e');
      return [];
    }
  }

  // ── File Picker ────────────────────────────────────────────────────────

  Future<AttachmentResult?> pickFile() async {
    try {
      final String? path = await _channel.invokeMethod('pickFile');
      if (path != null) {
        return _resultFromPath(path);
      }
      return null;
    } catch (e) {
      debugPrint('AttachmentStudioService: pickFile error: $e');
      return null;
    }
  }

  // ── Helper Methods ──────────────────────────────────────────────────────

  AttachmentResult _resultFromPath(String filePath) {
    if (filePath.startsWith('file://')) {
      filePath = Uri.parse(filePath).toFilePath();
    }
    final ext = p.extension(filePath).toLowerCase();
    AttachmentType type;
    if (['.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic'].contains(ext)) {
      type = AttachmentType.image;
    } else if (ext == '.pdf') {
      type = AttachmentType.pdf;
    } else {
      type = AttachmentType.file;
    }
    int? size;
    try {
      size = File(filePath).lengthSync();
    } catch (_) {}
    return AttachmentResult(
      path: filePath,
      type: type,
      name: p.basename(filePath),
      sizeBytes: size,
    );
  }

  Future<File?> cropImage(String imagePath) async {
    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: imagePath,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop Image',
          ),
        ],
      );
      return cropped != null ? File(cropped.path) : null;
    } catch (e) {
      debugPrint('AttachmentStudioService: cropImage error: $e');
      return null;
    }
  }

  Future<File> buildPdf(List<String> imagePaths) async {
    final pdf = pw.Document();
    for (var path in imagePaths) {
      if (path.startsWith('file://')) {
        path = Uri.parse(path).toFilePath();
      }
      final bytes = await File(path).readAsBytes();
      final image = pw.MemoryImage(bytes);
      pdf.addPage(
        pw.Page(build: (ctx) => pw.Center(child: pw.Image(image))),
      );
    }
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/scan_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
