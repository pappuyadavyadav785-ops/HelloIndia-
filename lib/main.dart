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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? "Failed")));
      },
      codeSent: (verId, resend) {
        setState(() {
          verificationId = verId;
          otpSent = true;
          loading = false;
        });
      },
      codeAutoRetrievalTimeout: (verId) {
        verificationId = verId;
      },
    );
  }

  void verifyOTP() async {
    try {
      setState(() => loading = true);
      PhoneAuthCredential cred = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: otpCtrl.text.trim());
      await FirebaseAuth.instance.signInWithCredential(cred);
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Galat OTP")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("HelloIndia Login")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: "Phone Number", prefixText: "+91 ")),
            SizedBox(height: 20),
            if (otpSent) TextField(controller: otpCtrl, decoration: InputDecoration(labelText: "OTP")),
            SizedBox(height: 20),
            loading ? CircularProgressIndicator() : ElevatedButton(onPressed: otpSent ? verifyOTP : sendOTP, child: Text(otpSent ? "Verify OTP" : "Send OTP")),
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
  final searchCtrl = TextEditingController();
  List<DocumentSnapshot> searchResult = [];

  void doSearch(String val) async {
    if (val.trim().isEmpty) {
      setState(() => searchResult = []);
      return;
    }
    var res = await FirebaseFirestore.instance.collection('users').where('phone', isGreaterThanOrEqualTo: val).where('phone', isLessThan: val + 'z').get();
    setState(() => searchResult = res.docs);
  }

  void createUserDoc() async {
    var user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'phone': user.phoneNumber ?? "",
          'name': user.phoneNumber ?? "User",
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    createUserDoc();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("HelloIndia"), actions: [IconButton(onPressed: () => FirebaseAuth.instance.signOut(), icon: Icon(Icons.logout))]),
      body: Column(
        children: [
          Padding(padding: EdgeInsets.all(10), child: TextField(controller: searchCtrl, onChanged: doSearch, decoration: InputDecoration(hintText: "Phone number se search karo", prefixIcon: Icon(Icons.search), border: OutlineInputBorder()))),
          Expanded(child: searchResult.isEmpty ? StreamBuilder(stream: FirebaseFirestore.instance.collection('chats').where('members', arrayContains: FirebaseAuth.instance.currentUser!.uid).snapshots(), builder: (c, s) {
            if (!s.hasData) return Center(child: CircularProgressIndicator());
            return ListView(children: s.data!.docs.map((d) => ListTile(title: Text(d['lastMessage'] ?? ""), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(chatId: d.id, otherUserId: (d['members'] as List).firstWhere((e) => e != FirebaseAuth.instance.currentUser!.uid)))))).toList());
          }) : ListView.builder(itemCount: searchResult.length, itemBuilder: (c, i) {
            var data = searchResult[i].data() as Map;
            if (data['uid'] == FirebaseAuth.instance.currentUser!.uid) return SizedBox();
            return ListTile(title: Text(data['phone'] ?? ""), subtitle: Text(data['name'] ?? ""), trailing: Icon(Icons.chat), onTap: () async {
              var myUid = FirebaseAuth.instance.currentUser!.uid;
              var otherUid = data['uid'];
              var chatId = myUid.hashCode <= otherUid.hashCode ? "${myUid}_$otherUid" : "${otherUid}_$myUid";
              var chatDoc = await FirebaseFirestore.instance.collection('chats').doc(chatId).get();
              if (!chatDoc.exists) {
                await FirebaseFirestore.instance.collection('chats').doc(chatId).set({'members': [myUid, otherUid], 'lastMessage': '', 'createdAt': FieldValue.serverTimestamp()});
              }
              Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(chatId: chatId, otherUserId: otherUid)));
            });
          })),
        ],
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  ChatScreen({required this.chatId, required this.otherUserId});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final msgCtrl = TextEditingController();
  final ImagePicker picker = ImagePicker();

  void sendMessage({String? text, String? base64Image, String? fileName, String? fileBase64}) async {
    if ((text == null || text.trim().isEmpty) && base64Image == null && fileBase64 == null) return;
    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).collection('messages').add({
      'senderId': FirebaseAuth.instance.currentUser!.uid,
      'text': text ?? "",
      'imageBase64': base64Image ?? "",
      'fileName': fileName ?? "",
      'fileBase64': fileBase64 ?? "",
      'time': FieldValue.serverTimestamp(),
    });
    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({'lastMessage': text != null && text.isNotEmpty ? text : fileName != null ? "File: $fileName" : "Photo"});
    msgCtrl.clear();
  }

  Future<void> pickImage() async {
    var x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 30);
    if (x != null) {
      var bytes = await File(x.path).readAsBytes();
      var base64Str = base64Encode(bytes);
      sendMessage(base64Image: base64Str);
    }
  }

  Future<void> pickFile() async {
    var result = await FilePicker.platform.pickFiles(withData: true);
    if (result != null) {
      var file = result.files.first;
      var base64Str = file.bytes != null ? base64Encode(file.bytes!) : "";
      sendMessage(fileName: file.name, fileBase64: base64Str, text: "File");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chat")),
      body: Column(
        children: [
          Expanded(child: StreamBuilder(stream: FirebaseFirestore.instance.collection('chats').doc(widget.chatId).collection('messages').orderBy('time', descending: true).snapshots(), builder: (c, s) {
            if (!s.hasData) return Center(child: CircularProgressIndicator());
            return ListView.builder(reverse: true, itemCount: s.data!.docs.length, itemBuilder: (c, i) {
              var m = s.data!.docs[i].data() as Map;
              bool isMe = m['senderId'] == FirebaseAuth.instance.currentUser!.uid;
              return Align(alignment: isMe ? Alignment.centerRight : Alignment.centerLeft, child: Container(margin: EdgeInsets.all(6), padding: EdgeInsets.all(10), decoration: BoxDecoration(color: isMe ? Colors.green[100] : Colors.grey[200], borderRadius: BorderRadius.circular(10)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if ((m['text'] ?? "").toString().isNotEmpty) Text(m['text']),
                if ((m['imageBase64'] ?? "").toString().isNotEmpty) Image.memory(base64Decode(m['imageBase64']), width: 150),
                if ((m['fileName'] ?? "").toString().isNotEmpty) Text("📄 ${m['fileName']}", style: TextStyle(fontWeight: FontWeight.bold)),
              ])));
            });
          })),
          Row(children: [
            IconButton(onPressed: pickImage, icon: Icon(Icons.photo)),
            IconButton(onPressed: pickFile, icon: Icon(Icons.attach_file)),
            Expanded(child: TextField(controller: msgCtrl, decoration: InputDecoration(hintText: "Message"))),
            IconButton(onPressed: () => sendMessage(text: msgCtrl.text), icon: Icon(Icons.send)),
          ]),
        ],
      ),
    );
  }
}
