import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progcap_app/data/models/training_module.dart';
import 'package:progcap_app/data/repositories/training_repository.dart';

class TrainingPlayerScreen extends ConsumerStatefulWidget {
  final TrainingModule module;

  const TrainingPlayerScreen({super.key, required this.module});

  @override
  ConsumerState<TrainingPlayerScreen> createState() => _TrainingPlayerScreenState();
}

class _TrainingPlayerScreenState extends ConsumerState<TrainingPlayerScreen> {
  bool _isPlaying = false;
  double _progress = 0.0;
  bool _isCompleted = false;

  void _simulatePlayback() {
    setState(() => _isPlaying = true);
    
    // Simulate watching the video
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _progress = 0.3);
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _progress = 0.7);
    });
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _progress = 1.0;
          _isPlaying = false;
          _isCompleted = true;
        });
        _markCompleted();
      }
    });
  }

  Future<void> _markCompleted() async {
    try {
      final repo = ref.read(trainingRepositoryProvider);
      await repo.completeModule(widget.module.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Training module completed!')));
        ref.invalidate(trainingModulesProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Training Player')),
      body: Column(
        children: [
          // Simulated Video Player
          Container(
            width: double.infinity,
            height: 250,
            color: Colors.black,
            child: Center(
              child: _isPlaying 
                ? const CircularProgressIndicator(color: Colors.white)
                : IconButton(
                    icon: Icon(_isCompleted || widget.module.isCompleted ? Icons.replay : Icons.play_circle_fill, color: Colors.white, size: 64),
                    onPressed: _simulatePlayback,
                  ),
            ),
          ),
          LinearProgressIndicator(value: _progress, backgroundColor: Colors.grey.shade800, color: Colors.red),
          
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isCompleted || widget.module.isCompleted)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: const [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Module Completed', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  
                Text(widget.module.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(widget.module.contentType, style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Text(widget.module.description, style: const TextStyle(fontSize: 16, height: 1.5)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
