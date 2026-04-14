import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FCMRepository.handleBackgroundMessage(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FCMRepository.initialize();
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

class FCMRepository {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    await _requestPermissions();
    await FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler,
    );
  }

  static Future<void> _requestPermissions() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
  }

  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  static Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;
  static Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;
  static Future<RemoteMessage?> getInitialMessage() =>
      _messaging.getInitialMessage();

  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('Background message: ${message.messageId}');
  }

  static String getImagePathFromMessage(RemoteMessage message) {
    const defaultPath = 'assets/images/default.png';
    const promoPath = 'assets/images/promo.png';

    final assetKey = message.data['asset'];
    if (assetKey == 'promo') return promoPath;
    return defaultPath;
  }

  static String formatMessageForDisplay(RemoteMessage message) {
    return '''
Title: ${message.notification?.title ?? 'No title'}
Body: ${message.notification?.body ?? 'No body'}
Data: ${message.data}
''';
  }
}

class MessageHandler {
  final Function(String) onStatusChange;
  final Function(String) onMessageChange;
  final Function(String) onImageChange;

  MessageHandler({
    required this.onStatusChange,
    required this.onMessageChange,
    required this.onImageChange,
  });

  void handleForegroundMessage(RemoteMessage message) {
    onStatusChange(message.notification?.title ?? 'Message received!');
    onMessageChange(FCMRepository.formatMessageForDisplay(message));
    onImageChange(FCMRepository.getImagePathFromMessage(message));
  }

  void handleBackgroundOpen(RemoteMessage message) {
    onStatusChange('Opened from notification!');
    onMessageChange(
      'Opened from background:\n${FCMRepository.formatMessageForDisplay(message)}',
    );
    onImageChange(FCMRepository.getImagePathFromMessage(message));
  }

  void handleTerminatedLaunch(RemoteMessage message) {
    onStatusChange('Launched from notification!');
    onMessageChange(
      'Launched from terminated:\n${FCMRepository.formatMessageForDisplay(message)}',
    );
    onImageChange(FCMRepository.getImagePathFromMessage(message));
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late MessageHandler _messageHandler;

  String _statusText = 'Waiting for a cloud message...';
  String _imagePath = 'assets/images/default.png';
  String _fcmToken = 'Getting token...';
  String _lastMessage = 'None yet';

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _messageHandler = MessageHandler(
      onStatusChange: (status) => setState(() => _statusText = status),
      onMessageChange: (message) => setState(() => _lastMessage = message),
      onImageChange: (path) => setState(() => _imagePath = path),
    );
    _setupFCM();
  }

  Future<void> _setupFCM() async {
    try {
      final token = await FCMRepository.getToken();
      setState(() => _fcmToken = token ?? 'No token');

      FCMRepository.onMessage.listen(_messageHandler.handleForegroundMessage);
      FCMRepository.onMessageOpenedApp.listen(
        _messageHandler.handleBackgroundOpen,
      );

      final initialMessage = await FCMRepository.getInitialMessage();
      if (initialMessage != null) {
        _messageHandler.handleTerminatedLaunch(initialMessage);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to initialize FCM: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldMessengerKey,
      appBar: AppBar(
        title: const Text('FCM Activity #14'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _setupFCM,
            tooltip: 'Refresh FCM Token',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTokenSection(),
            const SizedBox(height: 20),
            _buildImageSection(),
            const SizedBox(height: 20),
            _buildStatusSection(),
            const SizedBox(height: 20),
            _buildMessageSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.vpn_key, size: 16),
                SizedBox(width: 4),
                Text(
                  'FCM Token:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SelectableText(_fcmToken, style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Center(
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Image.asset(
            _imagePath,
            width: 120,
            height: 120,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.broken_image,
                size: 120,
                color: Colors.grey,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const Icon(Icons.notifications_active, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(_statusText, style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageSection() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.message, size: 16),
              SizedBox(width: 4),
              Text(
                'Last Message:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: SingleChildScrollView(
                  child: SelectableText(_lastMessage),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
