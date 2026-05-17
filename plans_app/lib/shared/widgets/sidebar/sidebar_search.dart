import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_theme.dart';
import '../../../features/tasks/providers/task_provider.dart';

class SidebarSearch extends ConsumerStatefulWidget {
  const SidebarSearch({super.key});

  @override
  ConsumerState<SidebarSearch> createState() => _SidebarSearchState();
}

class _SidebarSearchState extends ConsumerState<SidebarSearch> {
  final _controller = TextEditingController();
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          _clear();
          node.unfocus();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
    );
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  void _clear() {
    _controller.clear();
    ref.read(searchQueryProvider.notifier).state = '';
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(searchFocusRequestProvider, (prev, _) => _focusNode.requestFocus());

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sidebarPadding,
        vertical: AppSpacing.sm,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _isFocused ? AppColors.accent : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.search_rounded,
              size: 15,
              color: _isFocused ? AppColors.accent : AppColors.textMuted,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search tasks...',
                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  suffixIcon: _controller.text.isNotEmpty
                      ? GestureDetector(
                          onTap: _clear,
                          child: const Icon(Icons.close_rounded, size: 14, color: AppColors.textMuted),
                        )
                      : null,
                ),
                onChanged: (val) {
                  ref.read(searchQueryProvider.notifier).state = val;
                  setState(() {});
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
