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

  Map<String, Map<DateTime, Set<int>>> _availablePerUser = {};
  Map<String, String> _friendNames = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _normalizeDate(_focusedDay);
    _loadFriendNames().then((_) => _loadSharedAvailability());
  }

  DateTime _normalizeDate(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
  DateTime _getWeekStart(DateTime date) =>
      DateTime(date.year, date.month, date.day - (date.weekday - 1));

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

    final availablePerUser = <String, Map<DateTime, Set<int>>>{};

    for (final key in allTimeKeys) {
      final dt = DateFormat('yyyy-MM-dd HH:mm').parse(key);
      final dateOnly = _normalizeDate(dt);
      final hour = dt.hour;

      for (final uid in allUids) {
        if (!unavailablePerUser[uid]!.contains(key) &&
            !reservedPerUser[uid]!.contains(key)) {
          availablePerUser.putIfAbsent(uid, () => {}).putIfAbsent(dateOnly, () => {}).add(hour);
        }
      }
    }

    setState(() {
      _availablePerUser = availablePerUser;
    });
  }

  Color _userColor(String uid) {
    final allUids = [widget.currentUser.uid, ...widget.selectedFriendIds];
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.brown,
    ];
    final index = allUids.indexOf(uid) % colors.length;
    return colors[index];
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소")),
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
    final selectedDateOnly = _selectedDay != null ? _normalizeDate(_selectedDay!) : null;

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
                  _selectedDay = _normalizeDate(selected);
                  _focusedDay = focused;
                });
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, _) {
                  final day = _normalizeDate(date);

                  final markers = _availablePerUser.entries
                      .where((entry) => entry.value.containsKey(day))
                      .map((entry) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _userColor(entry.key),
                              shape: BoxShape.circle,
                            ),
                          ))
                      .toList();

                  if (markers.isEmpty) return null;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: markers,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            if (selectedDateOnly != null)
              Expanded(
                child: Builder(
                  builder: (context) {
                    final allUids = [widget.currentUser.uid, ...widget.selectedFriendIds];
                    final availableTimes = List<int>.generate(14, (i) => i + 9).where((hour) {
                      return allUids.every((uid) =>
                          _availablePerUser[uid]?[selectedDateOnly]?.contains(hour) ?? false);
                    }).toList();

                    return availableTimes.isNotEmpty
                        ? ListView(
                            children: availableTimes.map((hour) {
                              final dt = DateTime(
                                  selectedDateOnly.year, selectedDateOnly.month, selectedDateOnly.day, hour);
                              return ListTile(
                                leading: const Icon(Icons.access_time),
                                title: Text(
                                    "${hour.toString().padLeft(2, '0')}:00 ~ ${(hour + 1).toString().padLeft(2, '0')}:00"),
                                onTap: () => _showConfirmationDialog(dt),
                              );
                            }).toList(),
                          )
                        : const Center(child: Text("이 날은 모두 가능한 시간이 없습니다."));
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
