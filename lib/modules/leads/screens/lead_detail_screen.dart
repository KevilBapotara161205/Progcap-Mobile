import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:progcap_app/data/repositories/lead_repository.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:progcap_app/data/repositories/ai_repository.dart';
import 'package:progcap_app/data/repositories/nba_repository.dart';
import 'package:progcap_app/data/models/lead.dart';
import 'package:progcap_app/services/connectivity_watcher.dart';
import 'package:progcap_app/core/theme/colors.dart';

class LeadDetailScreen extends ConsumerWidget {
  final String leadId;
  const LeadDetailScreen({super.key, required this.leadId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leadAsync = ref.watch(leadDetailProvider(leadId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: leadAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: AppColors.errorLight, shape: BoxShape.circle),
                child: const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 40),
              ),
              const SizedBox(height: 16),
              Text('Error loading lead', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 8),
              Text('$err', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
        data: (lead) {
          return CustomScrollView(
            slivers: [
              // ── Gradient Hero AppBar ──────────────────────────────────────
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0535E9), Color(0xFF0A1A8A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Decorative circle
                        Positioned(
                          right: -30,
                          top: -30,
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                        ),
                        // Content
                        Positioned(
                          left: 20,
                          bottom: 20,
                          right: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _StageBadge(stage: lead.stage),
                                  const SizedBox(width: 8),
                                  if (lead.urgencyFlag)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.error.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.local_fire_department_rounded, color: Colors.redAccent, size: 12),
                                          SizedBox(width: 3),
                                          Text('URGENT', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.w800)),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                lead.dealerName ?? 'Unknown Merchant',
                                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.business_rounded, color: Colors.white.withValues(alpha: 0.7), size: 14),
                                  const SizedBox(width: 4),
                                  Text(lead.anchorName ?? 'N/A', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── KYC Status Banner ─────────────────────────────────────────
              if (!lead.kycCompleted)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'KYC not completed — Complete KYC to unlock visit completion.',
                            style: TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Section: Financial ────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _SectionCard(
                    title: 'Financial Details',
                    icon: Icons.currency_rupee_rounded,
                    iconColor: AppColors.success,
                    children: [
                      _InfoRow(label: 'Expected Value', value: '₹${lead.expectedValue.toStringAsFixed(2)} Lakhs', icon: Icons.attach_money_rounded),
                      if (lead.sanctionExpiryDate != null)
                        _InfoRow(
                          label: 'Sanction Expiry',
                          value: '${lead.sanctionExpiryDate!.day}/${lead.sanctionExpiryDate!.month}/${lead.sanctionExpiryDate!.year}',
                          icon: Icons.event_rounded,
                          valueColor: lead.sanctionExpiryDate!.difference(DateTime.now()).inDays < 7 ? AppColors.error : null,
                        ),
                    ],
                  ),
                ),
              ),

              // ── Section: Merchant Info ────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _SectionCard(
                    title: 'Merchant Information',
                    icon: Icons.storefront_rounded,
                    iconColor: AppColors.primary,
                    children: [
                      _InfoRow(label: 'Dealer', value: lead.dealerName ?? 'N/A', icon: Icons.storefront_rounded),
                      _InfoRow(label: 'Phone', value: lead.dealerPhone ?? 'N/A', icon: Icons.phone_rounded),
                      _InfoRow(label: 'Anchor', value: lead.anchorName ?? 'N/A', icon: Icons.business_rounded),
                      _InfoRow(label: 'Assigned RM', value: lead.assignedRmName ?? 'Unassigned', icon: Icons.person_rounded),
                    ],
                  ),
                ),
              ),

              // ── Section: Notes ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _SectionCard(
                    title: 'Visit Notes',
                    icon: Icons.notes_rounded,
                    iconColor: AppColors.aiPurple,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
                        child: Text(
                          lead.notes?.isNotEmpty == true ? lead.notes! : 'No notes available for this lead.',
                          style: TextStyle(color: lead.notes?.isNotEmpty == true ? AppColors.textPrimary : AppColors.textDisabled, fontSize: 13, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Section: AI Tools ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _LeadAiSection(leadId: leadId),
                ),
              ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
            ],
          );
        },
      ),
      bottomNavigationBar: leadAsync.hasValue ? SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: _LeadActionsSection(lead: leadAsync.value!),
        ),
      ) : null,
    );
  }
}

