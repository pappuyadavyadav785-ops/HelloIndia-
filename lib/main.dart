// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  // Ensure engine bindings are wired before any plugin call
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Catch framework-level errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError caught: ${details.exceptionAsString()}');
  };

  // Run app inside guarded zone to catch unhandled async errors
  runZonedGuarded<Future<void>>(() async {
    runApp(const HelloIndiaBootstrap());
  }, (Object error, StackTrace stack) {
    debugPrint('Uncaught async error: $error\n$stack');
  });
}

/// Root application widget responsible for progressive initialization
class HelloIndiaBootstrap extends StatefulWidget {
  const HelloIndiaBootstrap({Key? key}) : super(key: key);

  @override
  State<HelloIndiaBootstrap> createState() => _HelloIndiaBootstrapState();
}

class _HelloIndiaBootstrapState extends State<HelloIndiaBootstrap> {
  bool _initialized = false;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

Future<void> _initializeServices() async {
  try {
    // 1. Initialize Firebase with 10-second timeout to prevent deadlocks
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAAfuxxRLF1tp741VSzk1-Gn_QQzdoOXFM", 
        appId: "1:645310611056:android:c069938f1373d6b2a1beb5",
        messagingSenderId: "645310611056",
        projectId: "helloindia-acf1f",
        storageBucket: "helloindia-acf1f.firebasestorage.app",
      ),
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw TimeoutException('Firebase initialization timed out. Check network or configuration.');
      },
    );
    

      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e) {
      debugPrint('Initialization error: $e');
      if (mounted) {
        setState(() {
          _initError = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HelloIndia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6600), // Saffron brand accent
          primary: const Color(0xFFFF6600),
          secondary: const Color(0xFF048543), // Green brand accent
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
      ),
      home: _buildHomeView(),
    );
  }

  Widget _buildHomeView() {
    // If initialization threw an error, render fallback error screen
    if (_initError != null) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Initialization Error',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _initError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _initError = null;
                      _initialized = false;
                    });
                    _initializeServices();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6600),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // While initializing, show the branded splash screen
    if (!_initialized) {
      return const SplashScreen();
    }

    // Services ready: hand off to auth state gate
    return const AuthStateGate();
  }
}

/// Branded Splash Screen with "HI" identity
class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Branded "HI" Container
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6600), Color(0xFF048543)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6600).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'HI',
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'HelloIndia',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.8,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Authentication state router
class AuthStateGate extends StatelessWidget {
  const AuthStateGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // While Firebase Auth evaluates cached tokens
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        // Active authenticated session
        if (snapshot.hasData && snapshot.data != null) {
          return const PlaceholderHomeScreen();
        }

        // Unauthenticated session
        return const PlaceholderAuthScreen();
      },
    );
  }
}

/// Safe temporary entry screens to confirm rendering success
class PlaceholderHomeScreen extends StatelessWidget {
  const PlaceholderHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('HelloIndia'),
        backgroundColor: const Color(0xFFFF6600),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async => await FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to HelloIndia',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Signed in as: ${user?.phoneNumber ?? user?.email ?? user?.uid}'),
          ],
        ),
      ),
    );
  }
}

class PlaceholderAuthScreen extends StatelessWidget {
  const PlaceholderAuthScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6600),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text(
                    'HI',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'HelloIndia Login Ready',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Phase 2: Screen rendering functional.\nReady for full OTP & Google Sign-In setup.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
