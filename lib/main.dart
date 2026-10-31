import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const HelloIndiaApp());
}

class HelloIndiaApp extends StatelessWidget {
  const HelloIndiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HelloIndia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D47A1),
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

final auth = FirebaseAuth.instance;
final db = FirebaseFirestore.instance;
final storage = FirebaseStorage.instance;

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == null) return const LoginScreen();
        return const HomeScreen();
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  final name = TextEditingController();
  bool register = false;
  bool busy = false;

  Future<void> submit() async {
    if (email.text.trim().isEmpty || password.text.length < 6) {
      message('Email भरें और पासवर्ड कम से कम 6 अक्षर का रखें।');
      return;
    }

    setState(() => busy = true);
    try {
      if (register) {
        if (name.text.trim().isEmpty) {
          message('अपना नाम लिखें।');
          return;
        }
        final result = await auth.createUserWithEmailAndPassword(
          email: email.text.trim(),
          password: password.text,
        );
        await db.collection('users').doc(result.user!.uid).set({
          'name': name.text.trim(),
          'email': email.text.trim(),
          'photoUrl': '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await auth.signInWithEmailAndPassword(
          email: email.text.trim(),
          password: password.text,
        );
      }
    } on FirebaseAuthException catch (e) {
      message(e.message ?? 'Login नहीं हो पाया।');
    } catch (e) {
      message('Error: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.forum, size: 76, color: Color(0xFF0D47A1)),
              const SizedBox(height: 12),
              const Text(
                'HelloIndia',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const Text('Connect with people'),
              const SizedBox(height: 28),
              if (register)
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Your name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
              if (register) const SizedBox(height: 12),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password (at least 6 characters)',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: busy ? null : submit,
                  child: Text(
                    busy
                        ? 'Please wait...'
                        : register
                            ? 'Create account'
                            : 'Login',
                  ),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => register = !register),
                child: Text(register
                    ? 'Already have an account? Login'
                    : 'New user? Create account'),
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
    final me = auth.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('HelloIndia'),
        actions: [
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () => auth.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: db.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Could not load users.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final people = snapshot.data!.docs
              .where((doc) => doc.id != me.uid)
              .toList();

          if (people.isEmpty) {
            return const Center(
              child: Text('अभी कोई दूसरा यूज़र नहीं है।'),
            );
          }

          return ListView.builder(
            itemCount: people.length,
            itemBuilder: (context, index) {
              final person = people[index];
              final data = person.data();
              final photo = data['photoUrl'] as String? ?? '';

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                      photo.isNotEmpty ? NetworkImage(photo) : null,
                  child: photo.isEmpty
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(data['name'] as String? ?? 'User'),
                subtitle: Text(data['email'] as String? ?? ''),
                trailing: const Icon(Icons.chat_bubble_outline),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      peerId: person.id,
                      peerName: data['name'] as String? ?? 'User',
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String peerId;
  final String peerName;

  const ChatScreen({
    super.key,
    required this.peerId,
    required this.peerName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final input = TextEditingController();
  bool busy = false;

  String get chatId {
    final ids = [auth.currentUser!.uid, widget.peerId]..sort();
    return ids.join('_');
  }

  Future<void> send({String text = '', String mediaUrl = ''}) async {
    if (text.trim().isEmpty && mediaUrl.isEmpty) return;

    await db.collection('chats').doc(chatId).collection('messages').add({
      'senderId': auth.currentUser!.uid,
      'text': text.trim(),
      'mediaUrl': mediaUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
    input.clear();
  }

  Future<void> sendMedia() async {
    final picker = ImagePicker();
    final file = await picker.pickMedia();
    if (file == null) return;

    setState(() => busy = true);
    try {
      final ref = storage.ref(
        'chat_media/$chatId/${DateTime.now().millisecondsSinceEpoch}_${file.name}',
      );
      final uploaded = await ref.putFile(File(file.path));
      final url = await uploaded.ref.getDownloadURL();
      await send(mediaUrl: url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final me = auth.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.peerName),
        actions: [
          IconButton(
            tooltip: 'Voice call (setup required)',
            icon: const Icon(Icons.call),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Voice calling अभी सेटअप नहीं हुई है।'),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Video call (setup required)',
            icon: const Icon(Icons.video_call),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Video calling अभी सेटअप नहीं हुई है।'),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: db
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Chat load नहीं हुई।'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;
                if (messages.isEmpty) {
                  return const Center(child: Text('पहला मैसेज भेजें!'));
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data();
                    final mine = data['senderId'] == me;
                    final text = data['text'] as String? ?? '';
                    final media = data['mediaUrl'] as String? ?? '';

                    return Align(
                      alignment: mine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 280),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: mine
                              ? Colors.blue.shade100
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (media.isNotEmpty)
                              Image.network(
                                media,
                                width: 220,
                                errorBuilder: (_, __, ___) =>
                                    const Text('Media unavailable'),
                              ),
                            if (text.isNotEmpty) Text(text),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: busy ? null : sendMedia,
                    icon: const Icon(Icons.attach_file),
                  ),
                  Expanded(
                    child: TextField(
                      controller: input,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Message...',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => send(text: input.text),
                    ),
                  ),
                  IconButton(
                    onPressed: () => send(text: input.text),
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final name = TextEditingController();
  bool loaded = false;
  bool busy = false;
  String photoUrl = '';

  Future<void> loadProfile() async {
    if (loaded) return;
    final doc = await db.collection('users').doc(auth.currentUser!.uid).get();
    name.text = doc.data()?['name'] as String? ?? '';
    photoUrl = doc.data()?['photoUrl'] as String? ?? '';
    loaded = true;
  }

  Future<void> choosePhoto() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() => busy = true);
    try {
      final ref = storage.ref('profiles/${auth.currentUser!.uid}/avatar.jpg');
      await ref.putFile(File(file.path));
      photoUrl = await ref.getDownloadURL();
      await saveProfile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> saveProfile() async {
    await db.collection('users').doc(auth.currentUser!.uid).set({
      'name': name.text.trim(),
      'email': auth.currentUser!.email,
      'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved')),
      );
    }
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: loadProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('My Profile')),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                GestureDetector(
                  onTap: busy ? null : choosePhoto,
                  child: CircleAvatar(
                    radius: 48,
                    backgroundImage:
                        photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                    child: photoUrl.isEmpty
                        ? const Icon(Icons.add_a_photo, size: 32)
                        : null,
                  ),
                ),
                const SizedBox(height: 20),
                Text(auth.currentUser?.email ?? ''),
                const SizedBox(height: 16),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Display name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: busy ? null : saveProfile,
                  child: const Text('Save profile'),
                ),
                if (busy) const CircularProgressIndicator(),
              ],
            ),
          ),
        );
      },
    );
  }
}
