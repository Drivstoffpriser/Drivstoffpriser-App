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

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../l10n/l10n_helper.dart';
import '../../models/station_submission.dart';
import '../../services/firestore_service.dart';
import '../../widgets/brand_logo.dart';
import 'admin_submission_detail_screen.dart';

class AdminSubmissionsScreen extends StatefulWidget {
  const AdminSubmissionsScreen({super.key});

  @override
  State<AdminSubmissionsScreen> createState() => _AdminSubmissionsScreenState();
}

class _AdminSubmissionsScreenState extends State<AdminSubmissionsScreen> {
  List<StationSubmission>? _submissions;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final submissions = await FirestoreService.getAllPendingSubmissions();
    if (!mounted) return;
    setState(() {
      _submissions = submissions;
      _isLoading = false;
    });
  }

  Future<void> _approve(StationSubmission sub) async {
    final feedbackController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.approveStationTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.approveStationBody),
            const SizedBox(height: 12),
            TextField(
              controller: feedbackController,
              decoration: InputDecoration(
                hintText: context.l10n.adminFeedbackHint,
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.approve),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await FirestoreService.approveStation(
      sub,
      feedback: feedbackController.text.trim(),
    );
    feedbackController.dispose();
    if (mounted) _load();
  }

  Future<void> _reject(StationSubmission sub) async {
    final feedbackController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.rejectStationTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.rejectStationBody),
            const SizedBox(height: 12),
            TextField(
              controller: feedbackController,
              decoration: InputDecoration(
                hintText: context.l10n.adminFeedbackHint,
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(context.l10n.reject),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await FirestoreService.rejectStation(
      sub.id,
      feedback: feedbackController.text.trim(),
    );
    feedbackController.dispose();
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.adminPanel,
          style: AppTextStyles.title(context),
        ),
        backgroundColor: AppColors.surface(context),
        elevation: 0,
      ),
      backgroundColor: AppColors.background(context),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _submissions == null || _submissions!.isEmpty
          ? Center(
              child: Text(
                context.l10n.noPendingSubmissions,
                style: AppTextStyles.label(context),
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              itemCount: _submissions!.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final sub = _submissions![index];
                return _AdminSubmissionCard(
                  submission: sub,
                  onApprove: () => _approve(sub),
                  onReject: () => _reject(sub),
                  onTap: () async {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AdminSubmissionDetailScreen(submission: sub),
                      ),
                    );
                    if (result == true) _load();
                  },
                );
              },
            ),
    );
  }
}

class _AdminSubmissionCard extends StatelessWidget {
  final StationSubmission submission;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onTap;

  const _AdminSubmissionCard({
    required this.submission,
    required this.onApprove,
    required this.onReject,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border(context), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                BrandLogo(
                  brand: submission.brand,
                  radius: 18,
                  logoUrl: submission.logoUrl,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        submission.name,
                        style: AppTextStyles.bodyMedium(context),
                      ),
                      Text(
                        '${submission.brand} — ${submission.city}',
                        style: AppTextStyles.meta(context),
                      ),
                      if (submission.address.isNotEmpty)
                        Text(
                          submission.address,
                          style: AppTextStyles.meta(context),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onReject,
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  icon: const Icon(Icons.close, size: 18),
                  label: Text(context.l10n.reject),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check, size: 18),
                  label: Text(context.l10n.approve),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
