import 'package:flutter/material.dart';
import '../helpers/task_highlighter.dart';

class HighlightedTaskController extends TextEditingController {
  HighlightedTaskController({super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final nodes = TaskHighlighter.scan(text);
    if (nodes.isEmpty || text.isEmpty) {
      return TextSpan(text: text, style: style);
    }

    final children = <InlineSpan>[];
    var cursor = 0;

    for (final node in nodes) {
      if (node.start > cursor) {
        children.add(TextSpan(
          text: text.substring(cursor, node.start),
          style: style,
        ));
      }
      children.add(TextSpan(
        text: text.substring(node.start, node.end),
        style: style?.copyWith(
          color: node.color,
        ),
      ));
      cursor = node.end;
    }

    if (cursor < text.length) {
      children.add(TextSpan(text: text.substring(cursor), style: style));
    }

    return TextSpan(children: children, style: style);
  }
}
