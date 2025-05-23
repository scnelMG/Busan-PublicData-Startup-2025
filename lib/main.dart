import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/calendar/calendar_screen.dart';
import 'screens/home_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '놀콕이라능능',
      theme: ThemeData(useMaterial3: true),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(nickname: '비회원'),
        '/login': (context) => const LoginScreen(),
        // 캘린더는 직접 push로 전달
      },
    );
  }
}

final GoogleSignIn googleSignIn = GoogleSignIn(
  clientId: "824515968706-rnbtspong1767djfob6mk2f1mdguucrr.apps.googleusercontent.com",
  scopes: ['email'],
);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String statusMessage = "로그인되지 않았습니다";

  Future<void> _handleGoogleSignIn() async {
    try {
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        setState(() {
          statusMessage = "사용자가 로그인 취소함";
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // ✅ FirebaseAuth로 로그인
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        // ✅ Firestore에 사용자 정보 저장 (또는 업데이트)
        await FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid).set({
          'uid': firebaseUser.uid,
          'email': firebaseUser.email,
          'displayName': firebaseUser.displayName,
          'photoURL': firebaseUser.photoURL,
          'lastLogin': DateTime.now(),
        }, SetOptions(merge: true));

        setState(() {
          statusMessage = "Firebase 로그인 성공: ${firebaseUser.email}";
        });

        // ✅ 캘린더 화면으로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CalendarScreen(currentUser: firebaseUser),
          ),
        );
      }
    } catch (error) {
      print("로그인 에러: $error");
      setState(() {
        statusMessage = "로그인 실패: $error";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("로그인 화면")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(statusMessage),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _handleGoogleSignIn,
              child: const Text("Google 로그인"),
            ),
          ],
        ),
      ),
    );
  }
}
