class DashboardSummary {
  final int totalLeads;
  final int todaysVisits;
  final int activeVisits;
  final double targetMonthly;
  final double targetAchieved;
  final double targetProgress;

  DashboardSummary({
    required this.totalLeads,
    required this.todaysVisits,
    required this.activeVisits,
    required this.targetMonthly,
    required this.targetAchieved,
    required this.targetProgress,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final target = json['target'] ?? {};
    return DashboardSummary(
      totalLeads: json['totalLeads'] ?? 0,
      todaysVisits: json['todaysVisits'] ?? 0,
      activeVisits: json['activeVisits'] ?? 0,
      targetMonthly: (target['monthly'] ?? 0).toDouble(),
      targetAchieved: (target['achieved'] ?? 0).toDouble(),
      targetProgress: (target['progress'] ?? 0).toDouble(),
    );
  }
}
