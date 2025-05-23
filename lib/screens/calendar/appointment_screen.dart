import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppointmentScreen extends StatefulWidget {
  final User currentUser;

  const AppointmentScreen({super.key, required this.currentUser});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  DateTime _startOfWeek = _getWeekStart(DateTime.now());
  List<DateTime> _candidates = [];
  Set<String> _unavailable = {};

  static DateTime _getWeekStart(DateTime date) {
    return DateTime(date.year, date.month, date.day - (date.weekday - 1));
  }

  @override
  void initState() {
    super.initState();
    _generateCandidates();
    _loadUnavailable();
  }

  void _generateCandidates() {
    _candidates = [];
    for (int i = 0; i < 7; i++) {
      final date = _startOfWeek.add(Duration(days: i));
      for (int h = 8; h <= 22; h++) {
        _candidates.add(DateTime(date.year, date.month, date.day, h));
      }
    }
  }

  Future<void> _loadUnavailable() async {
    final uid = widget.currentUser.uid;
    final weekKey = DateFormat('yyyy-MM-dd').format(_startOfWeek);

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('appointments')
        .doc(weekKey)
        .get();

    final List<String> times =
        doc.exists ? List<String>.from(doc.data()?['times'] ?? []) : [];

    setState(() {
      _unavailable = times.toSet();
    });
  }

  Future<void> _toggleUnavailable(DateTime dt) async {
    final uid = widget.currentUser.uid;
    final weekKey = DateFormat('yyyy-MM-dd').format(_startOfWeek);
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('appointments')
        .doc(weekKey);

    final key = DateFormat('yyyy-MM-dd HH:mm').format(dt);
    final newSet = Set<String>.from(_unavailable);

    if (_unavailable.contains(key)) {
      newSet.remove(key);
    } else {
      newSet.add(key);
    }

    setState(() {
      _unavailable = newSet;
    });

    await docRef.set({'times': newSet.toList()}, SetOptions(merge: true));
  }

  DateTime? getRecommendedTime() {
    final now = DateTime.now();
    for (final dt in _candidates) {
      if (dt.isBefore(now)) continue;
      final key = DateFormat('yyyy-MM-dd HH:mm').format(dt);
      if (!_unavailable.contains(key)) return dt;
    }
    return null;
  }

  void _goToPreviousWeek() {
    setState(() {
      _startOfWeek = _startOfWeek.subtract(Duration(days: 7));
    });
    _generateCandidates();
    _loadUnavailable();
  }

  void _goToNextWeek() {
    setState(() {
      _startOfWeek = _startOfWeek.add(Duration(days: 7));
    });
    _generateCandidates();
    _loadUnavailable();
  }

  @override
  Widget build(BuildContext context) {
    final recommended = getRecommendedTime();
    final weekLabel =
        '${DateFormat('MM/dd').format(_startOfWeek)} - ${DateFormat('MM/dd').format(_startOfWeek.add(const Duration(days: 6)))}';

    return Scaffold(
      appBar: AppBar(title: const Text("약속 시간 설정")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text("주차: $weekLabel", style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                  recommended != null
                      ? "추천 시간: ${DateFormat('MM/dd (E) HH:mm').format(recommended)}"
                      : "가능한 시간이 없습니다",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(onPressed: _goToPreviousWeek, icon: const Icon(Icons.arrow_back)),
              IconButton(onPressed: _goToNextWeek, icon: const Icon(Icons.arrow_forward)),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: _candidates.length,
              itemBuilder: (context, index) {
                final dt = _candidates[index];
                final key = DateFormat('yyyy-MM-dd HH:mm').format(dt);
                final isUnavailable = _unavailable.contains(key);

                return ListTile(
                  title: Text(DateFormat('MM/dd (E) HH:mm').format(dt)),
                  trailing: Icon(
                    isUnavailable ? Icons.block : Icons.check_circle,
                    color: isUnavailable ? Colors.red : Colors.green,
                  ),
                  onTap: () => _toggleUnavailable(dt),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
