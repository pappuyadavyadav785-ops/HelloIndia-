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
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isSignUp = false;
  final _emailController = TextEditingController();
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
              Icon(Icons.chat_bubble, size: 80, color: Theme.of(context).primaryColor),
              const SizedBox(height: 16),
              Text(
                isSignUp ? 'नया अकाउंट बनाएं' : 'Hello India में लॉग इन करें',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'ईमेल (Email)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'पासवर्ड (Password)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
                },
                child: Text(isSignUp ? 'साइन अप (Sign Up)' : 'लॉग इन (Log In)', style: const TextStyle(fontSize: 16)),
              ),
              TextButton(
                onPressed: () {
                  setState(() { isSignUp = !isSignUp; });
                },
                child: Text(isSignUp ? 'पहले से अकाउंट है? लॉग इन करें' : 'नया अकाउंट चाहिए? साइन अप करें'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
            title: const Text('Hello India', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            actions: [
              IconButton(icon: const Icon(Icons.search, color: Colors.white), onPressed: () {}),
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
              ListView.builder(
                itemCount: 4,
                itemBuilder: (context, index) {
                  List<String> names = ['अमित कुमार', 'राहुल सिंह', 'प्रिया शर्मा', 'विकास यादव'];
                  List<String> messages = ['फोटो देख ली मैंने', 'कल फाइल भेज देना जरूर', 'वीडियो कॉल पर आओ अभी', 'हाँ भाई, सब ठीक है'];
                  return ListTile(
                    leading: CircleAvatar(backgroundColor: Theme.of(context).primaryColor, child: Text(names[index].substring(0, 1), style: const TextStyle(color: Colors.white))),
                    title: Text(names[index], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(messages[index]),
                    trailing: const Text('10:30 AM', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ChatDetailScreen(userName: names[index])));
                    },
                  );
                },
              ),
              ListView.builder(
                itemCount: 2,
                itemBuilder: (context, index) {
                  List<String> names = ['राहुल सिंह', 'प्रिया शर्मा'];
                  return ListTile(
                    leading: const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.person, color: Colors.white)),
                    title: Text(names[index], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Row(
                      children: [
                        Icon(index == 0 ? Icons.call_made : Icons.call_received, color: index == 0 ? Colors.green : Colors.red, size: 16),
                        const SizedBox(width: 5),
                        Text(index == 0 ? 'आज, 9:15 AM' : 'कल, 8:45 PM'),
                      ],
                    ),
                    trailing: Icon(index == 0 ? Icons.phone : Icons.videocam, color: Theme.of(context).primaryColor),
                  );
                },
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(radius: 30, backgroundColor: Theme.of(context).primaryColor, child: const Icon(Icons.person, size: 50, color: Colors.white)),
                    const SizedBox(height: 16),
                    const Text('Hello India User', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Status: Available', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                      onPressed: () {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('लॉग आउट'),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
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
                  ? Center(child: Text('${widget.userName} के साथ चैट और media शेयर करें', style: const TextStyle(color: Colors.grey)))
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
                  Text(isVideo ? 'वीडियो कॉल कनेक्ट हो रहा है...' : 'ऑдио कॉल कनेक्ट हो रहा है...', style: const TextStyle(color: Colors.white70, fontSize: 16)),
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
