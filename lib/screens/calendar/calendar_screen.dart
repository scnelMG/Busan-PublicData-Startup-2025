import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarScreen extends StatefulWidget {
  final User currentUser;

  const CalendarScreen({super.key, required this.currentUser});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<int>> _availableSlots = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadAvailability();
  }

  DateTime _getWeekStart(DateTime date) {
    return DateTime(date.year, date.month, date.day - (date.weekday - 1));
  }

  Future<void> _loadAvailability() async {
    final uid = widget.currentUser.uid;
    final now = DateTime.now();
    final weeks = List.generate(5, (i) => _getWeekStart(now.add(Duration(days: i * 7))));
    final Set<String> unavailable = {};

    for (final week in weeks) {
      final weekKey = DateFormat('yyyy-MM-dd').format(week);
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('availability')
          .doc(weekKey)
          .get();

      if (doc.exists) {
        unavailable.addAll(List<String>.from(doc.data()?['times'] ?? []));
      }
    }

    // 가능한 시간 계산
    final Map<DateTime, List<int>> available = {};

    for (int dayOffset = 0; dayOffset < 35; dayOffset++) {
      final date = now.add(Duration(days: dayOffset));
      final dateOnly = DateTime(date.year, date.month, date.day);
      final slots = <int>[];

      for (int h = 9; h <= 22; h++) {
        final key = DateFormat('yyyy-MM-dd HH:mm')
            .format(DateTime(date.year, date.month, date.day, h));
        if (!unavailable.contains(key)) {
          slots.add(h);
        }
      }

      if (slots.isNotEmpty) {
        available[dateOnly] = slots;
      }
    }

    setState(() {
      _availableSlots = available;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("약속 가능한 시간 보기")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2020),
              lastDay: DateTime.utc(2030),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
              },
              onPageChanged: (focused) {
                _focusedDay = focused;
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, _) {
                  if (_availableSlots.containsKey(DateTime(date.year, date.month, date.day))) {
                    return Positioned(
                      bottom: 1,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue,
                        ),
                      ),
                    );
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedDay != null)
              Expanded(
                child: _availableSlots.containsKey(
                        DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day))
                    ? ListView(
                        children: _availableSlots[
                                DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)]!
                            .map((h) => ListTile(
                                  title: Text(
                                      "${h.toString().padLeft(2, '0')}:00 ~ ${(h + 1).toString().padLeft(2, '0')}:00"),
                                ))
                            .toList(),
                      )
                    : const Center(child: Text("가능한 시간이 없습니다.")),
              )
          ],
        ),
      ),
    );
  }
}
