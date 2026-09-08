import 'package:karmin/api/dtos/calendar_event.dart';
import 'package:karmin/api/dtos/json_util.dart';

/// Exam Karmin can show / attempt to register. Signup POST body is unproven.
class ExamOffer {
  const ExamOffer({
    required this.id,
    required this.subjectName,
    this.subjectId,
    this.start,
    this.room,
    this.canSignUp = false,
    this.signedUp = false,
  });

  final String id;
  final String subjectName;
  final String? subjectId;
  final DateTime? start;
  final String? room;
  final bool canSignUp;
  final bool signedUp;

  bool get hasSignupTarget => id.isNotEmpty && !signedUp;

  ExamOffer copyWith({bool? signedUp, bool? canSignUp}) {
    return ExamOffer(
      id: id,
      subjectName: subjectName,
      subjectId: subjectId,
      start: start,
      room: room,
      canSignUp: canSignUp ?? this.canSignUp,
      signedUp: signedUp ?? this.signedUp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subjectName': subjectName,
      'subjectId': subjectId,
      'start': start?.toIso8601String(),
      'room': room,
      'canSignUp': canSignUp,
      'signedUp': signedUp,
    };
  }

  factory ExamOffer.fromCacheJson(Map<String, dynamic> json) {
    return ExamOffer(
      id: json['id'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      subjectId: json['subjectId'] as String?,
      start: DateTime.tryParse(json['start'] as String? ?? ''),
      room: json['room'] as String?,
      canSignUp: json['canSignUp'] == true,
      signedUp: json['signedUp'] == true,
    );
  }
}

class ExamSignupResult {
  const ExamSignupResult({
    required this.message,
    this.accepted = false,
  });

  final String message;
  final bool accepted;
}

List<ExamOffer> parseExamOffers(dynamic raw) {
  final exams = <ExamOffer>[];
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
        'examName',
        'courseName',
      ]),
    );
    if (name == null) {
      continue;
    }
    final signedUp = asBool(
      firstValue(map, const [
        'isSignedUp',
        'signedUp',
        'signed',
        'isRegistered',
        'alreadySigned',
        'onWaitingList',
      ]),
    );
    final canSignUp = asBool(
          firstValue(map, const [
            'canSignUp',
            'signUpEnabled',
            'isSignUpEnabled',
            'canRegister',
            'signInEnabled',
          ]),
        ) ||
        (!signedUp &&
            asBool(
              firstValue(map, const ['available', 'isAvailable']),
            ));
    exams.add(
      ExamOffer(
        id: asNonEmptyString(
              firstValue(map, const [
                'examId',
                'id',
                'examIdentifier',
              ]),
            ) ??
            '',
        subjectName: name,
        subjectId: asNonEmptyString(
          firstValue(map, const ['subjectId', 'courseId']),
        ),
        start: parseFlexibleDate(
          firstValue(map, const [
            'examDate',
            'startDate',
            'start',
            'fromDate',
            'date',
            'from',
          ]),
        ),
        room: asNonEmptyString(
          firstValue(map, const ['rooms', 'room', 'location', 'place']),
        ),
        canSignUp: canSignUp && !signedUp,
        signedUp: signedUp,
      ),
    );
  }
  exams.sort((a, b) {
    final aDate = a.start ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bDate = b.start ?? DateTime.fromMillisecondsSinceEpoch(0);
    return aDate.compareTo(bDate);
  });
  return exams;
}

List<ExamOffer> parseCachedExams(dynamic raw) {
  if (raw is! List) {
    return const [];
  }
  return raw
      .whereType<Map>()
      .map(
        (item) => ExamOffer.fromCacheJson(
          item.map((key, value) => MapEntry(key.toString(), value)),
        ),
      )
      .toList();
}
