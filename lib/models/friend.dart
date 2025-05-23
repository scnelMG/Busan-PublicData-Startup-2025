import 'package:cloud_firestore/cloud_firestore.dart';

class Friend {
  final String id;
  final String email;
  final String displayName;
  final String? photoURL;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime createdAt;

  Friend({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoURL,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Friend.fromMap(Map<String, dynamic> map) {
    return Friend(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoURL: map['photoURL'],
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : (map['createdAt'] is DateTime)
              ? map['createdAt'] as DateTime
              : DateTime.now(),
    );
  }
} 