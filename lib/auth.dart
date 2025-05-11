import 'dart:io';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/auth_io.dart';

/// 구글 캘린더 API 스코프 (일정 읽기 전용)
const _scopes = [calendar.CalendarApi.calendarReadonlyScope];

/// GoogleCalendarService 클래스
class GoogleCalendarService {
  /// 구글 캘린더 API 클라이언트 생성 함수
  static Future<calendar.CalendarApi?> getCalendarApi() async {
    final clientId = ClientId(
      '365197092359-l7uupr50ln5158c5r4p4f3ag1582b9es.apps.googleusercontent.com',
      'YOUR_CLIENT_SECRET',
    );

    try {
      final authClient = await clientViaUserConsent(clientId, _scopes, (url) {
        print("이 URL로 이동해서 인증을 완료하세요:");
        print("  => $url");
      });

      return calendar.CalendarApi(authClient);
    } catch (e) {
      print("인증 에러 발생: $e");
      return null;
    }
  }
}
