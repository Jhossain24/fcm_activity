import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Background message received: ${message.messageId}');
  print('Background message data: ${message.data}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FCM Activity 14',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String statusText = 'Waiting for a cloud message...';
  String imagePath = 'assets/images/default.png';
  String fcmToken = 'Getting token...';
  String lastMessage = 'None yet';

  @override
  void initState() {
    super.initState();
    setupFCM();
  }

  Future<void> setupFCM() async {
    NotificationSettings settings = await FirebaseMessaging.instance
        .requestPermission(alert: true, badge: true, sound: true);

    print('Permission granted: ${settings.authorizationStatus}');

    String? token = await FirebaseMessaging.instance.getToken();
    setState(() {
      fcmToken = token ?? 'No token';
    });
    print('FCM Token: $token');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message received!');
      print('Message data: ${message.data}');

      setState(() {
        statusText = message.notification?.title ?? 'Message received!';
        lastMessage =
            'Title: ${message.notification?.title}\nBody: ${message.notification?.body}\nData: ${message.data}';

        if (message.data['asset'] == 'promo') {
          imagePath = 'assets/images/promo.png';
        } else if (message.data['asset'] == 'default') {
          imagePath = 'assets/images/default.png';
        } else {
          imagePath = 'assets/images/default.png';
        }
      });
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App opened from background notification!');

      setState(() {
        statusText = 'Opened from notification!';
        lastMessage = 'Opened from background: ${message.data}';

        if (message.data['asset'] == 'promo') {
          imagePath = 'assets/images/promo.png';
        }
      });
    });

    RemoteMessage? initialMessage = await FirebaseMessaging.instance
        .getInitialMessage();
    if (initialMessage != null) {
      print('App launched from terminated state with message!');
      setState(() {
        statusText = 'Launched from notification!';
        lastMessage = 'Launched from terminated: ${initialMessage.data}';

        if (initialMessage.data['asset'] == 'promo') {
          imagePath = 'assets/images/promo.png';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FCM Activity #14'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey[200],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📱 FCM Token:', fontWeight: FontWeight.bold),
                  Text(fcmToken, style: const TextStyle(fontSize: 10)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Image.asset(
                imagePath,
                width: 150,
                height: 150,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.image_not_supported, size: 150);
                },
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.blue[50],
              child: Text(statusText, style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 20),
            const Text(
              '📨 Last Message:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey[100],
              child: Text(lastMessage),
            ),
          ],
        ),
      ),
    );
  }
}
