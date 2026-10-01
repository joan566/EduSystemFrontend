import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/imports_provider.dart';
import '../shared/import_activity.dart';

/// Strip above the bottom navigation while an import runs, on every
/// screen but the import/export one: what it is doing, a bar and the
/// percentage. Tapping it opens the import/export screen.
class MobileImportBanner extends StatelessWidget {
  const MobileImportBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final active = context.watch<ImportsProvider>().activeImport;
    if (active == null || isOnDataManagement(context)) {
      return const SizedBox.shrink();
    }
    final value = importRunProgress(active.run);
    return Material(
      color: AppColors.accentBlue.withValues(alpha: 0.08),
      child: InkWell(
        onTap: () => context.push(RoutePaths.dataManagement),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.upload_file_outlined,
                    size: 18,
                    color: AppColors.accentBlue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      importRunLabel(active.run),
                      style: context.textStyles.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (value != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '${(value * 100).round()}%',
                      style: context.textStyles.bodySmall?.copyWith(
                        color: AppColors.accentBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: value, minHeight: 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
