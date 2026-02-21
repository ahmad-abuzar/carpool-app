import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/color_palette.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    const OnboardingPage(
      icon: Icons.attach_money,
      title: 'Affordable Rides',
      subtitle:
          'Share rides for your campus & office commute. Save money while traveling together.',
    ),
    const OnboardingPage(
      icon: Icons.verified_user,
      title: 'Safe & Verified',
      subtitle:
          'All drivers are verified. Choose female-only rides for added safety.',
    ),
    const OnboardingPage(
      icon: Icons.route,
      title: 'Smart Suggestions',
      subtitle:
          'Get personalized ride suggestions based on your daily commute patterns.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => context.go('/role-selection'),
                child: Text(
                  'Skip',
                  style: AppTypography.label(
                    context,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _pages[index];
                },
              ),
            ),

            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: Spacing.xs),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppColors.primaryDark
                        : AppColors.dividerLight,
                    borderRadius: BorderRadius.circular(Spacing.radiusFull),
                  ),
                ),
              ),
            ),

            const SizedBox(height: Spacing.xl),

            // Next/Get Started button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.xl),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage < _pages.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      context.go('/role-selection');
                    }
                  },
                  child: Text(
                    _currentPage < _pages.length - 1 ? 'Next' : 'Get Started',
                  ),
                ),
              ),
            ),

            const SizedBox(height: Spacing.xl),
          ],
        ),
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const OnboardingPage({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon illustration
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(Spacing.radiusXl),
            ),
            child: Icon(icon, size: 100, color: Colors.white),
          ),

          const SizedBox(height: Spacing.xxxl),

          // Title
          Text(
            title,
            style: AppTypography.headline(context),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: Spacing.lg),

          // Subtitle
          Text(
            subtitle,
            style: AppTypography.body(
              context,
              color: AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
