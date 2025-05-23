import 'package:cloud_firestore/cloud_firestore.dart';

class Friend {
  final String id;
  final String email;
  final String displayName;
  final String? photoURL;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime createdAt;
  final String? fromUid;
  final String? toUid;
  final String? fromEmail;
  final String? toEmail;

  Friend({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoURL,
    required this.status,
    required this.createdAt,
    this.fromUid,
    this.toUid,
    this.fromEmail,
    this.toEmail,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'fromUid': fromUid,
      'toUid': toUid,
      'fromEmail': fromEmail,
      'toEmail': toEmail,
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
      fromUid: map['fromUid'],
      toUid: map['toUid'],
      fromEmail: map['fromEmail'],
      toEmail: map['toEmail'],
    );
  }
} 