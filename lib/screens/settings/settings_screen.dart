import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Stations refreshed')));
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;
    final isAuth = userProvider.isAuthenticated;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = AppColors.primaryContainer(context);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.background(context),
            surfaceTintColor: Colors.transparent,
            pinned: true,
            expandedHeight: 100,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Text(
                'Profile',
                style: AppTextStyles.heading(context).copyWith(fontSize: 28),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 100,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Profile Hero ──
                _ProfileHero(
                  user: user,
                  isAuthenticated: isAuth,
                  userProvider: userProvider,
                ),
                const SizedBox(height: 20),

                // ── Contributions Card ──
                if (isAuth) ...[
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.border(context),
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.bar_chart_rounded, size: 20, color: activeColor),
                            const SizedBox(width: 8),
                            Text(
                              'Total Contributions',
                              style: AppTextStyles.bodyMedium(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${user.reportCount}',
                          style: AppTextStyles.priceLarge(context).copyWith(
                            fontSize: 28,
                          ),
                        ),
                        Text(
                          'price reports submitted',
                          style: AppTextStyles.meta(context),
                        ),
                        const SizedBox(height: 12),
                        // Trust score bar
                        Row(
                          children: [
                            Text('Trust Score', style: AppTextStyles.label(context)),
                            const Spacer(),
                            Text(
                              '${(user.trustScore * 100).toStringAsFixed(0)}%',
                              style: AppTextStyles.labelBold(context).copyWith(
                                color: activeColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: user.trustScore,
                            minHeight: 6,
                            backgroundColor: AppColors.surfaceLow(context),
                            valueColor: AlwaysStoppedAnimation<Color>(activeColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Sign In / Create Account ──
                if (!isAuth) ...[
                  _ActionCard(
                    icon: Icons.person_add_rounded,
                    iconColor: activeColor,
                    title: 'Create Account',
                    subtitle: 'Sign up to report prices and earn trust',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.auth),
                    isPrimary: true,
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Map Preferences ──
                Text(
                  'MAP PREFERENCES',
                  style: AppTextStyles.sectionHeader(context),
                ),
                const SizedBox(height: 12),
                _SettingsCard(
                  children: [
                    _ThemeModeTile(themeMode: userProvider.themeMode),
                    const _CardDivider(),
                    _SettingsTile(
                      icon: Icons.my_location_outlined,
                      iconColor: isDark
                          ? const Color(0xFF6fddaa)
                          : const Color(0xFF10B981),
                      title: 'Refresh Stations',
                      subtitle: 'Update nearby fuel stations',
                      trailing: _isRefreshing
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: activeColor,
                              ),
                            )
                          : null,
                      onTap: _isRefreshing ? null : _refreshStations,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Support ──
                Text(
                  'SUPPORT',
                  style: AppTextStyles.sectionHeader(context),
                ),
                const SizedBox(height: 12),
                _SettingsCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.bug_report_outlined,
                      iconColor: isDark
                          ? const Color(0xFFffd166)
                          : const Color(0xFFF59E0B),
                      title: 'Report a Bug',
                      subtitle: 'Found an issue? Let us know',
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: AppColors.textMuted(context),
                      ),
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.bugReport),
                    ),
                    const _CardDivider(),
                    _SettingsTile(
                      icon: Icons.info_outline,
                      iconColor: isDark
                          ? const Color(0xFFa4e6ff)
                          : const Color(0xFF6366F1),
                      title: 'About',
                      subtitle: AppConstants.appName,
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: AppColors.textMuted(context),
                      ),
                      onTap: () async {
                        final info = await PackageInfo.fromPlatform();
                        if (!context.mounted) return;
                        showAboutDialog(
                          context: context,
                          applicationName: AppConstants.appName,
                          applicationVersion:
                              '${info.version}+${info.buildNumber}',
                          children: [
                            const Text(
                              'Community-driven fuel price tracker for Norway. '
                              'Report and find the cheapest fuel prices near you.',
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              icon: ClipOval(
                                child: Image.asset(
                                  'assets/logos/github.png',
                                  width: 18,
                                  height: 18,
                                ),
                              ),
                              label: const Text('View on GitHub'),
                              onPressed: () {
                                launchUrl(
                                  Uri.parse(
                                    'https://github.com/tsotnek/tankvenn',
                                  ),
                                  mode: LaunchMode.externalApplication,
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Account Management ──
                if (isAuth) ...[
                  Text(
                    'ACCOUNT',
                    style: AppTextStyles.sectionHeader(context),
                  ),
                  const SizedBox(height: 12),
                  _SettingsCard(
                    children: [
                      _SettingsTile(
                        icon: Icons.logout_rounded,
                        iconColor: isDark
                            ? AppColors.darkError
                            : const Color(0xFFDC2626),
                        title: 'Sign Out',
                        subtitle: 'Sign out of your account',
                        onTap: () async {
                          await userProvider.signOut();
                        },
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final dynamic user;
  final bool isAuthenticated;
  final UserProvider userProvider;

  const _ProfileHero({
    required this.user,
    required this.isAuthenticated,
    required this.userProvider,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = AppColors.primaryContainer(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.darkSurfaceHigh,
                  AppColors.darkSurface,
                ]
              : [
                  AppColors.lightSurfaceLow,
                  AppColors.lightSurface,
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: activeColor.withValues(alpha: 0.15),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  activeColor.withValues(alpha: 0.2),
                  activeColor.withValues(alpha: 0.05),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: activeColor.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: activeColor.withValues(alpha: 0.15),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Center(
              child: isAuthenticated && user.displayName.isNotEmpty
                  ? Text(
                      user.displayName.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: activeColor,
                      ),
                    )
                  : Icon(
                      Icons.person_outline,
                      size: 28,
                      color: activeColor.withValues(alpha: 0.6),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAuthenticated && user.displayName.isNotEmpty
                      ? user.displayName
                      : 'Guest User',
                  style: AppTextStyles.title(context).copyWith(fontSize: 18),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isAuthenticated
                        ? activeColor.withValues(alpha: 0.12)
                        : AppColors.surfaceLow(context),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    userProvider.accountTypeLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isAuthenticated
                          ? activeColor
                          : AppColors.textMuted(context),
                    ),
                  ),
                ),
                if (isAuthenticated) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _StatBadge(
                        icon: Icons.edit_note,
                        value: '${user.reportCount}',
                        label: 'reports',
                      ),
                      const SizedBox(width: 12),
                      _StatBadge(
                        icon: Icons.verified,
                        value: '${(user.trustScore * 100).toStringAsFixed(0)}%',
                        label: 'trust',
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatBadge({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted(context)),
        const SizedBox(width: 4),
        Text(value, style: AppTextStyles.labelBold(context)),
        const SizedBox(width: 2),
        Text(label, style: AppTextStyles.meta(context)),
      ],
    );
  }
}

class _ActionCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isPrimary;

  const _ActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _isPressed ? 0.85 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: widget.isPrimary
                  ? LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF00d1ff), const Color(0xFF0091b3)]
                          : [const Color(0xFF0056b3), const Color(0xFF003f87)],
                    )
                  : null,
              color: widget.isPrimary ? null : AppColors.surface(context),
              borderRadius: BorderRadius.circular(14),
              border: widget.isPrimary
                  ? null
                  : Border.all(color: AppColors.border(context), width: 0.5),
              boxShadow: widget.isPrimary
                  ? [
                      BoxShadow(
                        color: (isDark
                                ? const Color(0xFF00d1ff)
                                : const Color(0xFF0056b3))
                            .withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: widget.isPrimary
                        ? Colors.white.withValues(alpha: 0.15)
                        : widget.iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      widget.icon,
                      size: 22,
                      color: widget.isPrimary
                          ? (isDark ? AppColors.darkBackground : Colors.white)
                          : widget.iconColor,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: AppTextStyles.bodyMedium(context).copyWith(
                          color: widget.isPrimary
                              ? (isDark
                                  ? AppColors.darkBackground
                                  : Colors.white)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle,
                        style: AppTextStyles.meta(context).copyWith(
                          color: widget.isPrimary
                              ? (isDark
                                      ? AppColors.darkBackground
                                      : Colors.white)
                                  .withValues(alpha: 0.8)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: widget.isPrimary
                      ? (isDark ? AppColors.darkBackground : Colors.white)
                          .withValues(alpha: 0.8)
                      : AppColors.textMuted(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context), width: 0.5),
      ),
      child: Column(children: children),
    );
  }
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.only(left: 68),
      color: AppColors.border(context),
    );
  }
}

class _SettingsTile extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  State<_SettingsTile> createState() => _SettingsTileState();
}

class _SettingsTileState extends State<_SettingsTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap != null
          ? (_) => setState(() => _isPressed = true)
          : null,
      onTapUp: widget.onTap != null
          ? (_) {
              setState(() => _isPressed = false);
              widget.onTap?.call();
            }
          : null,
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _isPressed ? 0.7 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: widget.iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(widget.icon, size: 20, color: widget.iconColor),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: AppTextStyles.bodyMedium(context),
                      ),
                      const SizedBox(height: 2),
                      Text(widget.subtitle, style: AppTextStyles.meta(context)),
                    ],
                  ),
                ),
                if (widget.trailing != null) widget.trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeModeTile extends StatelessWidget {
  final ThemeMode themeMode;

  const _ThemeModeTile({required this.themeMode});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.read<UserProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = AppColors.primaryContainer(context);
    final iconColor = isDark ? const Color(0xFFa4e6ff) : const Color(0xFFF59E0B);

    final IconData icon;
    final String subtitle;
    switch (themeMode) {
      case ThemeMode.dark:
        icon = Icons.dark_mode;
        subtitle = 'Dark';
      case ThemeMode.light:
        icon = Icons.light_mode;
        subtitle = 'Light';
      case ThemeMode.system:
        icon = Icons.brightness_auto;
        subtitle = 'System';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(icon, size: 20, color: iconColor),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Appearance', style: AppTextStyles.bodyMedium(context)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.meta(context)),
              ],
            ),
          ),
          _ThemeModeSelector(
            themeMode: themeMode,
            activeColor: activeColor,
            onChanged: userProvider.setThemeMode,
          ),
        ],
      ),
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  final ThemeMode themeMode;
  final Color activeColor;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeModeSelector({
    required this.themeMode,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? AppColors.darkSurfaceHighest
        : const Color(0xFFE5E7EB);

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ThemeOption(
            icon: Icons.light_mode,
            isSelected: themeMode == ThemeMode.light,
            activeColor: activeColor,
            onTap: () => onChanged(ThemeMode.light),
          ),
          _ThemeOption(
            icon: Icons.brightness_auto,
            isSelected: themeMode == ThemeMode.system,
            activeColor: activeColor,
            onTap: () => onChanged(ThemeMode.system),
          ),
          _ThemeOption(
            icon: Icons.dark_mode,
            isSelected: themeMode == ThemeMode.dark,
            activeColor: activeColor,
            onTap: () => onChanged(ThemeMode.dark),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 32,
        height: 28,
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : AppColors.textMuted(context),
          ),
        ),
      ),
    );
  }
}
