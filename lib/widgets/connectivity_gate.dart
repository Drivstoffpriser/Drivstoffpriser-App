import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../config/app_text_styles.dart';

class ConnectivityGate extends StatefulWidget {
  final Widget child;

  const ConnectivityGate({super.key, required this.child});

  @override
  State<ConnectivityGate> createState() => _ConnectivityGateState();
}

class _ConnectivityGateState extends State<ConnectivityGate> {
  late final StreamSubscription<List<ConnectivityResult>> _subscription;
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _subscription = Connectivity().onConnectivityChanged.listen(_onChanged);
  }

  Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    _onChanged(results);
  }

  void _onChanged(List<ConnectivityResult> results) {
    final connected = results.any(
      (r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet,
    );
    if (mounted && connected != _isConnected) {
      setState(() => _isConnected = connected);
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [widget.child, if (!_isConnected) const _NoConnectionOverlay()],
    );
  }
}

class _NoConnectionOverlay extends StatelessWidget {
  const _NoConnectionOverlay();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: AppColors.background(context),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.wifi_off_rounded,
                    size: 80,
                    color: AppColors.textMuted(context),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Ingen internettilkobling',
                    style: AppTextStyles.heading(context),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'TankVenn krever en aktiv Wi-Fi- eller mobildata\u00ADtilkobling for å fungere. '
                    'Vennligst aktiver Wi-Fi eller mobildata i innstillingene og prøv igjen.',
                    style: AppTextStyles.body(
                      context,
                    ).copyWith(color: AppColors.textMuted(context)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: () async {
                      final results = await Connectivity().checkConnectivity();
                      final connected = results.any(
                        (r) =>
                            r == ConnectivityResult.wifi ||
                            r == ConnectivityResult.mobile ||
                            r == ConnectivityResult.ethernet,
                      );
                      if (context.mounted && !connected) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Fortsatt ingen tilkobling'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer(context),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Prøv igjen',
                        style: AppTextStyles.bodyMedium(
                          context,
                        ).copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
