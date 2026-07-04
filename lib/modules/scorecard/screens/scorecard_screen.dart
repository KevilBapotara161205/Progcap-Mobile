import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progcap_app/data/repositories/dashboard_repository.dart';

class ScorecardScreen extends ConsumerWidget {
  const ScorecardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scorecardState = ref.watch(rmScorecardProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Scorecard')),
      body: scorecardState.when(
        data: (data) {
          final target = data['target'] ?? {};
          final achieved = (target['achieved'] ?? 0).toDouble();
          final monthly = (target['monthly'] ?? 1000000).toDouble();
          final progress = ((achieved / monthly) * 100).toInt();
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildPerformanceCard(context, progress, achieved),
                const SizedBox(height: 24),
                _buildMetricsGrid(data),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildPerformanceCard(BuildContext context, int progress, double achieved) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Colors.purple, Colors.deepPurple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const Text('Target Achieved', style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 8),
            Text('$progress%', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.arrow_upward, color: Colors.greenAccent, size: 20),
                const SizedBox(width: 4),
                Text('₹${(achieved / 100000).toStringAsFixed(1)}L / ₹${(1000000 / 100000).toStringAsFixed(1)}L', style: const TextStyle(color: Colors.white)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(Map<String, dynamic> data) {
    final totalLeads = data['totalLeads'] ?? 0;
    final todaysVisits = data['todaysVisits'] ?? 0;
    final activeVisits = data['activeVisits'] ?? 0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildMetricItem('Total Leads', totalLeads.toString(), Icons.people, Colors.blue),
        _buildMetricItem('Check-ins Today', todaysVisits.toString(), Icons.location_on, Colors.green),
        _buildMetricItem('Active Visits', activeVisits.toString(), Icons.timer, Colors.orange),
        _buildMetricItem('Target Rank', '#3', Icons.emoji_events, Colors.amber), // Stub rank
      ],
    );
  }

  Widget _buildMetricItem(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}
