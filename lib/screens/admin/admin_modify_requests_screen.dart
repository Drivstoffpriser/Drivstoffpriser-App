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
import '../../models/station_modify_request.dart';
import '../../services/firestore_service.dart';
import '../../widgets/proposed_logo_preview.dart';

class AdminModifyRequestsScreen extends StatefulWidget {
  const AdminModifyRequestsScreen({super.key});

  @override
  State<AdminModifyRequestsScreen> createState() =>
      _AdminModifyRequestsScreenState();
}

class _AdminModifyRequestsScreenState extends State<AdminModifyRequestsScreen> {
  List<StationModifyRequest>? _requests;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final requests = await FirestoreService.getAllPendingModifyRequests();
    if (!mounted) return;
    setState(() {
      _requests = requests;
      _isLoading = false;
    });
  }

  Future<void> _approve(StationModifyRequest req) async {
    final feedbackController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.approveStationTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.approveModifyBody),
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
    await FirestoreService.approveModifyRequest(
      req,
      feedback: feedbackController.text.trim(),
    );
    feedbackController.dispose();
    if (mounted) _load();
  }

  Future<void> _reject(StationModifyRequest req) async {
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
    await FirestoreService.rejectModifyRequest(
      req.id,
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
          context.l10n.modifyRequests,
          style: AppTextStyles.title(context),
        ),
        backgroundColor: AppColors.surface(context),
        elevation: 0,
      ),
      backgroundColor: AppColors.background(context),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests == null || _requests!.isEmpty
          ? Center(
              child: Text(
                context.l10n.noPendingModifyRequests,
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
              itemCount: _requests!.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final req = _requests![index];
                return _DiffCard(
                  request: req,
                  onApprove: () => _approve(req),
                  onReject: () => _reject(req),
                );
              },
            ),
    );
  }
}

class _DiffCard extends StatelessWidget {
  final StationModifyRequest request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _DiffCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
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
          Text(request.originalName, style: AppTextStyles.bodyMedium(context)),
          Text(
            context.l10n.stationId(request.stationId),
            style: AppTextStyles.meta(context),
          ),
          const SizedBox(height: 12),

          // Diff rows — only show fields that changed
          if (request.nameChanged)
            _DiffRow(
              label: context.l10n.addStationName,
              oldValue: request.originalName,
              newValue: request.proposedName,
            ),
          if (request.brandChanged)
            _DiffRow(
              label: context.l10n.addStationBrand,
              oldValue: request.originalBrand,
              newValue: request.proposedBrand,
            ),
          if (request.addressChanged)
            _DiffRow(
              label: context.l10n.addStationAddress,
              oldValue: request.originalAddress,
              newValue: request.proposedAddress,
            ),
          if (request.cityChanged)
            _DiffRow(
              label: context.l10n.addStationCity,
              oldValue: request.originalCity,
              newValue: request.proposedCity,
            ),
          if (request.locationChanged)
            _DiffRow(
              label: context.l10n.coordinates,
              oldValue:
                  '${request.originalLatitude.toStringAsFixed(5)}, ${request.originalLongitude.toStringAsFixed(5)}',
              newValue:
                  '${request.proposedLatitude.toStringAsFixed(5)}, ${request.proposedLongitude.toStringAsFixed(5)}',
            ),
          if (request.logoChanged)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ProposedLogoPreview(
                logoUrl: request.proposedLogoUrl!,
                brand: request.proposedBrand,
              ),
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
    );
  }
}

class _DiffRow extends StatelessWidget {
  final String label;
  final String oldValue;
  final String newValue;

  const _DiffRow({
    required this.label,
    required this.oldValue,
    required this.newValue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.labelBold(context)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(6),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '− ',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Expanded(
                  child: Text(
                    oldValue,
                    style: AppTextStyles.body(context).copyWith(
                      color: Colors.red,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(6),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '+ ',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Expanded(
                  child: Text(
                    newValue,
                    style: AppTextStyles.body(
                      context,
                    ).copyWith(color: Colors.green),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
