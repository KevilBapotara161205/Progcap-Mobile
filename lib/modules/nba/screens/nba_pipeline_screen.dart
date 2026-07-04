import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:progcap_app/data/repositories/nba_repository.dart';
import 'package:progcap_app/data/repositories/lead_repository.dart';
import 'package:progcap_app/data/models/nba_insight.dart';
import 'package:progcap_app/data/models/lead.dart';
import 'package:progcap_app/data/repositories/ai_repository.dart';
import 'package:progcap_app/services/connectivity_watcher.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:progcap_app/core/theme/colors.dart';

class NbaPipelineScreen extends ConsumerWidget {
  const NbaPipelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(nbaInsightsProvider);
    final leadsAsync = ref.watch(myLeadsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('NBA Pipeline', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () => context.push('/history'),
            tooltip: 'History',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await Future.wait([
            ref.refresh(nbaInsightsProvider.future),
            ref.refresh(myLeadsProvider.future),
          ]);
        },
        child: CustomScrollView(
          slivers: [
            // ── NBA Section Header ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 10),
                    const Text('Optimized Visit Sequence', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  ],
                ),
              ).animate().fade().slideY(begin: -0.2),
            ),

            // ── NBA Cards ──────────────────────────────────────────────────
            insightsAsync.when(
              loading: () => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                ),
              ),
              error: (err, stack) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(12)),
                    child: Text('Failed to load insights: $err', style: TextStyle(color: AppColors.error)),
                  ),
                ),
              ),
              data: (insights) {
                if (insights.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: _EmptyState(
                        icon: Icons.bolt_rounded,
                        title: 'No NBA Insights',
                        subtitle: 'No optimized visit plan available. Check back tomorrow.',
                      ),
                    ),
                  );
                }

                final int activeIndex = insights.indexWhere((i) => i.nbaStatus != 'COMPLETED');

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final insight = insights[index];
                      final bool isDisabled = activeIndex != -1 && index > activeIndex;

                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: NbaCard(
                          insight: insight,
                          isDisabled: isDisabled,
                          isFirst: index == 0,
                          sequenceNumber: index + 1,
                          onRefresh: () => ref.refresh(nbaInsightsProvider.future),
                        ),
                      ).animate().fade(delay: Duration(milliseconds: 80 * index)).slideY(begin: 0.12, duration: 400.ms, curve: Curves.easeOutQuad);
                    },
                    childCount: insights.length,
                  ),
                );
              },
            ),

            // ── Pipeline Section Header ────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.bar_chart_rounded, color: AppColors.primary, size: 16),
                    ),
                    const SizedBox(width: 10),
                    const Text('Pipeline by Stage', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  ],
                ),
              ).animate().fade().slideY(begin: -0.2),
            ),

            // ── Pipeline Lead Cards ────────────────────────────────────────
            leadsAsync.when(
              loading: () => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                ),
              ),
              error: (err, stack) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Failed to load pipeline: $err', style: TextStyle(color: AppColors.error)),
                ),
              ),
              data: (leads) {
                if (leads.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: _EmptyState(
                        icon: Icons.bar_chart_rounded,
                        title: 'No Leads',
                        subtitle: 'No leads in your pipeline yet.',
                      ),
                    ),
                  );
                }

                final Map<String, List<Lead>> grouped = {};
                for (var lead in leads) {
                  grouped.putIfAbsent(lead.stage, () => []).add(lead);
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final stage = grouped.keys.elementAt(index);
                      final stageLeads = grouped[stage]!;
                      final stageColor = AppColors.forStage(stage);

                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8, height: 8,
                                  decoration: BoxDecoration(color: stageColor, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 8),
                                Text(stage.replaceAll('_', ' '), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: stageColor)),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: stageColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text('${stageLeads.length}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: stageColor)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...stageLeads.map((lead) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: PipelineLeadCard(lead: lead, stageColor: stageColor),
                            )),
                          ],
                        ),
                      );
                    },
                    childCount: grouped.keys.length,
                  ),
                );
              },
            ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        ),
      ),
    );
  }
}

// ── NBA Card ──────────────────────────────────────────────────────────────────
class NbaCard extends ConsumerStatefulWidget {
  final NbaInsight insight;
  final bool isDisabled;
  final bool isFirst;
  final int sequenceNumber;
  final VoidCallback onRefresh;

