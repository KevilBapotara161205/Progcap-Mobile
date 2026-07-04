import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progcap_app/data/models/training_module.dart';
import 'package:progcap_app/data/repositories/training_repository.dart';
import 'package:progcap_app/modules/training/screens/training_player_screen.dart';

class TrainingHomeScreen extends ConsumerWidget {
  const TrainingHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modulesState = ref.watch(trainingModulesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Training & Modules')),
      body: modulesState.when(
        data: (modules) {
          if (modules.isEmpty) {
            return const Center(child: Text('No training modules available at the moment.'));
          }

          final mandatoryModule = modules.first;
          final recommendedModules = modules.skip(1).toList();

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildFeaturedModule(context, mandatoryModule),
              if (recommendedModules.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text('Recommended for You', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...recommendedModules.map((m) => _buildModuleTile(context, m)),
              ]
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildFeaturedModule(BuildContext context, TrainingModule module) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TrainingPlayerScreen(module: module))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: const Center(child: Icon(Icons.play_circle_fill, size: 64, color: Colors.blue)),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(4)),
                    child: const Text('MANDATORY', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  Text(module.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  if (module.isCompleted)
                    const Text('Completed', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                  else
                    const Text('Deadline: Pending', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TrainingPlayerScreen(module: module))),
                      child: Text(module.isCompleted ? 'Watch Again' : 'Start Module')
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildModuleTile(BuildContext context, TrainingModule module) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TrainingPlayerScreen(module: module))),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: module.isCompleted ? Colors.green.shade50 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(module.isCompleted ? Icons.check_circle : Icons.menu_book, color: module.isCompleted ? Colors.green : Colors.blue),
        ),
        title: Text(module.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(module.contentType),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: module.isCompleted ? 1.0 : 0.0, backgroundColor: Colors.grey.shade200, color: Colors.green),
          ],
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
