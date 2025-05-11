import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/googleapis_auth.dart';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<String>> _events = {};
  GoogleSignInAccount? _currentUser;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [calendar.CalendarApi.calendarScope],
  );

  @override
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged.listen((account) {
      setState(() {
        _currentUser = account;
      });
      if (account != null) {
        _fetchEvents();
      }
    });
    _googleSignIn.signInSilently();
  }

  Future<void> _fetchEvents() async {
    if (_currentUser == null) return;

    try {
      final authHeaders = await _currentUser!.authHeaders;
      final accessToken = authHeaders['Authorization']?.split(' ').last;

      if (accessToken != null) {
        final client = authenticatedClient(http.Client(), AccessCredentials(
          AccessToken('Bearer', accessToken, DateTime.now().add(Duration(hours: 1))),
          null,
          [calendar.CalendarApi.calendarScope],
        ));

        final calendarApi = calendar.CalendarApi(client);
        final events = await calendarApi.events.list(
          "primary",
          timeMin: DateTime.now().toUtc(),
          timeMax: DateTime.now().add(Duration(days: 30)).toUtc(),
          singleEvents: true,
          orderBy: "startTime",
        );

        setState(() {
          _events.clear();
          for (var event in events.items ?? []) {
            DateTime startDate = event.start?.dateTime?.toLocal() ?? DateTime.now();
            String title = event.summary ?? "No Title";

            _events[startDate] = _events[startDate] ?? [];
            _events[startDate]!.add(title);
          }
        });
      }
    } catch (e) {
      print("Error fetching events: $e");
    }
  }

  void _recommendDate() {
    List<DateTime> dates = _events.keys.toList();
    dates.sort((a, b) => a.compareTo(b));

    if (dates.isNotEmpty) {
      DateTime recommendedDate = dates.first;
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("추천 약속 날짜"),
            content: Text("가장 빠른 약속 날짜는 ${DateFormat('yyyy-MM-dd').format(recommendedDate)} 입니다."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("확인"),
              ),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("일정이 없습니다!")),
      );
    }
  }

  Future<void> _signIn() async {
    try {
      await _googleSignIn.signIn();
    } catch (e) {
      print("Error signing in: $e");
    }
  }

  Future<void> _signOut() async {
    await _googleSignIn.signOut();
    setState(() {
      _events.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("캘린더"),
        actions: [
          IconButton(
            icon: Icon(_currentUser != null ? Icons.logout : Icons.login),
            onPressed: _currentUser != null ? _signOut : _signIn,
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
                return _events[day] ?? [];
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _recommendDate,
              child: Text("가장 빠른 약속 날짜 추천"),
            ),
          ],
        ),
      ),
    );
  }
}
