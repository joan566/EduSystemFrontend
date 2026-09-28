import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Stable accent color for a subject, so the same class keeps its color
/// everywhere it appears.
Color subjectAccent(int subjectId) =>
    AppColors.accents[subjectId % AppColors.accents.length];

/// Best-effort icon from the subject's name (subjects are free text, so
/// this matches keywords and falls back to a book).
IconData subjectIcon(String subjectName) {
  final name = subjectName.toLowerCase();
  bool has(List<String> keys) => keys.any(name.contains);

  // Before the sciences: "Educación física" must not match "físic".
  if (has(['educación física', 'educacion fisica', 'deporte'])) {
    return Icons.sports_soccer_outlined;
  }
  if (has(['inglés', 'ingles', 'english', 'francés', 'idioma'])) {
    return Icons.translate;
  }
  if (has(['natural', 'ciencia', 'biolog', 'químic', 'quimic', 'físic'])) {
    return Icons.science_outlined;
  }
  if (has(['matemátic', 'matematic', 'álgebra', 'algebra', 'geometr'])) {
    return Icons.calculate_outlined;
  }
  if (has(['social', 'historia', 'geograf'])) return Icons.public;
  if (has(['arte', 'artística', 'música', 'musica', 'dibujo'])) {
    return Icons.palette_outlined;
  }
  if (has(['informátic', 'informatic', 'tecnolog', 'sistemas'])) {
    return Icons.computer_outlined;
  }
  return Icons.menu_book_outlined;
}
