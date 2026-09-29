import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../shared/questions_draft_controller.dart';

/// Every question at a glance: number, completeness, the start of its
/// statement and what's missing; click to edit it.
class QuestionNavigator extends StatefulWidget {
  const QuestionNavigator({
    super.key,
    required this.drafts,
    required this.selected,
    required this.onSelect,
    required this.onAdd,
  });

  final List<DraftQuestion> drafts;
  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;

  @override
  State<QuestionNavigator> createState() => _QuestionNavigatorState();
}

class _QuestionNavigatorState extends State<QuestionNavigator> {
  static const _itemExtent = 64.0;
  final _scroll = ScrollController();

  // Keep the selected question in view when it changes from the keyboard
  // or the editor's arrows.
  @override
  void didUpdateWidget(covariant QuestionNavigator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected == oldWidget.selected || !_scroll.hasClients) return;
    final top = widget.selected * _itemExtent;
    final position = _scroll.position;
    final target = top < position.pixels
        ? top
        : top + _itemExtent > position.pixels + position.viewportDimension
        ? top + _itemExtent - position.viewportDimension
        : null;
    if (target != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scroll.hasClients) return;
        _scroll.animateTo(
          target.clamp(0, _scroll.position.maxScrollExtent),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final drafts = widget.drafts;

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              'Preguntas (${drafts.length})',
              style: textTheme.labelLarge,
            ),
          ),
          Divider(height: 1, color: colors.outline),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              itemExtent: _itemExtent,
              itemCount: drafts.length,
              itemBuilder: (context, index) => _Item(
                key: drafts[index].uiKey,
                draft: drafts[index],
                selected: index == widget.selected,
                onTap: () => widget.onSelect(index),
              ),
            ),
          ),
          Divider(height: 1, color: colors.outline),
          TextButton.icon(
            onPressed: widget.onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Agregar pregunta'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accentBlue,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: const RoundedRectangleBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    super.key,
    required this.draft,
    required this.selected,
    required this.onTap,
  });

  final DraftQuestion draft;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final q = draft.data;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final statement = q.statement.trim().replaceAll(RegExp(r'\s+'), ' ');

    return Material(
      color: selected
          ? AppColors.accentBlue.withValues(alpha: 0.07)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: selected ? AppColors.accentBlue : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(13, 8, 12, 8),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: q.isComplete
                      ? AppColors.successBg
                      : AppColors.warningBg,
                ),
                child: Text(
                  '${q.questionNumber}',
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: q.isComplete ? AppColors.success : AppColors.warning,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      statement.isEmpty ? 'Sin enunciado' : statement,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: selected ? FontWeight.w600 : null,
                        fontStyle: statement.isEmpty ? FontStyle.italic : null,
                        color: statement.isEmpty
                            ? AppColors.textSecondary
                            : colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      q.isComplete
                          ? 'Respuesta: ${q.correctOption}  ·  '
                                '${q.options.length} opciones'
                          : 'Falta: ${q.missingFields.join(', ').toLowerCase()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: q.isComplete ? null : AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
