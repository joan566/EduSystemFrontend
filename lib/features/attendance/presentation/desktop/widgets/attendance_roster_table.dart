import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/shared/app_search_field.dart';
import '../../../domain/entities/attendance_entity.dart';
import '../../shared/attendance_day_controller.dart';
import '../../shared/attendance_visuals.dart';

const _statusWidth = 348.0;
const _compactStatusWidth = 132.0;

/// Below this table width the status buttons show only their icon.
const _compactBelow = 820.0;

/// The roster as a marking table: search and filters on top, one row per
/// student with the three statuses as buttons and an inline observation.
/// With the table focused, ↑/↓ move between students and P, A, J mark the
/// selected one and move to the next. Nothing is sent until the screen
/// saves.
class AttendanceRosterTable extends StatefulWidget {
  const AttendanceRosterTable({super.key, required this.controller});

  final AttendanceDayController controller;

  @override
  State<AttendanceRosterTable> createState() => _AttendanceRosterTableState();
}

class _AttendanceRosterTableState extends State<AttendanceRosterTable> {
  final _focus = FocusNode(debugLabel: 'attendance-roster');
  final _scroll = ScrollController();
  static const _rowHeight = 64.0;

  /// Keyboard cursor; ephemeral UI state (resets with the layout).
  int? _selectedId;

  AttendanceDayController get _c => widget.controller;

