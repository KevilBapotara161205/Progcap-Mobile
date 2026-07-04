import 'package:flutter/material.dart';
import '../theme/colors.dart';

enum SyncState { synced, syncing, offline, error }

class SyncBanner extends StatelessWidget {
  final SyncState syncState;
  final int pendingActions;

  const SyncBanner({super.key, required this.syncState, this.pendingActions = 0});

  @override
  Widget build(BuildContext context) {
    if (syncState == SyncState.synced && pendingActions == 0) return const SizedBox();
    
    Color bgColor = AppColors.warning;
    String text = 'Syncing...';
    
    if (syncState == SyncState.offline) {
      bgColor = AppColors.error;
      text = 'Offline - $pendingActions pending';
    } else if (syncState == SyncState.error) {
      bgColor = AppColors.error;
      text = 'Sync Failed';
    }

    return Container(
      width: double.infinity,
      color: bgColor,
      padding: const EdgeInsets.symmetric(vertical: 4),
      alignment: Alignment.center,
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
