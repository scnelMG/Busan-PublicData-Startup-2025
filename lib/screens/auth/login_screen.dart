import 'package:flutter/material.dart';
import '../../services/auth_service.dart'; // ✅ 1. AuthService import
import 'nickname_input_screen.dart';       // ✅ 2. 닉네임 화면 import

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService(); // ✅ 3. AuthService 인스턴스 생성

    return Scaffold(
      appBar: AppBar(title: const Text('로그인')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('SNS 계정으로 로그인해주세요'),
            const SizedBox(height: 20),
            ElevatedButton(
              // ✅ 4. 실제 로그인 기능 연결
              onPressed: () async {
                final user = await authService.signInWithGoogle();
                if (user != null) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const NicknameInputScreen()),
                  );
                }
              },
              child: const Text('구글로 로그인'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: 카카오 로그인 기능 연결 예정
              },
              child: const Text('카카오로 로그인'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: 네이버 로그인 기능 연결 예정
              },
              child: const Text('네이버로 로그인'),
            ),
          ],
        ),
      ),
    );
  }
}
