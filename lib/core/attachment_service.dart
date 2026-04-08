import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/attachment_models.dart';

class PixelToPdfService {
  PixelToPdfService._();
  static final PixelToPdfService instance = PixelToPdfService._();

  static const _channel = MethodChannel('pixel_to_pdf/scanner');

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
      debugPrint('PixelToPdfService: scanDocument error: $e');
      return null;
    }
  }

  // ── Camera ─────────────────────────────────────────────────────────────

  Future<AttachmentResult?> takePhoto({bool enableCropping = true}) async {
    print("takePhoto: started, enableCropping=$enableCropping");
    try {
      print("takePhoto: invoking 'takeImage' channel");
      final String? path = await _channel.invokeMethod('takeImage');
      print("takePhoto: 'takeImage' channel returned path: $path");
      
      if (path == null) {
        print("takePhoto: path is null, returning null early");
        return null;
      }

      print("takePhoto: now evaluating crop step. Will crop? $enableCropping");
      
      final file = enableCropping ? await cropImage(path) : File(path);
      print("takePhoto: final file is: ${file?.path}");
      
      final result = file != null ? _resultFromPath(file.path) : null;
      print("takePhoto: parsed result object: $result");
      return result;
    } catch (e) {
      debugPrint('PixelToPdfService: takePhoto error: $e');
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
      debugPrint('PixelToPdfService: pickImage error: $e');
      return null;
    }
  }

  Future<List<AttachmentResult>> pickMultiFromGallery() async {
    try {
      final List? results = await _channel.invokeMethod('pickMultiImage');
      if (results == null) return [];
      return results.map((e) => _resultFromPath(e.toString())).toList();
    } catch (e) {
      debugPrint('PixelToPdfService: pickMultiImage error: $e');
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
      debugPrint('PixelToPdfService: pickFile error: $e');
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
    print("cropImage: invoked with imagePath=$imagePath");
    try {
      if (Platform.isIOS) {
        // Wait on iOS to allow the previous fullscreen view (Camera/Gallery) to fully settle.
        // This ensures TOCropViewController measures the Safe Area correctly.
        print("cropImage: iOS detected, awaiting geometry stabilization...");
        await Future.delayed(const Duration(milliseconds: 1000));
      }

      print("cropImage: calling ImageCropper().cropImage...");
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
      print("cropImage: returned from ImageCropper. result path: ${cropped?.path}");
      return cropped != null ? File(cropped.path) : null;
    } catch (e) {
      debugPrint('PixelToPdfService: cropImage error: $e');
      print("cropImage: CAUGHT EXCEPTION: $e");
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
