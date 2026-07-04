import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:progcap_app/data/repositories/visit_repository.dart';
import 'package:progcap_app/data/repositories/ai_repository.dart';

class CheckOutScreen extends ConsumerStatefulWidget {
  final String visitId;
  const CheckOutScreen({super.key, required this.visitId});

  @override
  ConsumerState<CheckOutScreen> createState() => _CheckOutScreenState();
}

class _CheckOutScreenState extends ConsumerState<CheckOutScreen> {
  final _notesController = TextEditingController();
  bool _isLoading = false;
  String? _errorMsg;

  Future<void> _showAiSummaryDialog(String visitId) async {
    setState(() => _isLoading = true);
    final result = await ref.read(aiRepositoryProvider).getVisitSummary(visitId);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result == null || result['summary'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Checked out successfully!')));
      context.pop();
      return;
    }

    final summary = result['summary'];
    final profSummary = summary['professionalSummary'] ?? '';
    final actionItems = summary['actionItems'] ?? [];
    final managerSummary = summary['managerSummary'] ?? '';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: Colors.deepPurple),
                      SizedBox(width: 8),
                      Text(
                        'AI Visit Summary Generated',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepPurple),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('AI-generated draft for CRM & Manager review', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  const Divider(height: 32),
                  
                  if (profSummary.isNotEmpty) ...[
                    const Text('Professional Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                    const SizedBox(height: 6),
                    Text(profSummary, style: const TextStyle(fontSize: 13, height: 1.45, color: Colors.black87)),
                    const SizedBox(height: 16),
                  ],
                  
                  if (managerSummary.isNotEmpty) ...[
                    const Text('Manager Notes Brief', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                    const SizedBox(height: 6),
                    Text(managerSummary, style: const TextStyle(fontSize: 13, height: 1.45, color: Colors.black87)),
                    const SizedBox(height: 16),
                  ],

                  if (actionItems is List && actionItems.isNotEmpty) ...[
                    const Text('Suggested Action Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.deepPurple)),
                    const SizedBox(height: 8),
                    ...actionItems.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, color: Colors.deepPurple, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(item.toString(), style: const TextStyle(fontSize: 13))),
                        ],
                      ),
                    )),
                    const SizedBox(height: 20),
                  ],
                  
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Done & Return'),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );

    if (mounted) {
      context.pop();
    }
  }

  Future<void> _performCheckOut() async {
    if (_notesController.text.trim().isEmpty) {
      setState(() => _errorMsg = 'Please add a visit summary / meeting notes.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final repository = ref.read(visitRepositoryProvider);
      final visit = await repository.checkOut(
        visitId: widget.visitId,
        notes: _notesController.text.trim(),
      );

      if (mounted) {
        // Fetch and show the AI Visit Summary Dialog, then pop
        await _showAiSummaryDialog(visit.id);
      }
    } catch (e) {
      setState(() {
        _errorMsg = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check Out & Summary')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Visit Summary',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please enter meeting notes and outcome of this visit before checking out.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _notesController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Discussed terms, collected KYC, dealer asked for lower rate...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 24),
            if (_errorMsg != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_errorMsg!, style: const TextStyle(color: Colors.red))),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _performCheckOut,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Submit & Check-Out', style: TextStyle(fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
