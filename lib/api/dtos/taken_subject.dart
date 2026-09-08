import 'package:karmin/api/dtos/json_util.dart';

/// One taken subject row for Study. Field names are not frozen (PLAN.md §16).
class TakenSubject {
  const TakenSubject({
    required this.id,
    required this.name,
    this.code,
    this.credits,
    this.grade,
    this.gradeName,
    this.termId,
    this.termLabel,
    this.requirementType,
  });

  final String id;
  final String name;
  final String? code;
  final int? credits;
  final int? grade;
  final String? gradeName;
  final String? termId;
  final String? termLabel;
  final String? requirementType;

  String get gradeLabel {
    if (grade != null) {
      return '$grade';
    }
    if (gradeName != null && gradeName!.trim().isNotEmpty) {
      return gradeName!;
    }
    return '—';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'credits': credits,
      'grade': grade,
      'gradeName': gradeName,
      'termId': termId,
      'termLabel': termLabel,
      'requirementType': requirementType,
    };
  }

  factory TakenSubject.fromCacheJson(Map<String, dynamic> json) {
    return TakenSubject(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String?,
      credits: json['credits'] as int?,
      grade: json['grade'] as int?,
      gradeName: json['gradeName'] as String?,
      termId: json['termId'] as String?,
      termLabel: json['termLabel'] as String?,
      requirementType: json['requirementType'] as String?,
    );
  }

  TakenSubject withGrade({int? grade, String? gradeName}) {
    return TakenSubject(
      id: id,
      name: name,
      code: code,
      credits: credits,
      grade: grade ?? this.grade,
      gradeName: gradeName ?? this.gradeName,
      termId: termId,
      termLabel: termLabel,
      requirementType: requirementType,
    );
  }
}

class SubjectTerm {
  const SubjectTerm({
    required this.id,
    required this.label,
    this.isClosed = false,
  });

  final String id;
  final String label;
  final bool isClosed;
}

List<SubjectTerm> parseSubjectTerms(dynamic raw) {
  final terms = <SubjectTerm>[];
  for (final item in asItemList(raw)) {
    if (item is! Map) {
      continue;
    }
    final map = stringKeyed(item);
    final id = asNonEmptyString(
      firstValue(map, const ['value', 'id', 'termId', 'studentTrainingTermId']),
    );
    if (id == null) {
      continue;
    }
    terms.add(
      SubjectTerm(
        id: id,
        label: asNonEmptyString(
              firstValue(map, const ['text', 'name', 'termName', 'label']),
            ) ??
            id,
        isClosed: asBool(map['isClosed'] ?? map['closed']),
      ),
    );
  }
  return terms;
}

SubjectTerm? pickCurrentTerm(List<SubjectTerm> terms) {
  if (terms.isEmpty) {
    return null;
  }
  for (final term in terms) {
    if (!term.isClosed) {
      return term;
    }
  }
  return terms.last;
}

List<TakenSubject> parseTakenSubjects(
  dynamic raw, {
  String? termId,
  String? termLabel,
}) {
  final subjects = <TakenSubject>[];
  for (final item in asItemList(raw)) {
    if (item is! Map) {
      continue;
    }
    final map = stringKeyed(item);
    final name = asNonEmptyString(
      firstValue(map, const [
        'subjectName',
        'name',
        'title',
        'courseName',
      ]),
    );
    if (name == null) {
      continue;
    }
    final id = asNonEmptyString(
          firstValue(map, const [
            'subjectId',
            'id',
            'indexLineId',
            'courseId',
          ]),
        ) ??
        name;
    final result = map['subjectResult'];
    final resultMap = result is Map ? stringKeyed(result) : map;
    subjects.add(
      TakenSubject(
        id: id,
        name: name,
        code: asNonEmptyString(
          firstValue(map, const ['subjectCode', 'code', 'neptunCode']),
        ),
        credits: asInt(
          firstValue(map, const [
            'subjectCredit',
            'credit',
            'credits',
            'creditCount',
          ]),
        ),
        grade: asInt(
          firstValue(resultMap, const [
            'resultValue',
            'grade',
            'value',
            'mark',
          ]),
        ),
        gradeName: asNonEmptyString(
          firstValue(resultMap, const [
            'resultName',
            'gradeName',
            'result',
          ]),
        ),
        termId: termId ??
            asNonEmptyString(firstValue(map, const ['termId', 'term'])),
        termLabel: termLabel,
        requirementType: asNonEmptyString(
          firstValue(map, const ['requirementType', 'requirement']),
        ),
      ),
    );
  }
  return subjects;
}

/// Merge bulk `GetSubjectResultsList` rows onto taken subjects by id/code/name.
List<TakenSubject> mergeSubjectGrades(
  List<TakenSubject> subjects,
  dynamic resultsRaw,
) {
  if (subjects.isEmpty) {
    return subjects;
  }
  final grades = <String, ({int? grade, String? name})>{};
  void remember(String? key, int? grade, String? name) {
    if (key == null || key.isEmpty) {
      return;
    }
    grades[key.toLowerCase()] = (grade: grade, name: name);
  }

  for (final item in asItemList(resultsRaw)) {
    if (item is! Map) {
      continue;
    }
    final map = stringKeyed(item);
    final result = map['subjectResult'];
    final resultMap = result is Map ? stringKeyed(result) : map;
    final grade = asInt(
      firstValue(resultMap, const ['resultValue', 'grade', 'value', 'mark']),
    );
    final gradeName = asNonEmptyString(
      firstValue(resultMap, const ['resultName', 'gradeName', 'result']),
    );
    remember(
      asNonEmptyString(firstValue(map, const ['subjectId', 'id'])),
      grade,
      gradeName,
    );
    remember(
      asNonEmptyString(firstValue(map, const ['subjectCode', 'code'])),
      grade,
      gradeName,
    );
    remember(
      asNonEmptyString(firstValue(map, const ['subjectName', 'name'])),
      grade,
      gradeName,
    );
  }
  if (grades.isEmpty) {
    return subjects;
  }
  return subjects.map((subject) {
    final hit = grades[subject.id.toLowerCase()] ??
        (subject.code != null ? grades[subject.code!.toLowerCase()] : null) ??
        grades[subject.name.toLowerCase()];
    if (hit == null) {
      return subject;
    }
    return subject.withGrade(grade: hit.grade, gradeName: hit.name);
  }).toList();
}

List<TakenSubject> parseCachedSubjects(dynamic raw) {
  if (raw is! List) {
    return const [];
  }
  return raw
      .whereType<Map>()
      .map(
        (item) => TakenSubject.fromCacheJson(
          item.map((key, value) => MapEntry(key.toString(), value)),
        ),
      )
      .toList();
}
