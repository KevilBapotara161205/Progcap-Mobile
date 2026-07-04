import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:progcap_app/data/repositories/kyc_repository.dart';
import 'package:progcap_app/core/theme/colors.dart';

const _requiredDocs = [
  'GST_CERTIFICATE',
  'PAN_CARD',
  'AADHAAR_FRONT',
  'AADHAAR_BACK',
  'CANCELLED_CHEQUE',
];

const _docLabels = {
  'GST_CERTIFICATE': 'GST Certificate',
  'PAN_CARD': 'PAN Card',
  'AADHAAR_FRONT': 'Aadhaar Front',
  'AADHAAR_BACK': 'Aadhaar Back',
  'CANCELLED_CHEQUE': 'Cancelled Cheque',
};

const _docIcons = {
  'GST_CERTIFICATE': Icons.receipt_long_rounded,
  'PAN_CARD': Icons.credit_card_rounded,
  'AADHAAR_FRONT': Icons.person_rounded,
  'AADHAAR_BACK': Icons.person_outlined,
  'CANCELLED_CHEQUE': Icons.account_balance_rounded,
};

class KycScreen extends ConsumerWidget {
  final String leadId;
  final String dealerId;
  const KycScreen({super.key, required this.leadId, required this.dealerId});

  Future<void> _completeKyc(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.verified_rounded, color: AppColors.success, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Complete KYC'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure all documents are verified and accurate?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('This action cannot be undone.', style: TextStyle(fontSize: 12))),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Confirm & Complete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(kycRepositoryProvider).completeKyc(leadId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(children: [Icon(Icons.check_circle_rounded, color: Colors.white), SizedBox(width: 8), Text('KYC Completed successfully! ✅')]),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  void _viewDocument(BuildContext context, String s3Url) {
    final imageUrl = s3Url.startsWith('/') ? 'http://10.0.2.2:3000$s3Url' : s3Url;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Document Preview', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(backgroundColor: AppColors.background),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.broken_image_rounded, size: 48, color: AppColors.textSecondary),
                      const SizedBox(height: 8),
                      Text('Image could not be loaded.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                      color: AppColors.primary,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(kycDocumentsProvider(leadId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('KYC Collection', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: docsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(color: AppColors.errorLight, shape: BoxShape.circle),
                  child: const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 40),
                ),
                const SizedBox(height: 16),
                Text('Failed to load KYC documents', style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('$err', style: TextStyle(color: AppColors.textSecondary, fontSize: 12), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(kycDocumentsProvider(leadId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (uploadedDocs) {
          final uploadedCount = _requiredDocs.where((docType) => uploadedDocs.any((d) => d.docType == docType)).length;
          final allUploaded = uploadedCount == _requiredDocs.length;

          return Column(
            children: [
              // ── Progress Header ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Document Progress', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 2),
                            Text(
                              '$uploadedCount of ${_requiredDocs.length} documents',
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: allUploaded ? AppColors.successLight : AppColors.background,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: allUploaded ? AppColors.success.withValues(alpha: 0.3) : AppColors.border),
                          ),
                          child: Text(
                            allUploaded ? 'All Done ✅' : '${_requiredDocs.length - uploadedCount} remaining',
                            style: TextStyle(
                              color: allUploaded ? AppColors.success : AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: uploadedCount / _requiredDocs.length,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          allUploaded ? AppColors.success : AppColors.primary,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),

              Divider(color: AppColors.divider, height: 1),

              // ── Document List ─────────────────────────────────────────────
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _requiredDocs.length,
                  itemBuilder: (context, index) {
                    final docType = _requiredDocs[index];
                    final existingDoc = uploadedDocs.where((d) => d.docType == docType).firstOrNull;
                    final isUploaded = existingDoc != null;
                    final docColor = isUploaded ? AppColors.success : AppColors.primary;
                    final docIcon = _docIcons[docType] ?? Icons.upload_file_rounded;
                    final docLabel = _docLabels[docType] ?? docType.replaceAll('_', ' ');

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isUploaded ? AppColors.success.withValues(alpha: 0.3) : AppColors.border,
                          width: isUploaded ? 1.5 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: docColor.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Document type icon
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: docColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(isUploaded ? Icons.check_circle_rounded : docIcon, color: docColor, size: 24),
                            ),

                            const SizedBox(width: 14),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    docLabel,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: isUploaded ? AppColors.success : AppColors.textDisabled,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        isUploaded ? existingDoc.status : 'Pending Upload',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isUploaded ? AppColors.success : AppColors.textDisabled,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 10),

                            // Action button
                            if (!isUploaded)
                              GestureDetector(
                                onTap: () => context.push('/kyc/$leadId/$dealerId/capture/$docType'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.brandGradient,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3)),
                                    ],
                                  ),
                                  child: const Text(
                                    'Upload',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                                  ),
                                ),
                              )
                            else
                              GestureDetector(
                                onTap: () {
                                  if (existingDoc.s3Url != null) _viewDocument(context, existingDoc.s3Url!);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.visibility_rounded, color: AppColors.success, size: 14),
                                      SizedBox(width: 4),
                                      Text('View', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ).animate().fade(delay: Duration(milliseconds: 80 * index)).slideY(begin: 0.1, duration: 350.ms);
                  },
                ),
              ),

              // ── Complete KYC Button ────────────────────────────────────────
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: GestureDetector(
                    onTap: allUploaded ? () => _completeKyc(context, ref) : null,
                    child: Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: allUploaded ? AppColors.brandGradient : null,
                        color: allUploaded ? null : AppColors.border,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: allUploaded
                            ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))]
                            : null,
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              allUploaded ? Icons.verified_rounded : Icons.lock_outline_rounded,
                              color: allUploaded ? Colors.white : AppColors.textDisabled,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              allUploaded ? 'Complete KYC' : 'Upload all documents to proceed',
                              style: TextStyle(
                                color: allUploaded ? Colors.white : AppColors.textDisabled,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
