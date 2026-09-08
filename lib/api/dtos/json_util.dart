import 'dart:convert';

/// Shared best-effort JSON helpers. Unknown keys are ignored.
Map<String, dynamic> stringKeyed(Map<dynamic, dynamic> map) {
  return map.map((key, value) => MapEntry(key.toString(), value));
}

/// Dio / JSON decode sometimes yields [Map<dynamic, dynamic>] or a JSON string.
Map<String, dynamic> asJsonMap(dynamic raw) {
  if (raw is Map) {
    return stringKeyed(raw);
  }
  if (raw is String && raw.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return stringKeyed(decoded);
      }
    } on FormatException {
      // HTML / plaintext — not JSON.
    }
  }
  return const <String, dynamic>{};
}

List<dynamic> asItemList(dynamic raw) {
  if (raw is List) {
    return raw;
  }
  if (raw is Map) {
    final map = stringKeyed(raw);
    for (final key in const [
      'items',
      'results',
      'messages',
      'posts',
      'subjects',
      'exams',
      'events',
      'trainings',
      'data',
      'list',
    ]) {
      final nested = map[key];
      if (nested is List) {
        return nested;
      }
    }
  }
  return const [];
}

Object? firstValue(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value == null) {
      continue;
    }
    if (value is String && value.trim().isEmpty) {
      continue;
    }
    return value;
  }
  return null;
}

String? asNonEmptyString(Object? value) {
  if (value == null) {
    return null;
  }
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value.trim());
  }
  return null;
}

double? asDouble(Object? value) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value.replaceAll(',', '.').trim());
  }
  return null;
}

bool asBool(Object? value) {
  if (value == true || value == 1 || value == 1.0) {
    return true;
  }
  if (value is String) {
    final text = value.trim().toLowerCase();
    return text == 'true' || text == '1' || text == 'yes';
  }
  return false;
}

String initialsFor(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return 'N';
  }
  if (parts.length == 1) {
    return parts.first[0].toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

/// Strip tags / entities for inbox bodies. Not a full HTML sanitizer.
String stripHtml(String raw) {
  var text = raw.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
  text = text.replaceAll(RegExp(r'</p>', caseSensitive: false), '\n');
  text = text.replaceAll(RegExp(r'<[^>]+>'), '');
  text = text
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'");
  return text.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
}

/// Neptun write/read feedback (`notification`, model errors). Best-effort.
String? extractNeptunMessage(dynamic raw) {
  if (raw == null) {
    return null;
  }
  if (raw is String && raw.trim().isNotEmpty) {
    return stripHtml(raw);
  }
  if (raw is List) {
    for (final item in raw) {
      final parsed = extractNeptunMessage(item);
      if (parsed != null) {
        return parsed;
      }
    }
    return null;
  }
  if (raw is! Map) {
    return null;
  }
  final map = stringKeyed(raw);
  for (final key in const [
    'notification',
    'message',
    'errorMessage',
    'error',
    'title',
    'description',
    'text',
  ]) {
    final value = map[key];
    if (value is String && value.trim().isNotEmpty) {
      return stripHtml(value);
    }
    if (value is Map) {
      final nested = extractNeptunMessage(value);
      if (nested != null) {
        return nested;
      }
    }
  }
  final errors = map['errors'] ??
      map['modelState'] ??
      map['modelErrors'] ??
      map['modelStateErrors'];
  if (errors is Map) {
    for (final value in errors.values) {
      final parsed = extractNeptunMessage(value);
      if (parsed != null) {
        return parsed;
      }
    }
  }
  if (errors is List) {
    return extractNeptunMessage(errors);
  }
  return null;
}
