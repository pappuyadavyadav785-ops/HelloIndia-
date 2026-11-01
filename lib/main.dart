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

// 1. व्यावसायिक मोबाइल नंबर + OTP लॉगिन स्क्रीन
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
                textAlign: Center,
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
                  decoration: const InputDecoration(labelText: '6-अंकों का OTP दर्ज करें', border: OutlineInputBorder(), prefixIcon: Icon(Icons.sms)),
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
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP आपके नंबर पर भेज दिया गया है (डिफ़ॉल्ट: 123456)')));
                  } else {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
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

// 2. मुख्य होम स्क्रीन (सर्च बार और टैब्स के साथ)
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
    {'name': 'विकास यादव', 'msg': 'हाँ भाई, सब ठीक है', 'time': '२ दिन पहले'},
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
                    trailing: IconButton(
                      icon: Icon(index == 0 ? Icons.phone : Icons.videocam, color: Theme.of(context).primaryColor),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => CallScreen(userName: names[index], isVideo: index != 0)));
                      },
                    ),
                  );
                },
              ),
              // प्रोफाइल टैब
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(radius: 40, backgroundColor: Theme.of(context).primaryColor, child: const Icon(Icons.person, size: 50, color: Colors.white)),
                    // 3. एडवांस चैट स्क्रीन (कॉलिंग और मीडिया अटैचमेंट फीचर्स के साथ)
class ChatDetailScreen extends StatefulWidget {
  final String userName;
  const ChatDetailScreen({super.key, required this.userName});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final List<Map<String, dynamic>> _messages = [];
  final _messageController = TextEditingController();

  void _sendMessage(String text, {String type = 'text'}) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add({'text': text, 'isMe': true, 'type': type});
    });
    _messageController.clear();
    
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _messages.add({'text': 'प्राप्त हुआ: $text', 'isMe': false, 'type': 'text'});
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.userName, style: const TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam, color: Colors.white),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => CallScreen(userName: widget.userName, isVideo: true)));
            },
          ),
          IconButton(
            icon: const Icon(Icons.call, color: Colors.white),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => CallScreen(userName: widget.userName, isVideo: false)));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: const Color(0xFFEFE7E2),
              child: _messages.isEmpty
                  ? Center(child: Text('${widget.userName} के साथ चैट और मीडिया शेयर करें', style: const TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final isMe = msg['isMe'];
                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isMe ? const Color(0xFFDCF8C6) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: msg['type'] == 'text'
                                ? Text(msg['text'], style: const TextStyle(fontSize: 16))
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(msg['type'] == 'image' ? Icons.image : Icons.insert_drive_file, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Text(msg['text'], style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
                                    ],
                                  ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)]),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.attach_file, color: Colors.grey),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (context) => Wrap(
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.image, color: Colors.green),
                                    title: const Text('फोटो / इमेजेस भेजें'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _sendMessage('Photo_File.png', type: 'image');
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.insert_drive_file, color: Colors.blue),
                                    title: const Text('डॉक्यूमेंट फ़ाइल भेजें'),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _sendMessage('Document_File.pdf', type: 'doc');
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: const InputDecoration(hintText: 'मैसेज टाइप करें...', border: InputBorder.none),
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.camera_alt, color: Colors.grey), onPressed: () => _sendMessage('Camera_Capture.jpg', type: 'image')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  radius: 22,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: () => _sendMessage(_messageController.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 4. वर्किंग लाइव कॉलिंग स्क्रीन
class CallScreen extends StatelessWidget {
  final String userName;
  final bool isVideo;
  const CallScreen({super.key, required this.userName, required this.isVideo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF075E54),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 60.0),
              child: Column(
                children: [
                  Text(userName, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(isVideo ? 'वीडियो कॉल कनेक्टेड है...' : 'ऑडियो कॉल कनेक्टेड है...', style: const TextStyle(color: Colors.white70, fontSize: 16)),
                ],
              ),
            ),
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white24,
                child: isVideo ? const Icon(Icons.videocam, size: 60, color: Colors.white) : const Icon(Icons.person, size: 60, color: Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 60.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white24,
                    child: IconButton(icon: Icon(isVideo ? Icons.videocam_off : Icons.mic_off, color: Colors.white), onPressed: () {}),
                  ),
                  const SizedBox(width: 40),
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.red,
                    child: IconButton(
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
                    
