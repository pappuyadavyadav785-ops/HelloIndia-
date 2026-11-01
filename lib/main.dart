import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase Bypass: $e");
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
        primaryColor: const Color(0xFF075E54),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF075E54),
          secondary: const Color(0xFF25D366),
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const AuthScreen(),
    );
  }
}

// 1. सुरक्षित मोबाइल नंबर + OTP लॉगिन स्क्रीन
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isOtpSent = false;
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_person, size: 80, color: Theme.of(context).primaryColor),
              const SizedBox(height: 16),
              Text(
                isOtpSent ? 'OTP सत्यापन (Verification)' : 'मोबाइल नंबर से साइन अप / लॉगिन करें',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (!isOtpSent) ...[
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'मोबाइल नंबर', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'पासवर्ड बनाएं', border: OutlineInputBorder(), prefixIcon: Icon(Icons.password)),
                ),
              ] else ...[
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(labelText: '6-अंकों का OTP दर्ज करें (123456)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.sms)),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  if (!isOtpSent) {
                    if (_phoneController.text.length < 10) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('कृपया सही मोबाइल नंबर दर्ज करें')));
                      return;
                    }
                    setState(() { isOtpSent = true; });
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP भेज दिया गया है (टेस्टिंग के लिए: 123456)')));
                  } else {
                    if (_otpController.text == "123456") {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('गलत OTP दर्ज किया गया है')));
                    }
                  }
                },
                child: Text(isOtpSent ? 'सत्यापित करें और आगे बढ़ें' : 'OTP प्राप्त करें', style: const TextStyle(fontSize: 16)),
              ),
              if (isOtpSent)
                TextButton(
                  onPressed: () { setState(() { isOtpSent = false; }); },
                  child: const Text('नंबर बदलें'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// 2. मुख्य होम स्क्रीन (सर्च बार और वर्किंग टैब्स के साथ)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSearching = false;
  final _searchController = TextEditingController();
  
  final List<Map<String, String>> _allChats = [
    {'name': 'अमित कुमार', 'msg': 'फोटो देख ली मैंने', 'time': '10:30 AM'},
    {'name': 'राहुल सिंह', 'msg': 'कल फाइल भेज देना जरूर', 'time': '09:15 AM'},
    {'name': 'प्रिया शर्मा', 'msg': 'वीडियो कॉल पर आओ अभी', 'time': 'कल'},
    {'name': 'विकास यादव', 'msg': 'हाँ भाई, सब ठीक है', 'time': '2 दिन पहले'},
  ];
  
  List<Map<String, String>> _filteredChats = [];

  @override
  void initState() {
    _filteredChats = _allChats;
    super.initState();
  }

  void _filterSearch(String query) {
    setState(() {
      _filteredChats = _allChats
          .where((chat) => chat['name']!.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await SystemNavigator.pop();
      },
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).primaryColor,
            title: _isSearching
                ? TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: 'खोजें (Search)...', hintStyle: TextStyle(color: Colors.white70), border: InputBorder.none),
                    onChanged: _filterSearch,
                  )
                : const Text('Hello India', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchController.clear();
                      _filteredChats = _allChats;
                    }
                  });
                },
              ),
              IconButton(icon: const Icon(Icons.more_vert, color: Colors.white), onPressed: () {}),
            ],
            bottom: const TabBar(
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [Tab(text: 'CHATS'), Tab(text: 'CALLS'), Tab(text: 'PROFILE')],
            ),
          ),
          body: TabBarView(
            children: [
              // चैट्स टैब (वर्किंग सर्च के साथ)
              _filteredChats.isEmpty
                  ? const Center(child: Text('कोई यूजर नहीं मिला'))
                  : ListView.builder(
                      itemCount: _filteredChats.length,
                      itemBuilder: (context, index) {
                        final chat = _filteredChats[index];
                        return ListTile(
                          leading: CircleAvatar(backgroundColor: Theme.of(context).primaryColor, child: Text(chat['name']!.substring(0, 1), style: const TextStyle(color: Colors.white))),
                          title: Text(chat['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(chat['msg']!),
                          trailing: Text(chat['time']!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => ChatDetailScreen(userName: chat['name']!)));
                          },
                        );
                      },
                    ),
              // कॉल्स टैब (वर्किंग बटन के साथ)
              ListView.builder(
                itemCount: 2,
                itemBuilder: (context, index) {
                  List<String> names = ['राहुल सिंह', 'प्रिया शर्मा'];
                  return ListTile(
                    leading: const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.person, color: Colors.white)),
                    title: Text(names[index], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(index == 0 ? 'आज, 9:15 AM' : 'कल, 8:45 PM'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.phone, color: Theme.of(context).primaryColor),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => CallScreen(userName: names[index], isVideo: false)));
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.call_end, color: Colors.white, size: 28),
onPressed: () => Navigator.pop(context),
),
),
],
),
),
],
),
),
);
}
                }
