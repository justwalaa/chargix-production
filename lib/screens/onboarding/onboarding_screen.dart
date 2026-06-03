
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/app_colors.dart';
import '../../theme/tokens/tokens.dart';

/// Shows once on first launch after OTP sign-in.
/// Calls [onComplete] when the user taps "Get Started" on the last page.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  /// Convenience: mark onboarding as done and call [onComplete].
  static Future<void> markDone(VoidCallback onComplete) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDoneKey, true);
    onComplete();
  }

  static const String _kDoneKey = 'chargix_onboarding_done';

  /// Returns true if the user has already seen onboarding.
  static Future<bool> isDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kDoneKey) ?? false;
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  int _page = 0;

  static const _pages = [
    _PageData(
      icon: Icons.electric_bolt_rounded,
      gradientStart: AppColors.violet,
      gradientEnd: AppColors.cyan,
      headline: 'Charge smarter,\ngo further.',
      body:
          'Chargix connects you to a growing network of verified EV charging stations across Jordan — all in one app.',
    ),
    _PageData(
      icon: Icons.map_rounded,
      gradientStart: AppColors.cyanDeep,
      gradientEnd: AppColors.cyan,
      headline: 'Find the nearest\ncharger instantly.',
      body:
          'Browse live station availability on the map, filter by connector type, and get directions in one tap.',
    ),
    _PageData(
      icon: Icons.calendar_month_rounded,
      gradientStart: AppColors.violetMid,
      gradientEnd: AppColors.violet,
      headline: 'Reserve your bay\nbefore you arrive.',
      body:
          'Book a charging slot at any Chargix partner station. Your spot is held — no more waiting in line.',
    ),
  ];

  bool get _isLast => _page == _pages.length - 1;

  void _next() {
    if (_isLast) {
      OnboardingScreen.markDone(widget.onComplete);
    } else {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _skip() => OnboardingScreen.markDone(widget.onComplete);

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.bg1,
        body: SafeArea(
          child: Column(
            children: [
              // ── Skip button ──────────────────────────────────────────────
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(
                      right: AppSpacing.screenGutter, top: AppSpacing.md),
                  child: AnimatedOpacity(
                    opacity: _isLast ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: TextButton(
                      onPressed: _isLast ? null : _skip,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Pages ────────────────────────────────────────────────────
              Expanded(
                child: PageView.builder(
                  controller: _pageCtrl,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemCount: _pages.length,
                  itemBuilder: (context, i) =>
                      _OnboardingPage(data: _pages[i]),
                ),
              ),

              // ── Dots + CTA ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenGutter,
                  vertical: AppSpacing.xl,
                ),
                child: Column(
                  children: [
                    // Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOut,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _page ? 22 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: i == _page
                                ? AppColors.cyan
                                : AppColors.border2,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // CTA button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        onPressed: _next,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.cyan,
                          foregroundColor: AppColors.bg1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.xl),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        child: Text(_isLast ? 'Get Started' : 'Next'),
                      ),
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

// ── Single page ──────────────────────────────────────────────────────────────

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});
  final _PageData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenGutter),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon in gradient circle
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [data.gradientStart, data.gradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: data.gradientEnd.withAlpha(70),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Icon(data.icon, size: 52, color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.xl + 8),

          // Headline
          Text(
            data.headline,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.15,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Body
          Text(
            data.body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data class ───────────────────────────────────────────────────────────────

class _PageData {
  const _PageData({
    required this.icon,
    required this.gradientStart,
    required this.gradientEnd,
    required this.headline,
    required this.body,
  });

  final IconData icon;
  final Color gradientStart;
  final Color gradientEnd;
  final String headline;
  final String body;
}
