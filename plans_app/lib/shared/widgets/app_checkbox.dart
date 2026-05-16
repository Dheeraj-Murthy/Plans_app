import 'package:flutter/material.dart';
import '../../theme/app_animations.dart';
import '../../theme/app_theme.dart';

class AppCheckbox extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final double size;

  const AppCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 18,
  });

  @override
  State<AppCheckbox> createState() => _AppCheckboxState();
}

class _AppCheckboxState extends State<AppCheckbox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.normal,
    );
    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.fastOutSlowIn,
    );
    if (widget.value) {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(AppCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (widget.value) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    widget.onChanged(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: AppAnimations.normal,
        curve: AppAnimations.easeOut,
        width: s,
        height: s,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.value ? AppColors.accent : Colors.transparent,
          border: Border.all(
            color: widget.value ? AppColors.accent : AppColors.textMuted,
            width: 2,
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _scaleAnim,
            builder: (context, child) {
              return Opacity(
                opacity: _controller.value,
                child: Transform.scale(
                  scale: _scaleAnim.value,
                  child: child,
                ),
              );
            },
            child: Icon(
              Icons.check,
              size: s * 0.6,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
