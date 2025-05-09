import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // 자동 생성된 Firebase 옵션
import 'screens/home_screen.dart'; // 홈 화면 import

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
      home: const HomeScreen(nickname: '비회원'), // ✅ 첫 화면을 HomeScreen으로 설정
    );
  }
}
