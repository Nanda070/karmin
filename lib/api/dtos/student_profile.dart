import 'package:karmin/api/dtos/json_util.dart';

/// Safe profile fields only — no classmate PII (PLAN.md §6.2 / §10).
class StudentProfile {
  const StudentProfile({
    this.displayName,
    this.neptunCode,
    this.training,
  });

  final String? displayName;
  final String? neptunCode;
  final String? training;

  bool get isEmpty =>
      (displayName == null || displayName!.isEmpty) &&
      (neptunCode == null || neptunCode!.isEmpty) &&
      (training == null || training!.isEmpty);

  String initial({String fallback = 'K'}) {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) {
      return name[0].toUpperCase();
    }
    final code = neptunCode?.trim();
    if (code != null && code.isNotEmpty) {
      return code[0].toUpperCase();
    }
    return fallback;
  }

  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'neptunCode': neptunCode,
      'training': training,
    };
  }

  factory StudentProfile.fromCacheJson(Map<String, dynamic> json) {
    return StudentProfile(
      displayName: json['displayName'] as String?,
      neptunCode: json['neptunCode'] as String?,
      training: json['training'] as String?,
    );
  }
}

StudentProfile parseStudentProfile(dynamic raw) {
  if (raw is! Map) {
    return const StudentProfile();
  }
  final map = stringKeyed(raw);
  final first = asNonEmptyString(
    firstValue(map, const [
      'firstName',
      'givenName',
      'firstname',
    ]),
  );
  final last = asNonEmptyString(
    firstValue(map, const [
      'lastName',
      'familyName',
      'lastname',
      'sureName',
      'surname',
    ]),
  );
  String? composed;
  if (first != null && last != null) {
    composed = '$first $last';
  } else if (first != null) {
    composed = first;
  } else if (last != null) {
    composed = last;
  }
  return StudentProfile(
    displayName: asNonEmptyString(
          firstValue(map, const [
            'displayName',
            'name',
            'fullName',
            'userName',
            'nickName',
            'nickname',
          ]),
        ) ??
        composed,
    neptunCode: asNonEmptyString(
      firstValue(map, const [
        'neptunCode',
        'neptun',
        'code',
        'userNeptunCode',
      ]),
    ),
    training: asNonEmptyString(
      firstValue(map, const [
        'trainingName',
        'training',
        'program',
        'faculty',
        'studentTrainingName',
      ]),
    ),
  );
}

String? parseTrainingLabel(dynamic raw) {
  for (final item in asItemList(raw)) {
    if (item is! Map) {
      continue;
    }
    final map = stringKeyed(item);
    final actual = asBool(
      firstValue(map, const [
        'actualStudentTraining',
        'actual',
        'isActual',
        'current',
      ]),
    );
    final label = asNonEmptyString(
      firstValue(map, const [
        'studentTrainingName',
        'trainingName',
        'name',
        'code',
        'faculty',
      ]),
    );
    if (actual && label != null) {
      return label;
    }
  }
  for (final item in asItemList(raw)) {
    if (item is! Map) {
      continue;
    }
    final map = stringKeyed(item);
    final label = asNonEmptyString(
      firstValue(map, const [
        'studentTrainingName',
        'trainingName',
        'name',
        'code',
      ]),
    );
    if (label != null) {
      return label;
    }
  }
  return null;
}
