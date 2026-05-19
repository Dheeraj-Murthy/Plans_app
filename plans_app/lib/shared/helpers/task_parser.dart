import '../../features/tasks/models/task.dart';
import '../../features/projects/models/project.dart';

class TaskParseResult {
  final String title;
  final TaskPriority? priority;
  final String? projectId;
  final DateTime? dueDate;
  final bool hasDueDate;
  final int? defaultReminderMinutes;

  TaskParseResult({
    required this.title,
    this.priority,
    this.projectId,
    this.dueDate,
    this.hasDueDate = false,
    this.defaultReminderMinutes,
  });
}

class TaskParser {
  static TaskParseResult parse(
    String input,
    List<Project> projects, {
    DateTime? now,
  }) {
    final nowDt = now ?? DateTime.now();
    var text = input.trim();
    if (text.isEmpty) {
      return TaskParseResult(title: input);
    }

    TaskPriority? priority;
    String? projectId;
    DateTime? dueDate;
    bool hasDueDate = false;

    text = _extractPriority(text, (p) => priority = p);
    text = _extractProject(text, projects, (id) => projectId = id);

    final dateTimeResult = _extractDateTime(text, nowDt);
    text = dateTimeResult.remaining;
    if (dateTimeResult.dueDate != null) {
      dueDate = dateTimeResult.dueDate;
      hasDueDate = true;
    }

    final title = text.trim().isEmpty ? input.trim() : text.trim();

    return TaskParseResult(
      title: title,
      priority: priority,
      projectId: projectId,
      dueDate: dueDate,
      hasDueDate: hasDueDate,
      defaultReminderMinutes: hasDueDate ? 0 : null,
    );
  }

  // ── Priority ────────────────────────────────────────────────────────

  static String _extractPriority(
    String text,
    void Function(TaskPriority) set,
  ) {
    final m = RegExp(
      r'(?:^|\s)(p[1234]|!(?:high|medium|low|none))(?=\s|$)',
      caseSensitive: false,
    ).firstMatch(text);
    if (m == null) return text;

    final setPriority = switch (m.group(1)!.toLowerCase()) {
      'p1' || '!high' => TaskPriority.high,
      'p2' || '!medium' => TaskPriority.medium,
      'p3' || '!low' => TaskPriority.low,
      _ => TaskPriority.none,
    };
    set(setPriority);
    return text.replaceFirst(m.group(0)!, '').trim();
  }

  // ── Project ─────────────────────────────────────────────────────────

  static String _extractProject(
    String text,
    List<Project> projects,
    void Function(String) set,
  ) {
    if (projects.isEmpty) return text;
    final m = RegExp(r'@(\w+)', caseSensitive: false).firstMatch(text);
    if (m == null) return text;

    final matched = projects.where(
      (p) => p.name.toLowerCase() == m.group(1)!.toLowerCase(),
    );
    if (matched.isEmpty) return text;

    set(matched.first.id);
    return text.replaceFirst(m.group(0)!, '').trim();
  }

  // ── Date / Time ─────────────────────────────────────────────────────

  static _DateTimeResult _extractDateTime(String text, DateTime now) {
    var remaining = text;

    // Extract sequentially so each operates on updated remaining text.
    final timeInfo = _extractTime(remaining);
    if (timeInfo != null) {
      remaining = timeInfo.remaining;
    }

    final dateInfo = _extractDate(remaining, now);
    if (dateInfo != null) {
      remaining = dateInfo.remaining;
    }

    DateTime? dueDate;

    if (timeInfo != null && dateInfo != null) {
      dueDate = _combineTimeAndDate(
        timeInfo.hour,
        timeInfo.minute,
        timeInfo.isPm,
        dateInfo.date,
        now,
      );
    } else if (timeInfo != null) {
      dueDate = _resolveTime(timeInfo.hour, timeInfo.minute, timeInfo.isPm, now);
    } else if (dateInfo != null) {
      dueDate = dateInfo.preserveTime
          ? dateInfo.date
          : _sameTime(dateInfo.date, now);
    }

    return _DateTimeResult(remaining: remaining, dueDate: dueDate);
  }

  static _TimeInfo? _extractTime(String text) {
    final m = RegExp(
      r'(?:at\s+)?\b(\d{1,2})([:.](\d{2}))?\s*(am|pm)?\b',
      caseSensitive: false,
    ).firstMatch(text);
    if (m == null) return null;

    // Bare number without "at", ":MM", or "am/pm" → not a time
    final full = m.group(0)!.toLowerCase();
    final hasAt = full.startsWith('at ');
    final hasMinute = m.group(2) != null;
    final hasAmPm = m.group(4) != null;
    if (!hasAt && !hasMinute && !hasAmPm) return null;

    // Decimal "." separator requires "at" prefix
    if (full.contains('.') && !hasAt) return null;

    final hour = int.parse(m.group(1)!);
    final minute = m.group(2) != null ? int.parse(m.group(3)!) : 0;
    if (minute < 0 || minute > 59) return null;

    final ap = m.group(4)?.toLowerCase();
    bool? isPm;
    if (ap == 'pm') {
      isPm = true;
    } else if (ap == 'am') {
      isPm = false;
    }

    return _TimeInfo(
      remaining: text.replaceFirst(m.group(0)!, '').trim(),
      hour: hour,
      minute: minute,
      isPm: isPm,
    );
  }

