import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/awesome_notifications_empty.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_app/pages/Home.dart';
import 'package:ecommerce_app/pages/loginSignupScreen.dart';
import 'package:ecommerce_app/pages/vendorScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce_app/providers/authProvider.dart';
import 'package:ecommerce_app/providers/cart.dart';
import 'package:ecommerce_app/firebase_options.dart';
import 'package:ecommerce_app/providers/productProvider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
            channelKey: "basic_channel",
            channelName: "Basic notifications",
            channelDescription: "Notifications channel for basic test")
      ],
      debug: true);

  runApp(MyApp());
}

Future<String> fetchRoleByEmail(String email) async {
  try {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw Exception('No user found with this email.');
    }

    final userDoc = querySnapshot.docs.first;
    return userDoc['role'];
  } catch (e) {
    return "Not";
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => ProductProvider()),
        ChangeNotifierProvider(create: (ctx) => MyAuthProvider()),
        ChangeNotifierProvider(
            create: (ctx) => Cart()), // Add the Cart provider here
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ConnectionChecker(),
      ),
    );
  }
}

class ConnectionChecker extends StatefulWidget {
  @override
  _ConnectionCheckerState createState() => _ConnectionCheckerState();
}

class _ConnectionCheckerState extends State<ConnectionChecker> {
  @override
  void initState() {
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
    super.initState();
    checkConnection();
  }

  Future<void> checkConnection() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      _showNoConnectionDialog();
    }
  }

  void _showNoConnectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('No Connection'),
        content: Text('You have no internet connection. The app will close.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Close the app
              Future.delayed(Duration(milliseconds: 100), () {
                SystemNavigator.pop();
              });
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          User user = snapshot.data!;
          String email = user.email ?? 'No email';

          return FutureBuilder<String>(
            future: fetchRoleByEmail(email),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (roleSnapshot.hasError) {
                return Center(child: Text('Error: ${roleSnapshot.error}'));
              } else if (roleSnapshot.hasData) {
                String role = roleSnapshot.data!;

                // Redirect based on role
                if (role == 'Vendor') {
                  return Vendorscreen();
                } else {
                  return Home();
                }
              } else {
                return Center(child: Text('No role found'));
              }
            },
          );
        } else {
          print("HI");
          return Home();
        }
      },
    );
  }
}
