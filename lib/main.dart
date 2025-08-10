import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:green_rewards_v1/screen/get_started_screen.dart';
import 'package:green_rewards_v1/screen/home_screen.dart';
import 'package:green_rewards_v1/screen/leaderboards_screen.dart';
import 'package:green_rewards_v1/screen/login_screen.dart';
import 'package:green_rewards_v1/screen/profile_screen.dart';
import 'package:green_rewards_v1/screen/report_forums_screen.dart';
import 'package:green_rewards_v1/screen/rewards_screen.dart';
import 'package:green_rewards_v1/screen/sign_up_screen.dart';
import 'package:green_rewards_v1/screen/transactions_screen.dart';
import 'package:green_rewards_v1/screen/forgot_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyDslKcef5sJQk2LuGegJTVy6nAfM-jxcug',
      appId: '1:1024622849606:android:e34a223f86345420d12447',
      messagingSenderId: '1024622849606',
      projectId: 'green-rewards-ae329',
      storageBucket: 'green-rewards-ae329.firebasestorage.app',
    ),
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trash Rewards App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const GetStartedScreen(),
      routes: {
        '/signup': (context) => const SignUpScreen(),
        '/login': (context) => const LoginScreen(),
        '/forgot-password': (context) => const ForgotScreen(),
        '/get-started': (context) => const GetStartedScreen(),
        '/home': (context) => const HomeScreen(), 
        '/rewards': (context) => const RewardsScreen(),
        '/report-forum': (context) => const ReportForumScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/transactions': (context) => const TransactionsScreen(),
        '/leaderboards': (context) => const LeaderboardsScreen(),
      },
    );
  }
}