// ── Stage Badge ───────────────────────────────────────────────────────────────
class _StageBadge extends StatelessWidget {
  final String stage;
  const _StageBadge({required this.stage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Text(
        stage.replaceAll('_', ' '),
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ── Section Card ──────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.icon, required this.iconColor, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(color: Color(0x050535E9), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: iconColor, size: 16),
                ),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
              ],
            ),
          ),
          Divider(color: AppColors.divider, height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children.map((child) => Padding(
                padding: EdgeInsets.only(bottom: child == children.last ? 0 : 12),
                child: child,
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info Row ──────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, required this.icon, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
              const SizedBox(height: 1),
              Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor ?? AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Lead Actions Section ──────────────────────────────────────────────────────
class _LeadActionsSection extends ConsumerStatefulWidget {
  final Lead lead;
  const _LeadActionsSection({required this.lead});

  @override
  ConsumerState<_LeadActionsSection> createState() => _LeadActionsSectionState();
}

class _LeadActionsSectionState extends ConsumerState<_LeadActionsSection> {
  String? _localStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _localStatus = widget.lead.nbaStatus;
  }

  @override
  void didUpdateWidget(covariant _LeadActionsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lead.nbaStatus != widget.lead.nbaStatus) {
      _localStatus = widget.lead.nbaStatus;
    }
  }

  Future<void> _checkIn() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(nbaRepositoryProvider).checkInNba(widget.lead.id);
      if (!mounted) return;
      setState(() => _localStatus = 'IN_PROGRESS');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visit Started! 🎯')),
      );
      ref.invalidate(leadDetailProvider(widget.lead.id));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _complete() async {
    if (!widget.lead.kycCompleted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [Icon(Icons.warning_amber_rounded, color: AppColors.warning), const SizedBox(width: 8), const Text('Action Required')]),
          content: const Text('Merchant KYC is not completed. Please capture all KYC documents before completing this visit.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
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
            Text('Add your visit notes:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Merchant discussed expansion plans...',
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

    if (result == true) {
      setState(() => _isLoading = true);
      try {
        await ref.read(nbaRepositoryProvider).completeNba(widget.lead.id, notesController.text.trim());
        if (!mounted) return;
        setState(() => _localStatus = 'COMPLETED');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Visit Completed! ✅')),
        );
        ref.invalidate(leadDetailProvider(widget.lead.id));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _localStatus ?? widget.lead.nbaStatus;

    return Row(
      children: [
        // ── Primary Action Button ─────────────────────────────────────────
        if (status == 'PENDING' || status == 'IN_PROGRESS')
          Expanded(
            child: GestureDetector(
              onTap: _isLoading ? null : (status == 'PENDING' ? _checkIn : _complete),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: status == 'IN_PROGRESS'
                      ? LinearGradient(colors: [AppColors.success, Color(0xFF00966E)])
                      : AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: (status == 'IN_PROGRESS' ? AppColors.success : AppColors.primary).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(status == 'PENDING' ? Icons.play_arrow_rounded : Icons.check_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              status == 'PENDING' ? 'Start Visit' : 'Complete Visit',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),

        if (status == 'COMPLETED')
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                  SizedBox(width: 6),
                  Text('Completed', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 15)),
                ],
              ),
            ),
          ),

        const SizedBox(width: 10),

        // ── KYC Button ────────────────────────────────────────────────────
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (widget.lead.dealerId != null) {
                context.push('/kyc/${widget.lead.id}/${widget.lead.dealerId}');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Missing dealer information for KYC.')),
                );
              }
            },
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: widget.lead.kycCompleted ? AppColors.success : AppColors.primary, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.lead.kycCompleted ? Icons.verified_rounded : Icons.document_scanner_rounded,
                    color: widget.lead.kycCompleted ? AppColors.success : AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.lead.kycCompleted ? 'KYC Done' : 'Capture KYC',
                    style: TextStyle(
                      color: widget.lead.kycCompleted ? AppColors.success : AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Lead AI Section ───────────────────────────────────────────────────────────
class _LeadAiSection extends ConsumerStatefulWidget {
  final String leadId;
  const _LeadAiSection({required this.leadId});

  @override
  ConsumerState<_LeadAiSection> createState() => _LeadAiSectionState();
}

class _LeadAiSectionState extends ConsumerState<_LeadAiSection> {
  bool _loadingXray = false;
  Map<String, dynamic>? _xrayData;
  bool _loadingSuggestions = false;
  List<String>? _suggestions;

  Future<void> _fetchXray() async {
    if (_xrayData != null) return;
    setState(() => _loadingXray = true);
    final result = await ref.read(aiRepositoryProvider).getMerchantXray(leadId: widget.leadId);
    setState(() { _xrayData = result; _loadingXray = false; });
  }

  Future<void> _fetchSuggestions() async {
    if (_suggestions != null) return;
    setState(() => _loadingSuggestions = true);
    final result = await ref.read(aiRepositoryProvider).getFollowUpSuggestions(widget.leadId);
    setState(() { _suggestions = result; _loadingSuggestions = false; });
  }

  @override
  Widget build(BuildContext context) {
    final connectivity = ref.watch(connectivityProvider).value;

    if (connectivity == ConnectivityResult.none) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.wifi_off_rounded, color: AppColors.textSecondary, size: 18),
            const SizedBox(width: 10),
            Text('AI insights unavailable while offline.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildAiExpansionTile(
          icon: Icons.psychology_rounded,
          title: 'AI Merchant X-Ray',
          subtitle: 'Get 360° merchant health & risk summary',
          onExpand: _fetchXray,
          isLoading: _loadingXray,
          child: _xrayData == null ? null : _buildXrayContent(_xrayData!['insight']),
        ),
        const SizedBox(height: 10),
        _buildAiExpansionTile(
          icon: Icons.next_plan_rounded,
          title: 'AI Follow-up Suggestions',
          subtitle: 'Next steps based on system data',
          onExpand: _fetchSuggestions,
          isLoading: _loadingSuggestions,
          child: _suggestions == null ? null : _buildSuggestionsContent(_suggestions!),
        ),
      ],
    );
  }

  Widget _buildAiExpansionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onExpand,
    required bool isLoading,
    Widget? child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.aiPurple.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: AppColors.aiPurple.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: AppColors.aiPurpleLight, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: AppColors.aiPurple, size: 18),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          onExpansionChanged: (expanded) { if (expanded) onExpand(); },
          children: [
            Divider(color: AppColors.divider, height: 1),
            if (isLoading)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator(color: AppColors.aiPurple, strokeWidth: 2)),
              )
            else if (child == null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('AI analysis unavailable.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              )
            else
              Padding(padding: const EdgeInsets.all(16), child: child),
          ],
        ),
      ),
    );
  }

  Widget _buildXrayContent(dynamic insight) {
    if (insight == null) return Text('No data available.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12));

    final fields = [
      ('Summary', insight['businessSummary']),
      ('Health & Status', insight['merchantHealth']),
      ('Risks Identified', insight['riskAssessment']),
      ('Positive Signals', insight['positiveSignals']),
      ('Conversation Guide', insight['suggestedConversationPoints']),
      ('Recommended Follow-up', insight['recommendedFollowUp']),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: fields.where((f) => f.$2 != null).map((field) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(field.$1, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.aiPurple)),
            const SizedBox(height: 4),
            if (field.$2 is List)
              ...((field.$2 as List).map((item) => Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 2),
                child: Text('• $item', style: const TextStyle(fontSize: 12, height: 1.3)),
              )))
            else
              Text(field.$2.toString(), style: const TextStyle(fontSize: 12, height: 1.3)),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildSuggestionsContent(List<String> suggestions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: suggestions.map((s) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.aiPurple),
            const SizedBox(width: 8),
            Expanded(child: Text(s, style: const TextStyle(fontSize: 13, height: 1.4))),
          ],
        ),
      )).toList(),
    );
  }
}
