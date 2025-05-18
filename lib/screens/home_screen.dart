import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth/login_screen.dart';
import '../calendar.dart';

class HomeScreen extends StatefulWidget {
  final String nickname;

  const HomeScreen({super.key, required this.nickname});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _friendEmailController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;

  Future<void> _addFriend() async {
    final friendEmail = _friendEmailController.text.trim();

    if (friendEmail.isEmpty || user == null) return;

    try {
      // 친구 이메일로 UID 찾기
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: friendEmail)
          .get();

      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('해당 이메일의 사용자를 찾을 수 없습니다.')),
        );
        return;
      }

      final friendUid = querySnapshot.docs.first.id;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('friends')
          .doc(friendUid)
          .set({'email': friendEmail});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('친구가 추가되었습니다!')),
      );
      _friendEmailController.clear();
    } catch (e) {
      print("친구 추가 실패: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('친구 추가 중 오류 발생')),
      );
    }
  }

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
                    const SizedBox(height: 20),

                    // 🔹 친구 추가
                    TextField(
                      controller: _friendEmailController,
                      decoration: const InputDecoration(
                        labelText: '친구 이메일',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _addFriend,
                      child: const Text('친구 추가'),
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
