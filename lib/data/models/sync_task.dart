import 'package:hive/hive.dart';

part 'sync_task.g.dart';

@HiveType(typeId: 0)
class SyncTask extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String type; // e.g., 'CHECK_IN', 'CHECK_OUT', 'UPDATE_LEAD'

  @HiveField(2)
  final String payload; // JSON string

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  int retryCount;

  @HiveField(5)
  String status; // 'PENDING', 'FAILED'

  SyncTask({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
    this.status = 'PENDING',
  });
}