  const NbaCard({
    super.key,
    required this.insight,
    required this.isDisabled,
    required this.isFirst,
    required this.sequenceNumber,
    required this.onRefresh,
  });

  @override
  ConsumerState<NbaCard> createState() => _NbaCardState();
}

class _NbaCardState extends ConsumerState<NbaCard> {
  bool _showExplanation = false;
  bool _isLoadingExplanation = false;
  String? _explanation;
  bool _isCheckingIn = false;
  bool _isCompleting = false;
  String? _localStatus;

  @override
  void initState() {
    super.initState();
    _localStatus = widget.insight.nbaStatus;
  }

  @override
  void didUpdateWidget(NbaCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.insight.nbaStatus != widget.insight.nbaStatus) {
      _localStatus = widget.insight.nbaStatus;
    }
  }

  Color get _insightColor {
    if (widget.isDisabled) return AppColors.textSecondary;
    switch (widget.insight.type) {
      case 'DANGER': return AppColors.error;
      case 'WARNING': return AppColors.warning;
      case 'SUCCESS': return AppColors.success;
      default: return AppColors.primary;
    }
  }

  IconData get _insightIcon {
    switch (widget.insight.type) {
      case 'DANGER': return Icons.warning_rounded;
      case 'WARNING': return Icons.info_outline_rounded;
      case 'SUCCESS': return Icons.trending_up_rounded;
      default: return Icons.lightbulb_outline_rounded;
    }
  }

  Future<void> _checkInNba() async {
    if (widget.insight.leadId == null) return;
    setState(() => _isCheckingIn = true);
    try {
      await ref.read(nbaRepositoryProvider).checkInNba(widget.insight.leadId!);
      if (!mounted) return;
      setState(() => _localStatus = 'IN_PROGRESS');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Visit Started! 🎯'), backgroundColor: AppColors.primary),
      );
      widget.onRefresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isCheckingIn = false);
    }
  }

  Future<void> _fetchExplanation() async {
    if (_explanation != null) return;
    setState(() => _isLoadingExplanation = true);
    if (widget.insight.leadId == null) {
      setState(() { _explanation = 'System prioritized standard task.'; _isLoadingExplanation = false; });
      return;
    }
    final result = await ref.read(aiRepositoryProvider).getNbaExplanation(widget.insight.leadId!, 85.0);
    setState(() { _explanation = result?['explanation'] ?? 'AI explanation unavailable.'; _isLoadingExplanation = false; });
  }

  Future<void> _completeNba() async {
    if (!widget.insight.kycCompleted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            const SizedBox(width: 8),
            const Text('Action Required'),
          ]),
          content: const Text('Merchant KYC is not completed. Please capture all KYC documents before completing this visit.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
      );
      return;
    }

    final notesController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Complete Visit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add your merchant visit notes before completing:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Merchant discussed loan for expansion...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (notesController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notes are required')));
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (result == true && widget.insight.leadId != null) {
      setState(() => _isCompleting = true);
      try {
        await ref.read(nbaRepositoryProvider).completeNba(widget.insight.leadId!, notesController.text.trim());
        if (!mounted) return;
        setState(() => _localStatus = 'COMPLETED');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Visit Completed! ✅'), backgroundColor: AppColors.success),
        );
        widget.onRefresh();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      } finally {
        if (mounted) setState(() => _isCompleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectivity = ref.watch(connectivityProvider).value;
    final color = _insightColor;
    final currentStatus = _localStatus ?? widget.insight.nbaStatus;
    final isCompleted = currentStatus == 'COMPLETED';

    return Opacity(
      opacity: widget.isDisabled ? 0.55 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border(
            left: BorderSide(color: color, width: 4),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: widget.isDisabled ? 0.04 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: (widget.isDisabled || widget.insight.leadId == null)
                ? null
                : () => context.push('/leads/${widget.insight.leadId}'),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Card Header ──────────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isCompleted ? Icons.check_circle_rounded : _insightIcon,
                          color: color, size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.insight.title,
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: color),
                            ),
                            if (widget.insight.dealerName != null) ...[
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(Icons.storefront_rounded, size: 13, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(widget.insight.dealerName!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Sequence number badge
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: widget.isDisabled ? AppColors.border : color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: widget.isDisabled
                            ? const Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.textDisabled)
                            : Center(
                                child: Text(
                                  '#${widget.sequenceNumber}',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
                                ),
                              ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── Description ──────────────────────────────────────────
                  Text(widget.insight.description, style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),

                  // ── Deal Info Row ─────────────────────────────────────────
                  if (widget.insight.expectedValue != null || widget.insight.stage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 6, height: 6,
                                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                widget.insight.stage?.replaceAll('_', ' ') ?? 'N/A',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          Text(
                            '₹${widget.insight.expectedValue?.toStringAsFixed(0) ?? '0'}',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ── Visit Notes ──────────────────────────────────────────
                  if (widget.insight.nbaNotes.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.notes_rounded, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(widget.insight.nbaNotes, style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textSecondary)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ── AI Explanation ────────────────────────────────────────
                  if (!widget.isDisabled && connectivity != ConnectivityResult.none && widget.insight.leadId != null) ...[
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        setState(() => _showExplanation = !_showExplanation);
                        if (_showExplanation) _fetchExplanation();
                      },
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 13, color: AppColors.aiPurple),
                          const SizedBox(width: 5),
                          Text(
                            _showExplanation ? 'Hide AI Explanation' : 'Why this action? (AI)',
                            style: TextStyle(fontSize: 12, color: AppColors.aiPurple, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    if (_showExplanation) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.aiPurpleLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.aiPurple.withValues(alpha: 0.2)),
                        ),
                        child: _isLoadingExplanation
                            ? Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.aiPurple)))
                            : Text(_explanation ?? '', style: TextStyle(fontSize: 12, height: 1.4, color: AppColors.textPrimary)),
                      ),
                    ],
                  ],

                  // ── Action Buttons ────────────────────────────────────────
                  if (!widget.isDisabled && !isCompleted) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        if (currentStatus == 'PENDING')
                          Expanded(
                            child: GestureDetector(
                              onTap: _isCheckingIn ? null : _checkInNba,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                decoration: BoxDecoration(
                                  gradient: AppColors.brandGradient,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))],
                                ),
                                child: Center(
                                  child: _isCheckingIn
                                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                                            SizedBox(width: 5),
                                            Text('Start Visit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ),
                        if (currentStatus == 'IN_PROGRESS')
                          Expanded(
                            child: GestureDetector(
                              onTap: _isCompleting ? null : _completeNba,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [BoxShadow(color: AppColors.success.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
                                ),
                                child: Center(
                                  child: _isCompleting
                                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.check_rounded, color: Colors.white, size: 18),
                                            SizedBox(width: 5),
                                            Text('Complete Visit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ),
                        if (widget.insight.leadId != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: GestureDetector(
                              onTap: () => context.push('/leads/${widget.insight.leadId}'),
                              child: Text('View', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],

                  if (isCompleted) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                          SizedBox(width: 6),
                          Text('Visit Completed', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Pipeline Lead Card ────────────────────────────────────────────────────────
class PipelineLeadCard extends StatelessWidget {
  final Lead lead;
  final Color stageColor;

  const PipelineLeadCard({super.key, required this.lead, required this.stageColor});

  @override
  Widget build(BuildContext context) {
    final isUrgent = lead.urgencyFlag;
    final isStuck = lead.isStuck;
    bool isExpiring = false;
    if (lead.sanctionExpiryDate != null) {
      final daysLeft = lead.sanctionExpiryDate!.difference(DateTime.now()).inDays;
      if (daysLeft <= 14 && lead.stage == 'SANCTIONED') isExpiring = true;
    }

    Color badgeColor = stageColor;
    String badgeText = 'ACTIVE';
    if (isUrgent || isExpiring) {
      badgeColor = AppColors.error;
      badgeText = 'URGENT';
    } else if (isStuck) {
      badgeColor = AppColors.warning;
      badgeText = 'STUCK';
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: const Color(0x0A0535E9), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.push('/leads/${lead.id}'),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        lead.dealerName ?? 'Unknown Dealer',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(badgeText, style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.business_rounded, size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(lead.anchorName ?? 'No Anchor', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                    Text(
                      '₹${lead.expectedValue.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
            child: Icon(icon, size: 32, color: AppColors.textDisabled),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
