import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:karmin/api/dtos/exam_offer.dart';
import 'package:karmin/api/dtos/inbox_message.dart';
import 'package:karmin/api/dtos/json_util.dart';
import 'package:karmin/api/dtos/student_profile.dart';
import 'package:karmin/api/dtos/taken_subject.dart';

void main() {
  test('parses taken subjects and merges grades', () {
    final fixture = jsonDecode(
      File('test/fixtures/taken_subjects.json').readAsStringSync(),
    );
    final subjects = parseTakenSubjects(fixture, termId: 'term-1');
    expect(subjects, hasLength(3));
    expect(subjects[0].grade, 4);
    expect(subjects[1].gradeLabel, '5');
    expect(subjects[2].gradeLabel, '—');

    final merged = mergeSubjectGrades(subjects, {
      'items': [
        {'subjectId': 'sub-3', 'resultValue': 3, 'resultName': 'Satisfactory'},
      ],
    });
    expect(merged[2].grade, 3);
  });

  test('parses inbox messages with unread and dates', () {
    final fixture = jsonDecode(
      File('test/fixtures/inbox_messages.json').readAsStringSync(),
    );
    final messages = parseInboxMessages(fixture);
    expect(messages, hasLength(3));
    expect(messages.where((m) => m.unread).length, 2);
    expect(messages.first.sender, 'Registrar');
    expect(stripHtml('<p>Hello<br/>world</p>'), 'Hello\nworld');
  });

  test('parses profile, training, and exam offers', () {
    final profile = parseStudentProfile({
      'firstName': 'Ada',
      'lastName': 'Lovelace',
      'neptunCode': 'XYZ999',
    });
    expect(profile.displayName, 'Ada Lovelace');
    expect(
      parseTrainingLabel([
        {
          'actualStudentTraining': true,
          'studentTrainingName': 'Computer Science BSc',
        },
      ]),
      'Computer Science BSc',
    );
    final exams = parseExamOffers({
      'items': [
        {
          'examId': 'ex-1',
          'subjectName': 'Discrete math',
          'examDate': '2026-09-11T10:00:00',
          'canSignUp': true,
        },
      ],
    });
    expect(exams.single.canSignUp, isTrue);
    expect(exams.single.id, 'ex-1');
  });

  test('extracts Neptun notification text', () {
    expect(
      extractNeptunMessage({
        'notification': {'message': 'Already signed up'},
      }),
      'Already signed up',
    );
  });
}
