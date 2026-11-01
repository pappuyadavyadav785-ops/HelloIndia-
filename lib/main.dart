import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(HelloIndiaApp());
}

class HelloIndiaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HelloIndia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green),
      home: AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) return HomeScreen();
        return PhoneLoginScreen();
      },
    );
  }
}

class PhoneLoginScreen extends StatefulWidget {
  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final phoneCtrl = TextEditingController();
  final otpCtrl = TextEditingController();
  String verificationId = "";
  bool otpSent = false;
  bool loading = false;

  void sendOTP() async {
    if (phoneCtrl.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("10 digit number dalo")));
      return;
    }
    setState(() => loading = true);
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: '+91${phoneCtrl.text.trim()}',
      verificationCompleted: (c) async {
        await FirebaseAuth.instance.signInWithCredential(c);
      },
      verificationFailed: (e) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.message}")));
      },
      codeSent: (verId, token) {
        setState(() {
          verificationId = verId;
          otpSent = true;
          loading = false;
        });
      },
      codeAutoRetrievalTimeout: (verId) => verificationId = verId,
    );
  }

  void verifyOTP() async {
    try {
      setState(() => loading = true);
      var cred = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: otpCtrl.text.trim());
      var userCred = await FirebaseAuth.instance.signInWithCredential(cred);
      await FirebaseFirestore.instance.collection('users').doc(userCred.user!.uid).set({
        'uid': userCred.user!.uid,
        'phone': '+91${phoneCtrl.text.trim()}',
        'name': 'User ${phoneCtrl.text.trim().substring(6)}',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      setState(() => loading = false);
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Galat OTP")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("HelloIndia - OTP Login")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            if (!otpSent) ...[
              TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: "Mobile Number", prefixText: "+91 ", border: OutlineInputBorder())),
              SizedBox(height: 20),
              loading ? CircularProgressIndicator() : ElevatedButton(onPressed: sendOTP, child: Text("OTP Bhejo")),
            ] else ...[
              TextField(controller: otpCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "6 Digit OTP", border: OutlineInputBorder())),
              SizedBox(height: 20),
              loading ? CircularProgressIndicator() : ElevatedButton(onPressed: verifyOTP, child: Text("Verify & Login")),
              TextButton(onPressed: () => setState(() => otpSent = false), child: Text("Number Badlo"))
            ]
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String searchQuery = "";
  final searchCtrl = TextEditingController();
  @override
  Widget build(BuildContext context) {
    var currentUid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(title: Text("HelloIndia"), actions: [IconButton(icon: Icon(Icons.logout), onPressed: () => FirebaseAuth.instance.signOut())]),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(10),
            child: TextField(
              controller: searchCtrl,
              decoration: InputDecoration(hintText: "Search user by phone/name...", prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
              onChanged: (v) => setState(() => searchQuery = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) return Center(child: CircularProgressIndicator());
                var users = snap.data!.docs.where((d) => d.id != currentUid).toList();
                if (searchQuery.isNotEmpty) {
                  users = users.where((d) {
                    var data = d.data() as Map<String, dynamic>;
                    return (data['name'] ?? '').toString().toLowerCase().contains(searchQuery) || (data['phone'] ?? '').toString().toLowerCase().contains(searchQuery);
                  }).toList();
                }
                if (users.isEmpty) return Center(child: Text("Koi user nahi mila - Dusre number se login karke dekho"));
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (c, i) {
                    var data = users[i].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: CircleAvatar(child: Text(data['name'][0])),
                      title: Text(data['name']),
                      subtitle: Text(data['phone']),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(icon: Icon(Icons.call, color: Colors.green), onPressed: () => Navigator.push(c, MaterialPageRoute(builder: (_) => CallScreen(name: data['name'], isVideo: false)))),
                        IconButton(icon: Icon(Icons.videocam, color: Colors.blue), onPressed: () => Navigator.push(c, MaterialPageRoute(builder: (_) => CallScreen(name: data['name'], isVideo: true)))),
                      ]),
                      onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) => ChatScreen(otherUid: data['uid'], otherName: data['name']))),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String otherUid, otherName;
  ChatScreen({required this.otherUid, required this.otherName});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final msgCtrl = TextEditingController();
  String get chatId {
    var myUid = FirebaseAuth.instance.currentUser!.uid;
    return myUid.hashCode <= widget.otherUid.hashCode ? "${myUid}_${widget.otherUid}" : "${widget.otherUid}_${myUid}";
  }

  void sendMessage({String? text, String? imageBase64, String? fileName}) async {
    if ((text == null || text.isEmpty) && imageBase64 == null && fileName == null) return;
    await FirebaseFirestore.instance.collection('chats').doc(chatId).collection('messages').add({
      'sender': FirebaseAuth.instance.currentUser!.uid,
      'text': text ?? "",
      'image': imageBase64 ?? "",
      'fileName': fileName ?? "",
      'time': FieldValue.serverTimestamp(),
    });
    msgCtrl.clear();
  }

  Future<void> pickImage() async {
    var picker = ImagePicker();
    var x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 30);
    if (x == null) return;
    var bytes = await File(x.path).readAsBytes();
    if (bytes.length > 900000) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Photo bada hai, chhota photo chuno")));
      return;
    }
    String base64 = base64Encode(bytes);
    sendMessage(imageBase64: base64, text: "[Photo]");
  }

  Future<void> pickFile() async {
    var result = await FilePicker.platform.pickFiles();
    if (result == null) return;
    var file = result.files.first;
    if (file.size > 900000) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("File 1MB se kam hona chahiye bina Storage ke")));
      return;
    }
    String base64 = base64Encode(file.bytes!);
    sendMessage(imageBase64: base64, fileName: file.name, text: "[File: ${file.name}]");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.otherName)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('chats').doc(chatId).collection('messages').orderBy('time', descending: true).snapshots(),
              builder: (c, snap) {
                if (!snap.hasData) return Center(child: CircularProgressIndicator());
                return ListView.builder(
                  reverse: true,
                  itemCount: snap.data!.docs.length,
                  itemBuilder: (c, i) {
                    var data = snap.data!.docs[i].data() as Map<String, dynamic>;
                    bool isMe = data['sender'] == FirebaseAuth.instance.currentUser!.uid;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.all(6),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(color: isMe ? Colors.green[100] : Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          if ((data['image'] ?? "").toString().isNotEmpty) Image.memory(base64Decode(data['image']), width: 180),
                          if ((data['text'] ?? "").toString().isNotEmpty) Text(data['text']),
                          if ((data['fileName'] ?? "").toString().isNotEmpty) Text("📎 ${data['fileName']}", style: TextStyle(fontWeight: FontWeight.bold)),
                        ]),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Row(
            children: [
              IconButton(icon: Icon(Icons.photo), onPressed: pickImage),
              IconButton(icon: Icon(Icons.attach_file), onPressed: pickFile),
              Expanded(child: TextField(controller: msgCtrl, decoration: InputDecoration(hintText: "Message likho..."))),
              IconButton(icon: Icon(Icons.send, color: Colors.green), onPressed: () => sendMessage(text: msgCtrl.text.trim())),
            ],
          )
        ],
      ),
    );
  }
}

class CallScreen extends StatelessWidget {
  final String name;
  final bool isVideo;
  CallScreen({required this.name, required this.isVideo});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(isVideo ? Icons.videocam : Icons.call, size: 80, color: Colors.white),
          SizedBox(height: 20),
          Text("${isVideo ? "Video" : "Voice"} Calling $name...", style: TextStyle(color: Colors.white, fontSize: 20)),
          SizedBox(height: 40),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: CircleBorder(), padding: EdgeInsets.all(20)), onPressed: () => Navigator.pop(context), child: Icon(Icons.call_end, size: 30)),
        ]),
      ),
    );
  }
}
