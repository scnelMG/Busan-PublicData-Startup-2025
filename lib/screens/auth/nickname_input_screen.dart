import 'package:flutter/material.dart';

class NicknameInputScreen extends StatefulWidget {
  const NicknameInputScreen({super.key});

  @override
  State<NicknameInputScreen> createState() => _NicknameInputScreenState();
}

class _NicknameInputScreenState extends State<NicknameInputScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _nickname;

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
              onPressed: () {
                setState(() {
                  _nickname = _controller.text.trim();
                });

                if (_nickname != null && _nickname!.isNotEmpty) {
                  // TODO: 닉네임 저장 로직 (Firebase Firestore 등)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('닉네임 $_nickname 저장 완료!')),
                  );
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
