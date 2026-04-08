import 'dart:io';
import 'package:flutter/material.dart';
import '../models/attachment_models.dart';

/// A compact thumbnail widget representing an acquired attachment.
/// 
/// Displays an image preview or a PDF icon, with an optional
/// delete button in the top-right corner.
class AttachmentThumbnailWidget extends StatelessWidget {
  /// Creates an [AttachmentThumbnailWidget].
  const AttachmentThumbnailWidget({
    super.key,
    required this.result,
    this.onDelete,
    this.onTap,
  });

  /// The attachment result to display.
  final AttachmentResult result;

  /// Optional callback triggered when the delete (close) button is tapped.
  final VoidCallback? onDelete;

  /// Optional callback triggered when the entire thumbnail is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isPdf = result.type == AttachmentType.pdf;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: isPdf ? _buildPdfPlaceholder() : _buildImagePreview(),
            ),
          ),
          if (onDelete != null)
            Positioned(
              top: -8,
              right: -8,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Image.file(
      File(result.path),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) => _buildErrorIcon(),
    );
  }

  Widget _buildPdfPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 32),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              result.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorIcon() {
    return const Center(child: Icon(Icons.error_outline, color: Colors.white24));
  }
}
