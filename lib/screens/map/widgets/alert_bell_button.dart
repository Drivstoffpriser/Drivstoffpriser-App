import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/routes.dart';
import '../../../providers/alert_provider.dart';
import '../../../providers/user_provider.dart';
import 'create_alert_dialog.dart';

class AlertBellButton extends StatelessWidget {
  const AlertBellButton({super.key});

  @override
  Widget build(BuildContext context) {
    final alertProvider = context.watch<AlertProvider>();
    final hasActive = alertProvider.hasActiveAlerts;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        FloatingActionButton.small(
          heroTag: 'alertBell',
          onPressed: () => _onTap(context),
          child: const Icon(Icons.notifications_outlined),
        ),
        if (hasActive)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _onTap(BuildContext context) {
    final userProvider = context.read<UserProvider>();
    if (!userProvider.isAuthenticated) {
      Navigator.pushNamed(context, AppRoutes.auth);
      return;
    }

    showDialog(
      context: context,
      builder: (_) => const CreateAlertDialog(),
    );
  }
}
