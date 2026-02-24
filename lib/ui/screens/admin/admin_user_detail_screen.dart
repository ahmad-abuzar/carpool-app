import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user.dart';
import '../../../models/commission.dart';
import '../../../state/admin_provider.dart';

/// Admin User Detail Screen
/// Shows individual user's earnings, commission history, and admin actions
class AdminUserDetailScreen extends ConsumerStatefulWidget {
  final User user;

  const AdminUserDetailScreen({super.key, required this.user});

  @override
  ConsumerState<AdminUserDetailScreen> createState() =>
      _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends ConsumerState<AdminUserDetailScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(
      userCommissionSummaryProvider(widget.user.id),
    );
    final commissionsAsync = ref.watch(userCommissionsProvider(widget.user.id));

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E21),
        elevation: 0,
        title: Text(
          widget.user.name,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1F36), Color(0xFF252A45)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: widget.user.isProfileLocked
                    ? Border.all(
                        color: Colors.redAccent.withOpacity(0.5),
                        width: 2,
                      )
                    : null,
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: widget.user.isProfileLocked
                        ? Colors.redAccent
                        : const Color(0xFF6C63FF),
                    child: Text(
                      widget.user.name.isNotEmpty
                          ? widget.user.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.user.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.user.email,
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                  Text(
                    widget.user.phone,
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _InfoChip(
                        label: widget.user.role.name.toUpperCase(),
                        color: const Color(0xFF6C63FF),
                      ),
                      const SizedBox(width: 8),
                      _InfoChip(
                        label: '${widget.user.totalRidesAsDriver} rides',
                        color: const Color(0xFF00C9A7),
                      ),
                      const SizedBox(width: 8),
                      if (widget.user.isProfileLocked)
                        _InfoChip(label: '🔒 LOCKED', color: Colors.redAccent),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Commission Summary
            summaryAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
                ),
              ),
              error: (e, _) => Text(
                'Error: $e',
                style: const TextStyle(color: Colors.redAccent),
              ),
              data: (summary) => Column(
                children: [
                  // Earnings Summary
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1F36),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Earnings & Commission',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _StatRow(
                          label: 'Total Earnings',
                          value:
                              'Rs ${summary.totalEarnings.toStringAsFixed(0)}',
                          color: const Color(0xFF00C9A7),
                        ),
                        _StatRow(
                          label: 'Commission Owed (5%)',
                          value:
                              'Rs ${summary.totalCommissionOwed.toStringAsFixed(0)}',
                          color: summary.totalCommissionOwed > 0
                              ? Colors.orangeAccent
                              : Colors.grey,
                        ),
                        _StatRow(
                          label: 'Commission Paid',
                          value:
                              'Rs ${summary.totalCommissionPaid.toStringAsFixed(0)}',
                          color: const Color(0xFF6C63FF),
                        ),
                        _StatRow(
                          label: 'Rides Since Last Payment',
                          value:
                              '${summary.completedRidesSinceLastPayment} / 4',
                          color: summary.completedRidesSinceLastPayment >= 4
                              ? Colors.redAccent
                              : Colors.white,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Admin Actions
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          label: summary.isLocked
                              ? 'Unlock Profile'
                              : 'Lock Profile',
                          icon: summary.isLocked ? Icons.lock_open : Icons.lock,
                          color: summary.isLocked
                              ? const Color(0xFF00C9A7)
                              : Colors.redAccent,
                          isLoading: _isProcessing,
                          onTap: () => _toggleLock(summary.isLocked),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionButton(
                          label: 'Mark Paid',
                          icon: Icons.check_circle,
                          color: const Color(0xFF6C63FF),
                          isLoading: _isProcessing,
                          onTap: summary.totalCommissionOwed > 0
                              ? () => _markPaid(summary.totalCommissionOwed)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Commission History
            const Text(
              'Commission History',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            commissionsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
              ),
              error: (e, _) => Text(
                'Error: $e',
                style: const TextStyle(color: Colors.redAccent),
              ),
              data: (commissions) {
                if (commissions.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1F36),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long,
                          color: Colors.grey[700],
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No commission records yet',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }
                return Column(
                  children: commissions
                      .map((c) => _CommissionHistoryTile(commission: c))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleLock(bool isCurrentlyLocked) async {
    setState(() => _isProcessing = true);
    final service = ref.read(commissionServiceProvider);

    if (isCurrentlyLocked) {
      await service.unlockProfile(widget.user.id);
    } else {
      await service.lockProfile(widget.user.id);
    }

    // Refresh data
    ref.invalidate(userCommissionSummaryProvider(widget.user.id));
    ref.invalidate(userCommissionsProvider(widget.user.id));
    ref.invalidate(adminUsersProvider);
    ref.invalidate(adminDashboardStatsProvider);
    setState(() => _isProcessing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCurrentlyLocked ? '✅ Profile unlocked' : '🔒 Profile locked',
          ),
          backgroundColor: isCurrentlyLocked
              ? const Color(0xFF00C9A7)
              : Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _markPaid(double amount) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F36),
        title: const Text(
          'Confirm Payment',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Mark Rs ${amount.toStringAsFixed(0)} commission as paid for ${widget.user.name}?\n\nThis will unlock their profile and reset the ride counter.',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    final service = ref.read(commissionServiceProvider);
    await service.markCommissionPaid(userId: widget.user.id, amount: amount);

    ref.invalidate(userCommissionSummaryProvider(widget.user.id));
    ref.invalidate(userCommissionsProvider(widget.user.id));
    ref.invalidate(adminUsersProvider);
    ref.invalidate(adminDashboardStatsProvider);
    setState(() => _isProcessing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Commission marked as paid'),
          backgroundColor: Color(0xFF00C9A7),
        ),
      );
    }
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;

  const _InfoChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(onTap != null ? 0.15 : 0.05),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isLoading ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(onTap != null ? 0.4 : 0.1),
            ),
          ),
          child: isLoading
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: color, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _CommissionHistoryTile extends StatelessWidget {
  final Commission commission;

  const _CommissionHistoryTile({required this.commission});

  @override
  Widget build(BuildContext context) {
    final isPaid = commission.status == CommissionStatus.paid;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F36),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPaid
              ? const Color(0xFF00C9A7).withOpacity(0.3)
              : Colors.orangeAccent.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isPaid
                  ? const Color(0xFF00C9A7).withOpacity(0.15)
                  : Colors.orangeAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isPaid ? Icons.check_circle : Icons.pending,
              color: isPaid ? const Color(0xFF00C9A7) : Colors.orangeAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ride Earning: Rs ${commission.rideEarnings.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Commission: Rs ${commission.commissionAmount.toStringAsFixed(0)}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isPaid
                      ? const Color(0xFF00C9A7).withOpacity(0.15)
                      : Colors.orangeAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isPaid ? 'PAID' : 'PENDING',
                  style: TextStyle(
                    color: isPaid
                        ? const Color(0xFF00C9A7)
                        : Colors.orangeAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(commission.createdAt),
                style: TextStyle(color: Colors.grey[600], fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
