import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progcap_app/data/repositories/home_repository.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:progcap_app/data/repositories/ai_repository.dart';
import 'package:progcap_app/services/connectivity_watcher.dart';
import 'package:progcap_app/core/theme/colors.dart';
import 'package:go_router/go_router.dart';

final dailyBriefProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final connectivity = ref.watch(connectivityProvider).value;
  if (connectivity == ConnectivityResult.none) return null;
  final repository = ref.watch(aiRepositoryProvider);
  return repository.getDailyBrief();
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final connectivityAsync = ref.watch(connectivityProvider);
    final isOffline = connectivityAsync.value == ConnectivityResult.none;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: summaryAsync.when(
          loading: () => const _HomeShimmer(),
          error: (err, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 40),
                ),
                const SizedBox(height: 16),
                Text('Failed to load dashboard', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Text('$err', style: TextStyle(color: AppColors.textSecondary, fontSize: 12), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => ref.refresh(dashboardSummaryProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (summary) {
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                ref.invalidate(dashboardSummaryProvider);
                ref.invalidate(dailyBriefProvider);
              },
              child: CustomScrollView(
                slivers: [
                  // ── Hero Header ────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: _HeroHeader(isOffline: isOffline)
                      .animate().fade().slideY(begin: -0.1, duration: 400.ms),
                  ),

                  // ── Offline Banner ─────────────────────────────────────────
                  if (isOffline)
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.warningLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.wifi_off_rounded, color: AppColors.warning, size: 18),
                            const SizedBox(width: 10),
                            Text('You are offline — syncing when connected', style: TextStyle(color: AppColors.warning, fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ).animate().fade(delay: 100.ms),
                    ),

                  // ── AI Daily Brief ─────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      child: const _DailyBriefSection()
                        .animate().fade(delay: 150.ms).slideY(begin: 0.1),
                    ),
                  ),

                  // ── KPI Cards ──────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: _KpiCard(
                              label: 'Total Leads',
                              value: summary.totalLeads.toString(),
                              icon: Icons.people_alt_rounded,
                              color: AppColors.primary,
                            ).animate().fade(delay: 200.ms).slideX(begin: -0.15),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _KpiCard(
                              label: 'Visits Today',
                              value: summary.todaysVisits.toString(),
                              icon: Icons.directions_walk_rounded,
                              color: AppColors.warning,
                            ).animate().fade(delay: 250.ms).slideX(begin: 0.15),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Target Card ───────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: _TargetCard(
                        progress: summary.targetProgress,
                        achieved: summary.targetAchieved,
                        target: summary.targetMonthly,
                      ).animate().fade(delay: 300.ms).scale(begin: const Offset(0.97, 0.97)),
                    ),
                  ),

                  // ── Self-Source Action ────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: const _SelfSourceAction()
                        .animate().fade(delay: 350.ms),
                    ),
                  ),

                  // ── Today's Activity ──────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Today's Status", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          const SizedBox(height: 12),
                          if (summary.activeVisits > 0)
                            _ActivityCard(
                              icon: Icons.play_circle_fill_rounded,
                              color: AppColors.success,
                              title: 'Active Visit In Progress',
                              subtitle: 'You have a visit checked in currently.',
                            )
                          else
                            _ActivityCard(
                              icon: Icons.check_circle_outline_rounded,
                              color: AppColors.textDisabled,
                              title: 'No Active Visits',
                              subtitle: 'Head to NBA to start your next visit.',
                            ),
                        ],
                      ).animate().fade(delay: 400.ms),
                    ),
                  ),

                  const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Hero Header Widget ─────────────────────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  final bool isOffline;
  const _HeroHeader({required this.isOffline});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String greeting = 'Good Morning';
    if (now.hour >= 12 && now.hour < 17) greeting = 'Good Afternoon';
    if (now.hour >= 17) greeting = 'Good Evening';

    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0535E9), Color(0xFF0A1A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting! 👋',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Relationship Manager',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isOffline
                          ? AppColors.warning.withValues(alpha: 0.2)
                          : AppColors.success.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isOffline
                            ? AppColors.warning.withValues(alpha: 0.4)
                            : AppColors.success.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isOffline ? AppColors.warning : AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isOffline ? 'Offline' : 'Online',
                          style: TextStyle(
                            color: isOffline ? AppColors.warning : AppColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── KPI Card ───────────────────────────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Target Card ────────────────────────────────────────────────────────────────
class _TargetCard extends StatelessWidget {
  final double progress;
  final double achieved;
  final double target;

  const _TargetCard({required this.progress, required this.achieved, required this.target});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0535E9), Color(0xFF3A5FFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Monthly Disbursement', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${progress.toStringAsFixed(1)}% achieved',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹${(achieved / 100000).toStringAsFixed(1)}L / ₹${(target / 100000).toStringAsFixed(1)}L',
            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (progress / 100).clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Self-Source Action ────────────────────────────────────────────────────
class _SelfSourceAction extends StatelessWidget {
  const _SelfSourceAction();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/self-source'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add_business_rounded, color: AppColors.success, size: 24),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Self-Source Lead', style: TextStyle(color: AppColors.success, fontSize: 16, fontWeight: FontWeight.w700)),
                    SizedBox(height: 4),
                    Text('Add a new merchant lead directly', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ],
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.success),
          ],
        ),
      ),
    );
  }
}

