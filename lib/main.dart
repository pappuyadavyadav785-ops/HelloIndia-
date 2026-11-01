import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  // एरर रोकने के लिए बाइंडिंग पक्की करें
  WidgetsFlutterBinding.ensureInitialized();
  
  // अगर फ़ायरबेस लोड न हो, तो भी ऐप को ब्लैक होने से रोकने के लिए try-catch
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase init failed: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hello India',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white, // स्क्रीन को हमेशा सफेद रखेगा
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true, // बैक बटन को एक बार में बाहर जाने की अनुमति दें
      child: const Scaffold(
        body: Center(
          child: Text(
            'Welcome to Hello India App',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
      ),
    );
  }
}
