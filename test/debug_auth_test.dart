import 'package:flutter_test/flutter_test.dart';
import 'package:karmin/api/exceptions.dart';
import 'package:karmin/api/neptun_auth.dart';
import 'package:karmin/auth/auth_models.dart';

void main() {
  final api = DebugNeptunAuth();

  test('empty credentials are rejected', () async {
    expect(
      () => api.submitPassword(userName: ' ', password: '', lcid: 1033),
      throwsA(isA<NeptunAuthException>()),
    );
  });

  test('password step always requires OTP', () async {
    final ticket = await api.submitPassword(
      userName: 'abc',
      password: 'x',
      lcid: 1033,
    );
    expect(ticket.step, NeptunAuthStep.needsOtp);
    expect(ticket.hasJwt, isFalse);
  });

  test('any 6-digit OTP authenticates', () async {
    final ticket = await api.submitOtp(
      userName: 'abc',
      password: 'x',
      lcid: 1033,
      otp: '000000',
    );
    expect(ticket.step, NeptunAuthStep.authenticated);
    expect(ticket.accessToken, 'debug-jwt');
    expect(ticket.neptunCode, 'ABC');
  });

  test('non-digit OTP is rejected', () async {
    expect(
      () => api.submitOtp(
        userName: 'abc',
        password: 'x',
        lcid: 1033,
        otp: 'abcdef',
      ),
      throwsA(isA<NeptunOtpException>()),
    );
  });

  test('resend repeats the password step', () async {
    final api = DebugNeptunAuth();
    final first = await api.submitPassword(
      userName: 'abc',
      password: 'x',
      lcid: 1033,
    );
    final again = await api.resendEmailCode(
      userName: 'abc',
      password: 'x',
      lcid: 1033,
    );
    expect(first.step, NeptunAuthStep.needsOtp);
    expect(again.step, NeptunAuthStep.needsOtp);
    expect(again.hasJwt, isFalse);
  });

  test('useDebugAuth honors live override', () {
    expect(useDebugAuth(liveOverride: true, debugMode: true), isFalse);
    expect(useDebugAuth(debugOverride: true, debugMode: false), isTrue);
    expect(useDebugAuth(debugMode: true), isTrue);
  });
}
