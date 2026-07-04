import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progcap_app/data/repositories/lead_repository.dart';
import 'package:progcap_app/data/models/lead.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  DateTimeRange? _selectedDateRange;

  Future<void> _pickDateRange() async {
    final DateTime now = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _selectedDateRange ?? DateTimeRange(
        start: now.subtract(const Duration(days: 30)),
        end: now,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedDateRange = result;
      });
    }
  }

  void _clearFilter() {
    setState(() {
      _selectedDateRange = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final leadsAsync = ref.watch(myLeadsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Lead History'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDateRange,
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _selectedDateRange != null
                          ? '${DateFormat('MMM d, yyyy').format(_selectedDateRange!.start)} - ${DateFormat('MMM d, yyyy').format(_selectedDateRange!.end)}'
                          : 'Filter by Date Range',
                    ),
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      foregroundColor: _selectedDateRange != null ? theme.primaryColor : Colors.grey.shade700,
                      side: BorderSide(color: _selectedDateRange != null ? theme.primaryColor : Colors.grey.shade300),
                    ),
                  ),
                ),
                if (_selectedDateRange != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _clearFilter,
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    tooltip: 'Clear filter',
                  ),
                ]
              ],
            ),
          ),
          
          // History List Section
          Expanded(
            child: leadsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (leads) {
                // Apply date filter
                List<Lead> filteredLeads = leads;
                if (_selectedDateRange != null) {
                  filteredLeads = leads.where((lead) {
                    final dateToCompare = lead.lastActivityAt ?? lead.sanctionExpiryDate;
                    if (dateToCompare == null) return false;
                    return dateToCompare.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
                           dateToCompare.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
                  }).toList();
                }

                // Sort by latest activity first
                filteredLeads.sort((a, b) {
                  final da = a.lastActivityAt ?? DateTime(1970);
                  final db = b.lastActivityAt ?? DateTime(1970);
                  return db.compareTo(da); // Descending
                });

                if (filteredLeads.isEmpty) {
                  return const Center(child: Text('No history found for the selected dates.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredLeads.length,
                  itemBuilder: (context, index) {
                    final lead = filteredLeads[index];
                    return _HistoryCard(lead: lead);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Lead lead;

  const _HistoryCard({required this.lead});

  @override
  Widget build(BuildContext context) {
    Color getStageColor() {
      switch (lead.stage) {
        case 'CLOSED_WON':
        case 'DISBURSED':
          return Colors.green;
        case 'CLOSED_LOST':
          return Colors.red;
        default:
          return Colors.blue;
      }
    }

    final dateStr = lead.lastActivityAt != null 
        ? DateFormat('MMM d, yyyy - h:mm a').format(lead.lastActivityAt!)
        : 'Unknown Date';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.push('/leads/${lead.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      lead.dealerName ?? 'Unknown Dealer',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: getStageColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: getStageColor().withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      lead.stage,
                      style: TextStyle(color: getStageColor(), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.business, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Anchor: ${lead.anchorName ?? "N/A"}',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                  ),
                  Text(
                    '₹${lead.expectedValue.toStringAsFixed(1)}L',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'Last Activity: $dateStr',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
              if (lead.nbaStatus == 'COMPLETED') ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'NBA Visit Completed',
                          style: TextStyle(color: Colors.green.shade800, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
