import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:progcap_app/data/repositories/auth_repository.dart';
import 'package:progcap_app/core/theme/colors.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final phone = _phoneController.text.trim();
        await ref.read(authRepositoryProvider).sendOtp(phone);
        if (mounted) {
          context.push('/otp', extra: phone);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: SizedBox(
          height: size.height,
          width: size.width,
          child: Stack(
            children: [
              // ── Background gradient ───────────────────────────────────────
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0535E9), Color(0xFF0A1A8A)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              // ── Decorative circles ────────────────────────────────────────
              Positioned(
                top: -60,
                right: -60,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent.withValues(alpha: 0.12),
                  ),
                ),
              ),
              Positioned(
                top: 80,
                right: 40,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white.withValues(alpha: 0.07),
                  ),
                ),
              ),
              Positioned(
                bottom: 160,
                left: -40,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent.withValues(alpha: 0.08),
                  ),
                ),
              ),

              // ── Content ───────────────────────────────────────────────────
              SafeArea(
                child: Column(
                  children: [
                    // Brand area (top 40%)
                    Expanded(
                      flex: 4,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo mark
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.black.withValues(alpha: 0.15),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'P',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),

                          const SizedBox(height: 20),

                          const Text(
                            'PROGCAP',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 4,
                            ),
                          ).animate().fade(delay: 200.ms).slideY(begin: 0.3),

                          const SizedBox(height: 6),

                          Text(
                            'Sales Force Automation',
                            style: TextStyle(
                              color: AppColors.white.withValues(alpha: 0.7),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 1.5,
                            ),
                          ).animate().fade(delay: 300.ms),
                        ],
                      ),
                    ),

                    // ── Form card (bottom 60%) ────────────────────────────
                    Expanded(
                      flex: 6,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                        ),
                        child: Form(
                          key: _formKey,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                            physics: const ClampingScrollPhysics(),
                            child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Handle bar
                              Center(
                                child: Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: AppColors.border,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),

                              const Text(
                                'Welcome Back! 👋',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ).animate().fade(delay: 100.ms).slideY(begin: 0.2),

                              const SizedBox(height: 8),

                              Text(
                                'Enter your registered mobile number\nto access your RM dashboard.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                  height: 1.6,
                                ),
                              ).animate().fade(delay: 150.ms),

                              const SizedBox(height: 32),

                              // Phone field
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                ],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Mobile Number',
                                  hintText: '98765 43210',
                                  prefixIcon: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 12),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      '+91',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Please enter your mobile number';
                                  if (value.length != 10) return 'Mobile number must be exactly 10 digits';
                                  return null;
                                },
                              ).animate().fade(delay: 200.ms).slideY(begin: 0.2),

                              const SizedBox(height: 32),

                              // CTA button
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: _isLoading
                                    ? Container(
                                        decoration: BoxDecoration(
                                          gradient: AppColors.brandGradient,
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: const Center(
                                          child: SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                          ),
                                        ),
                                      )
                                    : GestureDetector(
                                        onTap: _submit,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: AppColors.brandGradient,
                                            borderRadius: BorderRadius.circular(14),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.primary.withValues(alpha: 0.35),
                                                blurRadius: 16,
                                                offset: const Offset(0, 6),
                                              ),
                                            ],
                                          ),
                                          child: const Center(
                                            child: Text(
                                              'Send OTP  →',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                              ).animate().fade(delay: 300.ms).slideY(begin: 0.2),

                              const SizedBox(height: 32),

                              // Footer note
                              Center(
                                child: Text(
                                  'Powered by TechnoYuga · Progcap v2.0',
                                  style: TextStyle(
                                    color: AppColors.textDisabled,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          ),
                        ),
                      ).animate().slideY(begin: 0.4, duration: 600.ms, curve: Curves.easeOutCubic),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
