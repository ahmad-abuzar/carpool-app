import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user.dart';
import '../../../state/admin_provider.dart';
import 'admin_user_detail_screen.dart';

/// Admin Users Screen
/// Lists all users with search, filter, and lock status
class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String _searchQuery = '';
  String _filter = 'all'; // all, locked, drivers, passengers

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E21),
        elevation: 0,
        title: const Text('All Users', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminUsersProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                filled: true,
                fillColor: const Color(0xFF1A1F36),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),

          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _filter == 'all',
                    onTap: () => setState(() => _filter = 'all'),
                  ),
                  _FilterChip(
                    label: 'Locked',
                    selected: _filter == 'locked',
                    onTap: () => setState(() => _filter = 'locked'),
                    color: Colors.redAccent,
                  ),
                  _FilterChip(
                    label: 'Drivers',
                    selected: _filter == 'drivers',
                    onTap: () => setState(() => _filter = 'drivers'),
                  ),
                  _FilterChip(
                    label: 'Passengers',
                    selected: _filter == 'passengers',
                    onTap: () => setState(() => _filter = 'passengers'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Users list
          Expanded(
            child: usersAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Error: $e',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              data: (users) {
                final filtered = _applyFilters(users);
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          color: Colors.grey[700],
                          size: 64,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No users found',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) =>
                      _UserListTile(user: filtered[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<User> _applyFilters(List<User> users) {
    var result = users;

    // Search filter
    if (_searchQuery.isNotEmpty) {
      result = result
          .where(
            (u) =>
                u.name.toLowerCase().contains(_searchQuery) ||
                u.email.toLowerCase().contains(_searchQuery),
          )
          .toList();
    }

    // Category filter
    switch (_filter) {
      case 'locked':
        result = result.where((u) => u.isProfileLocked).toList();
        break;
      case 'drivers':
        result = result
            .where((u) => u.role == UserRole.driver || u.role == UserRole.both)
            .toList();
        break;
      case 'passengers':
        result = result
            .where(
              (u) => u.role == UserRole.passenger || u.role == UserRole.both,
            )
            .toList();
        break;
    }

    return result;
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? const Color(0xFF6C63FF);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? chipColor.withOpacity(0.2)
                : const Color(0xFF1A1F36),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? chipColor : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? chipColor : Colors.grey[400],
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _UserListTile extends StatelessWidget {
  final User user;

  const _UserListTile({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F36),
        borderRadius: BorderRadius.circular(12),
        border: user.isProfileLocked
            ? Border.all(color: Colors.redAccent.withOpacity(0.5))
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: user.isProfileLocked
              ? Colors.redAccent
              : const Color(0xFF6C63FF),
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (user.isProfileLocked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '🔒 LOCKED',
                  style: TextStyle(color: Colors.redAccent, fontSize: 10),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.email,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _MiniTag(
                  label: user.role.name.toUpperCase(),
                  color: const Color(0xFF6C63FF),
                ),
                const SizedBox(width: 6),
                _MiniTag(
                  label: '${user.totalRidesAsDriver} rides',
                  color: const Color(0xFF00C9A7),
                ),
                const SizedBox(width: 6),
                _MiniTag(
                  label:
                      'Rs ${user.totalCommissionOwed.toStringAsFixed(0)} owed',
                  color: user.totalCommissionOwed > 0
                      ? Colors.orangeAccent
                      : Colors.grey,
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminUserDetailScreen(user: user),
            ),
          );
        },
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
