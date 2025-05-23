import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/friend.dart';

class FriendScreen extends StatefulWidget {
  final User currentUser;

  const FriendScreen({super.key, required this.currentUser});

  @override
  _FriendScreenState createState() => _FriendScreenState();
}

class _FriendScreenState extends State<FriendScreen> {
  final _emailController = TextEditingController();
  List<Friend> _friends = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .collection('friends')
          .get();

      setState(() {
        _friends = snapshot.docs
            .map((doc) => Friend.fromMap(doc.data()))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('친구 목록을 불러오는데 실패했습니다: $e')),
        );
      }
    }
  }

  Future<void> _addFriend() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일을 입력해주세요')),
      );
      return;
    }

    try {
      // 이메일로 사용자 찾기
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('해당 이메일의 사용자를 찾을 수 없습니다')),
        );
        return;
      }

      final targetUser = userQuery.docs.first;
      final targetUserData = targetUser.data();
      final targetUserId = targetUser.id;

      // 이미 친구인지 확인
      final existingFriend = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .collection('friends')
          .doc(targetUserId)
          .get();

      if (existingFriend.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미 친구로 등록된 사용자입니다')),
        );
        return;
      }

      // 친구 요청 추가
      final friend = Friend(
        id: targetUserId,
        email: email,
        displayName: targetUserData['displayName'] ?? 'Unknown',
        photoURL: targetUserData['photoURL'],
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .collection('friends')
          .doc(targetUserId)
          .set(friend.toMap());

      // 상대방의 친구 목록에도 추가
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .get();
      
      final currentUserData = currentUserDoc.data() ?? {};

      final reverseFriend = Friend(
        id: widget.currentUser.uid,
        email: widget.currentUser.email!,
        displayName: currentUserData['displayName'] ?? 'Unknown',
        photoURL: currentUserData['photoURL'],
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId)
          .collection('friends')
          .doc(widget.currentUser.uid)
          .set(reverseFriend.toMap());

      _emailController.clear();
      _loadFriends();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('친구 요청이 전송되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('친구 추가에 실패했습니다: $e')),
        );
      }
    }
  }

  Future<void> _updateFriendStatus(String friendId, String status) async {
    try {
      // 현재 사용자의 친구 상태 업데이트
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .collection('friends')
          .doc(friendId)
          .update({'status': status});

      // 상대방의 친구 상태도 업데이트
      await FirebaseFirestore.instance
          .collection('users')
          .doc(friendId)
          .collection('friends')
          .doc(widget.currentUser.uid)
          .update({'status': status});

      _loadFriends();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('상태 업데이트에 실패했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('친구'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: '친구 이메일',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _addFriend,
                  child: const Text('친구 추가'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _friends.length,
                    itemBuilder: (context, index) {
                      final friend = _friends[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: friend.photoURL != null
                              ? NetworkImage(friend.photoURL!)
                              : null,
                          child: friend.photoURL == null
                              ? Text(friend.displayName[0])
                              : null,
                        ),
                        title: Text(friend.displayName),
                        subtitle: Text(friend.email),
                        trailing: friend.status == 'pending'
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check),
                                    onPressed: () =>
                                        _updateFriendStatus(friend.id, 'accepted'),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () =>
                                        _updateFriendStatus(friend.id, 'rejected'),
                                  ),
                                ],
                              )
                            : Text(friend.status == 'accepted'
                                ? '친구'
                                : '거절됨'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
} 