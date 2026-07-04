import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:progcap_app/data/repositories/visit_repository.dart';
import 'package:progcap_app/data/repositories/ai_repository.dart';
import 'package:progcap_app/services/connectivity_watcher.dart';

class CheckInScreen extends ConsumerStatefulWidget {
  final String leadId;
  final String dealerId;
  const CheckInScreen({super.key, required this.leadId, required this.dealerId});

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  bool _isLoading = false;
  String? _errorMsg;

  Future<void> _performCheckIn() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable GPS.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      Position position = await Geolocator.getCurrentPosition();

      final repository = ref.read(visitRepositoryProvider);
      await repository.checkIn(
        leadId: widget.leadId,
        dealerId: widget.dealerId,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Checked in successfully!')));
        context.pop();
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check In at Dealer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // AI Visit Assistant prep
            _VisitAssistantSection(leadId: widget.leadId, dealerId: widget.dealerId),
            
            const SizedBox(height: 12),
            const Icon(Icons.location_on, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              'Dealer Check-In',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your GPS location will be verified against the dealer\'s registered geofence.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
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
                onPressed: _isLoading ? null : _performCheckIn,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Confirm Check-In', style: TextStyle(fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _VisitAssistantSection extends ConsumerStatefulWidget {
  final String leadId;
  final String dealerId;
  const _VisitAssistantSection({required this.leadId, required this.dealerId});

  @override
  ConsumerState<_VisitAssistantSection> createState() => _VisitAssistantSectionState();
}

class _VisitAssistantSectionState extends ConsumerState<_VisitAssistantSection> {
  bool _isLoading = false;
  Map<String, dynamic>? _prepData;

  Future<void> _fetchPrep() async {
    setState(() => _isLoading = true);
    final repository = ref.read(aiRepositoryProvider);
    final result = await repository.getVisitAssistant(
      leadId: widget.leadId.isNotEmpty ? widget.leadId : null,
      dealerId: widget.dealerId.isNotEmpty ? widget.dealerId : null,
    );
    setState(() {
      _prepData = result;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final connectivity = ref.watch(connectivityProvider).value;

    if (connectivity == ConnectivityResult.none) {
      return Card(
        margin: const EdgeInsets.only(bottom: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.grey.shade100,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.wifi_off_rounded, color: Colors.grey.shade600),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'AI insights are unavailable while offline.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.deepPurple.shade100),
      ),
      child: ExpansionTile(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: Colors.deepPurple, size: 18),
            SizedBox(width: 8),
            Text(
              'AI Visit Assistant',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple, fontSize: 14),
            ),
          ],
        ),
        subtitle: const Text('Get visit objective, checklist, and questions', style: TextStyle(fontSize: 11, color: Colors.grey)),
        onExpansionChanged: (expanded) {
          if (expanded && _prepData == null) {
            _fetchPrep();
          }
        },
        children: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: CircularProgressIndicator(color: Colors.deepPurple)),
            )
          else if (_prepData == null || _prepData!['preparation'] == null)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Could not load visit recommendations. Proceed with regular check-in.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPrepSection('🎯 Objective', _prepData!['preparation']['visitObjective']),
                  _buildPrepSection('💬 Suggested Conversation', _prepData!['preparation']['suggestedConversation']),
                  _buildPrepSection('📄 Required Documents', _prepData!['preparation']['requiredDocuments']),
                  _buildPrepSection('❓ Likely Customer Questions', _prepData!['preparation']['likelyCustomerQuestions']),
                  _buildPrepSection('⚠️ Risks', _prepData!['preparation']['risks']),
                  _buildPrepSection('📈 Follow-up Strategy', _prepData!['preparation']['followUpStrategy']),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPrepSection(String title, dynamic content) {
    if (content == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.deepPurple)),
          const SizedBox(height: 4),
          if (content is List)
            ...content.map((item) => Padding(
                  padding: const EdgeInsets.only(left: 8.0, bottom: 2.0),
                  child: Text('• $item', style: const TextStyle(fontSize: 12, height: 1.3)),
                ))
          else
            Text(content.toString(), style: const TextStyle(fontSize: 12, height: 1.3)),
        ],
      ),
    );
  }
}
