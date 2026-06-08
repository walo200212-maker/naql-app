import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = _resolve(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  (String, Color) _resolve(String s) => switch (s) {
        AppConstants.jobStatusOpen => ('Disponible', AppColors.statusOpen),
        AppConstants.jobStatusMatched => ('Attribué', AppColors.statusInProgress),
        AppConstants.jobStatusInProgress => ('En cours', AppColors.statusInProgress),
        AppConstants.jobStatusCompleted => ('Terminé', AppColors.statusCompleted),
        AppConstants.jobStatusCancelled => ('Annulé', AppColors.statusBlocked),
        'confirmed' => ('Confirmé', AppColors.statusOpen),
        'pending' => ('En attente', AppColors.warning),
        _ => (s, AppColors.textSecondary),
      };
}
