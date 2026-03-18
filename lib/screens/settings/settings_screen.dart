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

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.background(context),
            surfaceTintColor: Colors.transparent,
            pinned: true,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Text(
                'Settings',
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
                _ProfileCard(
                  user: user,
                  isAuthenticated: isAuth,
                  userProvider: userProvider,
                ),
                const SizedBox(height: 24),
                if (!isAuth) ...[
                  _ActionCard(
                    icon: Icons.person_add_rounded,
                    iconColor: const Color(0xFF2563EB),
                    title: 'Create Account',
                    subtitle: 'Sign up to report prices and earn trust',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.auth),
                    isPrimary: true,
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  _ActionCard(
                    icon: Icons.logout_rounded,
                    iconColor: AppColors.textMuted(context),
                    title: 'Sign Out',
                    subtitle: 'Sign out of your account',
                    onTap: () async {
                      await userProvider.signOut();
                    },
                  ),
                  const SizedBox(height: 24),
                ],
                _SectionHeader(title: 'Preferences'),
                const SizedBox(height: 12),
                _SettingsCard(
                  children: [
                    _DarkModeTile(isDarkMode: userProvider.isDarkMode),
                    const _CardDivider(),
                    _SettingsTile(
                      icon: Icons.my_location_outlined,
                      iconColor: const Color(0xFF10B981),
                      title: 'Refresh Stations',
                      subtitle: 'Update nearby fuel stations',
                      trailing: _isRefreshing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : null,
                      onTap: _isRefreshing ? null : _refreshStations,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _SectionHeader(title: 'Support'),
                const SizedBox(height: 12),
                _SettingsCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.bug_report_outlined,
                      iconColor: const Color(0xFFF59E0B),
                      title: 'Report a Bug',
                      subtitle: 'Found an issue? Let us know',
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Color(0xFF8A8A8A),
                      ),
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.bugReport),
                    ),
                    const _CardDivider(),
                    _SettingsTile(
                      icon: Icons.info_outline,
                      iconColor: const Color(0xFF6366F1),
                      title: 'About',
                      subtitle: AppConstants.appName,
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Color(0xFF8A8A8A),
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
                          ],
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final dynamic user;
  final bool isAuthenticated;
  final UserProvider userProvider;

  const _ProfileCard({
    required this.user,
    required this.isAuthenticated,
    required this.userProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2563EB).withValues(alpha: 0.08),
            const Color(0xFF2563EB).withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2563EB).withValues(alpha: 0.12),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF2563EB).withValues(alpha: 0.2),
                  const Color(0xFF2563EB).withValues(alpha: 0.05),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: Center(
              child: isAuthenticated && user.displayName.isNotEmpty
                  ? Text(
                      user.displayName.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2563EB),
                      ),
                    )
                  : Icon(
                      Icons.person_outline,
                      size: 28,
                      color: const Color(0xFF2563EB).withValues(alpha: 0.6),
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
                        ? const Color(0xFF10B981).withValues(alpha: 0.1)
                        : AppColors.surface(context),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    userProvider.accountTypeLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isAuthenticated
                          ? const Color(0xFF10B981)
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
    return GestureDetector(
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
              color: widget.isPrimary
                  ? const Color(0xFF2563EB)
                  : AppColors.surface(context),
              borderRadius: BorderRadius.circular(12),
              border: widget.isPrimary
                  ? null
                  : Border.all(color: AppColors.border(context), width: 0.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: widget.isPrimary
                        ? Colors.white.withValues(alpha: 0.15)
                        : const Color(0xFF2563EB).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(
                      widget.icon,
                      size: 22,
                      color: widget.isPrimary ? Colors.white : widget.iconColor,
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
                          color: widget.isPrimary ? Colors.white : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle,
                        style: AppTextStyles.meta(context).copyWith(
                          color: widget.isPrimary
                              ? Colors.white.withValues(alpha: 0.8)
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
                      ? Colors.white.withValues(alpha: 0.8)
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

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.label(
          context,
        ).copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w600),
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
        borderRadius: BorderRadius.circular(12),
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

class _DarkModeTile extends StatelessWidget {
  final bool isDarkMode;

  const _DarkModeTile({required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.read<UserProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:
                  (isDarkMode
                          ? const Color(0xFF6366F1)
                          : const Color(0xFFF59E0B))
                      .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(
                isDarkMode ? Icons.dark_mode : Icons.light_mode,
                size: 20,
                color: isDarkMode
                    ? const Color(0xFF6366F1)
                    : const Color(0xFFF59E0B),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dark Mode', style: AppTextStyles.bodyMedium(context)),
                const SizedBox(height: 2),
                Text(
                  isDarkMode ? 'On' : 'Off',
                  style: AppTextStyles.meta(context),
                ),
              ],
            ),
          ),
          _AnimatedSwitch(
            value: isDarkMode,
            onChanged: (_) => userProvider.toggleDarkMode(),
          ),
        ],
      ),
    );
  }
}

class _AnimatedSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AnimatedSwitch({required this.value, required this.onChanged});

  @override
  State<_AnimatedSwitch> createState() => _AnimatedSwitchState();
}

class _AnimatedSwitchState extends State<_AnimatedSwitch>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
      value: widget.value ? 1.0 : 0.0,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void didUpdateWidget(_AnimatedSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (widget.value) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onChanged(!widget.value),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            width: 52,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Color.lerp(
                const Color(0xFFE5E7EB),
                const Color(0xFF2563EB),
                _animation.value,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Stack(
              children: [
                Positioned(
                  left: 2 + (18 * _animation.value),
                  top: 2,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        widget.value ? Icons.dark_mode : Icons.light_mode,
                        size: 14,
                        color: Color.lerp(
                          const Color(0xFF6B7280),
                          const Color(0xFF2563EB),
                          _animation.value,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
