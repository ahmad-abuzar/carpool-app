import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/commission.dart';
import '../../../state/admin_provider.dart';

/// Admin Commissions Screen
/// Shows all commission records with filter tabs
class AdminCommissionsScreen extends ConsumerStatefulWidget {
  const AdminCommissionsScreen({super.key});

  @override
  ConsumerState<AdminCommissionsScreen> createState() =>
      _AdminCommissionsScreenState();
}

class _AdminCommissionsScreenState extends ConsumerState<AdminCommissionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allCommissionsAsync = ref.watch(adminCommissionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E21),
        elevation: 0,
        title: const Text('Commissions', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(adminCommissionsProvider);
              ref.invalidate(adminPendingCommissionsProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6C63FF),
          labelColor: const Color(0xFF6C63FF),
          unselectedLabelColor: Colors.grey[500],
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Paid'),
          ],
        ),
      ),
      body: allCommissionsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e', style: const TextStyle(color: Colors.white)),
        ),
        data: (allCommissions) {
          final pendingList = allCommissions
              .where((c) => c.status == CommissionStatus.pending)
              .toList();
          final paidList = allCommissions
              .where((c) => c.status == CommissionStatus.paid)
              .toList();

          // Calculate totals
          final totalPending = pendingList.fold<double>(
            0,
            (sum, c) => sum + c.commissionAmount,
          );
          final totalPaid = paidList.fold<double>(
            0,
            (sum, c) => sum + c.commissionAmount,
          );

          return Column(
            children: [
              // Summary bar
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A1F36), Color(0xFF252A45)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF6C63FF).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Rs ${totalPending.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Pending',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 36, color: Colors.grey[800]),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Rs ${totalPaid.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Color(0xFF00C9A7),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Collected',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 36, color: Colors.grey[800]),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '${allCommissions.length}',
                            style: const TextStyle(
                              color: Color(0xFF6C63FF),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Total',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _CommissionList(commissions: allCommissions),
                    _CommissionList(commissions: pendingList),
                    _CommissionList(commissions: paidList),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CommissionList extends StatelessWidget {
  final List<Commission> commissions;

  const _CommissionList({required this.commissions});

  @override
  Widget build(BuildContext context) {
    if (commissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, color: Colors.grey[700], size: 64),
            const SizedBox(height: 12),
            Text(
              'No commissions found',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: commissions.length,
      itemBuilder: (context, index) {
        final c = commissions[index];
        final isPaid = c.status == CommissionStatus.paid;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F36),
            borderRadius: BorderRadius.circular(12),
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
                  isPaid ? Icons.check_circle : Icons.schedule,
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
                      'User: ${c.userId.substring(0, c.userId.length > 8 ? 8 : c.userId.length)}...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Earning: Rs ${c.rideEarnings.toStringAsFixed(0)} → Commission: Rs ${c.commissionAmount.toStringAsFixed(0)}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 11),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
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
                    '${c.createdAt.day}/${c.createdAt.month}/${c.createdAt.year}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
