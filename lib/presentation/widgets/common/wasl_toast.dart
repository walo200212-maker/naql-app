import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

enum ToastType { success, error, warning, info }

class WaslToast {
  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final (color, glow, icon) = switch (type) {
      ToastType.success => (AppColors.success, AppColors.successGlow, Icons.check_circle_rounded),
      ToastType.error   => (AppColors.error,   AppColors.errorGlow,   Icons.error_rounded),
      ToastType.warning => (AppColors.warning,  AppColors.primaryGlow, Icons.warning_rounded),
      ToastType.info    => (AppColors.info,      AppColors.primaryGlow, Icons.info_rounded),
    };

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: duration,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
            boxShadow: [
              BoxShadow(color: glow, blurRadius: 20, spreadRadius: 0),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(message,
                    style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
