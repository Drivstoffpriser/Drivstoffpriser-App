/*
* A crowdsourced platform for real-time fuel price monitoring in Norway
* Copyright (C) 2026  Tsotne Karchava & Contributors
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_colors.dart';
import '../config/app_text_styles.dart';
import '../l10n/l10n_helper.dart';

const _onboardingSeenKey = 'onboarding_seen';

Future<void> showOnboardingIfNeeded(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(_onboardingSeenKey) ?? false) return;
  if (!context.mounted) return;

  bool dontShowAgain = false;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return _OnboardingDialog(
        requireDismiss: true,
        onDontShowAgainChanged: (value) => dontShowAgain = value,
      );
    },
  );

  if (dontShowAgain) {
    await prefs.setBool(_onboardingSeenKey, true);
  }
}

Future<void> showOnboarding(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (context) {
      return const _OnboardingDialog(requireDismiss: false);
    },
  );
}

class _OnboardingDialog extends StatefulWidget {
  final bool requireDismiss;
  final ValueChanged<bool>? onDontShowAgainChanged;

  const _OnboardingDialog({
    required this.requireDismiss,
    this.onDontShowAgainChanged,
  });

  @override
  State<_OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends State<_OnboardingDialog> {
  final _controller = PageController();
  int _currentPage = 0;
  bool _dontShowAgain = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tips = [
      (
        title: l10n.onboardingRadiusTitle,
        body: l10n.onboardingRadiusBody,
        image: 'assets/tips/radius_tip.jpeg',
      ),
      (
        title: l10n.onboardingAddStationTitle,
        body: l10n.onboardingAddStationBody,
        image: 'assets/tips/add_station_tip.jpeg',
      ),
      (
        title: l10n.onboardingEditStationTitle,
        body: l10n.onboardingEditStationBody,
        image: 'assets/tips/edit_station_tip.jpeg',
      ),
    ];

    final isLastPage = _currentPage == tips.length - 1;

    return AlertDialog(
      title: Text(
        _currentPage == 0 ? l10n.onboardingTitle : tips[_currentPage].title,
        style: AppTextStyles.heading(context).copyWith(fontSize: 20),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: tips.length,
                itemBuilder: (context, index) {
                  final tip = tips[index];
                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_currentPage != 0 || index != 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              tip.body,
                              style: AppTextStyles.body(context),
                            ),
                          )
                        else ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              tip.body,
                              style: AppTextStyles.body(context),
                            ),
                          ),
                        ],
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(tip.image, fit: BoxFit.contain),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                tips.length,
                (i) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _currentPage
                        ? AppColors.primaryContainer(context)
                        : AppColors.textMuted(context).withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.onboardingStepOf(_currentPage + 1, tips.length),
              style: AppTextStyles.meta(context),
            ),
          ],
        ),
      ),
      actions: [
        if (isLastPage && widget.requireDismiss)
          Row(
            children: [
              Checkbox(
                value: _dontShowAgain,
                onChanged: (value) {
                  setState(() => _dontShowAgain = value ?? false);
                  widget.onDontShowAgainChanged?.call(_dontShowAgain);
                },
              ),
              Flexible(child: Text(l10n.dontShowAgain)),
            ],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (isLastPage)
              FilledButton(
                onPressed: !widget.requireDismiss || _dontShowAgain
                    ? () => Navigator.pop(context)
                    : null,
                child: Text(l10n.gotIt),
              )
            else
              FilledButton(
                onPressed: () {
                  _controller.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Text(l10n.onboardingNext),
              ),
          ],
        ),
      ],
    );
  }
}
