import 'dart:io';
import 'package:flutter/material.dart';
import '../models/attachment_models.dart';

/// A fullscreen viewer widget for displaying acquired attachments.
/// 
/// Supports interactive image viewing with pinch-to-zoom and provides
/// a PDF placeholder with file metadata.
class AttachmentViewer extends StatelessWidget {
  /// Creates an [AttachmentViewer] for the given [result].
  const AttachmentViewer({
    super.key,
    required this.result,
  });

  /// The attachment result to be displayed in the viewer.
  final AttachmentResult result;

  /// Shows the viewer as a full-screen transition.
  static void show(BuildContext context, AttachmentResult result) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AttachmentViewer(result: result)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPdf = result.type == AttachmentType.pdf;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(result.name, style: const TextStyle(fontSize: 16)),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: Stack(
        children: [
          Center(
            child: isPdf ? _buildPdfPlaceholder() : _buildImageDisplay(),
          ),
          _buildInfoOverlay(),
        ],
      ),
    );
  }

  Widget _buildImageDisplay() {
    return Hero(
      tag: result.path,
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Image.file(
          File(result.path),
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildPdfPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 80),
        const SizedBox(height: 24),
        const Text(
          'PDF Document',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'View with a PDF reader',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildInfoOverlay() {
    return Positioned(
      bottom: 40,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(
              result.type == AttachmentType.pdf ? Icons.picture_as_pdf : Icons.image,
              color: Colors.white70,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    result.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    result.humanSize,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