  @override
  void dispose() {
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _select(int studentId) {
    setState(() => _selectedId = studentId);
    _focus.requestFocus();
  }

  void _move(int delta) {
    final visible = _c.visibleStudents;
    if (visible.isEmpty) return;
    final index = visible.indexWhere((s) => s.studentId == _selectedId);
    final next = (index + delta).clamp(0, visible.length - 1);
    setState(() => _selectedId = visible[index < 0 ? 0 : next].studentId);
    _reveal(index < 0 ? 0 : next);
  }

  void _reveal(int index) {
    if (!_scroll.hasClients) return;
    final top = index * _rowHeight;
    final viewport = _scroll.position.viewportDimension;
    final offset = _scroll.offset;
    if (top < offset) {
      _scroll.jumpTo(top);
    } else if (top + _rowHeight > offset + viewport) {
      _scroll.jumpTo(top + _rowHeight - viewport);
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    // Only when the table itself has focus, never while typing somewhere.
    if (!node.hasPrimaryFocus || _c.saving) return KeyEventResult.ignored;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      _move(1);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _move(-1);
    } else if (_statusForKey(key) case final status?) {
      final id = _selectedId;
      if (id == null) {
        _move(0);
        return KeyEventResult.handled;
      }
      _c.mark(id, status, observation: _c.observationOf(id));
      _move(1);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  AttendanceStatus? _statusForKey(LogicalKeyboardKey key) => switch (key) {
    LogicalKeyboardKey.keyP => AttendanceStatus.present,
    LogicalKeyboardKey.keyA => AttendanceStatus.absent,
    LogicalKeyboardKey.keyJ => AttendanceStatus.excused,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) =>
          _table(context, compact: constraints.maxWidth < _compactBelow),
    );
  }

  Widget _table(BuildContext context, {required bool compact}) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final students = _c.visibleStudents;
    final unmarked = _c.unmarkedCount;
    final statusWidth = compact ? _compactStatusWidth : _statusWidth;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 260,
                  child: AppSearchField(
                    hint: 'Buscar estudiante...',
                    initialValue: _c.query,
                    onChanged: _c.search,
                  ),
                ),
                _FilterBar(controller: _c),
                if (unmarked > 0)
                  TextButton.icon(
                    onPressed: _c.saving ? null : _c.markUnmarkedPresent,
                    icon: const Icon(Icons.done_all, size: 18),
                    label: Text(
                      unmarked == 1
                          ? 'Marcar presente al que falta'
                          : 'Marcar presentes a los $unmarked que faltan',
                    ),
                  ),
              ],
            ),
          ),
          Container(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: DefaultTextStyle.merge(
              style: textTheme.labelMedium?.copyWith(
                color: textTheme.bodySmall?.color,
                fontWeight: FontWeight.w600,
              ),
              child: Row(
                children: [
                  const SizedBox(width: 36, child: Text('#')),
                  const Expanded(flex: 3, child: Text('ESTUDIANTE')),
                  SizedBox(width: statusWidth, child: const Text('ESTADO')),
                  const SizedBox(width: 16),
                  const Expanded(flex: 2, child: Text('OBSERVACIÓN')),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: colors.outline),
          Expanded(
            child: Focus(
              focusNode: _focus,
              onKeyEvent: _onKey,
              child: students.isEmpty
                  ? Center(
                      child: Text(
                        'Ningún estudiante coincide con la búsqueda o el filtro.',
                        style: textTheme.bodyMedium,
                      ),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      itemExtent: _rowHeight,
                      itemCount: students.length,
                      itemBuilder: (context, i) {
                        final s = students[i];
                        return _Row(
                          index: _c.students.indexOf(s) + 1,
                          student: s,
                          status: _c.statusOf(s.studentId),
                          observation: _c.observationOf(s.studentId),
                          pending: _c.isPending(s.studentId),
                          selected: s.studentId == _selectedId,
                          compact: compact,
                          enabled: !_c.saving,
                          onSelect: () => _select(s.studentId),
                          onStatus: (status) {
                            _select(s.studentId);
                            _c.mark(
                              s.studentId,
                              status,
                              observation: _c.observationOf(s.studentId),
                            );
                          },
                          onObservation: (text) =>
                              _c.setObservation(s.studentId, text),
                          onObservationDone: _focus.requestFocus,
                        );
                      },
                    ),
            ),
          ),
          Divider(height: 1, color: colors.outline),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.keyboard_outlined,
                  size: 16,
                  color: textTheme.bodySmall?.color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Selecciona un estudiante y usa ↑ ↓ para moverte · '
                    'P presente · A ausente · J justificada',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.controller});

  final AttendanceDayController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    String label(AttendanceFilter f) => switch (f) {
      AttendanceFilter.all => 'Todos ${c.students.length}',
      AttendanceFilter.unmarked => 'Sin marcar ${c.unmarkedCount}',
      AttendanceFilter.present =>
        'Presentes ${c.countOf(AttendanceStatus.present)}',
      AttendanceFilter.absent =>
        'Ausentes ${c.countOf(AttendanceStatus.absent)}',
      AttendanceFilter.excused =>
        'Justificadas ${c.countOf(AttendanceStatus.excused)}',
    };
    return SegmentedButton<AttendanceFilter>(
      showSelectedIcon: false,
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
      segments: [
        for (final f in AttendanceFilter.values)
          ButtonSegment(value: f, label: Text(label(f))),
      ],
      selected: {c.filter},
      onSelectionChanged: (v) => c.setFilter(v.first),
    );
  }
}

class _Row extends StatefulWidget {
  const _Row({
    required this.index,
    required this.student,
    required this.status,
    required this.observation,
    required this.pending,
    required this.selected,
    required this.compact,
    required this.enabled,
    required this.onSelect,
    required this.onStatus,
    required this.onObservation,
    required this.onObservationDone,
  });

  final int index;
  final SessionStudentRecord student;
  final AttendanceStatus? status;
  final String? observation;
  final bool pending;
  final bool selected;

  /// Status buttons show only their icon.
  final bool compact;
  final bool enabled;
  final VoidCallback onSelect;
  final ValueChanged<AttendanceStatus> onStatus;
  final ValueChanged<String> onObservation;

