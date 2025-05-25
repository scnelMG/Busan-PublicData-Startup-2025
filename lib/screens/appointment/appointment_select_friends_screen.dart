import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'appointment_result_screen.dart';
import '../../models/friend.dart';

class AppointmentSelectFriendsScreen extends StatefulWidget {
  final User currentUser;
  final int targetCount;

  const AppointmentSelectFriendsScreen({
    super.key,
    required this.currentUser,
    required this.targetCount,
  });

  @override
  State<AppointmentSelectFriendsScreen> createState() =>
      _AppointmentSelectFriendsScreenState();
}

class _AppointmentSelectFriendsScreenState extends State<AppointmentSelectFriendsScreen> {
  List<Friend> _friends = [];
  Set<String> _selectedFriendIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUser.uid)
        .collection('friends')
        .where('status', isEqualTo: 'accepted')
        .get();

    setState(() {
      _friends = snapshot.docs.map((doc) => Friend.fromMap(doc.data())).toList();
      _isLoading = false;
    });
  }

  void _onFriendChecked(String id, bool? selected) {
    final alreadySelected = _selectedFriendIds.contains(id);
    final maxReached = _selectedFriendIds.length >= widget.targetCount;

    if (selected == true && maxReached && !alreadySelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("최대 ${widget.targetCount}명까지 선택할 수 있습니다.")),
      );
      return;
    }

    setState(() {
      if (selected == true) {
        _selectedFriendIds.add(id);
      } else {
        _selectedFriendIds.remove(id);
      }
    });
  }

  void _goToNextScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AppointmentResultScreen(
          currentUser: widget.currentUser,
          selectedFriendIds: _selectedFriendIds.toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("약속 잡기 ② (${_selectedFriendIds.length}/${widget.targetCount})"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _friends.isEmpty
              ? const Center(child: Text("등록된 친구가 없습니다."))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        "놀콕 친구 중 최대 ${widget.targetCount}명까지 선택할 수 있습니다.",
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _friends.length,
                        itemBuilder: (context, index) {
                          final friend = _friends[index];
                          final isChecked = _selectedFriendIds.contains(friend.id);
                          final isDisabled = _selectedFriendIds.length >= widget.targetCount && !isChecked;

                          return CheckboxListTile(
                            value: isChecked,
                            onChanged: isDisabled
                                ? null
                                : (selected) => _onFriendChecked(friend.id, selected),
                            title: Text(friend.displayName),
                            subtitle: Text(friend.email),
                            secondary: friend.photoURL != null
                                ? CircleAvatar(backgroundImage: NetworkImage(friend.photoURL!))
                                : const CircleAvatar(child: Icon(Icons.person)),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ElevatedButton(
          onPressed: _selectedFriendIds.isEmpty
              ? null // ❗ 친구를 0명도 선택하지 않았을 때는 비활성화
              : () {
                  if (_selectedFriendIds.length < widget.targetCount) {
                    final otherCount = widget.targetCount - _selectedFriendIds.length;
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("외부 친구 포함"),
                        content: Text("놀콕 친구 ${_selectedFriendIds.length}명, "
                            "그 외 친구 ${otherCount}명과 약속을 잡을까요?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("아니오"),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _goToNextScreen();
                            },
                            child: const Text("예"),
                          ),
                        ],
                      ),
                    );
                  } else {
                    _goToNextScreen();
                  }
                },
          child: const Text("다음"),
        ),
      ),
    );
  }
}
