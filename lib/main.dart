import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      title: 'Hello India',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF087F8C)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) return const HomeScreen();
        return const LoginScreen();
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
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _verificationId;
  bool _loading = false;
  bool _usePhone = true;
  bool _isSignUp = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (!phone.startsWith('+') || phone.length < 8) {
      _show('पूरा फोन नंबर country code के साथ लिखें, जैसे +91XXXXXXXXXX');
      return;
    }
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
        },
        verificationFailed: (error) {
          if (mounted) _show(error.message ?? 'OTP भेजा नहीं जा सका। Firebase सेटिंग जाँचें।');
        },
        codeSent: (verificationId, resendToken) {
          if (!mounted) return;
          setState(() => _verificationId = verificationId);
          _show('OTP भेज दिया गया है। SMS देखें।');
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );
    } on FirebaseAuthException catch (e) {
      _show(e.message ?? 'OTP भेजने में समस्या हुई।');
    } catch (e) {
      _show('Firebase सेटअप जाँचें: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final id = _verificationId;
    final code = _otpController.text.trim();
    if (id == null) {
      _show('पहले Send OTP दबाएँ।');
      return;
    }
    if (code.length != 6) {
      _show('6 अंकों का OTP लिखें।');
      return;
    }
    setState(() => _loading = true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: id,
        smsCode: code,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      _show(e.message ?? 'OTP गलत है या उसकी समय-सीमा खत्म हो गई।');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _emailAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || !email.contains('@') || password.length < 6) {
      _show('सही email और कम-से-कम 6 अक्षर का password लिखें।');
      return;
    }
    setState(() => _loading = true);
    try {
      if (_isSignUp) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } on FirebaseAuthException catch (e) {
      _show(e.message ?? 'Login नहीं हो सका।');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const CircleAvatar(
                    radius: 42,
                    child: Icon(Icons.forum_rounded, size: 42),
                  ),
                  const SizedBox(height: 18),
                  const Text('Hello India',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Connect with everyone',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 30),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('Phone OTP'), icon: Icon(Icons.sms_outlined)),
                      ButtonSegment(value: false, label: Text('Email')),
                    ],
                    selected: {_usePhone},
                    onSelectionChanged: (value) => setState(() => _usePhone = value.first),
                  ),
                  const SizedBox(height: 22),
                  if (_usePhone) ...[
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                        hintText: '+91XXXXXXXXXX',
                        prefixIcon: Icon(Icons.phone_android),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_verificationId != null)
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          labelText: '6-digit OTP',
                          prefixIcon: Icon(Icons.lock_outline),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _loading ? null : (_verificationId == null ? _sendOtp : _verifyOtp),
                      child: _loading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_verificationId == null ? 'Send OTP' : 'Verify OTP & Login'),
                    ),
                    if (_verificationId != null)
                      TextButton(
                        onPressed: _loading ? null : _sendOtp,
                        child: const Text('Resend OTP'),
                      ),
                  ] else ...[
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password (minimum 6 characters)',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: _loading ? null : _emailAuth,
                      child: _loading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_isSignUp ? 'Create account' : 'Login'),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _isSignUp = !_isSignUp),
                      child: Text(_isSignUp
                          ? 'Already have an account? Login'
                          : 'New here? Create account'),
                    ),
                  ],
                  const SizedBox(height: 14),
                  const Text(
                    'Note: OTP login works only after Firebase Authentication is configured.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ChatItem {
  ChatItem(this.name, this.message, this.time, {this.unread = 0});
  final String name;
  final String message;
  final String time;
  final int unread;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  String _search = '';
  final _searchController = TextEditingController();
  final List<ChatItem> _chats = [
    ChatItem('Aman Kumar', 'Hey! Kaise ho?', '9:41 AM', unread: 2),
    ChatItem('Priya Singh', 'Photo bhej di hai', 'Yesterday'),
    ChatItem('Rahul', 'Kal baat karte hain', 'Yesterday'),
    ChatItem('Hello India Team', 'Welcome to Hello India!', 'Monday'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _chats.where((chat) =>
      chat.name.toLowerCase().contains(_search.toLowerCase()) ||
      chat.message.toLowerCase().contains(_search.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hello India', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search),
            onPressed: () async {
              final query = await showSearch<String>(
                context: context,
                delegate: ChatSearchDelegate(_chats),
              );
              if (query != null) setState(() => _search = query);
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') _logout();
              if (value == 'profile') setState(() => _tab = 2);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'profile', child: Text('Profile')),
              PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _search = value),
                  decoration: InputDecoration(
                    hintText: 'Search chats...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _search.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _search = '');
                            },
                          ),
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('कोई chat नहीं मिली'))
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, indent: 84),
                        itemBuilder: (context, index) {
                          final chat = filtered[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              child: Text(chat.name.isNotEmpty ? chat.name[0] : '?'),
                            ),
                            title: Text(chat.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(chat.message, maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(chat.time, style: const TextStyle(fontSize: 11)),
                                if (chat.unread > 0) ...[
                                  const SizedBox(height: 5),
                                  CircleAvatar(radius: 9, child: Text('${chat.unread}', style: const TextStyle(fontSize: 10))),
                                ],
                              ],
                            ),
                            onTap: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => ChatDetailScreen(name: chat.name),
                            )),
                          );
                        },
                      ),
              ),
            ],
          ),
          const CallsTab(),
          const ProfileTab(),
        ],
      ),
      floatingActionButton: _tab == 0
          ? FloatingActionButton(
              onPressed: () => _showNewChatDialog(context),
              child: const Icon(Icons.chat),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat), label: 'Chats'),
          NavigationDestination(icon: Icon(Icons.call_outlined), selectedIcon: Icon(Icons.call), label: 'Calls'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  void _showNewChatDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New chat'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'Contact name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                setState(() => _chats.insert(0, ChatItem(name, 'Start a conversation', 'Now')));
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class ChatSearchDelegate extends SearchDelegate<String> {
  ChatSearchDelegate(this.chats);
  final List<ChatItem> chats;

  @override
  List<Widget> buildActions(BuildContext context) => [
    IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, query),
  );

  @override
  Widget buildResults(BuildContext context) => _results();

  @override
  Widget buildSuggestions(BuildContext context) => _results();

  Widget _results() {
    final matches = chats.where((c) =>
      c.name.toLowerCase().contains(query.toLowerCase()) ||
      c.message.toLowerCase().contains(query.toLowerCase())).toList();
    if (matches.isEmpty) return const Center(child: Text('कोई chat नहीं मिली'));
    return ListView.builder(
      itemCount: matches.length,
      itemBuilder: (context, index) => ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(matches[index].name),
        subtitle: Text(matches[index].message),
        onTap: () => close(context, query),
      ),
    );
  }
}

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({super.key, required this.name});
  final String name;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _controller = TextEditingController();
  final List<String> _messages = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _messages.add(text));
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.name), actions: [
        IconButton(
          tooltip: 'Voice call',
          icon: const Icon(Icons.call_outlined),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CallScreen(name: widget.name))),
        ),
        IconButton(
          tooltip: 'Video call',
          icon: const Icon(Icons.videocam_outlined),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CallScreen(name: widget.name, video: true))),
        ),
      ]),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
              ? const Center(child: Text('बातचीत शुरू करें'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) => Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      constraints: const BoxConstraints(maxWidth: 300),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(_messages[index]),
                    ),
                  ),
                ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Message...',
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(onPressed: _send, icon: const Icon(Icons.send)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CallsTab extends StatelessWidget {
  const CallsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        ListTile(leading: CircleAvatar(child: Icon(Icons.call_received)), title: Text('Aman Kumar'), subtitle: Text('Incoming call · Demo only'), trailing: Icon(Icons.call)),
        ListTile(leading: CircleAvatar(child: Icon(Icons.call_made)), title: Text('Priya Singh'), subtitle: Text('Outgoing call · Demo only'), trailing: Icon(Icons.videocam_outlined)),
        Padding(
          padding: EdgeInsets.all(20),
          child: Text('यह अभी call history का demo है। असली audio/video calling के लिए calling service जोड़नी होगी।', textAlign: TextAlign.center),
        ),
      ],
    );
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(radius: 42, child: Icon(Icons.person, size: 42)),
            const SizedBox(height: 16),
            const Text('My Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(user?.phoneNumber ?? user?.email ?? 'Hello India user'),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => FirebaseAuth.instance.signOut(),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}

class CallScreen extends StatelessWidget {
  const CallScreen({super.key, required this.name, this.video = false});
  final String name;
  final bool video;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF102126),
      appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: Colors.white),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(radius: 54, child: Icon(video ? Icons.videocam : Icons.person, size: 54)),
            const SizedBox(height: 22),
            Text(name, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Calling interface demo', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 44),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(context),
              child: const Icon(Icons.call_end, size: 30),
            ),
            const SizedBox(height: 18),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'असली कॉल करने के लिए Agora, Stream या WebRTC जैसी calling service और backend signaling की जरूरत होगी।',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
