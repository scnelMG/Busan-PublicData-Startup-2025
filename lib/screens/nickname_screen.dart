import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'dart:async';

class NicknameScreen extends StatefulWidget {
  final User user;
  const NicknameScreen({super.key, required this.user});

  @override
  State<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends State<NicknameScreen> {
  final _nicknameController = TextEditingController();
  bool _isChecking = false;
  bool _isAvailable = false;
  String? _errorText;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _nicknameController.addListener(_onNicknameChanged);
  }

  @override
  void dispose() {
    _nicknameController.removeListener(_onNicknameChanged);
    _nicknameController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onNicknameChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _checkNickname();
    });
  }

  Future<void> _checkNickname() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      setState(() {
        _errorText = '닉네임을 입력해주세요';
        _isAvailable = false;
        _isChecking = false;
      });
      return;
    }
    setState(() {
      _isChecking = true;
      _errorText = null;
      _isAvailable = false;
    });
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('nickname', isEqualTo: nickname)
        .get();
    setState(() {
      _isChecking = false;
      if (query.docs.isEmpty) {
        _isAvailable = true;
        _errorText = null;
      } else {
        _isAvailable = false;
        _errorText = '이미 사용 중인 닉네임입니다';
      }
    });
  }

  Future<void> _submit() async {
    final nickname = _nicknameController.text.trim();
    if (!_isAvailable) return;
    await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).set({
      'uid': widget.user.uid,
      'email': widget.user.email,
      'nickname': nickname,
      'photoURL': widget.user.photoURL,
      'lastLogin': DateTime.now(),
    }, SetOptions(merge: true));
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen(currentUser: widget.user)),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('닉네임 입력')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('닉네임을 입력하세요', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            TextField(
              controller: _nicknameController,
              decoration: InputDecoration(
                labelText: '닉네임',
                border: const OutlineInputBorder(),
                errorText: _errorText,
                suffixIcon: _isChecking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _isAvailable
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isAvailable ? _submit : null,
                child: const Text('확인'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 