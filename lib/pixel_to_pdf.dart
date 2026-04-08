/// A comprehensive attachment picker and document scanner for Flutter.
/// Supports camera, gallery, file picking, and native document scanning.
library pixel_to_pdf;

import 'package:flutter/material.dart';
import './core/attachment_service.dart';
import './models/attachment_config.dart';
import './models/attachment_models.dart';
import './ui/attachment_picker_shell.dart';

export './models/attachment_models.dart';
export './models/attachment_config.dart';
export './widgets/attachment_feature_button.dart';
export './widgets/attachment_thumbnail.dart';
export './widgets/app_image_viewer.dart';

/// The primary entry point for the pixel_to_pdf package.
/// 
/// This class provides a simple static wrapper to launch the acquisition UI
/// or access the underlying raw service.
class PixelToPdf {
  PixelToPdf._();

  /// Access the raw service functions for custom UI implementations.
  static PixelToPdfService get service => PixelToPdfService.instance;

  /// Shows the pre-built attachment picker UI or a custom UI.
  /// 
  /// Provide a [builder] to design your own bottom sheet or dialog components
  /// while still utilizing the configured UI style.
  /// 
  /// Returns a list of [AttachmentResult] if successful, or null if cancelled.
  static Future<List<AttachmentResult>?> show(
    BuildContext context, {
    required AttachmentConfig config,
    Widget Function(BuildContext context, AttachmentConfig config)? builder,
  }) async {
    if (config.uiStyle == AttachmentUIStyle.bottomSheet) {
      return showModalBottomSheet<List<AttachmentResult>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (bottomSheetContext) => builder != null 
            ? builder(bottomSheetContext, config) 
            : AttachmentPickerShell(config: config),
      );
    } else if (config.uiStyle == AttachmentUIStyle.dialog) {
      return showDialog<List<AttachmentResult>>(
        context: context,
        builder: (dialogContext) => Dialog(
          backgroundColor: Colors.transparent,
          child: builder != null 
              ? builder(dialogContext, config) 
              : AttachmentPickerShell(config: config),
        ),
      );
    } else {
      // For AttachmentUIStyle.custom, the developer should use PixelToPdf.service directly.
      debugPrint('PixelToPdf: Custom style selected. Use PixelToPdf.service directly.');
      return null;
    }
  }
}
