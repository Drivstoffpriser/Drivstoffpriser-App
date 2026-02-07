import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../providers/user_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;

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
                          Text('User ID: ${user.id}',
                              style: Theme.of(context).textTheme.bodySmall),
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

          const Divider(),

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
