import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/layout/responsive.dart';
import '../../../../core/state/detail_state.dart';
import '../../../../core/widgets/shared/app_confirm_dialog.dart';
import '../../../schedule/presentation/providers/schedule_provider.dart';
import '../../../teaching/domain/entities/teaching_period_entity.dart';
import '../../../teaching/presentation/providers/teaching_provider.dart';
import '../desktop/attendance_desktop_view.dart';
import '../mobile/attendance_mobile_view.dart';
import '../providers/attendance_provider.dart';
import '../shared/attendance_day_controller.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({
    super.key,
    this.initialTeachingPeriodId,
    this.initialDate,
  });

  /// Class to preselect (from `?teachingPeriodId=`), e.g. when opened from
  /// a class screen.
  final int? initialTeachingPeriodId;

  /// Date to open (from `?date=`), e.g. an attendance evaluation's date.
  final DateTime? initialDate;

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  // Live here, not in a view, so the class, the date and the marks survive
  // a mobile <-> desktop switch.
  TeachingPeriodEntity? _period;
  late DateTime _date = widget.initialDate == null
      ? _today()
      : DateUtils.dateOnly(widget.initialDate!);
  final _day = AttendanceDayController();

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pickInitialClass());
  }

  @override
  void dispose() {
    _day.dispose();
    super.dispose();
  }

  /// The requested class, else the one in progress or next today, else the
  /// first one.
  Future<void> _pickInitialClass() async {
    final teaching = context.read<TeachingProvider>();
    final schedule = context.read<ScheduleProvider>();
    await Future.wait([
      teaching.ensureAllPeriodsLoaded(),
      if (schedule.today.status == DetailStatus.initial) schedule.loadToday(),
    ]);
    if (!mounted || _period != null || teaching.allPeriods.isEmpty) return;
    final periods = teaching.allPeriods;
    final nextId = schedule.today.data?.nextClass?.teachingPeriodId;
    _setPeriod(
      periods
              .where((p) => p.id == widget.initialTeachingPeriodId)
              .firstOrNull ??
          periods.where((p) => p.id == nextId).firstOrNull ??
          periods.first,
    );
  }

  /// Asks before dropping marks that weren't saved.
  Future<bool> _confirmDiscard() async {
    if (!_day.hasPending) return true;
    return showAppConfirmDialog(
      context,
      title: 'Cambios sin guardar',
      message: 'Hay asistencia marcada que no has guardado. ¿Descartarla?',
      confirmLabel: 'Descartar',
    );
  }

  Future<void> _onPeriodChanged(TeachingPeriodEntity? period) async {
    if (period?.id == _period?.id || !await _confirmDiscard()) return;
    _setPeriod(period);
  }

  void _setPeriod(TeachingPeriodEntity? period) {
    setState(() {
      _period = period;
      if (period != null) _date = _clampToClass(_date, period);
    });
    if (period == null) {
      _day.clear();
      return;
    }
    context.read<AttendanceProvider>().load(teachingPeriodId: period.id);
    context.read<ScheduleProvider>().loadClassSchedules(period.id);
    _loadDay();
  }

  Future<void> _onDateChanged(DateTime date) async {
    final day = DateTime(date.year, date.month, date.day);
    if (day == _date || !await _confirmDiscard()) return;
    setState(() => _date = day);
    _loadDay();
  }

  DateTime _clampToClass(DateTime date, TeachingPeriodEntity period) {
    if (date.isBefore(period.startDate)) return period.startDate;
    if (date.isAfter(period.endDate)) return period.endDate;
    return date;
  }

  Future<void> _loadDay() async {
    final period = _period;
    if (period == null) return;
    final date = _date;
    _day.clear();
    final day = await context.read<AttendanceProvider>().loadDay(
      teachingPeriodId: period.id,
      date: date,
    );
    if (day != null && mounted && _period?.id == period.id && _date == date) {
      _day.seed(day.students);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (_) => AttendanceMobileView(
        period: _period,
        date: _date,
        controller: _day,
        onPeriodChanged: _onPeriodChanged,
        onDateChanged: _onDateChanged,
        onRetry: _loadDay,
      ),
      desktop: (_) => AttendanceDesktopView(
        period: _period,
        date: _date,
        controller: _day,
        onPeriodChanged: _onPeriodChanged,
        onDateChanged: _onDateChanged,
        onRetry: _loadDay,
      ),
    );
  }
}
