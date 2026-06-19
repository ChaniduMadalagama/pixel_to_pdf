import 'package:flutter/material.dart';

import '../core/attachment_service.dart';
import '../models/attachment_config.dart';
import '../models/attachment_models.dart';

/// A standalone widget that triggers a specific acquisition feature.
/// 
/// This button can be used to build custom attachment picker UIs while
/// reusing the package's underlying logic.
class AttachmentFeatureButton extends StatelessWidget {
  /// Creates a [AttachmentFeatureButton].
  const AttachmentFeatureButton({
    super.key,
    required this.feature,
    required this.config,
    this.child,
    this.onResult,
    this.onProcessingStateChanged,
  });

  /// The specific acquisition feature to trigger when tapped.
  final AttachmentFeature feature;

  /// The configuration used for the acquisition (e.g., cropping settings).
  final AttachmentConfig config;

  /// Called when an attachment is successfully acquired.
  final ValueChanged<List<AttachmentResult>>? onResult;

  /// Called when the processing state (loading) changes.
  final ValueChanged<bool>? onProcessingStateChanged;

  /// An optional custom child widget to use as the button body.
  /// If provided, uses a [GestureDetector] to wrap this child.
  final Widget? child;

  Future<void> _handleTap(BuildContext context) async {
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
        if (config.allowMultipleGallery && (config.maxImageCount == 0 || config.maxImageCount > 1)) {
          final results = await PixelToPdfService.instance.pickMultiFromGallery(
            maxCount: config.maxImageCount,
          );
          if (results.isNotEmpty) {
            var finalResults = results;
            if (config.maxImageCount > 0 && results.length > config.maxImageCount) {
              finalResults = results.take(config.maxImageCount).toList();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Maximum ${config.maxImageCount} images allowed. Truncating selection.'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }
            onResult?.call(finalResults);
          }
        } else {
          final result = await PixelToPdfService.instance.pickImage(
            enableCropping: config.enableCropping,
          );
          if (result != null) onResult?.call([result]);
        }
      } else if (feature == AttachmentFeature.fromFiles) {
        if (config.maxFileCount == 0 || config.maxFileCount > 1) {
          final results = await PixelToPdfService.instance.pickMultiFiles(
            maxCount: config.maxFileCount,
            photosOnly: config.photosOnly,
          );
          if (results.isNotEmpty) {
            var finalResults = results;
            if (config.maxFileCount > 0 && results.length > config.maxFileCount) {
              finalResults = results.take(config.maxFileCount).toList();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Maximum ${config.maxFileCount} files allowed. Truncating selection.'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }
            onResult?.call(finalResults);
          }
        } else {
          final result = await PixelToPdfService.instance.pickFile(
            photosOnly: config.photosOnly,
          );
          if (result != null) onResult?.call([result]);
        }
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
        onTap: () => _handleTap(context),
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
      onTap: () => _handleTap(context),
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
