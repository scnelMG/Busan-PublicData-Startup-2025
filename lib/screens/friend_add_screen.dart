import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/friend.dart';

class FriendAddScreen extends StatefulWidget {
  final User currentUser;
  const FriendAddScreen({super.key, required this.currentUser});

  @override
  State<FriendAddScreen> createState() => _FriendAddScreenState();
}

class _FriendAddScreenState extends State<FriendAddScreen> {
  final _emailController = TextEditingController();
  List<Friend> _receivedRequests = [];
  List<Friend> _sentRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    setState(() { _isLoading = true; });
    try {
      // 받은 요청: status가 pending이고 내가 받은 요청
      final receivedSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .collection('friends')
          .where('status', isEqualTo: 'pending')
          .get();
      final received = receivedSnapshot.docs
          .map((doc) => Friend.fromMap(doc.data()))
          .where((f) => f.id != widget.currentUser.uid)
          .toList();

      // 보낸 요청: status가 pending이고 내가 보낸 요청
      final sentSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .collection('friends')
          .where('status', isEqualTo: 'pending')
          .get();
      final sent = sentSnapshot.docs
          .map((doc) => Friend.fromMap(doc.data()))
          .where((f) => f.email != widget.currentUser.email)
          .toList();

      setState(() {
        _receivedRequests = received;
        _sentRequests = sent;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _isLoading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('친구 요청 목록을 불러오는데 실패했습니다: $e')),
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
      _loadRequests();

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
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .collection('friends')
          .doc(friendId)
          .update({'status': status});
      await FirebaseFirestore.instance
          .collection('users')
          .doc(friendId)
          .collection('friends')
          .doc(widget.currentUser.uid)
          .update({'status': status});
      _loadRequests();
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
      appBar: AppBar(title: const Text('친구 추가/요청 관리')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: '친구 이메일',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _addFriend,
                      child: const Text('친구 추가'),
                    ),
                    const SizedBox(height: 32),
                    const Text('받은 친구 요청', style: TextStyle(fontWeight: FontWeight.bold)),
                    _receivedRequests.isEmpty
                        ? const Text('받은 친구 요청이 없습니다')
                        : Column(
                            children: _receivedRequests.map((friend) => ListTile(
                              leading: friend.photoURL != null
                                  ? CircleAvatar(backgroundImage: NetworkImage(friend.photoURL!))
                                  : CircleAvatar(child: Text(friend.displayName.isNotEmpty ? friend.displayName[0] : '?')),
                              title: Text(friend.displayName),
                              subtitle: Text(friend.email),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check),
                                    onPressed: () => _updateFriendStatus(friend.id, 'accepted'),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () => _updateFriendStatus(friend.id, 'rejected'),
                                  ),
                                ],
                              ),
                            )).toList(),
                          ),
                    const SizedBox(height: 32),
                    const Text('보낸 친구 요청', style: TextStyle(fontWeight: FontWeight.bold)),
                    _sentRequests.isEmpty
                        ? const Text('보낸 친구 요청이 없습니다')
                        : Column(
                            children: _sentRequests.map((friend) => ListTile(
                              leading: friend.photoURL != null
                                  ? CircleAvatar(backgroundImage: NetworkImage(friend.photoURL!))
                                  : CircleAvatar(child: Text(friend.displayName.isNotEmpty ? friend.displayName[0] : '?')),
                              title: Text(friend.displayName),
                              subtitle: Text(friend.email),
                              trailing: const Text('대기중'),
                            )).toList(),
                          ),
                  ],
                ),
              ),
            ),
    );
  }
} 