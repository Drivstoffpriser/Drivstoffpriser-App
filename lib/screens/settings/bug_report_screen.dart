import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

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

      // Gather device info
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
          const SnackBar(content: Text('Bug report submitted. Thank you!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to submit report: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report a Bug')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Found an issue? Let us know the details and we will look into it.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Brief summary of the issue',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'What happened? How can we reproduce it?',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _isSubmitting ? null : _submitReport,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Submit Report'),
            ),
            const SizedBox(height: 16),
            Text(
              'Technical information about your device and app version will be included automatically to help us debug.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
