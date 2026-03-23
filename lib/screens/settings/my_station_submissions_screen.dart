import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../config/routes.dart';
import '../../l10n/l10n_helper.dart';
import '../../models/station_submission.dart';
import '../../providers/user_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/brand_logo.dart';

class MyStationSubmissionsScreen extends StatefulWidget {
  const MyStationSubmissionsScreen({super.key});

  @override
  State<MyStationSubmissionsScreen> createState() =>
      _MyStationSubmissionsScreenState();
}

class _MyStationSubmissionsScreenState
    extends State<MyStationSubmissionsScreen> {
  List<StationSubmission>? _submissions;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = context.read<UserProvider>().user.id;
    final submissions = await FirestoreService.getUserStationSubmissions(uid);
    if (!mounted) return;
    setState(() {
      _submissions = submissions;
      _isLoading = false;
    });
  }

  Future<void> _editSubmission(StationSubmission sub) async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.addStation,
      arguments: sub,
    );
    if (result == true) _load();
  }

  Future<void> _deleteSubmission(StationSubmission sub) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          context.l10n.deleteSubmissionTitle,
          style: AppTextStyles.title(context),
        ),
        content: Text(
          context.l10n.deleteSubmissionBody,
          style: AppTextStyles.body(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await FirestoreService.deleteStationSubmission(sub.id);
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.myStationSubmissions,
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
                    context.l10n.noSubmissionsYet,
                    style: AppTextStyles.label(context),
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    16, 16, 16,
                    MediaQuery.of(context).padding.bottom + 16,
                  ),
                  itemCount: _submissions!.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final sub = _submissions![index];
                    return _SubmissionCard(
                      submission: sub,
                      onFeedbackRead: () async {
                        await FirestoreService.markFeedbackRead(sub.id);
                        _load();
                      },
                      onEdit: sub.status == SubmissionStatus.pending
                          ? () => _editSubmission(sub)
                          : null,
                      onDelete: sub.status == SubmissionStatus.pending
                          ? () => _deleteSubmission(sub)
                          : null,
                    );
                  },
                ),
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  final StationSubmission submission;
  final VoidCallback onFeedbackRead;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _SubmissionCard({
    required this.submission,
    required this.onFeedbackRead,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final (Color color, String label, IconData icon) = switch (submission.status) {
      SubmissionStatus.pending => (
          Colors.orange,
          context.l10n.submissionStatusPending,
          Icons.schedule,
        ),
      SubmissionStatus.approved => (
          Colors.green,
          context.l10n.submissionStatusApproved,
          Icons.check_circle,
        ),
      SubmissionStatus.rejected => (
          Colors.red,
          context.l10n.submissionStatusRejected,
          Icons.cancel,
        ),
    };

    final hasFeedback =
        submission.feedback != null && submission.feedback!.isNotEmpty;

    return Container(
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
              BrandLogo(brand: submission.brand, radius: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      submission.name,
                      style: AppTextStyles.bodyMedium(context),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (submission.address.isNotEmpty ||
                        submission.city.isNotEmpty)
                      Text(
                        [submission.address, submission.city]
                            .where((s) => s.isNotEmpty)
                            .join(', '),
                        style: AppTextStyles.meta(context),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 14, color: color),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: AppTextStyles.meta(context).copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasFeedback) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceLow(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.adminFeedback,
                    style: AppTextStyles.labelBold(context),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    submission.feedback!,
                    style: AppTextStyles.body(context),
                  ),
                ],
              ),
            ),
            if (!submission.feedbackRead) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onFeedbackRead,
                  icon: const Icon(Icons.done, size: 16),
                  label: Text(context.l10n.dismiss),
                ),
              ),
            ],
          ],
          // Edit / Delete actions for pending submissions
          if (onEdit != null || onDelete != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onEdit != null)
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: Text(context.l10n.edit),
                  ),
                if (onDelete != null)
                  TextButton.icon(
                    onPressed: onDelete,
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: Text(context.l10n.delete),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