  static _DateInfo? _extractDate(String text, DateTime now) {
    final m = RegExp(
      r'\b(?:'
      r'today|tomorrow|tom|tmr|'
      r'in\s+(?:(\d+)|a(?:n)?)\s*'
      r'(min|mins|minute|minutes|hour|hours|hr|hrs|day|days|week|weeks|month|months)|'
      r'next\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)|'
      r'(monday|tuesday|wednesday|thursday|friday|saturday|sunday)'
      r')\b',
      caseSensitive: false,
    ).firstMatch(text);
    if (m == null) return null;

    final keyword = m.group(0)!.toLowerCase();
    DateTime date;

    if (keyword == 'today') {
      date = now;
    } else if (keyword == 'tomorrow' || keyword == 'tom' || keyword == 'tmr') {
      date = now.add(const Duration(days: 1));
    } else if (keyword.startsWith('in ')) {
      final amount = m.group(1) != null ? int.parse(m.group(1)!) : 1;
      final unit = m.group(2)!.toLowerCase();
      switch (unit) {
        case 'min' || 'mins' || 'minute' || 'minutes':
          date = now.add(Duration(minutes: amount));
        case 'hour' || 'hours' || 'hr' || 'hrs':
          date = now.add(Duration(hours: amount));
        case 'day' || 'days':
          date = now.add(Duration(days: amount));
        case 'week' || 'weeks':
          date = now.add(Duration(days: amount * 7));
        case 'month' || 'months':
          date = now.add(Duration(days: amount * 30));
        default:
          date = now;
      }
    } else {
      final skipToday = keyword.startsWith('next ');
      final dayName = skipToday ? keyword.substring(5) : keyword;
      final target = _dayIndex(dayName);
      if (target == null) return null;
      date = _nextWeekday(now, target, skipToday: skipToday);
    }

    final isTimeRelative = keyword.startsWith('in ') &&
        switch (m.group(2)!.toLowerCase()) {
          'min' || 'mins' || 'minute' || 'minutes' || 'hour' || 'hours' || 'hr' || 'hrs' => true,
          _ => false,
        };

    return _DateInfo(
      remaining: text.replaceFirst(m.group(0)!, '').trim(),
      date: date,
      isToday: keyword == 'today',
      preserveTime: isTimeRelative,
    );
  }

  /// Combine parsed time with parsed date.
  ///
  /// Rules:
  ///   - Explicit am/pm → use that time on the date.
  ///   - Ambiguous time + "today" → next-occurrence from now.
  ///   - Ambiguous time + non-today date → default to AM.
  static DateTime _combineTimeAndDate(
    int hour,
    int minute,
    bool? isPm,
    DateTime date,
    DateTime now,
  ) {
    if (isPm != null) {
      final h = _to24Hour(hour, isPm);
      return DateTime(date.year, date.month, date.day, h, minute);
    }

    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;

    if (isToday) {
      return _resolveTime(hour, minute, null, now);
    }

    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  /// Resolve ambiguous time to next occurrence from [now].
  ///
  ///  "7" @ 2pm → 7pm today.  "7" @ 10pm → 7am tomorrow.
  ///  "12" → noon first, then midnight.
  static DateTime _resolveTime(
    int hour,
    int minute,
    bool? isPm,
    DateTime now,
  ) {
    final today = DateTime(now.year, now.month, now.day);

    if (isPm == true) {
      var dt = DateTime(today.year, today.month, today.day, _to24Hour(hour, true), minute);
      return dt.isAfter(now) ? dt : dt.add(const Duration(days: 1));
    }
    if (isPm == false) {
      var dt = DateTime(today.year, today.month, today.day, _to24Hour(hour, false), minute);
      return dt.isAfter(now) ? dt : dt.add(const Duration(days: 1));
    }

    if (hour == 12) {
      var noon = DateTime(today.year, today.month, today.day, 12, minute);
      if (noon.isAfter(now)) return noon;
      var mid = DateTime(today.year, today.month, today.day, 0, minute);
      if (mid.isAfter(now)) return mid;
      return noon.add(const Duration(days: 1));
    }

    var am = DateTime(today.year, today.month, today.day, hour, minute);
    var pm = DateTime(today.year, today.month, today.day, hour + 12, minute);
    if (am.isAfter(now)) return am;
    if (pm.isAfter(now)) return pm;
    return am.add(const Duration(days: 1));
  }

  // ── Helpers ─────────────────────────────────────────────────────────

  static int _to24Hour(int hour, bool isPm) {
    if (isPm) return hour == 12 ? 12 : hour + 12;
    return hour == 12 ? 0 : hour;
  }

  /// Returns a date with same clock time as [now] on [target]'s date.
  static DateTime _sameTime(DateTime target, DateTime now) {
    return DateTime(
      target.year, target.month, target.day,
      now.hour, now.minute, now.second,
    );
  }

  static int? _dayIndex(String name) {
    const days = [
      'monday', 'tuesday', 'wednesday', 'thursday',
      'friday', 'saturday', 'sunday',
    ];
    final idx = days.indexWhere((d) => d == name);
    return idx >= 0 ? idx + 1 : null;
  }

  static DateTime _nextWeekday(DateTime now, int target, {bool skipToday = false}) {
    var diff = target - now.weekday;
    if (diff < 0 || (diff == 0 && skipToday)) diff += 7;
    return now.add(Duration(days: diff));
  }
}

// ── Internal types ───────────────────────────────────────────────────

class _TimeInfo {
  final String remaining;
  final int hour;
  final int minute;
  final bool? isPm;
  _TimeInfo({
    required this.remaining,
    required this.hour,
    required this.minute,
    this.isPm,
  });
}

class _DateInfo {
  final String remaining;
  final DateTime date;
  final bool isToday;
  final bool preserveTime;
  _DateInfo({
    required this.remaining,
    required this.date,
    required this.isToday,
    this.preserveTime = false,
  });
}

class _DateTimeResult {
  final String remaining;
  final DateTime? dueDate;
  _DateTimeResult({required this.remaining, this.dueDate});
}
