import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarScreen extends StatefulWidget {
  final User currentUser;

  CalendarScreen({required this.currentUser});

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<String>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEventsFromFirestore();
  }

  Future<void> _loadEventsFromFirestore() async {
    final uid = widget.currentUser.uid;
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('events')
        .get();

    Map<DateTime, List<String>> loadedEvents = {};

    for (var doc in snapshot.docs) {
      final date = DateFormat('yyyy-MM-dd').parse(doc.id);
      final events = List<String>.from(doc['events'] ?? []);
      loadedEvents[date] = events;
    }

    setState(() {
      _events = loadedEvents;
    });
  }

  Future<void> _saveEventToFirestore(DateTime date, String title) async {
    final uid = widget.currentUser.uid;
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('events')
        .doc(formattedDate)
        .set({
      'date': formattedDate,
      'events': FieldValue.arrayUnion([title]),
    }, SetOptions(merge: true));
  }

  void _addEvent() {
    if (_selectedDay == null) return;

    final selectedDate = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);

    setState(() {
      _events[selectedDate] = _events[selectedDate] ?? [];
      _events[selectedDate]!.add("약속");
    });

    _saveEventToFirestore(selectedDate, "약속");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${DateFormat('yyyy-MM-dd').format(selectedDate)}에 약속이 추가되었습니다.")),
    );
  }

  void _recommendDate() {
    DateTime startDate = DateTime.now();
    DateTime? recommendedDate;

    for (int i = 0; i <= 30; i++) {
      DateTime checkDate = DateTime(startDate.year, startDate.month, startDate.day).add(Duration(days: i));
      if ((_events[checkDate]?.isEmpty ?? true)) {
        recommendedDate = checkDate;
        break;
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("추천 약속 날짜"),
          content: Text(
            recommendedDate != null
                ? "가장 빠른 약속 없는 날짜는 ${DateFormat('yyyy-MM-dd').format(recommendedDate)} 입니다."
                : "앞으로 30일 내 모든 날짜에 약속이 있습니다.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("확인"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text("캘린더"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                user.displayName ?? user.email ?? '사용자',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () {
              Navigator.pushNamed(context, '/friend-list');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TableCalendar(
              focusedDay: _focusedDay,
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              eventLoader: (day) {
                final date = DateTime(day.year, day.month, day.day);
                return _events[date] ?? [];
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addEvent,
              child: Text("선택한 날짜에 약속 등록"),
            ),
            ElevatedButton(
              onPressed: _recommendDate,
              child: Text("가장 빠른 약속 없는 날짜 추천"),
            ),
          ],
        ),
      ),
    );
  }
}
