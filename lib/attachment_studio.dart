import 'package:flutter/material.dart';
import './core/attachment_service.dart';
import './models/attachment_config.dart';
import './models/attachment_models.dart';
import './ui/attachment_picker_shell.dart';

export './models/attachment_models.dart';
export './models/attachment_config.dart';

class AttachmentStudio {
  AttachmentStudio._();

  /// Access the raw service functions for custom UI implementations.
  static AttachmentStudioService get service => AttachmentStudioService.instance;

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
    final child = builder != null ? builder(context, config) : AttachmentPickerShell(config: config);

    if (config.uiStyle == AttachmentUIStyle.bottomSheet) {
      return showModalBottomSheet<List<AttachmentResult>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => child,
      );
    } else if (config.uiStyle == AttachmentUIStyle.dialog) {
      return showDialog<List<AttachmentResult>>(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          child: child,
        ),
      );
    } else {
      // For AttachmentUIStyle.custom, the developer should use AttachmentStudio.service directly.
      debugPrint('AttachmentStudio: Custom style selected. Use AttachmentStudio.service directly.');
      return null;
    }
  }
}