// ── Activity Card ──────────────────────────────────────────────────────────────
class _ActivityCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _ActivityCard({required this.icon, required this.color, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppColors.textDisabled),
        ],
      ),
    );
  }
}

// ── Home Shimmer ───────────────────────────────────────────────────────────────
class _HomeShimmer extends StatelessWidget {
  const _HomeShimmer();

  Widget _shimmerBox({double height = 20, double? width, double radius = 8}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header shimmer
          Container(
            height: 120,
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(children: [
                  Expanded(child: _shimmerBox(height: 80, radius: 16)),
                  const SizedBox(width: 12),
                  Expanded(child: _shimmerBox(height: 80, radius: 16)),
                ]),
                const SizedBox(height: 12),
                _shimmerBox(height: 120, radius: 20),
              ],
            ),
          ),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(
      color: AppColors.border.withValues(alpha: 0.6),
      duration: 1500.ms,
    );
  }
}

// ── Daily Brief Section ────────────────────────────────────────────────────────
class _DailyBriefSection extends ConsumerWidget {
  const _DailyBriefSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final briefAsync = ref.watch(dailyBriefProvider);
    final connectivity = ref.watch(connectivityProvider).value;

    if (connectivity == ConnectivityResult.none) return const SizedBox.shrink();

    return briefAsync.when(
      loading: () => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.aiPurpleLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.aiPurple.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.aiPurple),
            ),
            const SizedBox(width: 12),
            Text('Loading your AI briefing...', style: TextStyle(color: AppColors.aiPurple, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
      error: (e, _) => const SizedBox.shrink(),
      data: (data) {
        if (data == null || data['brief'] == null) return const SizedBox.shrink();
        final brief = data['brief'];
        final greeting = brief['greeting'] ?? 'Good Morning!';
        final rawHighlights = brief['morningHighlights'];
        final String highlights = rawHighlights is List ? rawHighlights.join('\n') : (rawHighlights?.toString() ?? '');
        final rawPriorities = brief['todayPriorities'];
        final List priorities = rawPriorities is List ? rawPriorities : (rawPriorities != null ? [rawPriorities] : []);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.aiPurple.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(color: AppColors.aiPurple.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI badge header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.aiPurpleLight,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, color: AppColors.aiPurple, size: 16),
                        const SizedBox(width: 8),
                        Text('AI Generated Briefing', style: TextStyle(color: AppColors.aiPurple, fontWeight: FontWeight.w700, fontSize: 12)),
                      ],
                    ),
                    Text(
                      '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(greeting, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.aiPurple)),
                    if (highlights.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(highlights, style: TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.5)),
                    ],
                    if (priorities.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text("Today's Priorities:", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.aiPurple)),
                      const SizedBox(height: 6),
                      ...priorities.map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.circle, size: 6, color: AppColors.aiPurple),
                            const SizedBox(width: 8),
                            Expanded(child: Text(p.toString(), style: const TextStyle(fontSize: 12, height: 1.4))),
                          ],
                        ),
                      )),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
