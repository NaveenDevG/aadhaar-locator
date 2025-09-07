import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/widgets/animated_logo.dart';
import '../../../core/widgets/powered_by_branding.dart';
import '../../auth/providers/auth_providers.dart';
import '../../location/providers/location_sharing_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.profile;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            AnimatedLogo(
              size: 32.0,
              showText: false,
              autoAnimate: true,
            ),
            const SizedBox(width: 12),
            const Text('Dashboard'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRouter.profile);
            },
            tooltip: 'View Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Logo Section
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: AnimatedLogo(
                  size: 100.0,
                  showText: true,
                  autoAnimate: true,
                ),
              ),
            ),
            
            // Welcome Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${user?.name ?? 'User'}!',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your Aadhaar: ${user?.aadhaarNumber ?? 'N/A'}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Online Users Indicator
            FutureBuilder<int>(
              future: ref.read(loggedInUsersProvider.future).then((users) => users.length),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Row(
                      children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Loading user count...'),
                        ],
                      ),
                    ),
                  );
                }
                
                final userCount = snapshot.data ?? 0;
                return Card(
                  color: userCount > 0 ? Colors.green.shade50 : Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          userCount > 0 ? Icons.people : Icons.person_off,
                          color: userCount > 0 ? Colors.green.shade700 : Colors.orange.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userCount > 0 
                                    ? '🟢 $userCount user${userCount == 1 ? '' : 's'} online'
                                    : '🟠 No other users online',
                                style: TextStyle(
                                  color: userCount > 0 ? Colors.green.shade700 : Colors.orange.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (userCount > 0) ...[
                                const SizedBox(height: 4),
                              Text(
                                  'Your location will be shared with all online users',
                                  style: TextStyle(
                                    color: Colors.green.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
              children: [
                _buildActionCard(
                  context,
                  '📍 Share Location\n(Auto-send to all users)',
                  Icons.location_on,
                  Colors.blue,
                  () {
                    Navigator.of(context).pushNamed(
                      AppRouter.locationSharing,
                      arguments: {'autoShare': true},
                    );
                  },
                ),
                _buildActionCard(
                  context,
                  'View Map',
                  Icons.map,
                  Colors.green,
                  () {
                    Navigator.of(context).pushNamed(AppRouter.map, arguments: {
                      'senderName': 'Demo User',
                      'lat': 28.6139,
                      'lng': 77.2090,
                        });
                      },
                ),
                _buildActionCard(
                  context,
                  'Location Demo',
                  Icons.explore,
                  Colors.teal,
                  () {
                    Navigator.of(context).pushNamed(AppRouter.locationSharingDemo);
                  },
                ),
                _buildActionCard(
                  context,
                  'Profile',
                  Icons.person,
                  Colors.purple,
                  () {
                    Navigator.of(context).pushNamed(AppRouter.profile);
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Powered by branding
            const PoweredByBranding(
              textColor: Colors.grey,
              textSize: 12.0,
              imageHeight: 18.0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
