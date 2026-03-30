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
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../l10n/l10n_helper.dart';
import '../../models/station_submission.dart';
import '../../services/firestore_service.dart';
import '../../widgets/brand_logo.dart';

class AdminSubmissionDetailScreen extends StatelessWidget {
  final StationSubmission submission;

  const AdminSubmissionDetailScreen({super.key, required this.submission});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tileUrl = isDark
        ? 'https://cartodb-basemaps-a.global.ssl.fastly.net/dark_all/{z}/{x}/{y}.png'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    final location = LatLng(submission.latitude, submission.longitude);

    return Scaffold(
      appBar: AppBar(
        title: Text(submission.name, style: AppTextStyles.title(context)),
        backgroundColor: AppColors.surface(context),
        elevation: 0,
      ),
      backgroundColor: AppColors.background(context),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).padding.bottom + 32,
        ),
        children: [
          // Map — tap to open in external map app
          GestureDetector(
            onTap: () {
              final uri = Uri.parse(
                'https://www.google.com/maps/search/?api=1&query=${submission.latitude},${submission.longitude}',
              );
              launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 220,
                child: AbsorbPointer(
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: location,
                      initialZoom: 17,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: tileUrl,
                        userAgentPackageName: 'com.example.fuel_price_tracker',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: location,
                            width: 40,
                            height: 40,
                            child: Icon(
                              Icons.location_pin,
                              color: AppColors.primaryContainer(context),
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Station info card
          Container(
            padding: const EdgeInsets.all(16),
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
                    BrandLogo(brand: submission.brand, radius: 22),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            submission.name,
                            style: AppTextStyles.title(context),
                          ),
                          Text(
                            submission.brand,
                            style: AppTextStyles.label(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _DetailRow(
                  icon: Icons.location_on_outlined,
                  label: context.l10n.addStationAddress,
                  value: submission.address.isNotEmpty
                      ? submission.address
                      : '—',
                ),
                const SizedBox(height: 10),
                _DetailRow(
                  icon: Icons.location_city_outlined,
                  label: context.l10n.addStationCity,
                  value: submission.city.isNotEmpty ? submission.city : '—',
                ),
                const SizedBox(height: 10),
                _DetailRow(
                  icon: Icons.my_location_outlined,
                  label: context.l10n.coordinates,
                  value:
                      '${submission.latitude.toStringAsFixed(5)}, '
                      '${submission.longitude.toStringAsFixed(5)}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Approve / Reject buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _reject(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.close, size: 18),
                  label: Text(context.l10n.reject),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _approve(context),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.check, size: 18),
                  label: Text(context.l10n.approve),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _approve(BuildContext context) async {
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
      submission,
      feedback: feedbackController.text.trim(),
    );
    feedbackController.dispose();
    if (context.mounted) Navigator.pop(context, true);
  }

  Future<void> _reject(BuildContext context) async {
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
      submission.id,
      feedback: feedbackController.text.trim(),
    );
    feedbackController.dispose();
    if (context.mounted) Navigator.pop(context, true);
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted(context)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.meta(context)),
              Text(value, style: AppTextStyles.body(context)),
            ],
          ),
        ),
      ],
    );
  }
}
