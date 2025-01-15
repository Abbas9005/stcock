import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../dashboard.dart';
import 'register.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        centerTitle: true,
        title: const Text(
          '',
          style: TextStyle(
            decoration: TextDecoration.underline,
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'Pacifico',
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.black],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Center(
              child: Text(
                'LOGIN',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                  fontSize: 70,
                  fontFamily: 'Pacifico',
                ),
              ),
            ),
            const SizedBox(height: 15),
            Container(
              width: 500,
              child: TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  hintText: 'Email',
                  fillColor: Colors.white,
                  filled: true,
                  prefixIcon: const Icon(Icons.email, color: Colors.black),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 500,
              child: TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Password',
                  fillColor: Colors.white,
                  filled: true,
                  prefixIcon: const Icon(Icons.lock_open, color: Colors.black),
                  suffixIcon: const Icon(Icons.visibility),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 50),
            Container(
              height: 60,
              width: 400,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextButton(
                onPressed: () {
                  // Access the Hive box
                  var box = Hive.box('userBox');

                  // Get stored email and password
                  String? storedEmail = box.get('email');
                  String? storedPassword = box.get('password');

                  // Validate input
                  if (emailController.text.isEmpty || passwordController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter both email and password'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } else if (storedEmail != null &&
                      storedEmail == emailController.text) {
                    // If email exists, validate the password
                    if (storedPassword == passwordController.text) {
                      // Navigate to Dashboard
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>  DashboardScreen()),
                      );
                    } else {
                      // Incorrect password
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Incorrect password'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } else {
                    // Email not found
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Email not found'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text(
                  'LOG IN',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
            ),
            const SizedBox(height: 7),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Don’t have an account? '),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const Register()),
                    );
                  },
                  child: const Text(
                    'Register',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
