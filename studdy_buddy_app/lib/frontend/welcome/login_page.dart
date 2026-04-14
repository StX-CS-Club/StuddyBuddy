import 'package:flutter/material.dart';
import 'package:studdy_buddy_app/backend/supabase/supabase_db.dart';
import 'package:studdy_buddy_app/extensions/build_context_extension.dart';
import 'package:studdy_buddy_app/frontend/startup/home_page.dart';
import 'package:studdy_buddy_app/frontend/startup/theme.dart';
import 'package:studdy_buddy_app/frontend/welcome/role_page.dart';

import '../../widgets/avatar_stack.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  static final List<Color> _gradient = [
    StuddyBuddyTheme.teal,
    StuddyBuddyTheme.forest,
  ];

  InputDecoration _fieldDecoration(String label) => InputDecoration(
        labelText: label,
        floatingLabelStyle: TextStyle(color: StuddyBuddyTheme.teal),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: StuddyBuddyTheme.teal, width: 2),
        ),
      );

  Future<void> _login() async {
    try {
      final bool res = await SupabaseDB.signIn(
        _emailController.text,
        _passwordController.text,
      );
      if (!res) {
        if (mounted) context.showSnackBar("Invalid email or password");
        return;
      }

      await SupabaseDB.fetchData();

      if (mounted) {
        Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (_) => HomePage()), (_) => false);
      }
    } catch (e) {
      if (mounted) context.showSnackBar("Error signing in: $e", isError: true);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _gradient,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AvatarStack(),
                      const SizedBox(height: 24),
                      const Text(
                        'Welcome back',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _emailController,
                        decoration: _fieldDecoration('Email'),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        decoration: _fieldDecoration('Password'),
                        obscureText: true,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: StuddyBuddyTheme.teal,
                          ),
                          child: const Text('Log in'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => context.pushSwipePage(RolePage()),
                        child: const Text("Don't have an account? Sign up"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
