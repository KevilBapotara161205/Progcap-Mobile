class TrainingModule {
  final String id;
  final String title;
  final String description;
  final String contentType;
  final String contentUrl;
  final bool isCompleted;

  TrainingModule({
    required this.id,
    required this.title,
    required this.description,
    required this.contentType,
    required this.contentUrl,
    required this.isCompleted,
  });

  factory TrainingModule.fromJson(Map<String, dynamic> json, String currentUserId) {
    bool completed = false;
    if (json['completions'] != null) {
      final completions = json['completions'] as List;
      completed = completions.any((c) => c['user'] == currentUserId);
    }

    return TrainingModule(
      id: json['_id'] ?? '',
      title: json['title'] ?? 'Unknown Module',
      description: json['description'] ?? '',
      contentType: json['contentType'] ?? 'VIDEO',
      contentUrl: json['contentUrl'] ?? '',
      isCompleted: completed,
    );
  }
}
