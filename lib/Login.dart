import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:time_keeper/HomeScreen.dart';
import 'main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  final storage = FlutterSecureStorage();
  final supabase = Supabase.instance.client;

  final _formKey = GlobalKey<FormState>();

  String? errorMessage; // To store and display error messages
  bool isLoading = false; // To show loading circular

  Future<void> signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true; // Show loading indicator
      });

      try {
        final response = await supabase.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        // Save tokens and other details in secure storage
        await storage.write(key: 'access_token', value: response.session!.accessToken);
        await storage.write(key: 'refresh_token', value: response.session!.refreshToken);
        await storage.write(key: 'expires_at', value: response.session!.expiresAt.toString());
        await storage.write(key: 'token_type', value: response.session!.tokenType);
        await storage.write(key: 'user_id', value: response.user!.id);

        // Navigate to the home screen on successful sign in
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeScreen(),
          ),
        );
      } catch (e) {
        // Show an alert dialog if sign-in fails
        // setState(() {
        //   errorMessage = 'Failed to sign in. Please check your credentials.';
        // });
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text('Invalid email or password. Please try again.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      } finally {
        setState(() {
          isLoading = false; // Hide loading indicator
        });
      }
    }
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an email';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.grey[300],
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 16),
                        ),
                      ),

                    // Email
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          border: Border.all(
                            color: Colors.white,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 20, top: 5, bottom: 5),
                          child: TextFormField(
                            controller: _emailController,
                            validator: validateEmail,
                            decoration: InputDecoration(
                              hintText: 'Email',
                              suffixIcon: Icon(Icons.email),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),

                    // Password
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          border: Border.all(
                            color: Colors.white,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 20, top: 5, bottom: 5),
                          child: TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            validator: validatePassword,
                            decoration: InputDecoration(
                              hintText: 'Password',
                              suffixIcon: Icon(Icons.lock),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),

                    // Loading Circular or Sign In Button
                    isLoading
                        ? CircularProgressIndicator()
                        : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: GestureDetector(
                        onTap: signIn,
                        child: Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'Sign In',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 18),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
