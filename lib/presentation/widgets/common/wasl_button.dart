import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class _ButtonDots extends StatefulWidget {
  final Color color;
  const _ButtonDots({required this.color});

  @override
  State<_ButtonDots> createState() => _ButtonDotsState();
}

class _ButtonDotsState extends State<_ButtonDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final offset = ((_ctrl.value * 3) - i) % 3;
          final opacity =
              offset < 1 ? offset : offset < 2 ? 1.0 : (3 - offset);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color
                  .withValues(alpha: opacity.clamp(0.2, 1.0)),
            ),
          );
        }),
      ),
    );
  }
}

enum WaslButtonVariant { primary, outline, ghost, danger }

class WaslButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final WaslButtonVariant variant;
  final double? width;
  final double height;

  const WaslButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.variant = WaslButtonVariant.primary,
    this.width,
    this.height = 56,
  });

  const WaslButton.outline({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 56,
  }) : variant = WaslButtonVariant.outline;

  const WaslButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 48,
  }) : variant = WaslButtonVariant.ghost;

  const WaslButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 56,
  }) : variant = WaslButtonVariant.danger;

  @override
  State<WaslButton> createState() => _WaslButtonState();
}

class _WaslButtonState extends State<WaslButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) {
    if (widget.onPressed != null && !widget.isLoading) _ctrl.reverse();
  }

  void _onTapUp(_) => _ctrl.forward();
  void _onTapCancel() => _ctrl.forward();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.isLoading ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: _buildButton(),
      ),
    );
  }

  Widget _buildButton() {
    final disabled = widget.onPressed == null || widget.isLoading;

    Color bg;
    Color fg;
    Border? border;
    List<BoxShadow>? shadows;

    switch (widget.variant) {
      case WaslButtonVariant.primary:
        bg = disabled ? AppColors.primary.withValues(alpha: 0.4) : AppColors.primary;
        fg = Colors.white;
        shadows = disabled
            ? null
            : [
                BoxShadow(
                  color: AppColors.primaryGlow,
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ];
      case WaslButtonVariant.outline:
        bg = Colors.transparent;
        fg = AppColors.primary;
        border = Border.all(color: AppColors.primary, width: 1.5);
      case WaslButtonVariant.ghost:
        bg = Colors.transparent;
        fg = AppColors.primary;
      case WaslButtonVariant.danger:
        bg = disabled ? AppColors.error.withValues(alpha: 0.4) : AppColors.error;
        fg = Colors.white;
    }

    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: border,
        boxShadow: shadows,
      ),
      child: Center(
        child: widget.isLoading
            ? _ButtonDots(color: fg)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: fg, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.label,
                    style: AppTextStyles.button.copyWith(color: fg),
                  ),
                ],
              ),
      ),
    );
  }
}
