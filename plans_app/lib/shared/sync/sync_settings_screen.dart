import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plans_app/shared/sync/sync_service.dart';

class SyncSettingsScreen extends ConsumerWidget {
  const SyncSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncServiceProvider);
    final sync = ref.read(syncServiceProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Sync')),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(
              sync.isAuthenticated ? Icons.cloud_done : Icons.cloud_off,
              color: sync.isAuthenticated ? Colors.green : Colors.grey,
            ),
            title: Text(sync.isAuthenticated ? 'Google Drive connected' : 'Not connected'),
            subtitle: Text(sync.isAuthenticated
                ? 'Syncing in background'
                : 'Connect to sync across devices'),
            trailing: sync.isAuthenticated
                ? TextButton(onPressed: sync.signOut, child: const Text('Disconnect'))
                : FilledButton(onPressed: sync.authenticate, child: const Text('Connect')),
          ),
          if (sync.lastSyncedFrom != null)
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Last sync'),
              subtitle: Text(sync.lastSyncedFrom!),
            ),
          if (status == SyncStatus.error && sync.lastError != null)
            ListTile(
              leading: const Icon(Icons.error, color: Colors.red),
              title: const Text('Error'),
              subtitle: Text(sync.lastError!),
              trailing: TextButton(
                onPressed: sync.checkForUpdates,
                child: const Text('Retry'),
              ),
            ),
          if (sync.isAuthenticated)
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Sync now'),
              onTap: sync.checkForUpdates,
            ),
        ],
      ),
    );
  }
}
