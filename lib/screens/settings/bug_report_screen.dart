import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../l10n/l10n_helper.dart';
import '../../models/bug_report.dart';
import '../../providers/user_provider.dart';
import '../../services/firestore_service.dart';

class BugReportScreen extends StatefulWidget {
  const BugReportScreen({super.key});

  @override
  State<BugReportScreen> createState() => _BugReportScreenState();
}

class _BugReportScreenState extends State<BugReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final userProvider = context.read<UserProvider>();
      final userId = userProvider.isAuthenticated
          ? userProvider.user.id
          : 'anonymous';

      final deviceInfo = DeviceInfoPlugin();
      String deviceName = 'unknown';
      String osVersion = 'unknown';

      if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        deviceName = webInfo.browserName.toString();
        osVersion = webInfo.platform ?? 'web';
      } else {
        switch (defaultTargetPlatform) {
          case TargetPlatform.android:
            final androidInfo = await deviceInfo.androidInfo;
            deviceName = '${androidInfo.manufacturer} ${androidInfo.model}';
            osVersion = 'Android ${androidInfo.version.release}';
            break;
          case TargetPlatform.iOS:
            final iosInfo = await deviceInfo.iosInfo;
            deviceName = iosInfo.name;
            osVersion = 'iOS ${iosInfo.systemVersion}';
            break;
          default:
            deviceName = 'unknown';
            osVersion = defaultTargetPlatform.toString();
        }
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

      final report = BugReport(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        timestamp: DateTime.now(),
        userId: userId,
        deviceName: deviceName,
        osVersion: osVersion,
        appVersion: appVersion,
      );

      await FirestoreService.submitBugReport(report);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.bugReportSubmitted)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.bugReportFailed(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        surfaceTintColor: Colors.transparent,
        title: Text(context.l10n.bugReportTitle, style: AppTextStyles.title(context)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              context.l10n.bugReportIntro,
              style: AppTextStyles.body(context),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              style: AppTextStyles.body(context),
              decoration: InputDecoration(
                labelText: context.l10n.title,
                hintText: context.l10n.briefSummary,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return context.l10n.pleaseEnterTitle;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              style: AppTextStyles.body(context),
              decoration: InputDecoration(
                labelText: context.l10n.description,
                hintText: context.l10n.whatHappened,
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return context.l10n.pleaseEnterDescription;
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: _isSubmitting ? null : _submitReport,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          context.l10n.submitReportButton,
                          style: AppTextStyles.bodyMedium(
                            context,
                          ).copyWith(color: Colors.white),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.technicalInfo,
              style: AppTextStyles.meta(context),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
