import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_colors.dart';
import '../config/app_text_styles.dart';
import '../l10n/l10n_helper.dart';
import '../models/station_modify_request.dart';
import '../models/station_submission.dart';
import '../providers/user_provider.dart';
import '../screens/map/map_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/station_detail/station_list_screen.dart';
import '../services/firestore_service.dart';

class FloatingPillNav extends StatefulWidget {
  const FloatingPillNav({super.key});

  @override
  State<FloatingPillNav> createState() => _FloatingPillNavState();
}

class _FloatingPillNavState extends State<FloatingPillNav> {
  int _currentIndex = 0;
  bool _hasCheckedFeedback = false;

  static const _screens = [MapScreen(), StationListScreen(), SettingsScreen()];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasCheckedFeedback) {
      _hasCheckedFeedback = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkForFeedback());
    }
  }

  Future<void> _checkForFeedback() async {
    final userProvider = context.read<UserProvider>();
    if (!userProvider.isAuthenticated) return;
    final uid = userProvider.user.id;

    // Check new station submission feedback
    final unread = await FirestoreService.getUnreadFeedback(uid);
    if (mounted) {
      for (final submission in unread) {
        if (!mounted) return;
        await _showFeedbackDialog(submission);
      }
    }

    // Check modify request feedback
    final unreadModify = await FirestoreService.getUnreadModifyFeedback(uid);
    if (mounted) {
      for (final req in unreadModify) {
        if (!mounted) return;
        await _showModifyFeedbackDialog(req);
      }
    }
  }

  Future<void> _showFeedbackDialog(StationSubmission submission) async {
    final statusLabel = switch (submission.status) {
      SubmissionStatus.approved => context.l10n.submissionStatusApproved,
      SubmissionStatus.rejected => context.l10n.submissionStatusRejected,
      SubmissionStatus.pending => context.l10n.submissionStatusPending,
    };
    final statusColor = switch (submission.status) {
      SubmissionStatus.approved => Colors.green,
      SubmissionStatus.rejected => Colors.red,
      SubmissionStatus.pending => Colors.orange,
    };

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          context.l10n.adminFeedbackFor(submission.name),
          style: AppTextStyles.title(context),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusLabel,
                style: AppTextStyles.labelBold(
                  context,
                ).copyWith(color: statusColor),
              ),
            ),
            const SizedBox(height: 12),
            Text(submission.feedback!, style: AppTextStyles.body(context)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.dismiss),
          ),
        ],
      ),
    );

    await FirestoreService.markFeedbackRead(submission.id);
  }

  Future<void> _showModifyFeedbackDialog(StationModifyRequest request) async {
    final statusLabel = switch (request.status) {
      ModifyRequestStatus.approved => context.l10n.submissionStatusApproved,
      ModifyRequestStatus.rejected => context.l10n.submissionStatusRejected,
      ModifyRequestStatus.pending => context.l10n.submissionStatusPending,
    };
    final statusColor = switch (request.status) {
      ModifyRequestStatus.approved => Colors.green,
      ModifyRequestStatus.rejected => Colors.red,
      ModifyRequestStatus.pending => Colors.orange,
    };

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          context.l10n.adminFeedbackFor(request.originalName),
          style: AppTextStyles.title(context),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusLabel,
                style: AppTextStyles.labelBold(
                  context,
                ).copyWith(color: statusColor),
              ),
            ),
            const SizedBox(height: 12),
            Text(request.feedback!, style: AppTextStyles.body(context)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.dismiss),
          ),
        ],
      ),
    );

    await FirestoreService.markModifyFeedbackRead(request.id);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _screens),
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomPadding + 16,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceLow.withValues(alpha: 0.85)
                          : AppColors.lightSurface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkOutlineVariant.withValues(
                                alpha: 0.5,
                              )
                            : const Color(0xFFDDE1E6),
                        width: 0.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 10,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _NavTab(
                            icon: Icons.explore_outlined,
                            activeIcon: Icons.explore,
                            label: context.l10n.navMap,
                            isActive: _currentIndex == 0,
                            onTap: () => setState(() => _currentIndex = 0),
                          ),
                          const SizedBox(width: 2),
                          _NavTab(
                            icon: Icons.local_gas_station_outlined,
                            activeIcon: Icons.local_gas_station,
                            label: context.l10n.navStations,
                            isActive: _currentIndex == 1,
                            onTap: () => setState(() => _currentIndex = 1),
                          ),
                          const SizedBox(width: 2),
                          _NavTab(
                            icon: Icons.person_outline,
                            activeIcon: Icons.person,
                            label: context.l10n.navProfile,
                            isActive: _currentIndex == 2,
                            onTap: () => setState(() => _currentIndex = 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTab extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavTab> createState() => _NavTabState();
}

class _NavTabState extends State<_NavTab> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _iconSizeAnimation;
  late Animation<double> _circleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>(
      [
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 50),
        TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.05), weight: 30),
        TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 20),
      ],
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _iconSizeAnimation = Tween<double>(
      begin: 20,
      end: 22,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _circleAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    if (widget.isActive) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_NavTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.forward();
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark
        ? AppColors.darkPrimaryContainer
        : AppColors.lightPrimaryContainer;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return AnimatedScale(
            scale: _isPressed ? 0.96 : 1.0,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: _isPressed ? 0.8 : 1.0,
              duration: const Duration(milliseconds: 100),
              child: SizedBox(
                width: 68,
                height: 60,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          width: 36 * _circleAnimation.value,
                          height: 36 * _circleAnimation.value,
                          decoration: BoxDecoration(
                            color: Color.lerp(
                              Colors.transparent,
                              activeColor.withValues(alpha: 0.15),
                              _circleAnimation.value,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: widget.isActive
                                ? [
                                    BoxShadow(
                                      color: activeColor.withValues(alpha: 0.3),
                                      blurRadius: 12,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        AnimatedScale(
                          scale: _scaleAnimation.value,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(
                                  scale: animation,
                                  child: child,
                                ),
                              );
                            },
                            child: Icon(
                              widget.isActive ? widget.activeIcon : widget.icon,
                              key: ValueKey(widget.isActive),
                              size: _iconSizeAnimation.value,
                              color: widget.isActive
                                  ? activeColor
                                  : AppColors.textMuted(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: widget.isActive
                            ? FontWeight.w500
                            : FontWeight.w400,
                        color: widget.isActive
                            ? activeColor
                            : AppColors.textMuted(context),
                      ),
                      child: Text(widget.label),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
