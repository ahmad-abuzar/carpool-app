import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../state/messaging_provider.dart';
import '../theme/spacing.dart';

// Current navigation index provider
final navigationIndexProvider = StateProvider<int>((ref) => 0);

class MainNavigation extends ConsumerWidget {
  final Widget child;

  const MainNavigation({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);
    final unreadMessages = ref
        .watch(conversationsProvider)
        .maybeWhen(
          data: (conversations) =>
              conversations.fold(0, (sum, conv) => sum + conv.unreadCount),
          orElse: () => 0,
        );

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(navigationIndexProvider.notifier).state = index;
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/rides');
              break;
            case 2:
              context.go('/messages');
              break;
            case 3:
              context.go('/profile');
              break;
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(Icons.directions_car),
            label: 'Rides',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unreadMessages > 0,
              label: Text('$unreadMessages'),
              child: const Icon(Icons.chat_bubble_outline),
            ),
            selectedIcon: Badge(
              isLabelVisible: unreadMessages > 0,
              label: Text('$unreadMessages'),
              child: const Icon(Icons.chat_bubble),
            ),
            label: 'Messages',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
