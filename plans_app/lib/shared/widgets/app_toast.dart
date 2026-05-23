import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_typography.dart';

OverlayEntry? _currentEntry;
Timer? _currentTimer;

void showAppToast({
  required BuildContext context,
  required String message,
  required String actionLabel,
  required VoidCallback onAction,
  Duration duration = const Duration(seconds: 5),
}) {
  _currentEntry?.remove();
  _currentTimer?.cancel();

  final overlay = Overlay.of(context);

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _ToastBar(
      message: message,
      actionLabel: actionLabel,
      onAction: () {
        onAction();
        entry.remove();
        _currentTimer?.cancel();
        if (_currentEntry == entry) _currentEntry = null;
      },
      onDismiss: () {
        entry.remove();
        _currentTimer?.cancel();
        if (_currentEntry == entry) _currentEntry = null;
      },
    ),
  );

  _currentEntry = entry;
  overlay.insert(entry);
  _currentTimer = Timer(duration, () {
    entry.remove();
    if (_currentEntry == entry) _currentEntry = null;
  });
}

class _ToastBar extends StatefulWidget {
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final VoidCallback onDismiss;

  const _ToastBar({
    required this.message,
    required this.actionLabel,
    required this.onAction,
    required this.onDismiss,
  });

  @override
  State<_ToastBar> createState() => _ToastBarState();
}

class _ToastBarState extends State<_ToastBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24,
      left: 24,
      right: 24,
      child: SlideTransition(
        position: _slide,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.elevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.message,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: widget.onAction,
                  child: Text(
                    widget.actionLabel,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.accent,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: widget.onDismiss,
                  child: const Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
