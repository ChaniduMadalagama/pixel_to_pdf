import 'package:flutter/material.dart';

import '../models/attachment_config.dart';
import '../models/attachment_models.dart';
import '../widgets/attachment_feature_button.dart';

class AttachmentPickerShell extends StatefulWidget {
  const AttachmentPickerShell({
    super.key,
    required this.config,
  });

  final AttachmentConfig config;

  @override
  State<AttachmentPickerShell> createState() => _AttachmentPickerShellState();
}

class _AttachmentPickerShellState extends State<AttachmentPickerShell> {
  bool _isProcessing = false;
  bool _showCaptureSubOptions = false;
  bool _showUploadSubOptions = false;

  void _handleMultipleResults(BuildContext context, List<AttachmentResult> results) {
    if (results.isNotEmpty) {
      Navigator.pop(context, results);
    } else {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.config.theme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPadding),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: widget.config.uiStyle == AttachmentUIStyle.bottomSheet
            ? const BorderRadius.vertical(top: Radius.circular(32))
            : BorderRadius.circular(32),
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = widget.config.theme;
    final showBack = (_showCaptureSubOptions || _showUploadSubOptions) && !_isProcessing;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (showBack)
              IconButton(
                onPressed: () => setState(() {
                  _showCaptureSubOptions = false;
                  _showUploadSubOptions = false;
                }),
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.textColor.withValues(alpha: 0.7), size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            if (showBack) const SizedBox(width: 12),
            Text(
              _getTitle(),
              style: TextStyle(
                color: theme.textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        if (!_isProcessing)
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: theme.textColor.withValues(alpha: 0.2)),
          ),
      ],
    );
  }

  String _getTitle() {
    if (_isProcessing) return 'Working...';
    if (_showCaptureSubOptions) return 'Capture';
    if (_showUploadSubOptions) return 'Upload From';
    return 'Add Attachments';
  }

  Widget _buildContent() {
    if (_isProcessing) return _buildLoadingState();
    if (_showCaptureSubOptions) return _buildCaptureOptions();
    if (_showUploadSubOptions) return _buildUploadOptions();
    return _buildMainOptions();
  }

  Widget _buildLoadingState() {
    final theme = widget.config.theme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
            strokeWidth: 3,
          ),
          const SizedBox(height: 24),
          Text(
            'Processing...',
            style: TextStyle(color: theme.textColor.withValues(alpha: 0.7), fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildMainOptions() {
    final hasCapture = widget.config.features.contains(AttachmentFeature.scanDoc) || 
                       widget.config.features.contains(AttachmentFeature.takePhoto);
    final hasUpload = widget.config.features.contains(AttachmentFeature.fromGallery) || 
                      widget.config.features.contains(AttachmentFeature.fromFiles);

    return Row(
      children: [
        if (hasCapture)
          _ActionTile(
            icon: Icons.camera_enhance_rounded,
            label: 'Capture',
            color: widget.config.theme.primaryColor,
            onTap: () => setState(() => _showCaptureSubOptions = true),
          ),
        if (hasCapture && hasUpload) const SizedBox(width: 16),
        if (hasUpload)
          _ActionTile(
            icon: Icons.cloud_upload_rounded,
            label: 'Upload',
            color: widget.config.theme.accentColor,
            onTap: () => setState(() => _showUploadSubOptions = true),
          ),
      ],
    );
  }

  Widget _buildCaptureOptions() {
    final showTake = widget.config.features.contains(AttachmentFeature.takePhoto);
    final showScan = widget.config.features.contains(AttachmentFeature.scanDoc);

    return Row(
      children: [
        if (showTake)
          Expanded(
            child: AttachmentFeatureButton(
              feature: AttachmentFeature.takePhoto,
              config: widget.config,
              onProcessingStateChanged: (val) => mounted ? setState(() => _isProcessing = val) : null,
              onResult: (res) => mounted ? _handleMultipleResults(context, res) : null,
            ),
          ),
        if (showTake && showScan) const SizedBox(width: 16),
        if (showScan)
          Expanded(
            child: AttachmentFeatureButton(
              feature: AttachmentFeature.scanDoc,
              config: widget.config,
              onProcessingStateChanged: (val) => mounted ? setState(() => _isProcessing = val) : null,
              onResult: (res) => mounted ? _handleMultipleResults(context, res) : null,
            ),
          ),
      ],
    );
  }

  Widget _buildUploadOptions() {
    final showGallery = widget.config.features.contains(AttachmentFeature.fromGallery);
    final showFiles = widget.config.features.contains(AttachmentFeature.fromFiles);

    return Row(
      children: [
        if (showGallery)
          Expanded(
            child: AttachmentFeatureButton(
              feature: AttachmentFeature.fromGallery,
              config: widget.config,
              onProcessingStateChanged: (val) => mounted ? setState(() => _isProcessing = val) : null,
              onResult: (res) => mounted ? _handleMultipleResults(context, res) : null,
            ),
          ),
        if (showGallery && showFiles) const SizedBox(width: 16),
        if (showFiles)
          Expanded(
            child: AttachmentFeatureButton(
              feature: AttachmentFeature.fromFiles,
              config: widget.config,
              onProcessingStateChanged: (val) => mounted ? setState(() => _isProcessing = val) : null,
              onResult: (res) => mounted ? _handleMultipleResults(context, res) : null,
            ),
          ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
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
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
