import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth/login_screen.dart';
import 'calendar/availability_screen.dart';
import 'calendar/calendar_screen.dart';


class HomeScreen extends StatefulWidget {
  final String nickname;

  const HomeScreen({super.key, required this.nickname});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _friendEmailController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
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
                    (context as Element).reassemble();
                  }
                },
                child: const Text('로그인하기'),
              )
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('안녕하세요, ${widget.nickname}님!'),
                    const SizedBox(height: 20),

                    // 🔹 캘린더 이동 버튼
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CalendarScreen(currentUser: user!),
                          ),
                        );
                      },
                      child: const Text('캘린더로 이동'),
                    ),
                    const SizedBox(height: 10),

                    // ✅ 가능한 시간 설정 버튼
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AvailabilityScreen(currentUser: user!),
                          ),
                        );
                      },
                      child: const Text('가능한 시간 설정'),
                    ),
                    const SizedBox(height: 20),


                    // 🔹 로그아웃
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
      ),
    );
  }
}
