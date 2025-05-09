import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../home_screen.dart';

class NicknameInputScreen extends StatefulWidget {
  const NicknameInputScreen({super.key});

  @override
  State<NicknameInputScreen> createState() => _NicknameInputScreenState();
}

class _NicknameInputScreenState extends State<NicknameInputScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _nickname;

  // ✅ 닉네임 저장 함수
  Future<void> saveNickname(String nickname) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'nickname': nickname,
      'createdAt': Timestamp.now(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('닉네임 입력')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('닉네임을 입력해주세요'),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '예: 민규짱, mingyu123',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  _nickname = _controller.text.trim();
                });

                if (_nickname != null && _nickname!.isNotEmpty) {
                  await saveNickname(_nickname!); // ✅ Firestore 저장
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('닉네임 $_nickname 저장 완료!')),
                  );

                  // 👉 다음 화면으로 이동하거나 홈으로
                  // Navigator.push(...);
                if (_nickname != null && _nickname!.isNotEmpty) {
                  await saveNickname(_nickname!); // ✅ Firestore 저장

                  // ✅ 저장 완료 메시지
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('닉네임 $_nickname 저장 완료!')),
                  );

                  // ✅ 홈 화면으로 이동
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HomeScreen(nickname: _nickname!), //✅ 닉네임 전달
                    ),
                  );
                }

                }
              },
              child: const Text('확인'),
            )
          ],
        ),
      ),
    );
  }
}
