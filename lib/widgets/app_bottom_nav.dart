import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../screens/map/map_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/station_detail/station_list_screen.dart';

class AppBottomNav extends StatefulWidget {
  const AppBottomNav({super.key});

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav> {
  int _currentIndex = 0;

  static const _screens = [MapScreen(), StationListScreen(), SettingsScreen()];

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final isDark = userProvider.isDarkMode;

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _screens),
          Positioned(
            bottom: 24 + MediaQuery.of(context).padding.bottom,
            left: 0,
            right: 0,
            child: Center(
              child: _FloatingPillNav(
                currentIndex: _currentIndex,
                onTap: (index) => setState(() => _currentIndex = index),
                isDark: isDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingPillNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool isDark;

  const _FloatingPillNav({
    required this.currentIndex,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: (isDark ? const Color(0xFF1A1A1A) : Colors.white)
                .withOpacity(0.85),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isDark ? const Color(0x1AFFFFFF) : const Color(0x1A000000),
              width: 0.5,
            ),
            boxShadow: const [
              BoxShadow(
                offset: Offset(0, 4),
                blurRadius: 24,
                color: Color(0x1A000000),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(0, Icons.map_outlined, 'Map'),
              const SizedBox(width: 8),
              _buildNavItem(1, Icons.local_gas_station_outlined, 'Stations'),
              const SizedBox(width: 8),
              _buildNavItem(2, Icons.settings_outlined, 'Settings'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = currentIndex == index;
    final activeColor = const Color(0xFF2563EB);
    final inactiveColor = const Color(0xFF8A8A8A);

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                AnimatedOpacity(
                  opacity: isActive ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: activeColor.withOpacity(0.10),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                if (isActive)
                  Icon(icon, size: 20, color: activeColor)
                      .animate()
                      .scale(
                        begin: const Offset(1.0, 1.0),
                        end: const Offset(1.18, 1.18),
                        duration: const Duration(milliseconds: 90),
                        curve: Curves.easeOutBack,
                      )
                      .then()
                      .scale(
                        begin: const Offset(1.18, 1.18),
                        end: const Offset(1.08, 1.08),
                        duration: const Duration(milliseconds: 90),
                        curve: Curves.easeOut,
                      )
                else
                  Icon(icon, size: 20, color: inactiveColor),
              ],
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w400,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
