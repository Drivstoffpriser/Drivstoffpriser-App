import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
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

    final isDark = context.read<UserProvider>().isDarkMode;
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
          SnackBar(
            content: Text('Report submitted. Thanks!', style: AppTextStyles.label(isDark).copyWith(color: Colors.white)),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission failed: $e', style: AppTextStyles.label(isDark).copyWith(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<UserProvider>().isDarkMode;

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        title: Text('Report a Bug', style: AppTextStyles.heading(isDark)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            children: [
              Text(
                'Found an issue?',
                style: AppTextStyles.heading(isDark).copyWith(fontSize: 24),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Help us improve by providing details about the problem.',
                style: AppTextStyles.body(isDark).copyWith(color: AppColors.textMuted(isDark)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _ReportTextField(
                controller: _titleController,
                label: 'Title',
                hint: 'Brief summary',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
              ),
              const SizedBox(height: 24),
              _ReportTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'What happened? How can we reproduce it?',
                maxLines: 6,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a description' : null,
              ),
              const SizedBox(height: 48),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'Submit Report',
                          style: AppTextStyles.body(isDark).copyWith(fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface(isDark),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border(isDark)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 20, color: AppColors.textMuted(isDark)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Technical info about your device will be included automatically.',
                        style: AppTextStyles.label(isDark).copyWith(color: AppColors.textMuted(isDark)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final String? Function(String?)? validator;

  const _ReportTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<UserProvider>().isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: AppTextStyles.label(isDark).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(isDark).withOpacity(0.8),
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          style: AppTextStyles.body(isDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.body(isDark).copyWith(color: AppColors.textMuted(isDark)),
            filled: true,
            fillColor: AppColors.surface(isDark),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border(isDark)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border(isDark)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.accent, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }
}
