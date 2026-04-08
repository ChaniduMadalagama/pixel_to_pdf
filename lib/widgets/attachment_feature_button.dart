import 'package:flutter/material.dart';

import '../core/attachment_service.dart';
import '../models/attachment_config.dart';
import '../models/attachment_models.dart';

class AttachmentFeatureButton extends StatelessWidget {
  const AttachmentFeatureButton({
    super.key,
    required this.feature,
    required this.config,
    this.child,
    this.onResult,
    this.onProcessingStateChanged,
  });

  final AttachmentFeature feature;
  final AttachmentConfig config;
  final ValueChanged<List<AttachmentResult>>? onResult;
  final ValueChanged<bool>? onProcessingStateChanged;

  final Widget? child;

  Future<void> _handleTap() async {
    onProcessingStateChanged?.call(true);

    try {
      if (feature == AttachmentFeature.takePhoto) {
        final result = await PixelToPdfService.instance.takePhoto(
          enableCropping: config.enableCropping,
        );
        if (result != null) onResult?.call([result]);
      } else if (feature == AttachmentFeature.scanDoc) {
        final result = await PixelToPdfService.instance.scanDocument();
        if (result != null) onResult?.call([result]);
      } else if (feature == AttachmentFeature.fromGallery) {
        if (config.allowMultipleGallery) {
          final results = await PixelToPdfService.instance.pickMultiFromGallery();
          if (results.isNotEmpty) onResult?.call(results);
        } else {
          final result = await PixelToPdfService.instance.pickImage(
            enableCropping: config.enableCropping,
          );
          if (result != null) onResult?.call([result]);
        }
      } else if (feature == AttachmentFeature.fromFiles) {
        final result = await PixelToPdfService.instance.pickFile();
        if (result != null) onResult?.call([result]);
      }
    } finally {
      onProcessingStateChanged?.call(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // If the user provided their own custom UI, just wrap it with our functionality!
    if (child != null) {
      return GestureDetector(
        onTap: _handleTap,
        child: child,
      );
    }

    // Otherwise, render the default package theme UI.
    IconData icon;
    String label;
    Color color;

    switch (feature) {
      case AttachmentFeature.takePhoto:
        icon = Icons.camera_alt_rounded;
        label = 'Take Photo';
        color = config.theme.primaryColor;
        break;
      case AttachmentFeature.scanDoc:
        icon = Icons.document_scanner_rounded;
        label = 'Scan Doc';
        color = config.theme.primaryColor.withValues(alpha: 0.8);
        break;
      case AttachmentFeature.fromGallery:
        icon = Icons.photo_library_rounded;
        label = 'Photos';
        color = config.theme.accentColor;
        break;
      case AttachmentFeature.fromFiles:
        icon = Icons.folder_rounded;
        label = 'Files';
        color = Colors.orangeAccent;
        break;
    }

    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
