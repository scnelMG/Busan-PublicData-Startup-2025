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
  Set<String> _unavailable = {};
  Map<DateTime, List<String>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents();
    _loadUnavailable();
    Future.delayed(Duration.zero, () => _recommendDateTime());
  }

  Future<void> _loadEvents() async {
    final uid = widget.currentUser.uid;
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('events')
        .get();

    Map<DateTime, List<String>> loaded = {};
    for (var doc in snapshot.docs) {
      final date = DateFormat('yyyy-MM-dd').parse(doc.id);
      loaded[date] = List<String>.from(doc['events'] ?? []);
    }

    setState(() {
      _events = loaded;
    });
  }

  Future<void> _loadUnavailable() async {
    final uid = widget.currentUser.uid;
    final DateTime monthStart = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final List<DateTime> weeks = List.generate(5, (i) => _getWeekStart(monthStart.add(Duration(days: i * 7))));

    Set<String> all = {};

    for (final week in weeks) {
      final weekKey = DateFormat('yyyy-MM-dd').format(week);
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('availability')
          .doc(weekKey)
          .get();

      if (doc.exists) {
        final times = List<String>.from(doc.data()?['times'] ?? []);
        all.addAll(times);
      }
    }

    setState(() {
      _unavailable = all;
    });
  }

  DateTime _getWeekStart(DateTime date) {
    return DateTime(date.year, date.month, date.day - (date.weekday - 1));
  }
  Future<void> _recommendSharedTime() async {
  final uid = widget.currentUser.uid;
  final now = DateTime.now();
  final weeks = List.generate(2, (i) => _getWeekStart(now.add(Duration(days: i * 7))));
  final timeKeys = <String>{};

  // 1. 후보 시간대 생성
  for (final week in weeks) {
    for (int d = 0; d < 7; d++) {
      final date = week.add(Duration(days: d));
      for (int h = 8; h <= 22; h++) {
        final dt = DateTime(date.year, date.month, date.day, h);
        if (dt.isAfter(now)) {
          timeKeys.add(DateFormat('yyyy-MM-dd HH:mm').format(dt));
        }
      }
    }
  }

  // 2. 친구 목록 불러오기
  final friendSnapshots = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('friends')
      .get();

  final friendUids = friendSnapshots.docs.map((doc) => doc.id).toList();
  final allUids = [uid, ...friendUids];

  // 3. 각 사용자의 불가능한 시간대 불러오기
  final unavailablePerUser = <String, Set<String>>{};

  for (final userId in allUids) {
    final unavailable = <String>{};
    for (final week in weeks) {
      final weekKey = DateFormat('yyyy-MM-dd').format(week);
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('availability')
          .doc(weekKey)
          .get();
      if (doc.exists) {
        unavailable.addAll(List<String>.from(doc.data()?['times'] ?? []));
      }
    }
    unavailablePerUser[userId] = unavailable;
  }

  // 4. 공통 가능한 시간대 계산
  final sharedAvailable = timeKeys.where((time) {
    return allUids.every((uid) => !unavailablePerUser[uid]!.contains(time));
  }).toList()
    ..sort();

  // 5. 추천 표시
  if (sharedAvailable.isNotEmpty) {
    final dt = DateFormat('yyyy-MM-dd HH:mm').parse(sharedAvailable.first);
    final slotText = "${dt.hour.toString().padLeft(2, '0')}:00~${(dt.hour + 1).toString().padLeft(2, '0')}:00";

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("친구와 가능한 시간"),
        content: Text("${DateFormat('yyyy-MM-dd').format(dt)} $slotText"),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("확인"))],
      ),
    );
  } else {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("겹치는 시간 없음"),
        content: Text("앞으로 2주 내 친구들과 모두 가능한 시간이 없습니다."),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("확인"))],
      ),
    );
  }
}


  Future<void> _deleteEventsForSelectedDay() async {
    if (_selectedDay == null) return;
    final uid = widget.currentUser.uid;
    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDay!);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('events')
        .doc(formattedDate)
        .delete();

    setState(() {
      _events.remove(_selectedDay);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$formattedDate 의 약속이 삭제되었습니다.")),
    );
  }

  void _recommendDateTime() {
    final now = DateTime.now();
    for (int dayOffset = 0; dayOffset < 14; dayOffset++) {
      final date = now.add(Duration(days: dayOffset));
      for (int h = 8; h <= 22; h++) {
        final dt = DateTime(date.year, date.month, date.day, h);
        if (dt.isBefore(now)) continue;
        final key = DateFormat('yyyy-MM-dd HH:mm').format(dt);
        final dateOnly = DateTime(dt.year, dt.month, dt.day);
        final slotText = "${h.toString().padLeft(2, '0')}:00~${(h + 1).toString().padLeft(2, '0')}:00";

        if (_unavailable.contains(key)) continue;
        if (_events[dateOnly]?.contains(slotText) ?? false) continue;

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("추천 시간"),
            content: Text("${DateFormat('yyyy-MM-dd').format(dateOnly)} $slotText"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text("확인")),
            ],
          ),
        );
        return;
      }
    }



    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("추천 시간 없음"),
        content: Text("앞으로 2주 내 가능한 시간이 없습니다."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("확인")),
        ],
      ),
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
          )
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
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
              },
              onFormatChanged: (format) => setState(() => _calendarFormat = format),
              onPageChanged: (focused) {
                _focusedDay = focused;
                _loadUnavailable();
              },
              eventLoader: (day) {
                final date = DateTime(day.year, day.month, day.day);
                List<String> result = [];
                if (_events[date]?.isNotEmpty ?? false) {
                  result.add("약속");
                } else {
                  // 날짜 기준으로 가능 여부 판단
                  for (int h = 8; h <= 22; h++) {
                    final key = DateFormat('yyyy-MM-dd HH:mm')
                        .format(DateTime(date.year, date.month, date.day, h));
                    if (!_unavailable.contains(key)) {
                      result.add("가능");
                      break;
                    }
                  }
                }
                return result;
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isEmpty) return SizedBox();

                  Color dotColor = Colors.grey;
                  if (events.contains("약속")) dotColor = Colors.red;
                  else if (events.contains("가능")) dotColor = Colors.blue;

                  return Positioned(
                    bottom: 1,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dotColor,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _recommendDateTime,
              child: Text("가능한 가장 빠른 시간 추천"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _recommendSharedTime,
              child: Text("친구와 겹치는 시간 추천"),
            ),
            const SizedBox(height: 20),
            if (_selectedDay != null) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "${DateFormat('yyyy-MM-dd').format(_selectedDay!)} 약속 시간대:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),
              if ((_events[_selectedDay!] ?? []).isNotEmpty)
                ..._events[_selectedDay!]!.map((e) => Text("• $e")).toList()
              else
                const Text("약속이 없습니다."),
              const SizedBox(height: 10),
              if ((_events[_selectedDay!] ?? []).isNotEmpty)
                ElevatedButton(
                  onPressed: _deleteEventsForSelectedDay,
                  child: Text("이 날짜의 약속 삭제"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
