import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import 'nickname_input_screen.dart';
import '../home_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

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
              onPressed: () async {
                final userCredential = await authService.signInWithGoogle();
                final user = userCredential?.user;

                if (user != null) {
                  final doc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .get();

                  if (!doc.exists) {
                    // 신규 유저 → 닉네임 입력
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NicknameInputScreen(),
                      ),
                    );
                  } else {
                    // 기존 유저 → 닉네임 불러와서 홈으로
                    final nickname = doc.data()?['nickname'] ?? '익명';
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HomeScreen(nickname: nickname),
                      ),
                    );
                  }
                }
              },
              child: const Text('구글로 로그인'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: 카카오 로그인
              },
              child: const Text('카카오로 로그인'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: 네이버 로그인
              },
              child: const Text('네이버로 로그인'),
            ),
          ],
        ),
      ),
    );
  }
}
