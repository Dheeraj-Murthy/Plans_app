import 'package:flutter_test/flutter_test.dart';
import 'package:plans_app/shared/helpers/task_highlighter.dart';

void main() {
  group('TaskHighlighter', () {
    test('highlights p1', () {
      final tokens = TaskHighlighter.scan('p1 fix bug');
      expect(tokens.length, 1);
      expect(tokens[0].start, 0);
      expect(tokens[0].end, 2);
    });

    test('highlights @project', () {
      final tokens = TaskHighlighter.scan('meeting @work');
      expect(tokens.any((t) => t.start == 8 && t.end == 13), true);
    });

    test('highlights at 2', () {
      final tokens = TaskHighlighter.scan('do work at 2');
      expect(tokens.any((t) => t.start >= 7), true);
    });

    test('both at 2 highlighted with p1 and @hero', () {
      final text = 'work at 2 p1 @hero at 2';
      final tokens = TaskHighlighter.scan(text);

      // Should have 4 tokens: priority, project, and both "at 2"
      expect(tokens.length, 4);

      // Priority "p1"
      expect(tokens.any((t) => text.substring(t.start, t.end).trim() == 'p1'), true);

      // @hero
      expect(tokens.any((t) => text.substring(t.start, t.end) == '@hero'), true);

      // Both "at 2" occurrences
      final atTwo = tokens.where((t) => text.substring(t.start, t.end).trim() == 'at 2');
      expect(atTwo.length, 2);
    });

    test('highlights tomorrow', () {
      final tokens = TaskHighlighter.scan('do tomorrow');
      expect(tokens.any((t) => t.start == 3 && t.end == 11), true);
    });

    test('highlights in 5 min', () {
      final tokens = TaskHighlighter.scan('break in 5 min');
      expect(tokens.any((t) => t.start == 6 && t.end == 14), true);
    });

    test('highlights at 3.27', () {
      final tokens = TaskHighlighter.scan('meet at 3.27');
      expect(tokens.any((t) => t.start >= 5), true);
    });

    test('bare 3.27 not highlighted', () {
      final tokens = TaskHighlighter.scan('version 3.27');
      expect(tokens.where((t) => t.start >= 8).toList(), isEmpty);
    });

    test('no tokens for plain text', () {
      final tokens = TaskHighlighter.scan('just a task');
      expect(tokens, isEmpty);
    });

    test('single digit not highlighted', () {
      final tokens = TaskHighlighter.scan('step 1');
      expect(tokens.where((t) => t.start == 5), isEmpty);
    });

    test('in 2min (no space) highlighted', () {
      final tokens = TaskHighlighter.scan('break in 2min');
      expect(tokens.any((t) => t.start == 6), true);
    });
  });
}
