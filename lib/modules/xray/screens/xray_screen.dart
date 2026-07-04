import 'package:flutter/material.dart';

class XrayScreen extends StatelessWidget {
  const XrayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dealer X-Ray')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TextField(
              decoration: InputDecoration(
                hintText: 'Search Dealer Name or Phone',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Recent Scans', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            _buildXrayResultCard('ABC Electronics', '789/900', Colors.green),
            _buildXrayResultCard('Super Gadgets', '520/900', Colors.red),
            _buildXrayResultCard('Metro Appliances', '680/900', Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildXrayResultCard(String name, String bureauScore, Color scoreColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                const Text('Last scanned: 2 days ago', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: scoreColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: [
                  const Text('Bureau', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  Text(bureauScore, style: TextStyle(fontWeight: FontWeight.bold, color: scoreColor)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
