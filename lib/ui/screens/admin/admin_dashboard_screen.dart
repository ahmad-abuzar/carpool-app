import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../state/admin_provider.dart';
import 'admin_users_screen.dart';
import 'admin_commissions_screen.dart';
import 'admin_login_screen.dart';

/// Admin Dashboard Screen
/// Shows overview stats and quick navigation
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminDashboardStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E21),
        elevation: 0,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              ref.invalidate(adminDashboardStatsProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text('Error: $e', style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(adminDashboardStatsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (stats) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminDashboardStatsProvider),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats Grid
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.4,
                  children: [
                    _StatCard(
                      title: 'Total Users',
                      value: '${stats['totalUsers'] ?? 0}',
                      icon: Icons.people,
                      color: const Color(0xFF6C63FF),
                    ),
                    _StatCard(
                      title: 'Active Riders',
                      value: '${stats['activeRiders'] ?? 0}',
                      icon: Icons.directions_car,
                      color: const Color(0xFF00C9A7),
                    ),
                    _StatCard(
                      title: 'Locked Profiles',
                      value: '${stats['lockedProfiles'] ?? 0}',
                      icon: Icons.lock,
                      color: const Color(0xFFFF6B6B),
                    ),
                    _StatCard(
                      title: 'Commission\nCollected',
                      value:
                          'Rs ${((stats['totalCommissionCollected'] ?? 0) as num).toStringAsFixed(0)}',
                      icon: Icons.payments,
                      color: const Color(0xFFFFD93D),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Commission Summary Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A1F36), Color(0xFF252A45)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF6C63FF).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Commission Overview',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _MiniStat(
                              label: 'Pending',
                              value:
                                  'Rs ${((stats['totalCommissionPending'] ?? 0) as num).toStringAsFixed(0)}',
                              color: Colors.orangeAccent,
                            ),
                          ),
                          Expanded(
                            child: _MiniStat(
                              label: 'Collected',
                              value:
                                  'Rs ${((stats['totalCommissionCollected'] ?? 0) as num).toStringAsFixed(0)}',
                              color: const Color(0xFF00C9A7),
                            ),
                          ),
                          Expanded(
                            child: _MiniStat(
                              label: 'Total Records',
                              value: '${stats['totalCommissions'] ?? 0}',
                              color: const Color(0xFF6C63FF),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Quick Actions
                const Text(
                  'Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                _ActionTile(
                  title: 'All Users',
                  subtitle: 'View and manage all registered users',
                  icon: Icons.people_outline,
                  color: const Color(0xFF6C63FF),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
                  ),
                ),
                const SizedBox(height: 10),
                _ActionTile(
                  title: 'Commissions',
                  subtitle: 'View pending and paid commissions',
                  icon: Icons.receipt_long,
                  color: const Color(0xFFFFD93D),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminCommissionsScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F36),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1A1F36),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[600]),
            ],
          ),
        ),
      ),
    );
  }
}