  /// Editing ended; focus goes back to the table (keys and Ctrl+S work
  /// again).
  final VoidCallback onObservationDone;

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final w = widget;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: w.onSelect,
        child: Container(
          decoration: BoxDecoration(
            color: w.selected
                ? AppColors.accentBlue.withValues(alpha: 0.06)
                : _hovered
                ? colors.surfaceContainerHighest.withValues(alpha: 0.35)
                : null,
            border: Border(
              left: BorderSide(
                color: w.selected ? AppColors.accentBlue : Colors.transparent,
                width: 3,
              ),
              bottom: BorderSide(color: colors.outline.withValues(alpha: 0.6)),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(13, 0, 16, 0),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child: Text('${w.index}', style: textTheme.bodySmall),
              ),
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: AppColors.accentBlue.withValues(
                        alpha: 0.1,
                      ),
                      child: Text(
                        _initials(w.student.studentName),
                        style: textTheme.labelMedium?.copyWith(
                          color: AppColors.accentBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            w.student.studentName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            [
                              w.student.studentCode,
                              if (w.pending) 'Sin guardar',
                            ].join(' · '),
                            maxLines: 1,
                            style: textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: w.pending ? AppColors.warning : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: w.compact ? _compactStatusWidth : _statusWidth,
                child: Row(
                  children: [
                    for (final (i, status)
                        in AttendanceStatus.values.indexed) ...[
                      if (i > 0) const SizedBox(width: 6),
                      Expanded(
                        child: _StatusButton(
                          status: status,
                          selected: w.status == status,
                          compact: w.compact,
                          onPressed: w.enabled
                              ? () => w.onStatus(status)
                              : null,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _ObservationCell(
                  value: w.observation,
                  enabled: w.enabled && w.status != null,
                  onChanged: w.onObservation,
                  onDone: w.onObservationDone,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.status,
    required this.selected,
    required this.compact,
    required this.onPressed,
  });

  final AttendanceStatus status;
  final bool selected;
  final bool compact;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final visuals = attendanceVisuals(status);
    final color = visuals.color;
    final key = switch (status) {
      AttendanceStatus.present => 'P',
      AttendanceStatus.absent => 'A',
      AttendanceStatus.excused => 'J',
    };

    return Tooltip(
      message: '${visuals.label} ($key)',
      waitDuration: const Duration(milliseconds: 600),
      child: Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: selected ? color : colors.outline),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: SizedBox(
              height: 34,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: selected ? color : null,
                      shape: BoxShape.circle,
                      border: selected
                          ? null
                          : Border.all(
                              color: color.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                    ),
                    child: selected
                        ? Icon(visuals.icon, size: 13, color: Colors.white)
                        : null,
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        visuals.label,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: textTheme.labelMedium?.copyWith(
                          color: selected ? color : textTheme.bodySmall?.color,
                          fontWeight: selected ? FontWeight.w700 : null,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The observation as text; click to edit it in place (Enter or clicking
/// away keeps it, Esc cancels). Needs a status first.
class _ObservationCell extends StatefulWidget {
  const _ObservationCell({
    required this.value,
    required this.enabled,
    required this.onChanged,
    required this.onDone,
  });

  final String? value;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final VoidCallback onDone;

  @override
  State<_ObservationCell> createState() => _ObservationCellState();
}

class _ObservationCellState extends State<_ObservationCell> {
  bool _editing = false;
  late final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _start() {
    _text.text = widget.value ?? '';
    setState(() => _editing = true);
  }

  void _commit() {
    if (!_editing) return;
    widget.onChanged(_text.text);
    _stop();
  }

  void _stop() {
    setState(() => _editing = false);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.color;

    if (_editing) {
      return CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.escape): _stop},
        child: TextField(
          controller: _text,
          autofocus: true,
          maxLength: 255,
          style: textTheme.bodyMedium,
          decoration: const InputDecoration(
            isDense: true,
            counterText: '',
            hintText: 'Escribe y pulsa Enter',
          ),
          onSubmitted: (_) => _commit(),
          onTapOutside: (_) => _commit(),
        ),
      );
    }

    final value = widget.value;
    return Tooltip(
      message: widget.enabled ? '' : 'Marca primero el estado',
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: widget.enabled ? _start : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Icon(
                value == null ? Icons.add_comment_outlined : Icons.edit_note,
                size: 18,
                color: widget.enabled ? muted : muted?.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value ?? 'Agregar observación',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: value == null
                      ? textTheme.bodySmall?.copyWith(
                          color: widget.enabled
                              ? muted
                              : muted?.withValues(alpha: 0.4),
                        )
                      : textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
