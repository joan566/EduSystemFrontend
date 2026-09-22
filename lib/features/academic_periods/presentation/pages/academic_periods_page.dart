import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/state/list_state.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/app_data_table.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_pagination.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/academic_period_entity.dart';
import '../providers/academic_periods_provider.dart';

class AcademicPeriodsPage extends StatefulWidget {
  const AcademicPeriodsPage({super.key});

  @override
  State<AcademicPeriodsPage> createState() => _AcademicPeriodsPageState();
}

class _AcademicPeriodsPageState extends State<AcademicPeriodsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AcademicPeriodsProvider>().load(),
    );
  }

  Future<void> _openForm({AcademicPeriodEntity? initial}) async {
    final provider = context.read<AcademicPeriodsProvider>();
    final result = await showAppDialog(
      context,
      child: _PeriodForm(initial: initial),
    );
    if (result == null) return;
    final data =
        result as ({String name, DateTime startDate, DateTime endDate});
    final error = initial == null
        ? await provider.create(
            name: data.name,
            startDate: data.startDate,
            endDate: data.endDate,
          )
        : await provider.update(
            initial.id,
            name: data.name,
            startDate: data.startDate,
            endDate: data.endDate,
          );
    if (!mounted) return;
    if (error != null) {
      context.showApiError(error);
    } else {
      context.showSuccess(
        initial == null ? 'Periodo creado.' : 'Periodo actualizado.',
      );
    }
  }

  Future<void> _delete(AcademicPeriodEntity period) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Eliminar periodo',
      message: 'Esta acción no se puede deshacer. ¿Eliminar "${period.name}"?',
      confirmLabel: 'Eliminar',
    );
    if (!confirmed || !mounted) return;
    final error = await context.read<AcademicPeriodsProvider>().delete(
      period.id,
    );
    if (!mounted) return;
    if (error != null) {
      context.showApiError(error);
    } else {
      context.showSuccess('Periodo eliminado.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AcademicPeriodsProvider>().state;

    return Scaffold(
      floatingActionButton: context.isMobile
          ? FloatingActionButton(
              onPressed: () => _openForm(),
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          AppPageHeader(
            title: 'Periodos académicos',
            subtitle:
                'Periodos usados para organizar la enseñanza y la calificación.',
            actions: context.isMobile
                ? []
                : [
                    AppButton(
                      label: 'Nuevo periodo',
                      icon: Icons.add,
                      onPressed: () => _openForm(),
                    ),
                  ],
          ),
          Expanded(child: _buildBody(state)),
          if (state.status == ViewStatus.success)
            AppPagination(
              page: state.page,
              totalPages: state.totalPages,
              totalElements: state.totalElements,
              onPageChanged: (page) =>
                  context.read<AcademicPeriodsProvider>().load(page: page),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(ListViewState<AcademicPeriodEntity> state) {
    switch (state.status) {
      case ViewStatus.initial:
      case ViewStatus.loading:
        return const AppLoading();
      case ViewStatus.error:
        return AppErrorState(
          exception: state.error!,
          onRetry: () => context.read<AcademicPeriodsProvider>().load(),
        );
      case ViewStatus.empty:
        return AppEmptyState(
          title: 'No hay periodos registrados',
          message:
              'Crea un periodo académico para empezar a asignar tus clases.',
          icon: Icons.calendar_month_outlined,
          actionLabel: 'Nuevo periodo',
          onAction: () => _openForm(),
        );
      case ViewStatus.success:
        return AppDataTable<AcademicPeriodEntity>(
          isMobile: context.isMobile,
          items: state.items,
          onRowTap: (item) => _openForm(initial: item),
          mobileCardBuilder: (context, item) => AppListTile(
            icon: Icons.calendar_month_outlined,
            title: item.name,
            subtitle:
                '${Formatters.date(item.startDate)} — ${Formatters.date(item.endDate)}',
            trailing: item.isActive
                ? const AppStatusChip(
                    label: 'Activo',
                    kind: AppStatusKind.success,
                  )
                : IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => _delete(item),
                  ),
            onTap: () => _openForm(initial: item),
          ),
          columns: [
            AppDataColumn(
              label: 'Nombre',
              cellBuilder: (item) => Text(item.name),
            ),
            AppDataColumn(
              label: 'Inicio',
              cellBuilder: (item) => Text(Formatters.date(item.startDate)),
            ),
            AppDataColumn(
              label: 'Fin',
              cellBuilder: (item) => Text(Formatters.date(item.endDate)),
            ),
            AppDataColumn(
              label: 'Estado',
              cellBuilder: (item) => item.isActive
                  ? const AppStatusChip(
                      label: 'Activo',
                      kind: AppStatusKind.success,
                    )
                  : const AppStatusChip(
                      label: 'Inactivo',
                      kind: AppStatusKind.neutral,
                    ),
            ),
            AppDataColumn(
              label: 'Acciones',
              cellBuilder: (item) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: () => _openForm(initial: item),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () => _delete(item),
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }
}

class _PeriodForm extends StatefulWidget {
  const _PeriodForm({this.initial});

  final AcademicPeriodEntity? initial;

  @override
  State<_PeriodForm> createState() => _PeriodFormState();
}

class _PeriodFormState extends State<_PeriodForm> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.initial?.name,
  );
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initial?.startDate;
    _endDate = widget.initial?.endDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona la fecha de inicio y fin.')),
      );
      return;
    }
    if (!_endDate!.isAfter(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La fecha de fin debe ser posterior a la de inicio.'),
        ),
      );
      return;
    }
    Navigator.of(context).pop((
      name: _nameController.text.trim(),
      startDate: _startDate!,
      endDate: _endDate!,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initial != null;
    return AppDialogFrame(
      title: isEditing ? 'Editar periodo' : 'Nuevo periodo',
      actions: [AppButton(label: 'Guardar', onPressed: _submit)],
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _nameController,
              label: 'Nombre',
              required: true,
              hint: 'Ej. Primer periodo 2026',
              validator: (v) => Validators.combine([
                (v) => Validators.required(v, field: 'El nombre'),
                (v) => Validators.maxLength(v, 100, field: 'El nombre'),
              ])(v),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'Fecha de inicio',
                    date: _startDate,
                    onTap: () => _pickDate(isStart: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateField(
                    label: 'Fecha de fin',
                    date: _endDate,
                    onTap: () => _pickDate(isStart: false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: '$label *'),
        child: Text(date == null ? 'Seleccionar' : Formatters.date(date!)),
      ),
    );
  }
}
