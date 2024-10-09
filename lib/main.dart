import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'HomeScreen.dart';
import 'login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'URL',
    anonKey: 'YOUR key',
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Time Keeper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AuthChecker(),
    );
  }
}

class AuthChecker extends StatefulWidget {
  @override
  _AuthCheckerState createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> {
  final storage = FlutterSecureStorage();
  bool? isLoggedIn;

  @override
  void initState() {
    super.initState();
    _checkUserLogin();
  }

  Future<void> _checkUserLogin() async {
    String? expiresAtString = await storage.read(key: 'expires_at');
    if (expiresAtString != null) {
      int expiresAt = int.parse(expiresAtString);
      if (expiresAt > DateTime.now().millisecondsSinceEpoch ~/ 1000) {
        // Token is valid, navigate to home
        setState(() {
          isLoggedIn = true;
        });
      } else {
        // Token has expired, navigate to login
        setState(() {
          isLoggedIn = false;
        });
      }
    } else {
      // No token found, navigate to login
      setState(() {
        isLoggedIn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoggedIn == null) {
      // Show loading indicator while checking
      return Center(child: CircularProgressIndicator());
    } else if (isLoggedIn == true) {
      return HomeScreen(); // Replace with your home screen widget
    } else {
      return LoginScreen(); // Replace with your login screen widget
    }
  }
}
