import 'package:flutter/material.dart';
import 'attachment_models.dart';

class AttachmentTheme {
  const AttachmentTheme({
    this.primaryColor = const Color(0xFF7C6AF6),
    this.backgroundColor = const Color(0xFF1A1A25),
    this.surfaceColor = const Color(0xFF22222F),
    this.textColor = Colors.white,
    this.iconColor = Colors.white,
    this.accentColor = const Color(0xFF50D1AA),
  });

  final Color primaryColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color textColor;
  final Color iconColor;
  final Color accentColor;

  static const dark = AttachmentTheme();
}

class AttachmentConfig {
  const AttachmentConfig({
    required this.features,
    this.uiStyle = AttachmentUIStyle.bottomSheet,
    this.enableCropping = true,
    this.allowMultipleGallery = true,
    this.theme = AttachmentTheme.dark,
    this.maxScanPages = 20,
  });

  final List<AttachmentFeature> features;
  final AttachmentUIStyle uiStyle;
  final bool enableCropping;
  final bool allowMultipleGallery;
  final AttachmentTheme theme;
  final int maxScanPages;
}
