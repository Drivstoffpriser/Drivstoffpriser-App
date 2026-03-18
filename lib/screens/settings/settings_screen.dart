import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../config/constants.dart';
import '../../config/routes.dart';
import '../../providers/station_provider.dart';
import '../../providers/user_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isRefreshing = false;

  Future<void> _refreshStations() async {
    setState(() => _isRefreshing = true);

    final stationProvider = context.read<StationProvider>();
    await stationProvider.fetchAllNorwayStations();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Stations refreshed',
            style: AppTextStyles.label(
              context.read<UserProvider>().isDarkMode,
            ).copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final isDark = userProvider.isDarkMode;
    final user = userProvider.user;
    final isAuth = userProvider.isAuthenticated;

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        title: Text('Settings', style: AppTextStyles.heading(isDark)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
        ).copyWith(bottom: 100),
        children: [
          const SizedBox(height: 8),
          // User Profile Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated(isDark),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border(isDark)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.accent.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          user.displayName.isNotEmpty
                              ? user.displayName.substring(0, 1).toUpperCase()
                              : '?',
                          style: AppTextStyles.heading(
                            isDark,
                          ).copyWith(color: AppColors.accent, fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName.isNotEmpty
                                ? user.displayName
                                : 'Guest User',
                            style: AppTextStyles.heading(
                              isDark,
                            ).copyWith(fontSize: 18),
                          ),
                          Text(
                            isAuth
                                ? userProvider.accountTypeLabel
                                : 'Not signed in',
                            style: AppTextStyles.label(
                              isDark,
                            ).copyWith(color: AppColors.textMuted(isDark)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (isAuth) ...[
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        label: 'Reports',
                        value: user.reportCount.toString(),
                      ),
                      _StatItem(
                        label: 'Trust',
                        value: '${(user.trustScore * 100).toStringAsFixed(0)}%',
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: isAuth
                      ? OutlinedButton(
                          onPressed: () => userProvider.signOut(),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Colors.red.withOpacity(0.3),
                            ),
                            foregroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Sign Out',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRoutes.auth),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Sign In / Register',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          _SettingsGroup(
            title: 'Appearance',
            children: [
              _SettingsTile(
                icon: isDark
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                title: 'Dark Mode',
                trailing: Switch.adaptive(
                  value: isDark,
                  activeColor: AppColors.accent,
                  onChanged: (_) => userProvider.toggleDarkMode(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          _SettingsGroup(
            title: 'General',
            children: [
              _SettingsTile(
                icon: Icons.refresh_rounded,
                title: 'Refresh Stations',
                subtitle: 'Update local data from OSM',
                isLoading: _isRefreshing,
                onTap: _refreshStations,
              ),
              _SettingsTile(
                icon: Icons.bug_report_rounded,
                title: 'Report a Bug',
                onTap: () => Navigator.pushNamed(context, AppRoutes.bugReport),
              ),
            ],
          ),

          const SizedBox(height: 24),
          _SettingsGroup(
            title: 'About',
            children: [
              _SettingsTile(
                icon: Icons.info_rounded,
                title: 'Version',
                subtitle: 'FuelPrice v1.0.0',
                onTap: () async {
                  final info = await PackageInfo.fromPlatform();
                  if (!context.mounted) return;
                  showAboutDialog(
                    context: context,
                    applicationName: AppConstants.appName,
                    applicationVersion: '${info.version}+${info.buildNumber}',
                    children: [
                      const Text(
                        'Community-driven fuel price tracker for Norway.',
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<UserProvider>().isDarkMode;
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.heading(isDark).copyWith(fontSize: 20),
        ),
        Text(
          label,
          style: AppTextStyles.label(
            isDark,
          ).copyWith(color: AppColors.textMuted(isDark)),
        ),
      ],
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<UserProvider>().isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: AppTextStyles.label(isDark).copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: AppColors.textMuted(isDark),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface(isDark),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border(isDark)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isLoading;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<UserProvider>().isDarkMode;
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.background(isDark),
          borderRadius: BorderRadius.circular(10),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, color: AppColors.accent, size: 20),
      ),
      title: Text(
        title,
        style: AppTextStyles.body(isDark).copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!, style: AppTextStyles.label(isDark))
          : null,
      trailing:
          trailing ??
          (onTap != null
              ? Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted(isDark),
                )
              : null),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
