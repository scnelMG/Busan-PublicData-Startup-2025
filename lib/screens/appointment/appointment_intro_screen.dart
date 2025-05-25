import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'appointment_select_friends_screen.dart';

class AppointmentIntroScreen extends StatefulWidget {
  final User currentUser;

  const AppointmentIntroScreen({super.key, required this.currentUser});

  @override
  State<AppointmentIntroScreen> createState() => _AppointmentIntroScreenState();
}

class _AppointmentIntroScreenState extends State<AppointmentIntroScreen> {
  int _friendCount = 1;
  int _myFriendCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFriendCount();
  }

  Future<void> _loadFriendCount() async {
    final uid = widget.currentUser.uid;
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('friends')
        .get();

    setState(() {
      _myFriendCount = snapshot.docs.length;
      _loading = false;
    });
  }

  void _goToNextScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AppointmentSelectFriendsScreen(
          currentUser: widget.currentUser,
          targetCount: _friendCount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("약속 잡기 ①"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "몇 명과 약속을 잡을 건가요?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text("인원 수: ", style: TextStyle(fontSize: 16)),
                DropdownButton<int>(
                  value: _friendCount,
                  items: List.generate(10, (i) => i + 1)
                      .map((num) => DropdownMenuItem(
                            value: num,
                            child: Text('$num명'),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _friendCount = val;
                      });
                    }
                  },
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _goToNextScreen,
                child: const Text("다음"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
