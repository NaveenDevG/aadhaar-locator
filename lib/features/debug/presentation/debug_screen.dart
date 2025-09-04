import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/development_helper_service.dart';
import '../../notifications/services/fcm_test_service.dart';

class DebugScreen extends ConsumerStatefulWidget {
  const DebugScreen({super.key});

  @override
  ConsumerState<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends ConsumerState<DebugScreen> {
  Map<String, dynamic> _testResults = {};
  bool _isRunningTests = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug & Testing'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTestSection(),
            const SizedBox(height: 24),
            _buildResultsSection(),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Text(
                  'Development Tests',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Run comprehensive tests to check Firebase Auth, FCM, and other services.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    if (_testResults.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'No test results yet. Run tests to see results.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.green.shade600),
                const SizedBox(width: 8),
                Text(
                  'Test Results',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._testResults.entries.map((entry) => _buildResultItem(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildResultItem(String testName, dynamic results) {
    if (results is Map) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            testName.toUpperCase(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 8),
          ...results.entries.map((result) => Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
            child: Row(
              children: [
                Icon(
                  _getResultIcon(result.value),
                  size: 16,
                  color: _getResultColor(result.value),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${result.key}: ${result.value}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          )),
          const Divider(height: 24),
        ],
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          children: [
            Icon(
              _getResultIcon(results),
              size: 16,
              color: _getResultColor(results),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$testName: $results',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }
  }

  IconData _getResultIcon(dynamic value) {
    if (value == true || value == 'success' || value.toString().contains('true')) {
      return Icons.check_circle;
    } else if (value == false || value == 'error' || value.toString().contains('false')) {
      return Icons.error;
    } else {
      return Icons.info;
    }
  }

  Color _getResultColor(dynamic value) {
    if (value == true || value == 'success' || value.toString().contains('true')) {
      return Colors.green;
    } else if (value == false || value == 'error' || value.toString().contains('false')) {
      return Colors.red;
    } else {
      return Colors.blue;
    }
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _isRunningTests ? null : _runComprehensiveTests,
          icon: _isRunningTests
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.play_arrow),
          label: Text(_isRunningTests ? 'Running Tests...' : 'Run All Tests'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isRunningTests ? null : _testFcmOnly,
                icon: const Icon(Icons.notifications),
                label: const Text('Test FCM Only'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isRunningTests ? null : _createTestUser,
                icon: const Icon(Icons.person_add),
                label: const Text('Create Test User'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _isRunningTests ? null : _clearTestData,
          icon: const Icon(Icons.clear_all, color: Colors.red),
          label: const Text('Clear Test Data', style: TextStyle(color: Colors.red)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            side: const BorderSide(color: Colors.red),
          ),
        ),
      ],
    );
  }

  Future<void> _runComprehensiveTests() async {
    setState(() {
      _isRunningTests = true;
      _testResults = {};
    });

    try {
      final results = await DevelopmentHelperService.runComprehensiveTests();
      setState(() {
        _testResults = results;
        _isRunningTests = false;
      });
    } catch (e) {
      setState(() {
        _testResults = {'error': e.toString()};
        _isRunningTests = false;
      });
    }
  }

  Future<void> _testFcmOnly() async {
    setState(() {
      _isRunningTests = true;
      _testResults = {};
    });

    try {
      final results = await FCMTestService.runAllTests();
      setState(() {
        _testResults = {'fcm_tests': results};
        _isRunningTests = false;
      });
    } catch (e) {
      setState(() {
        _testResults = {'error': e.toString()};
        _isRunningTests = false;
      });
    }
  }

  Future<void> _createTestUser() async {
    setState(() {
      _isRunningTests = true;
      _testResults = {};
    });

    try {
      final result = await DevelopmentHelperService.createTestUser(
        email: 'test@example.com',
        password: 'testpass123',
      );
      setState(() {
        _testResults = {'test_user_creation': result};
        _isRunningTests = false;
      });
    } catch (e) {
      setState(() {
        _testResults = {'error': e.toString()};
        _isRunningTests = false;
      });
    }
  }

  Future<void> _clearTestData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Test Data'),
        content: const Text(
          'This will delete all test data and sign out the current user. '
          'This action cannot be undone. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isRunningTests = true;
        _testResults = {};
      });

      try {
        final success = await DevelopmentHelperService.clearTestData();
        setState(() {
          _testResults = {'clear_test_data': {'success': success}};
          _isRunningTests = false;
        });
      } catch (e) {
        setState(() {
          _testResults = {'error': e.toString()};
          _isRunningTests = false;
        });
      }
    }
  }
}

