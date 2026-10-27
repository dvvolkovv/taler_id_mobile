import 'package:flutter/material.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';

import '../../../../core/services/apk_installer_service.dart';
import '../../../../core/services/app_update_controller.dart';
import '../../../../core/theme/app_theme.dart';

/// The update offer. Floats over the home screen (AssistantScreen) and never
/// takes layout space — the old banner pushed every screen down.
class UpdateCard extends StatelessWidget {
  const UpdateCard({super.key, required this.controller});

  final AppUpdateController controller;

  static const _blue = Color(0xFF1565C0);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.visible) return const SizedBox.shrink();
        final l10n = AppLocalizations.of(context)!;
        final version = controller.version!;
        final phase = controller.phase;
        final notes = controller.info?.latestNotes(Localizations.localeOf(context).languageCode);

        final String title;
        String? actionLabel;
        VoidCallback? onAction;
        switch (phase) {
          case UpdatePhase.available:
            title = l10n.dashboardUpdateAvailable(version);
            actionLabel = l10n.dashboardUpdate;
            onAction = () => controller.startDownload();
          case UpdatePhase.downloading:
            title = l10n.updateDownloading((controller.progress * 100).round());
            actionLabel = l10n.updateHide;
            onAction = controller.dismiss;
          case UpdatePhase.ready:
            title = l10n.updateDownloaded(version);
            actionLabel = l10n.updateInstall;
            onAction = () => controller.install();
          case UpdatePhase.installing:
            title = l10n.dashboardInstalling;
          case UpdatePhase.failed:
            title = l10n.updateDownloadFailed;
            actionLabel = l10n.updateRetry;
            onAction = () => controller.startDownload();
        }
        final showClose = phase != UpdatePhase.downloading && phase != UpdatePhase.installing;
        final showNotes = phase == UpdatePhase.available && (notes?.isNotEmpty ?? false);
        final faded = Colors.white.withValues(alpha: 0.85);

        return Material(
          key: const Key('update-card'),
          color: _blue,
          elevation: 6,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
                child: Row(
                  children: [
                    const Icon(Icons.system_update_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (showNotes) ...[
                            const SizedBox(height: 2),
                            GestureDetector(
                              key: const Key('update-card-notes'),
                              onTap: () => showUpdateWhatsNew(context, version, notes!),
                              child: Text(
                                l10n.dashboardWhatsNew,
                                style: TextStyle(
                                  color: faded,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                  decorationColor: faded,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (actionLabel != null)
                      TextButton(
                        key: const Key('update-card-action'),
                        onPressed: onAction,
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          actionLabel,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        ),
                      ),
                    if (showClose)
                      IconButton(
                        key: const Key('update-card-close'),
                        onPressed: controller.dismiss,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close, color: Colors.white, size: 18),
                      )
                    else
                      const SizedBox(width: 8),
                  ],
                ),
              ),
              if (phase == UpdatePhase.downloading)
                LinearProgressIndicator(
                  value: controller.progress,
                  minHeight: 3,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
            ],
          ),
        );
      },
    );
  }
}

void showUpdateWhatsNew(BuildContext context, String version, String notes) {
  final l10n = AppLocalizations.of(context)!;
  final colors = AppColors.of(context);
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: colors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scrollCtrl) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: colors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              l10n.dashboardWhatsNewTitle(version),
              style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                child: Text(
                  notes,
                  style: TextStyle(color: colors.textPrimary, fontSize: 14, height: 1.45),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Explains a failed install; success and a declined prompt need no words.
void showUpdateInstallResult(BuildContext context, ApkInstallResponse res, String displayName) {
  final l10n = AppLocalizations.of(context)!;
  final String title;
  final String body;
  switch (res.status) {
    case ApkInstallStatus.success:
    case ApkInstallStatus.aborted:
      return;
    case ApkInstallStatus.conflict:
      title = l10n.updateInstallConflictTitle;
      body = l10n.updateInstallConflictBody(displayName);
    case ApkInstallStatus.downloadFailed:
    case ApkInstallStatus.incompatible:
    case ApkInstallStatus.blocked:
    case ApkInstallStatus.storage:
    case ApkInstallStatus.invalid:
    case ApkInstallStatus.failureUnknown:
      final reason = res.message.isNotEmpty ? res.message : res.status.name;
      title = l10n.updateInstallFailedTitle;
      body = l10n.updateInstallFailedBody(reason, displayName);
  }
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.updateInstallOk),
        ),
      ],
    ),
  );
}
