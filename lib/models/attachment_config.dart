import 'package:flutter/material.dart';
import 'attachment_models.dart';

/// Defines the color palette for the attachment picker UI components.
class AttachmentTheme {
  /// Creates a custom [AttachmentTheme].
  const AttachmentTheme({
    this.primaryColor = const Color(0xFF7C6AF6),
    this.backgroundColor = const Color(0xFF1A1A25),
    this.surfaceColor = const Color(0xFF22222F),
    this.textColor = Colors.white,
    this.iconColor = Colors.white,
    this.accentColor = const Color(0xFF50D1AA),
  });

  /// The main brand color used for primary buttons and selection indicators.
  final Color primaryColor;

  /// The base background color for the picker container.
  final Color backgroundColor;

  /// The color of surface elements like action cards and buttons.
  final Color surfaceColor;

  /// The default color for text within the UI.
  final Color textColor;

  /// The color for secondary icons.
  final Color iconColor;

  /// A highlight color used for secondary actions and accents.
  final Color accentColor;

  /// The default dark theme configuration.
  static const dark = AttachmentTheme();
}

/// Global configuration object for the PixelToPdf attachment picker.
class AttachmentConfig {
  /// Creates a new [AttachmentConfig].
  const AttachmentConfig({
    required this.features,
    this.uiStyle = AttachmentUIStyle.bottomSheet,
    this.enableCropping = true,
    this.allowMultipleGallery = true,
    this.theme = AttachmentTheme.dark,
    this.maxScanPages = 20,
  });

  /// The list of enabled features (e.g., [AttachmentFeature.scanDoc]).
  final List<AttachmentFeature> features;

  /// Whether to show the picker as a bottom sheet or a dialog.
  final AttachmentUIStyle uiStyle;

  /// Whether to enable the cropping step after taking a photo or picking an image.
  final bool enableCropping;

  /// Whether to allow multi-selection when picking from the gallery.
  final bool allowMultipleGallery;

  /// The theme configuration for the UI.
  final AttachmentTheme theme;

  /// The maximum number of pages allowed in a single document scan session.
  final int maxScanPages;
}
