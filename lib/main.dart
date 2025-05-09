import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // 자동 생성된 Firebase 옵션
import 'screens/home_screen.dart'; // 홈 화면 import
import 'calendar.dart'; // 캘린더 화면 import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '회원가입 예제',
      theme: ThemeData(useMaterial3: true),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(nickname: '비회원'), // 홈 화면
        '/calendar': (context) => CalendarScreen(), // 캘린더 화면 추가
      },
    );
  }
}