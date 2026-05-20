enum RecurrenceFrequency { daily, weekly, monthly, yearly }

class Recurrence {
  final RecurrenceFrequency frequency;
  final int interval;

  const Recurrence({required this.frequency, this.interval = 1});

  String toStorage() => '${frequency.name}|$interval';

  factory Recurrence.fromStorage(String s) {
    final parts = s.split('|');
    return Recurrence(
      frequency: RecurrenceFrequency.values.firstWhere(
        (e) => e.name == parts[0],
      ),
      interval: parts.length > 1 ? int.parse(parts[1]) : 1,
    );
  }

  DateTime? nextOccurrence(DateTime from) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return from.add(Duration(days: interval));
      case RecurrenceFrequency.weekly:
        return from.add(Duration(days: 7 * interval));
      case RecurrenceFrequency.monthly:
        return DateTime(from.year, from.month + interval, from.day, from.hour, from.minute);
      case RecurrenceFrequency.yearly:
        return DateTime(from.year + interval, from.month, from.day, from.hour, from.minute);
    }
  }

  String get label {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return interval == 1 ? 'Daily' : 'Every $interval days';
      case RecurrenceFrequency.weekly:
        return interval == 1 ? 'Weekly' : 'Every $interval weeks';
      case RecurrenceFrequency.monthly:
        return interval == 1 ? 'Monthly' : 'Every $interval months';
      case RecurrenceFrequency.yearly:
        return interval == 1 ? 'Yearly' : 'Every $interval years';
    }
  }

  static String? displayLabel(String? storage) {
    if (storage == null) return null;
    return Recurrence.fromStorage(storage).label;
  }
}
