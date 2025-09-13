// lib/widgets/sync_status_widget.dart
import 'package:flutter/material.dart';
import '../utils/formatters.dart';

class SyncStatusWidget extends StatelessWidget {
  final int localRecordCount;
  final DateTime? lastSyncTime;
  final bool isSyncing;
  final VoidCallback onSyncPressed;

  const SyncStatusWidget({
    Key? key,
    required this.localRecordCount,
    this.lastSyncTime,
    required this.isSyncing,
    required this.onSyncPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasLocalData = localRecordCount > 0;

    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: hasLocalData
                ? [Colors.green.shade50, Colors.green.shade100]
                : [Colors.orange.shade50, Colors.orange.shade100],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildStatusIcon(hasLocalData),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatusInfo(context, hasLocalData),
            ),
            _buildSyncButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(bool hasLocalData) {
    return Icon(
      hasLocalData ? Icons.cloud_done : Icons.cloud_off,
      color: hasLocalData ? Colors.green.shade700 : Colors.orange.shade700,
      size: 24,
    );
  }

  Widget _buildStatusInfo(BuildContext context, bool hasLocalData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hasLocalData ? 'Data Synced' : 'No Data',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: hasLocalData ? Colors.green.shade800 : Colors.orange.shade800,
          ),
        ),
        Text(
          '$localRecordCount records available',
          style: const TextStyle(fontSize: 12),
        ),
        if (lastSyncTime != null)
          Text(
            'Last sync: ${Formatters.formatRelativeTime(lastSyncTime)}',
            style: const TextStyle(fontSize: 12),
          ),
      ],
    );
  }

  Widget _buildSyncButton() {
    if (isSyncing) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return ElevatedButton.icon(
      onPressed: onSyncPressed,
      icon: const Icon(Icons.sync, size: 16),
      label: const Text('SYNC'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}