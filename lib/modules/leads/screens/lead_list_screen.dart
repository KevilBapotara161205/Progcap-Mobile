import 'package:flutter/material.dart';

class LeadListScreen extends StatelessWidget {
  final String? leadId;
  final String? visitId;
  final Widget? child;
  const LeadListScreen({super.key, this.leadId, this.visitId, this.child});

  @override
  Widget build(BuildContext context) {
    if (child != null) return Scaffold(body: child);
    return Scaffold(
      appBar: AppBar(title: const Text('LeadListScreen')),
      body: const Center(child: Text('Stub for LeadListScreen')),
    );
  }
}
