import 'package:flutter/material.dart';
import 'package:legalai_frontend/l10n/app_localizations.dart';
import '../../../../core/theme/app_palette.dart';
import '../../domain/models/lawyer_model.dart';
import '../../../../core/layout/app_responsive.dart';

class LawyerDetailScreen extends StatelessWidget {
  final Lawyer lawyer;
  const LawyerDetailScreen({super.key, required this.lawyer});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.lawyerDetails)),
      body: SingleChildScrollView(
        padding: AppResponsive.pagePadding(context),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(AppResponsive.spacing(context, 16)),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: AppResponsive.spacing(context, 44),
                      backgroundImage: lawyer.imageUrl != null ? NetworkImage(lawyer.imageUrl!) : null,
                      child: lawyer.imageUrl == null ? Text(lawyer.name.isNotEmpty ? lawyer.name[0] : 'L') : null,
                    ),
                    SizedBox(width: AppResponsive.spacing(context, 16)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lawyer.name,
                            style: TextStyle(
                              fontSize: AppResponsive.font(context, 20),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: AppResponsive.spacing(context, 6)),
                          Text(lawyer.specialization, style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: AppResponsive.spacing(context, 16)),
            Card(
              child: Padding(
                padding: EdgeInsets.all(AppResponsive.spacing(context, 16)),
                child: Column(
                  children: [
                    _InfoRow(label: l10n.email, value: lawyer.email),
                    _InfoRow(label: l10n.phone, value: lawyer.phone ?? l10n.notAvailable),
                    _InfoRow(label: l10n.category, value: lawyer.specialization),
                  ],
                ),
              ),
            ),
            if (lawyer.bio != null && lawyer.bio!.trim().isNotEmpty) ...[
              SizedBox(height: AppResponsive.spacing(context, 16)),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(AppResponsive.spacing(context, 16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.bio, style: TextStyle(color: AppPalette.primary, fontWeight: FontWeight.bold)),
                      SizedBox(height: AppResponsive.spacing(context, 8)),
                      Text(lawyer.bio!),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppResponsive.spacing(context, 12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: AppResponsive.spacing(context, 100),
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
