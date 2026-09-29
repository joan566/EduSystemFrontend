import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/shared/app_status_chip.dart';
import '../../../../../core/widgets/shared/tinted_icon.dart';
import '../../../domain/entities/exam_entity.dart';

/// Callbacks of the table's rows and their menu.
class ExamRowActions {
  const ExamRowActions({
    required this.onSelect,
    required this.onOpen,
    required this.onDownloadSheets,
    required this.onDelete,
  });

  final ValueChanged<ExamSummaryEntity> onSelect;

  /// Opens the exam, optionally on a tab (see `RoutePaths.examDetail`).
  final void Function(ExamSummaryEntity exam, {int? tab}) onOpen;
  final ValueChanged<ExamSummaryEntity> onDownloadSheets;
  final ValueChanged<ExamSummaryEntity> onDelete;
}

const _flexExam = 6;
const _flexDate = 2;
const _flexQuestions = 2;
const _statusWidth = 140.0;
const _menuWidth = 44.0;

/// Dense, hoverable table of a class's exams. Click selects, double click
/// (or Enter) opens, ↑/↓ move the selection.
class ExamsTable extends StatelessWidget {
  const ExamsTable({
    super.key,
    required this.exams,
    required this.selectedExamId,
    required this.actions,
    required this.clickOpens,
    this.footer,
  });

  final List<ExamSummaryEntity> exams;
  final int? selectedExamId;
  final ExamRowActions actions;

  /// Without a preview pane beside the table, a single click opens the
  /// exam instead of just selecting it.
  final bool clickOpens;

  /// Below the rows, e.g. pagination.
  final Widget? footer;

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (exams.isEmpty) return KeyEventResult.ignored;
    final index = exams.indexWhere((e) => e.id == selectedExamId);
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      actions.onSelect(exams[(index + 1).clamp(0, exams.length - 1)]);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      actions.onSelect(exams[(index - 1).clamp(0, exams.length - 1)]);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter && index >= 0) {
      actions.onOpen(exams[index]);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Focus(
      onKeyEvent: _onKey,
      child: Builder(
        builder: (context) => Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.outline.withValues(alpha: 0.7)),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowSoft,
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              const _HeaderRow(),
              Divider(height: 1, color: colors.outline),
              Expanded(
                child: ListView.separated(
                  itemCount: exams.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: colors.outline),
                  itemBuilder: (context, index) {
                    final exam = exams[index];
                    return _Row(
                      exam: exam,
                      selected: exam.id == selectedExamId,
                      actions: actions,
                      onTap: () {
                        Focus.of(context).requestFocus();
                        clickOpens
                            ? actions.onOpen(exam)
                            : actions.onSelect(exam);
                      },
                    );
                  },
                ),
              ),
              if (footer != null) ...[
                Divider(height: 1, color: colors.outline),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(letterSpacing: 0.4);
    Widget cell(String text, int flex) => Expanded(
      flex: flex,
      child: Text(text.toUpperCase(), style: style),
    );

    return Container(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          cell('Examen', _flexExam),
          cell('Fecha', _flexDate),
          cell('Preguntas', _flexQuestions),
          SizedBox(
            width: _statusWidth,
            child: Text('ESTADO', style: style),
          ),
          const SizedBox(width: _menuWidth),
        ],
      ),
    );
  }
}

class _Row extends StatefulWidget {
  const _Row({
    required this.exam,
    required this.selected,
    required this.actions,
    required this.onTap,
  });

  final ExamSummaryEntity exam;
  final bool selected;
  final ExamRowActions actions;
  final VoidCallback onTap;

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final exam = widget.exam;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final date = exam.evaluationDate;
    final description = exam.description?.trim();

    final background = widget.selected
        ? AppColors.accentBlue.withValues(alpha: 0.07)
        : _hovering
        ? colors.surfaceContainerHighest.withValues(alpha: 0.35)
        : Colors.transparent;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Material(
        color: background,
        child: InkWell(
          onTap: widget.onTap,
          onDoubleTap: () => widget.actions.onOpen(exam),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: widget.selected
                      ? AppColors.accentBlue
                      : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(17, 12, 8, 12),
            child: Row(
              children: [
                Expanded(
                  flex: _flexExam,
                  child: Row(
                    children: [
                      const TintedIcon(
                        icon: Icons.description_outlined,
                        color: AppColors.accentBlue,
                        size: 40,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exam.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (description != null && description.isNotEmpty)
                              Text(
                                description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: _flexDate,
                  child: Text(
                    date == null ? 'Sin fecha' : Formatters.date(date),
                    style: date == null
                        ? textTheme.bodySmall
                        : textTheme.bodyMedium,
                  ),
                ),
                Expanded(
                  flex: _flexQuestions,
                  child: Text(
                    '${exam.numberOfQuestions}',
                    style: textTheme.bodyMedium,
                  ),
                ),
                SizedBox(
                  width: _statusWidth,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: AppStatusChip(
                        label: exam.ready ? 'Listo' : 'Incompleto',
                        kind: exam.ready
                            ? AppStatusKind.success
                            : AppStatusKind.warning,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: _menuWidth,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 120),
                    opacity: _hovering || widget.selected ? 1 : 0.35,
                    child: _RowMenu(exam: exam, actions: widget.actions),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RowMenu extends StatelessWidget {
  const _RowMenu({required this.exam, required this.actions});

  final ExamSummaryEntity exam;
  final ExamRowActions actions;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip: 'Acciones',
      icon: const Icon(Icons.more_horiz, size: 20),
      onSelected: (value) => switch (value) {
        0 => actions.onOpen(exam),
        1 => actions.onOpen(exam, tab: 2),
        2 => actions.onDownloadSheets(exam),
        _ => actions.onDelete(exam),
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 0, child: Text('Abrir examen')),
        const PopupMenuItem(value: 1, child: Text('Ver resultados')),
        PopupMenuItem(
          value: 2,
          enabled: exam.ready,
          child: const Text('Descargar hojas de respuesta'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 3, child: Text('Eliminar examen')),
      ],
    );
  }
}
