import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildNotificationItem('Lead Assigned', 'New lead "Super Gadgets" has been assigned to you.', Icons.person_add, Colors.blue),
          _buildNotificationItem('KYC Approved', 'KYC documents for "Metro Appliances" have been verified.', Icons.check_circle, Colors.green),
          _buildNotificationItem('Target Update', 'You are 5% away from reaching your monthly target!', Icons.emoji_events, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(String title, String body, IconData icon, Color iconColor) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: 0.1),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(body),
        ),
        trailing: const Text('2h ago', style: TextStyle(color: Colors.grey, fontSize: 12)),
      ),
    );
  }
}
