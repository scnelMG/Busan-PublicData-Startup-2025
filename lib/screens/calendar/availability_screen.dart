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
  final Map<String, GlobalKey> _cellKeys = {};

  Set<String> _dragSelection = {};
  bool _isDragging = false;
  int? _dragColumnIndex;

  static DateTime _getWeekStart(DateTime date) {
    return DateTime(date.year, date.month, date.day - (date.weekday - 1));
  }

  @override
  void initState() {
    super.initState();
    _loadUnavailable();
  }

  List<String> get _hours => List.generate(24, (i) => i.toString().padLeft(2, '0') + ":00");

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
      _startOfWeek = _startOfWeek.subtract(const Duration(days: 7));
    });
    _loadUnavailable();
  }

  void _goToNextWeek() {
    setState(() {
      _startOfWeek = _startOfWeek.add(const Duration(days: 7));
    });
    _loadUnavailable();
  }

  void _checkDragTarget(Offset position) {
    _cellKeys.forEach((key, cellKey) {
      final context = cellKey.currentContext;
      if (context == null) return;
      final box = context.findRenderObject() as RenderBox;
      final offset = box.localToGlobal(Offset.zero);
      final size = box.size;
      final rect = offset & size;

      if (rect.contains(position)) {
        final split = key.split(" ");
        final colIndex = DateTime.parse(split[0]).weekday - 1;
        if (_dragColumnIndex == null) {
          _dragColumnIndex = colIndex;
        }
        if (colIndex == _dragColumnIndex) {
          _dragSelection.add(key);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final days = List.generate(7, (i) {
      final date = _startOfWeek.add(Duration(days: i));
      return DateFormat('E\nMM/dd').format(date);
    });

    return Scaffold(
      appBar: AppBar(title: const Text("불가능한 시간 설정")),
      body: GestureDetector(
        onPanStart: (_) {
          setState(() {
            _isDragging = true;
            _dragSelection.clear();
            _dragColumnIndex = null;
          });
        },
        onPanUpdate: (details) {
          final localPosition = (context.findRenderObject() as RenderBox)
              .globalToLocal(details.globalPosition);
          _checkDragTarget(localPosition);
          setState(() {}); // 반응 즉시 갱신
        },
        onPanEnd: (_) async {
          final newSet = Set<String>.from(_unavailable);
          for (final time in _dragSelection) {
            if (newSet.contains(time)) {
              newSet.remove(time);
            } else {
              newSet.add(time);
            }
          }

          setState(() {
            _unavailable = newSet;
            _isDragging = false;
            _dragColumnIndex = null;
            _dragSelection.clear();
          });

          final uid = widget.currentUser.uid;
          final weekKey = DateFormat('yyyy-MM-dd').format(_startOfWeek);
          final docRef = FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('availability')
              .doc(weekKey);

          await docRef.set({'times': newSet.toList()}, SetOptions(merge: true));
        },
        child: Column(
          children: [
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
                  children: _hours.map((hour) {
                    final hourInt = int.parse(hour.split(":")[0]);
                    if (hourInt < 9 || hourInt > 22) return const SizedBox.shrink();

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
                          final dt = DateTime(date.year, date.month, date.day, hourInt);
                          final key = DateFormat('yyyy-MM-dd HH:mm').format(dt);
                          final isSelected = _unavailable.contains(key);
                          final isDraggingOver = _dragSelection.contains(key);
                          final cellKey = _cellKeys[key] ?? GlobalKey();
                          _cellKeys[key] = cellKey;

                          final color = _isDragging && isDraggingOver
                              ? Colors.indigo.withOpacity(0.5)
                              : isSelected
                                  ? Colors.indigoAccent
                                  : Colors.grey[200];

                          return Expanded(
                            child: GestureDetector(
                              key: cellKey,
                              onTap: () => _toggleUnavailable(dt),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 100),
                                height: 40,
                                margin: const EdgeInsets.all(1),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(6),
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
      ),
    );
  }
}
