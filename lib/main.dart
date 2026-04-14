import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Background message received: ${message.messageId}');
}

Future<void> initializeFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  await FirebaseMessaging.instance.setAutoInitEnabled(true);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FCM Activity 14',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class FCMService {
  static Future<String?> getToken() async {
    return await FirebaseMessaging.instance.getToken();
  }

  static Future<void> requestPermissions() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;
  static Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;
  static Future<RemoteMessage?> getInitialMessage() =>
      FirebaseMessaging.instance.getInitialMessage();
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _statusText = 'Waiting for a cloud message...';
  String _imagePath = 'assets/images/default.png';
  String _fcmToken = 'Getting token...';
  String _lastMessage = 'None yet';

  final Map<String, String> _assetMap = {
    'promo': 'assets/images/promo.png',
    'default': 'assets/images/default.png',
  };

  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  void _updateImageFromAsset(String? assetKey) {
    _imagePath = _assetMap[assetKey] ?? _assetMap['default']!;
  }

  Future<void> _setupFCM() async {
    await FCMService.requestPermissions();

    final token = await FCMService.getToken();
    setState(() => _fcmToken = token ?? 'No token');

    FCMService.onMessage.listen(_handleForegroundMessage);
    FCMService.onMessageOpenedApp.listen(_handleBackgroundOpen);

    final initialMessage = await FCMService.getInitialMessage();
    if (initialMessage != null) _handleTerminatedLaunch(initialMessage);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    setState(() {
      _statusText = message.notification?.title ?? 'Message received!';
      _lastMessage =
          'Title: ${message.notification?.title}\nBody: ${message.notification?.body}\nData: ${message.data}';
      _updateImageFromAsset(message.data['asset']);
    });
  }

  void _handleBackgroundOpen(RemoteMessage message) {
    setState(() {
      _statusText = 'Opened from notification!';
      _lastMessage = 'Opened from background: ${message.data}';
      _updateImageFromAsset(message.data['asset']);
    });
  }

  void _handleTerminatedLaunch(RemoteMessage message) {
    setState(() {
      _statusText = 'Launched from notification!';
      _lastMessage = 'Launched from terminated: ${message.data}';
      _updateImageFromAsset(message.data['asset']);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FCM Activity #14'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTokenDisplay(),
            const SizedBox(height: 20),
            _buildImageDisplay(),
            const SizedBox(height: 20),
            _buildStatusDisplay(),
            const SizedBox(height: 20),
            _buildLastMessageDisplay(),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenDisplay() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📱 FCM Token:', fontWeight: FontWeight.bold),
          Text(_fcmToken, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildImageDisplay() {
    return Center(
      child: Image.asset(
        _imagePath,
        width: 150,
        height: 150,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.image_not_supported, size: 150);
        },
      ),
    );
  }

  Widget _buildStatusDisplay() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(_statusText, style: const TextStyle(fontSize: 16)),
    );
  }

  Widget _buildLastMessageDisplay() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📨 Last Message:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(child: Text(_lastMessage)),
            ),
          ),
        ],
      ),
    );
  }
}
