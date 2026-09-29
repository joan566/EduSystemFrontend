import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A file's kind as a small colored badge (W, PDF, X, P, IMG, TXT).
class AttachmentBadge extends StatelessWidget {
  const AttachmentBadge({super.key, required this.fileName, this.size = 40});

  final String fileName;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';
    final (label, color) = switch (ext) {
      'doc' || 'docx' || 'odt' || 'rtf' => ('W', AppColors.accentBlue),
      'pdf' => ('PDF', AppColors.error),
      'xls' || 'xlsx' => ('X', AppColors.accentGreen),
      'ppt' || 'pptx' => ('P', AppColors.accentOrange),
      'jpg' || 'jpeg' || 'png' => ('IMG', AppColors.accentPurple),
      _ => ('TXT', AppColors.textSecondary),
    };
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: label.length == 1 ? size * 0.42 : size * 0.26,
        ),
      ),
    );
  }
}
