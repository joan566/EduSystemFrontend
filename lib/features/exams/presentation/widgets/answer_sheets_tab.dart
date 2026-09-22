import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/exam_entity.dart';
import '../providers/exams_provider.dart';

/// Answer sheet PDF generation (§39, §40): download the whole group's
/// sheets in one PDF, or a single student's (used e.g. for reprints).
class AnswerSheetsTab extends StatefulWidget {
  const AnswerSheetsTab({super.key, required this.exam});

  final ExamEntity exam;

  @override
  State<AnswerSheetsTab> createState() => _AnswerSheetsTabState();
}

class _AnswerSheetsTabState extends State<AnswerSheetsTab> {
  bool _downloading = false;

  Future<void> _downloadAll() async {
    setState(() => _downloading = true);
    try {
      await context.read<ExamsProvider>().downloadAnswerSheets(widget.exam.id);
      if (mounted) context.showSuccess('Hojas de respuesta descargadas.');
    } catch (_) {
      if (mounted)
        context.showError('No se pudieron generar las hojas de respuesta.');
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (!widget.exam.ready)
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.errorContainer.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).colorScheme.error),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Completa todas las preguntas antes de generar las hojas.',
                  ),
                ),
              ],
            ),
          ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Generar hojas de respuesta',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              const Text(
                'Genera un PDF con las hojas de respuesta de todos los estudiantes '
                'activos del curso, listas para imprimir.',
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Generar y descargar todas',
                icon: Icons.picture_as_pdf_outlined,
                isLoading: _downloading,
                onPressed: widget.exam.ready ? _downloadAll : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
