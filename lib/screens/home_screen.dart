import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth/login_screen.dart';
import '../calendar.dart';

class HomeScreen extends StatelessWidget {
  final String nickname;

  const HomeScreen({super.key, required this.nickname});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('홈 화면')),
      body: Center(
        child: user == null
            ? ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                  if (result == 'logged_in') {
                    (context as Element).reassemble(); // 🔁 로그인 후 다시 빌드
                  }
                },
                child: const Text('로그인하기'),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('안녕하세요, $nickname님!'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (user != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CalendarScreen(currentUser: user),
                          ),
                        );
                      }
                    },
                    child: const Text('캘린더로 이동'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HomeScreen(nickname: '비회원'),
                        ),
                      );
                    },
                    child: const Text('로그아웃'),
                  ),
                ],
              ),
      ),
    );
  }
}
