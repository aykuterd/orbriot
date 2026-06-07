import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class NeonButton extends StatefulWidget {
  const NeonButton({
    super.key,
    required this.label,
    this.onTap,
    this.color = AppColors.primary,
    this.glowColor = AppColors.glowPrimary,
    this.outlined = false,
    this.icon,
    this.disabled = false,
  });

  final String label;
  final VoidCallback? onTap;
  final Color color;
  final Color glowColor;
  final bool outlined;
  final IconData? icon;
  final bool disabled;

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _isDisabled => widget.disabled || widget.onTap == null;

  void _onTapDown(_) {
    if (_isDisabled) return;
    _ctrl.forward();
  }

  void _onTapUp(_) {
    if (_isDisabled) return;
    _ctrl.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    final disabled = _isDisabled;
    final fgColor = disabled
        ? AppColors.muted.withAlpha(100)
        : AppColors.foreground;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: AnimatedOpacity(
          opacity: disabled ? 0.4 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: widget.outlined
                  ? Colors.transparent
                  : disabled
                      ? AppColors.surface
                      : widget.color,
              borderRadius: BorderRadius.circular(8),
              border: widget.outlined
                  ? Border.all(color: AppColors.border, width: 1.5)
                  : Border.all(
                      color: disabled
                          ? AppColors.border.withAlpha(60)
                          : widget.color.withAlpha(80),
                      width: 1,
                    ),
              boxShadow: (widget.outlined || disabled)
                  ? null
                  : [
                      BoxShadow(
                        color: widget.glowColor,
                        blurRadius: 18,
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: widget.color.withAlpha(40),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: fgColor, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(widget.label,
                    style: AppTextStyles.button.copyWith(color: fgColor)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
