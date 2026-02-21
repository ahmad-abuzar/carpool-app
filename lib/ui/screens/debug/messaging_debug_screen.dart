import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carpool_app/services/messaging_test_helper.dart';
import 'package:carpool_app/state/providers.dart';

/// Debug screen for testing messaging functionality
class MessagingDebugScreen extends ConsumerStatefulWidget {
  const MessagingDebugScreen({super.key});

  @override
  ConsumerState<MessagingDebugScreen> createState() =>
      _MessagingDebugScreenState();
}

class _MessagingDebugScreenState extends ConsumerState<MessagingDebugScreen> {
  final _helper = MessagingTestHelper();
  final _otherUserIdController = TextEditingController();
  String _output = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _otherUserIdController.dispose();
    super.dispose();
  }

  void _log(String message) {
    setState(() {
      _output += '$message\n';
    });
  }

  Future<void> _createTestConversation() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      _log('❌ No current user logged in');
      return;
    }

    final otherUserId = _otherUserIdController.text.trim();
    if (otherUserId.isEmpty) {
      _log('❌ Please enter other user ID');
      return;
    }

    setState(() {
      _isLoading = true;
      _output = '';
    });

    try {
      _log('Creating test conversation...');
      await _helper.createTestConversation(
        userId1: currentUser.id,
        userId2: otherUserId,
      );
      _log('✅ Test conversation created!');

      _log('\nAdding test messages...');
      await _helper.createTestMessages(
        userId1: currentUser.id,
        userId2: otherUserId,
        count: 5,
      );
      _log('✅ Test messages added!');

      _log('\n📊 Checking Firestore data...');
      await _helper.checkUserConversations(currentUser.id);
    } catch (e) {
      _log('❌ Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkConversations() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      _log('❌ No current user logged in');
      return;
    }

    setState(() {
      _isLoading = true;
      _output = '';
    });

    try {
      _log('Checking conversations for ${currentUser.id}...\n');
      await _helper.checkUserConversations(currentUser.id);
    } catch (e) {
      _log('❌ Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkMessages() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      _log('❌ No current user logged in');
      return;
    }

    final otherUserId = _otherUserIdController.text.trim();
    if (otherUserId.isEmpty) {
      _log('❌ Please enter other user ID');
      return;
    }

    setState(() {
      _isLoading = true;
      _output = '';
    });

    try {
      _log('Checking messages...\n');
      await _helper.checkConversationMessages(currentUser.id, otherUserId);
    } catch (e) {
      _log('❌ Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cleanupData() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      _log('❌ No current user logged in');
      return;
    }

    setState(() {
      _isLoading = true;
      _output = '';
    });

    try {
      _log('Cleaning up test data...');
      await _helper.cleanupTestData(currentUser.id);
      _log('✅ Test data cleaned up!');
    } catch (e) {
      _log('❌ Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messaging Debug'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current User Info
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current User',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('ID: ${currentUser?.id ?? 'Not logged in'}'),
                    Text('Name: ${currentUser?.name ?? 'N/A'}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Provider Status
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Provider Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    conversationsAsync.when(
                      data: (conversations) => Text(
                        '✅ Loaded: ${conversations.length} conversations',
                        style: const TextStyle(color: Colors.green),
                      ),
                      loading: () => const Text(
                        '⏳ Loading...',
                        style: TextStyle(color: Colors.orange),
                      ),
                      error: (err, stack) => Text(
                        '❌ Error: $err',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Other User ID Input
            TextField(
              controller: _otherUserIdController,
              decoration: const InputDecoration(
                labelText: 'Other User ID',
                hintText: 'Enter user ID to test with',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _createTestConversation,
              icon: const Icon(Icons.add),
              label: const Text('Create Test Conversation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _checkConversations,
              icon: const Icon(Icons.search),
              label: const Text('Check My Conversations'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _checkMessages,
              icon: const Icon(Icons.message),
              label: const Text('Check Messages'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _cleanupData,
              icon: const Icon(Icons.delete),
              label: const Text('Cleanup Test Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 24),

            // Output Console
            const Text(
              'Console Output:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              height: 300,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _output.isEmpty ? 'No output yet...' : _output,
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),

            if (_isLoading) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}
