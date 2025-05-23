import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AvailabilityScreen extends StatefulWidget {
  final User currentUser;

  const AvailabilityScreen({super.key, required this.currentUser});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  DateTime _startOfWeek = _getWeekStart(DateTime.now());
  Set<String> _unavailable = {};
  final List<String> hours = List.generate(24, (i) => i.toString().padLeft(2, '0') + ":00");
  final Map<String, GlobalKey> _cellKeys = {};

  static DateTime _getWeekStart(DateTime date) {
    return DateTime(date.year, date.month, date.day - (date.weekday - 1));
  }

  @override
  void initState() {
    super.initState();
    _loadUnavailable();
  }

  List<DateTime> _generateCandidates() {
    final List<DateTime> result = [];
    for (int i = 0; i < 7; i++) {
      final date = _startOfWeek.add(Duration(days: i));
      for (int h = 8; h <= 22; h++) {
        result.add(DateTime(date.year, date.month, date.day, h));
      }
    }
    return result;
  }

  Future<void> _loadUnavailable() async {
    final uid = widget.currentUser.uid;
    final weekKey = DateFormat('yyyy-MM-dd').format(_startOfWeek);

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('availability')
        .doc(weekKey)
        .get();

    final List<String> data =
        snapshot.exists ? List<String>.from(snapshot.data()?['times'] ?? []) : [];

    setState(() {
      _unavailable = data.toSet();
    });
  }

  Future<void> _toggleUnavailable(DateTime dt) async {
    final uid = widget.currentUser.uid;
    final weekKey = DateFormat('yyyy-MM-dd').format(_startOfWeek);
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('availability')
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

  void _goToPreviousWeek() {
    setState(() {
      _startOfWeek = _startOfWeek.subtract(Duration(days: 7));
    });
    _loadUnavailable();
  }

  void _goToNextWeek() {
    setState(() {
      _startOfWeek = _startOfWeek.add(Duration(days: 7));
    });
    _loadUnavailable();
  }

  @override
  Widget build(BuildContext context) {
    final days = List.generate(7, (i) {
      final date = _startOfWeek.add(Duration(days: i));
      return DateFormat('E\nMM/dd').format(date);
    });

    final candidates = _generateCandidates();

    return Scaffold(
      appBar: AppBar(title: const Text("불가능한 시간 설정")),
      body: Column(
        children: [
          // 요일 헤더
          Row(
            children: [
              const SizedBox(width: 60),
              ...days.map((day) => Expanded(
                    child: Center(child: Text(day, textAlign: TextAlign.center)),
                  )),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: hours.map((hour) {
                  return Row(
                    children: [
                      Container(
                        width: 60,
                        height: 40,
                        alignment: Alignment.center,
                        child: Text(hour),
                      ),
                      ...List.generate(7, (i) {
                        final date = _startOfWeek.add(Duration(days: i));
                        final dt = DateTime(date.year, date.month, date.day, int.parse(hour.split(":")[0]));
                        final key = DateFormat('yyyy-MM-dd HH:mm').format(dt);
                        final selected = _unavailable.contains(key);
                        final cellKey = _cellKeys[key] ?? GlobalKey();
                        _cellKeys[key] = cellKey;

                        return Expanded(
                          child: GestureDetector(
                            key: cellKey,
                            onTap: () => _toggleUnavailable(dt),
                            child: Container(
                              height: 40,
                              margin: const EdgeInsets.all(1),
                              decoration: BoxDecoration(
                                color: selected ? Colors.red : Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.arrow_back), onPressed: _goToPreviousWeek),
              Text(
                '${DateFormat('yyyy년 MM월 dd일').format(_startOfWeek)} - '
                '${DateFormat('MM월 dd일').format(_startOfWeek.add(const Duration(days: 6)))}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(icon: const Icon(Icons.arrow_forward), onPressed: _goToNextWeek),
            ],
          ),
        ],
      ),
    );
  }
}
