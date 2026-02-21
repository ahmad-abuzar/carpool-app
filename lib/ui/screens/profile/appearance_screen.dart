import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../state/theme_provider.dart' as theme_provider;
import '../../theme/spacing.dart';
import '../../theme/typography.dart';

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(theme_provider.themeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: ListView(
        padding: const EdgeInsets.all(Spacing.lg),
        children: [
          Text('Theme', style: AppTypography.headlineSmall(context)),
          const SizedBox(height: Spacing.md),

          RadioListTile<theme_provider.ThemeMode>(
            title: const Text('Light'),
            subtitle: const Text('Always use light theme'),
            value: theme_provider.ThemeMode.light,
            groupValue: currentTheme,
            onChanged: (value) {
              if (value != null) {
                ref.read(theme_provider.themeProvider.notifier).setTheme(value);
              }
            },
          ),

          RadioListTile<theme_provider.ThemeMode>(
            title: const Text('Dark'),
            subtitle: const Text('Always use dark theme'),
            value: theme_provider.ThemeMode.dark,
            groupValue: currentTheme,
            onChanged: (value) {
              if (value != null) {
                ref.read(theme_provider.themeProvider.notifier).setTheme(value);
              }
            },
          ),

          RadioListTile<theme_provider.ThemeMode>(
            title: const Text('System'),
            subtitle: const Text('Follow system theme'),
            value: theme_provider.ThemeMode.system,
            groupValue: currentTheme,
            onChanged: (value) {
              if (value != null) {
                ref.read(theme_provider.themeProvider.notifier).setTheme(value);
              }
            },
          ),
        ],
      ),
    );
  }
}
