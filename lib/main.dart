import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const HelloIndiaBootstrap());
}

class HelloIndiaBootstrap extends StatefulWidget {
  const HelloIndiaBootstrap({Key? key}) : super(key: key);

  @override
  State<HelloIndiaBootstrap> createState() => _HelloIndiaBootstrapState();
}

class _HelloIndiaBootstrapState extends State<HelloIndiaBootstrap> {
  bool _initialized = false;
  String? _initError;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _otpSent = false;
  String _verificationId = "";

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
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
          throw TimeoutException('Firebase initialization timed out.');
        },
      );

      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _initError = e.toString();
        });
      }
    }
  }

  Future<void> _sendOTP() async {
    if (_phoneController.text.isEmpty) return;
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: "+91${_phoneController.text}",
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          _loginSuccess();
        },
        verificationFailed: (FirebaseAuthException e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("OTP Failed: ${e.message}")),
          );
        },
        codeSent: (String verId, int? resendToken) {
          setState(() {
            _verificationId = verId;
            _otpSent = true;
          });
        },
        codeAutoRetrievalTimeout: (String verId) {},
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.isEmpty) return;
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otpController.text,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      _loginSuccess();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("गलत OTP, कृपया दोबारा जांचें।")),
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Google Sign-In Connecting...")),
    );
  }

  void _loginSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("लॉगिन सफल! HelloIndia में आपका स्वागत है।")),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_initError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: Text("Error: $_initError"))),
      );
    }
    if (!_initialized) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.orange))),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 80.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.orange, 
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text("HI", style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 20),
                const Center(child: Text("HelloIndia", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black))),
                const SizedBox(height: 40),

                if (!_otpSent) ...[
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      prefixText: "+91 ",
                      labelText: "मोबाइल नंबर दर्ज करें",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _sendOTP,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(vertical: 15)),
                    child: const Text("OTP भेजें", style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ] else ...[
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "6-अंकों का OTP डालें",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _verifyOTP,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 15)),
                    child: const Text("Verify & Login", style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ],

                const SizedBox(height: 30),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("या")),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 30),

                OutlinedButton.icon(
                  onPressed: _signInWithGoogle,
                  icon: Image.network('https://wikimedia.org', height: 24),
                  label: const Text("Google के साथ लॉग इन करें", style: TextStyle(color: Colors.black54)),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), side: const BorderSide(color: Colors.grey)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
