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

  /// Shows the pre-built attachment picker UI.
  /// 
  /// Returns a list of [AttachmentResult] if successful, or null if cancelled.
  static Future<List<AttachmentResult>?> show(
    BuildContext context, {
    required AttachmentConfig config,
  }) async {
    if (config.uiStyle == AttachmentUIStyle.bottomSheet) {
      return showModalBottomSheet<List<AttachmentResult>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => AttachmentPickerShell(config: config),
      );
    } else if (config.uiStyle == AttachmentUIStyle.dialog) {
      return showDialog<List<AttachmentResult>>(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          child: AttachmentPickerShell(config: config),
        ),
      );
    } else {
      // For AttachmentUIStyle.custom, the developer should use AttachmentStudio.service directly.
      debugPrint('AttachmentStudio: Custom style selected. Use AttachmentStudio.service directly.');
      return null;
    }
  }
}
