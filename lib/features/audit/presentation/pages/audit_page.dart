import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/state/list_state.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_pagination.dart';
import '../../domain/entities/audit_log_entity.dart';
import '../providers/audit_provider.dart';

class AuditPage extends StatefulWidget {
  const AuditPage({super.key});

  @override
  State<AuditPage> createState() => _AuditPageState();
}

class _AuditPageState extends State<AuditPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AuditProvider>().load());
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuditProvider>().state;

    return Scaffold(
      body: Column(
        children: [
          const AppPageHeader(
            title: 'Auditoría',
            subtitle: 'Historial de acciones realizadas en tu cuenta.',
          ),
          Expanded(child: _buildBody(state)),
          if (state.status == ViewStatus.success)
            AppPagination(
              page: state.page,
              totalPages: state.totalPages,
              totalElements: state.totalElements,
              onPageChanged: (page) => context.read<AuditProvider>().load(page: page),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(ListViewState<AuditLogEntity> state) {
    switch (state.status) {
      case ViewStatus.initial:
      case ViewStatus.loading:
        return const AppLoading();
      case ViewStatus.error:
        return AppErrorState(
          exception: state.error!,
          onRetry: () => context.read<AuditProvider>().load(),
        );
      case ViewStatus.empty:
        return const AppEmptyState(
          title: 'No hay actividad registrada',
          icon: Icons.history_outlined,
        );
      case ViewStatus.success:
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: state.items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 4),
          itemBuilder: (context, index) => _AuditTile(log: state.items[index]),
        );
    }
  }
}

class _AuditTile extends StatelessWidget {
  const _AuditTile({required this.log});

  final AuditLogEntity log;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        log.isSuccess ? Icons.check_circle_outline : Icons.error_outline,
        color: log.isSuccess
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.error,
      ),
      title: Text(_actionLabel(log.action)),
      subtitle: Text('${log.entityType}${log.entityId != null ? ' #${log.entityId}' : ''}'),
      trailing: Text(
        Formatters.dateTime(log.createdAt),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  String _actionLabel(AuditAction action) => switch (action) {
    AuditAction.login => 'Inicio de sesión',
    AuditAction.logout => 'Cierre de sesión',
    AuditAction.create => 'Creación',
    AuditAction.update => 'Actualización',
    AuditAction.delete => 'Eliminación',
    AuditAction.import => 'Importación',
    AuditAction.export => 'Exportación',
    AuditAction.examProcessed => 'Examen procesado',
    AuditAction.gradeUpdated => 'Calificación actualizada',
    AuditAction.answerUpdated => 'Respuesta corregida',
  };
}
