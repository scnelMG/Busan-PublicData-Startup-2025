import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/friend.dart';

class FriendListScreen extends StatefulWidget {
  final User currentUser;
  const FriendListScreen({super.key, required this.currentUser});

  @override
  State<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> {
  List<Friend> _friends = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    setState(() { _isLoading = true; });
    try {
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
    } catch (e) {
      setState(() { _isLoading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('친구 목록을 불러오는데 실패했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('친구 목록'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.pushNamed(context, '/friend-add');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _friends.isEmpty
              ? const Center(child: Text('친구가 없습니다'))
              : ListView.builder(
                  itemCount: _friends.length,
                  itemBuilder: (context, index) {
                    final friend = _friends[index];
                    return ListTile(
                      leading: friend.photoURL != null
                          ? CircleAvatar(backgroundImage: NetworkImage(friend.photoURL!))
                          : CircleAvatar(child: Text(friend.displayName.isNotEmpty ? friend.displayName[0] : '?')),
                      title: Text(friend.displayName),
                      subtitle: Text(friend.email),
                    );
                  },
                ),
    );
  }
} 