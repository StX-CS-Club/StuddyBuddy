import 'package:flutter/material.dart';
import 'package:studdy_buddy_app/backend/supabase/supabase_db.dart';
import 'package:studdy_buddy_app/extensions/build_context_extension.dart';
import 'package:studdy_buddy_app/frontend/startup/home_page.dart';
import 'package:studdy_buddy_app/frontend/startup/theme.dart';
import 'package:studdy_buddy_app/frontend/welcome/login_page.dart';

import '../../backend/data/account.dart';
import '../../widgets/avatar_stack.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key, required this.role});

  final Role role;

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _nameValid = false;
  bool _emailValid = false;
  bool _passwordValid = false;

  bool get _formValid => _nameValid && _emailValid && _passwordValid;

  bool _validateName(String? v) => v != null && v.trim().isNotEmpty;

  bool _validateEmail(String? v) =>
      v != null && RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v);

  bool _validatePassword(String? v) => v != null && v.length >= 6;

  static final List<Color> _studentGradient = [
    StuddyBuddyTheme.teal,
    StuddyBuddyTheme.skyBlue
  ];
  static final List<Color> _teacherGradient = [
    StuddyBuddyTheme.forest,
    StuddyBuddyTheme.sage
  ];

  List<Color> get _gradient =>
      widget.role == Role.student ? _studentGradient : _teacherGradient;

  Color get _accentColor => widget.role == Role.student
      ? StuddyBuddyTheme.teal
      : StuddyBuddyTheme.forest;

  InputDecoration _fieldDecoration(String label, String hint) =>
      InputDecoration(
        labelText: label,
        floatingLabelStyle: TextStyle(color: _accentColor),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
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
          borderSide: BorderSide(color: _accentColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB3261E)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB3261E), width: 2),
        ),
      );

  Future<void> _createAccount() async {
    if (!_formValid) return;

    try {
      final bool res = await SupabaseDB.signUp(
          _emailController.text, _passwordController.text);
      if (!res) {
        if (mounted) context.showSnackBar("Failed to create account");
        return;
      }

      await SupabaseDB.readAccount();
      await SupabaseDB.writeAccount(
          name: _nameController.text, role: widget.role.name);
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => HomePage()), (_) => false);
      }
    } catch (e) {
      if (mounted)
        context.showSnackBar("Error creating account: $e", isError: true);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AvatarStack(),
                        const SizedBox(height: 24),
                        Text(
                          'Create ${widget.role.name} account',
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _nameController,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: _fieldDecoration('Full name', 'John Doe'),
                          textCapitalization: TextCapitalization.words,
                          onChanged: (v) =>
                              setState(() => _nameValid = _validateName(v)),
                          validator: (v) =>
                              _validateName(v) ? null : 'Enter your full name',
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emailController,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration:
                              _fieldDecoration('Email', 'john@example.com'),
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (v) =>
                              setState(() => _emailValid = _validateEmail(v)),
                          validator: (v) =>
                              _validateEmail(v) ? null : 'Enter a valid email',
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration:
                              _fieldDecoration('Password', 'Min. 6 characters'),
                          obscureText: true,
                          onChanged: (v) => setState(
                              () => _passwordValid = _validatePassword(v)),
                          validator: (v) => _validatePassword(v)
                              ? null
                              : 'Password must be at least 6 characters',
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _formValid ? _createAccount : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accentColor,
                              disabledBackgroundColor:
                                  _accentColor.withValues(alpha: 0.4),
                            ),
                            child: const Text('Create account'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Change role'),
                        ),
                        TextButton(
                          onPressed: () => context.pushSwipePage(LoginPage()),
                          child: const Text('Already have an account? Sign in'),
                        ),
                      ],
                    ),
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
