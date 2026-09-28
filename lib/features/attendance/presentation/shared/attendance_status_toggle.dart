import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/attendance_entity.dart';

/// Three-way P / A / E selector for one student's attendance.
class AttendanceStatusToggle extends StatelessWidget {
  const AttendanceStatusToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final AttendanceStatus? value;
  final void Function(AttendanceStatus) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _chip(context, 'P', AttendanceStatus.present, AppColors.success),
        const SizedBox(width: 4),
        _chip(context, 'A', AttendanceStatus.absent, AppColors.error),
        const SizedBox(width: 4),
        _chip(context, 'E', AttendanceStatus.excused, AppColors.warning),
      ],
    );
  }

  Widget _chip(
    BuildContext context,
    String label,
    AttendanceStatus status,
    Color color,
  ) {
    final selected = value == status;
    return Tooltip(
      message: switch (status) {
        AttendanceStatus.present => 'Presente',
        AttendanceStatus.absent => 'Ausente',
        AttendanceStatus.excused => 'Excusado',
      },
      child: InkWell(
        onTap: () => onChanged(status),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? color : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
