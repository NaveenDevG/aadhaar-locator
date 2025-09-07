import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../core/routing/app_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.profile;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
        ),
        body: const Center(
          child: Text('No profile data available'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Profile Avatar
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user.aadhaarName,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Personal Information Section
            _buildSectionHeader(context, 'Personal Information'),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  _buildInfoTile(
                    context,
                    'Full Name',
                    user.name,
                    Icons.person,
                  ),
                  _buildDivider(),
                  _buildInfoTile(
                    context,
                    'Aadhaar Name',
                    user.aadhaarName,
                    Icons.badge,
                  ),
                  _buildDivider(),
                  _buildInfoTile(
                    context,
                    'Aadhaar Number',
                    _formatAadhaarNumber(user.aadhaarNumber),
                    Icons.credit_card,
                  ),
                  _buildDivider(),
                  _buildInfoTile(
                    context,
                    'Date of Birth',
                    DateFormat('dd MMM yyyy').format(user.aadhaarDob),
                    Icons.cake,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Contact Information Section
            _buildSectionHeader(context, 'Contact Information'),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  if (user.email != null && user.email!.isNotEmpty) ...[
                    _buildInfoTile(
                      context,
                      'Email',
                      user.email!,
                      Icons.email,
                    ),
                    _buildDivider(),
                  ],
                  if (user.phone != null && user.phone!.isNotEmpty) ...[
                    _buildInfoTile(
                      context,
                      'Phone',
                      user.phone!,
                      Icons.phone,
                    ),
                    _buildDivider(),
                  ],
                  _buildInfoTile(
                    context,
                    'User ID',
                    user.uid,
                    Icons.fingerprint,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Account Information Section
            _buildSectionHeader(context, 'Account Information'),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  _buildInfoTile(
                    context,
                    'Account Status',
                    user.isLoggedIn ? 'Active' : 'Inactive',
                    user.isLoggedIn ? Icons.check_circle : Icons.cancel,
                    valueColor: user.isLoggedIn ? Colors.green : Colors.red,
                  ),
                  _buildDivider(),
                  _buildInfoTile(
                    context,
                    'First Login Required',
                    user.firstLoginRequired ? 'Yes' : 'No',
                    user.firstLoginRequired ? Icons.warning : Icons.check,
                    valueColor: user.firstLoginRequired ? Colors.orange : Colors.green,
                  ),
                  if (user.createdAt != null) ...[
                    _buildDivider(),
                    _buildInfoTile(
                      context,
                      'Account Created',
                      DateFormat('dd MMM yyyy, hh:mm a').format(user.createdAt!),
                      Icons.access_time,
                    ),
                  ],
                  if (user.updatedAt != null) ...[
                    _buildDivider(),
                    _buildInfoTile(
                      context,
                      'Last Updated',
                      DateFormat('dd MMM yyyy, hh:mm a').format(user.updatedAt!),
                      Icons.update,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Location Information Section
            if (user.lastKnownLocation != null) ...[
              _buildSectionHeader(context, 'Location Information'),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    _buildInfoTile(
                      context,
                      'Last Known Location',
                      '${user.lastKnownLocation!.latitude.toStringAsFixed(6)}, ${user.lastKnownLocation!.longitude.toStringAsFixed(6)}',
                      Icons.location_on,
                    ),
                    _buildDivider(),
                    _buildInfoTile(
                      context,
                      'View on Map',
                      'Tap to view location',
                      Icons.map,
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          AppRouter.map,
                          arguments: {
                            'senderName': user.name,
                            'lat': user.lastKnownLocation!.latitude,
                            'lng': user.lastKnownLocation!.longitude,
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Action Buttons
            _buildSectionHeader(context, 'Actions'),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Logout'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      await ref.read(authControllerProvider.notifier).logout();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        value,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: valueColor ?? Theme.of(context).textTheme.bodyLarge?.color,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: onTap != null ? const Icon(Icons.arrow_forward_ios, size: 16) : null,
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 56);
  }

  String _formatAadhaarNumber(String aadhaarNumber) {
    if (aadhaarNumber.length == 12) {
      return '${aadhaarNumber.substring(0, 4)} ${aadhaarNumber.substring(4, 8)} ${aadhaarNumber.substring(8)}';
    }
    return aadhaarNumber;
  }
}
