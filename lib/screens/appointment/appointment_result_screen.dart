import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppointmentResultScreen extends StatefulWidget {
  final User currentUser;
  final List<String> selectedFriendIds;

  const AppointmentResultScreen({
    super.key,
    required this.currentUser,
    required this.selectedFriendIds,
  });

  @override
  State<AppointmentResultScreen> createState() => _AppointmentResultScreenState();
}

class _AppointmentResultScreenState extends State<AppointmentResultScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<int>> _sharedAvailable = {};
  Map<String, String> _friendNames = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadFriendNames().then((_) => _loadSharedAvailability());
  }

  DateTime _getWeekStart(DateTime date) {
    return DateTime(date.year, date.month, date.day - (date.weekday - 1));
  }

  Future<void> _loadFriendNames() async {
    for (final uid in widget.selectedFriendIds) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      _friendNames[uid] = doc.data()?['displayName'] ?? '이름없음';
    }
  }

  Future<void> _loadSharedAvailability() async {
    final now = DateTime.now();
    final weeks = List.generate(2, (i) => _getWeekStart(now.add(Duration(days: i * 7))));
    final allUids = [widget.currentUser.uid, ...widget.selectedFriendIds];
    final Set<String> allTimeKeys = {};

    for (final week in weeks) {
      for (int d = 0; d < 7; d++) {
        final date = week.add(Duration(days: d));
        for (int h = 9; h <= 22; h++) {
          final dt = DateTime(date.year, date.month, date.day, h);
          if (dt.isAfter(now)) {
            allTimeKeys.add(DateFormat('yyyy-MM-dd HH:mm').format(dt));
          }
        }
      }
    }

    final unavailablePerUser = <String, Set<String>>{};
    final reservedPerUser = <String, Set<String>>{};

    for (final uid in allUids) {
      final unavailable = <String>{};
      final reserved = <String>{};

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

      for (final key in allTimeKeys) {
        final dt = DateFormat('yyyy-MM-dd HH:mm').parse(key);
        final dateKey = DateFormat('yyyy-MM-dd').format(dt);
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('events')
            .doc(dateKey)
            .get();

        if (snapshot.exists) {
          final reservedSlots = List<String>.from(snapshot.data()?['events'] ?? []);
          for (final slot in reservedSlots) {
            if (slot.startsWith(dt.hour.toString().padLeft(2, '0'))) {
              reserved.add(key);
            }
          }
        }
      }

      unavailablePerUser[uid] = unavailable;
      reservedPerUser[uid] = reserved;
    }

    final sharedAvailable = <DateTime, List<int>>{};

    for (final key in allTimeKeys) {
      final dt = DateFormat('yyyy-MM-dd HH:mm').parse(key);
      final dateOnly = DateTime(dt.year, dt.month, dt.day);
      final hour = dt.hour;

      final isAvailableForAll = allUids.every((uid) =>
          !unavailablePerUser[uid]!.contains(key) &&
          !reservedPerUser[uid]!.contains(key));

      if (isAvailableForAll) {
        sharedAvailable.putIfAbsent(dateOnly, () => []).add(hour);
      }
    }

    setState(() {
      _sharedAvailable = sharedAvailable;
    });
  }

  Future<void> _createAppointment(DateTime dateTime) async {
    final String timeKey = DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
    final dateKey = DateFormat('yyyy-MM-dd').format(dateTime);
    final hourKey = dateTime.hour.toString().padLeft(2, '0');

    final participantIds = [widget.currentUser.uid, ...widget.selectedFriendIds];

    for (final uid in participantIds) {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('events')
          .doc(dateKey);

      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        await docRef.update({
          'events': FieldValue.arrayUnion(["$hourKey:00"]),
        });
      } else {
        await docRef.set({
          'events': ["$hourKey:00"],
        });
      }
    }

    await FirebaseFirestore.instance.collection('appointments').add({
      'creator': widget.currentUser.uid,
      'participants': participantIds,
      'datetime': timeKey,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  void _showConfirmationDialog(DateTime dateTime) {
    final hour = dateTime.hour;
    final formatted = DateFormat('yyyy-MM-dd').format(dateTime);
    final names = [widget.currentUser.displayName, ..._friendNames.values].join(", ");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("약속 등록 확인"),
        content: Text(
          "$names\n${formatted} ${hour.toString().padLeft(2, '0')}:00 ~ ${(hour + 1).toString().padLeft(2, '0')}:00\n\n이 시간에 약속을 잡을까요?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _createAppointment(dateTime);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("약속이 등록되었습니다!")),
              );
            },
            child: const Text("등록"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("약속 잡기 ③")),
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
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, _) {
                  if (_sharedAvailable.containsKey(DateTime(date.year, date.month, date.day))) {
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
                child: _sharedAvailable.containsKey(
                        DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day))
                    ? ListView(
                        children: _sharedAvailable[
                                DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)]!
                            .map((h) {
                          final selectedDateTime = DateTime(
                              _selectedDay!.year, _selectedDay!.month, _selectedDay!.day, h);
                          return ListTile(
                            leading: const Icon(Icons.access_time),
                            title: Text(
                                "${h.toString().padLeft(2, '0')}:00 ~ ${(h + 1).toString().padLeft(2, '0')}:00"),
                            onTap: () => _showConfirmationDialog(selectedDateTime),
                          );
                        }).toList(),
                      )
                    : const Center(child: Text("이 날은 모두 가능한 시간이 없습니다.")),
              ),
          ],
        ),
      ),
    );
  }
}
