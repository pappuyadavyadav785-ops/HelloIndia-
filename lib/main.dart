import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MaterialApp(home: AuthScreen(), debugShowCheckedModeBanner: false));
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isOtp = false;
  final _phone = TextEditingController();
  final _otp = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_person, size: 80, color: Color(0xFF075E54)),
            const SizedBox(height: 16),
            Text(isOtp ? 'OTP सत्यापन' : 'लॉगिन / साइन अप', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
              controller: isOtp ? _otp : _phone,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: isOtp ? '6-अंकों का OTP (123456)' : 'मोबाइल नंबर', border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF075E54), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
              onPressed: () {
                if (!isOtp) {
                  if (_phone.text.length >= 10) setState(() => isOtp = true);
                } else {
                  if (_otp.text == "123456") Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
                }
              },
              child: Text(isOtp ? 'सत्यापित करें' : 'OTP प्राप्त करें'),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSearch = false;
  final _search = TextEditingController();
  final List<Map<String, String>> _all = [
    {'name': 'अमित कुमार', 'msg': 'फोटो देख ली मैंने'},
    {'name': 'राहुल सिंह', 'msg': 'कल फाइल भेज देना'},
    {'name': 'प्रिया शर्मा', 'msg': 'वीडियो कॉल पर आओ'},
  ];
  List<Map<String, String>> _chats = [];

  @override
  void initState() { _chats = _all; super.initState(); }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, res) async { if (!didPop) await SystemNavigator.pop(); },
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF075E54),
            title: _isSearch 
                ? TextField(controller: _search, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'खोजें...', border: InputBorder.none), onChanged: (q) => setState(() => _chats = _all.where((c) => c['name']!.contains(q)).toList()))
                : const Text('Hello India', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            actions: [IconButton(icon: Icon(_isSearch ? Icons.close : Icons.search, color: Colors.white), onPressed: () => setState(() { _isSearch = !_isSearch; _search.clear(); _chats = _all; }))],
            bottom: const TabBar(indicatorColor: Colors.white, labelColor: Colors.white, unselectedLabelColor: Colors.white70, tabs: [Tab(text: 'CHATS'), Tab(text: 'CALLS'), Tab(text: 'PROFILE')]),
          ),
          body: TabBarView(
            children: [
              ListView.builder(
                itemCount: _chats.length,
                itemBuilder: (context, i) => ListTile(
                  leading: CircleAvatar(backgroundColor: const Color(0xFF075E54), child: Text(_chats[i]['name']!.substring(0, 1), style: const TextStyle(color: Colors.white))),
                  title: Text(_chats[i]['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(_chats[i]['msg']!),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChatDetailScreen(userName: _chats[i]['name']!))),
                ),
              ),
              ListView.builder(
                itemCount: 2,
                itemBuilder: (context, i) => ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(i == 0 ? 'राहुल सिंह' : 'प्रिया शर्मा'),
                  subtitle: Text(i == 0 ? 'आज, 9:15 AM' : 'कल, 8:45 PM'),
                  trailing: IconButton(icon: Icon(i == 0 ? Icons.phone : Icons.videocam, color: const Color(0xFF075E54)), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CallScreen(userName: i == 0 ? 'राहुल सिंह' : 'प्रिया शर्मा', isVideo: i != 0)))),
                ),
              ),
              Center(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AuthScreen())), child: const Text('लॉग आउट'))),
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
  final List<Map<String, dynamic>> _msgs = [];
  final _msg = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.userName, style: const TextStyle(color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.videocam), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CallScreen(userName: widget.userName, isVideo: true)))),
          IconButton(icon: const Icon(Icons.call), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CallScreen(userName: widget.userName, isVideo: false)))),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: const Color(0xFFEFE7E2),
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _msgs.length,
                itemBuilder: (context, i) => Align(
                  alignment: _msgs[i]['isMe'] ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: _msgs[i]['isMe'] ? const Color(0xFFDCF8C6) : Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: _msgs[i]['type'] == 'text' ? Text(_msgs[i]['text']) : Row(mainAxisSize: MainAxisSize.min, children: [Icon(_msgs[i]['type'] == 'image' ? Icons.image : Icons.insert_drive_file), const SizedBox(width: 8), Text(_msgs[i]['text'])]),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
                    child: Row(
                      children: [
                        IconButton(icon: const Icon(Icons.attach_file), onPressed: () => showModalBottomSheet(context: context, builder: (c) => Wrap(children: [ListTile(leading: const Icon(Icons.image), title: const Text('फोटो'), onTap: () { Navigator.pop(c); setState(() => _msgs.add({'text': 'Image.png', 'isMe': true, 'type': 'image'})); }), ListTile(leading: const Icon(Icons.file_present), title: const Text('डॉक्यूमेंट'), onTap: () { Navigator.pop(c); setState(() => _msgs.add({'text': 'Document.pdf', 'isMe': true, 'type': 'doc'})); })]))),
                        Expanded(child: TextField(controller: _msg, decoration: const InputDecoration(hintText: 'मैसेज...', border: InputBorder.none))),
                      ],
                    ),
                  ),
                ),
                CircleAvatar(backgroundColor: const Color(0xFF075E54), child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: () { if(_msg.text.isEmpty) return; setState(() => _msgs.add({'text': _msg.text, 'isMe': true, 'type': 'text'})); _msg.clear(); })),
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
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(children: [Text(userName, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text(isVideo ? 'वीडियो कॉल...' : 'ऑडियो कॉल...', style: const TextStyle(color: Colors.white70))]),
          CircleAvatar(radius: 60, backgroundColor: Colors.white24, child: Icon(isVideo ? Icons.videocam : Icons.person, size: 60, color: Colors.white)),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            
