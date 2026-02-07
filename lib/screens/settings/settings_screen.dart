import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../providers/location_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/overpass_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isRefreshing = false;

  Future<void> _refreshStations() async {
    setState(() => _isRefreshing = true);

    final locationProvider = context.read<LocationProvider>();
    if (!locationProvider.hasLocation) {
      await locationProvider.fetchLocation();
    }

    final position = locationProvider.position;
    final lat = position?.latitude ?? AppConstants.defaultMapCenter.latitude;
    final lng = position?.longitude ?? AppConstants.defaultMapCenter.longitude;

    final stations = await OverpassService.fetchNearbyStations(
      lat: lat,
      lng: lng,
      radiusMeters: AppConstants.defaultSearchRadiusMeters,
    );

    if (!mounted) return;

    if (stations.isNotEmpty) {
      await FirestoreService.upsertStations(stations);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Updated ${stations.length} stations')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not fetch stations. Check your internet connection.',
          ),
        ),
      );
    }

    if (mounted) setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;
    final isAuth = userProvider.isAuthenticated;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // User info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      child: Text(
                        user.displayName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.displayName,
                              style: Theme.of(context).textTheme.titleMedium),
                          Text(
                            isAuth
                                ? 'Email account'
                                : 'Anonymous (browsing only)',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${user.reportCount} reports · Trust: ${(user.trustScore * 100).toStringAsFixed(0)}%',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Auth actions
          if (!isAuth)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilledButton.icon(
                icon: const Icon(Icons.person_add),
                label: const Text('Create Account / Sign In'),
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.auth);
                },
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                onPressed: () async {
                  await userProvider.signOut();
                },
              ),
            ),

          const Divider(height: 32),

          // Theme toggle
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Toggle between light and dark theme'),
            secondary: Icon(
              userProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            ),
            value: userProvider.isDarkMode,
            onChanged: (_) => userProvider.toggleDarkMode(),
          ),

          const Divider(),

          // Refresh stations
          ListTile(
            leading: _isRefreshing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            title: const Text('Refresh Stations'),
            subtitle:
                const Text('Fetch nearby fuel stations from OpenStreetMap'),
            enabled: !_isRefreshing,
            onTap: _refreshStations,
          ),

          const Divider(),

          // About section
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            subtitle: Text(AppConstants.appName),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: AppConstants.appName,
                applicationVersion: '1.0.0',
                children: [
                  const Text(
                    'Community-driven fuel price tracker for Norway. '
                    'Report and find the cheapest fuel prices near you.',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
