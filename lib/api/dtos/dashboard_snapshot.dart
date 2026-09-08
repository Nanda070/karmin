/// GPA / unread / credits subset used by Today (Stage 2). Unknown keys ignored.
class DashboardSnapshot {
  const DashboardSnapshot({
    this.gpa,
    this.unreadCount = 0,
    this.completedCredits,
    this.requiredCredits,
  });

  final double? gpa;
  final int unreadCount;
  final int? completedCredits;
  final int? requiredCredits;

  String? get gpaLabel {
    if (gpa == null) {
      return null;
    }
    final value = gpa!;
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  String? get creditsLabel {
    if (completedCredits == null) {
      return null;
    }
    if (requiredCredits == null) {
      return '$completedCredits';
    }
    return '$completedCredits / $requiredCredits';
  }

  Map<String, dynamic> toJson() {
    return {
      'gpa': gpa,
      'unreadCount': unreadCount,
      'completedCredits': completedCredits,
      'requiredCredits': requiredCredits,
    };
  }

  factory DashboardSnapshot.fromCacheJson(Map<String, dynamic> json) {
    return DashboardSnapshot(
      gpa: (json['gpa'] as num?)?.toDouble(),
      unreadCount: json['unreadCount'] as int? ?? 0,
      completedCredits: json['completedCredits'] as int?,
      requiredCredits: json['requiredCredits'] as int?,
    );
  }
}

double? parseGpa(dynamic raw) {
  if (raw is num) {
    return raw.toDouble();
  }
  if (raw is String) {
    return double.tryParse(raw.replaceAll(',', '.'));
  }
  if (raw is List) {
    for (final item in raw) {
      final parsed = parseGpa(item);
      if (parsed != null) {
        return parsed;
      }
    }
    return null;
  }
  if (raw is! Map) {
    return null;
  }
  final map = raw.map((key, value) => MapEntry(key.toString(), value));
  const preferred = [
    'cumulativeAverage',
    'closedAverage',
    'weightedAverage',
    'scholarshipAverage',
    'average',
    'gpa',
    'value',
  ];
  for (final key in preferred) {
    final parsed = parseGpa(map[key]);
    if (parsed != null) {
      return parsed;
    }
  }
  for (final key in map.keys) {
    if (key.toLowerCase().contains('average') ||
        key.toLowerCase().contains('gpa')) {
      final parsed = parseGpa(map[key]);
      if (parsed != null) {
        return parsed;
      }
    }
  }
  for (final nestedKey in const ['averages', 'items', 'data']) {
    final parsed = parseGpa(map[nestedKey]);
    if (parsed != null) {
      return parsed;
    }
  }
  return null;
}

int parseUnreadCount(dynamic raw) {
  if (raw is int) {
    return raw;
  }
  if (raw is num) {
    return raw.toInt();
  }
  if (raw is Map) {
    final map = raw.map((key, value) => MapEntry(key.toString(), value));
    final count = map['count'] ?? map['unread'] ?? map['unreadedMessagesCount'];
    if (count is num) {
      return count.toInt();
    }
  }
  return 0;
}

({int? completed, int? required}) parseCreditProgress(dynamic raw) {
  if (raw is! Map) {
    return (completed: null, required: null);
  }
  final map = raw.map((key, value) => MapEntry(key.toString(), value));
  int? asInt(List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is num) {
        return value.toInt();
      }
    }
    return null;
  }

  return (
    completed: asInt(const [
      'completedCredits',
      'completed',
      'fullfilledCredit',
      'fulfilledCredit',
      'acquiredCredits',
    ]),
    required: asInt(const [
      'requiredCredits',
      'allCredits',
      'totalCredits',
      'mustAcquireCredit',
      'required',
    ]),
  );
}
