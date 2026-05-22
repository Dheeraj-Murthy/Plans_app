import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plans_app/shared/sync/sync_service.dart';

class SyncIndicator extends ConsumerWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncServiceProvider);
    final sync = ref.read(syncServiceProvider.notifier);
    final color = switch (status) {
      SyncStatus.disconnected => Colors.grey,
      SyncStatus.authenticating => Colors.orange,
      SyncStatus.syncing => Colors.blue,
      SyncStatus.idle => Colors.green,
      SyncStatus.error => Colors.red,
    };
    final tooltip = switch (status) {
      SyncStatus.disconnected => 'Sync disconnected',
      SyncStatus.authenticating => 'Authenticating…',
      SyncStatus.syncing => 'Syncing…',
      SyncStatus.idle => sync.lastSyncedFrom != null
          ? 'Last synced from ${sync.lastSyncedFrom}'
          : 'All synced',
      SyncStatus.error => sync.lastError ?? 'Sync error',
    };

    return Tooltip(
      message: tooltip,
      child: status == SyncStatus.syncing
          ? SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          : Icon(Icons.cloud_done_outlined, size: 20, color: color),
    );
  }
}
