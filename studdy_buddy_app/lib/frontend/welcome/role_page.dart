import 'package:flutter/material.dart';
import 'package:studdy_buddy_app/backend/data/account.dart';
import 'package:studdy_buddy_app/extensions/build_context_extension.dart';
import 'package:studdy_buddy_app/frontend/welcome/login_page.dart';
import 'package:studdy_buddy_app/frontend/welcome/signup_page.dart';
import 'package:studdy_buddy_app/frontend/startup/theme.dart';
import 'package:studdy_buddy_app/widgets/styled_button.dart';

import '../../widgets/avatar_stack.dart';

class RolePage extends StatefulWidget {
  const RolePage({super.key});

  @override
  State<RolePage> createState() => _RolePageState();
}

class _RolePageState extends State<RolePage> {
  String? _selected;

  List<Color> get _gradientColors {
    if (_selected == 'student') return [StuddyBuddyTheme.teal, StuddyBuddyTheme.skyBlue];
    if (_selected == 'teacher') return [StuddyBuddyTheme.sage, StuddyBuddyTheme.forest];
    return [const Color(0xFFa8e6eb), const Color(0xFFc8e6d0)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _gradientColors,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AvatarStack(),
                    const SizedBox(height: 24),
                    const Text('What\'s your role?',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text('Choose how you\'ll use StuddyBuddy.',
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 24),
                    _RoleButton(
                      role: 'student',
                      icon: '🎓',
                      label: 'Student',
                      tagline: 'I\'m here to learn',
                      details: const [
                        'Join classes and access study materials',
                        'Deepen your knowledge with an AI assistant',
                        'Submit work and materials to teachers'
                      ],
                      accentColor: StuddyBuddyTheme.teal,
                      isSelected: _selected == 'student',
                      onTap: () => setState(() =>
                      _selected = _selected == 'student' ? null : 'student'),
                    ),
                    const SizedBox(height: 12),
                    _RoleButton(
                      role: 'teacher',
                      icon: '📚',
                      label: 'Teacher',
                      tagline: 'I\'m here to teach',
                      details: const [
                        'Create and manage your own classes',
                        'Assign work and materials to students',
                        'Monitor class progress and AI usage',
                      ],
                      accentColor: StuddyBuddyTheme.forest,
                      isSelected: _selected == 'teacher',
                      onTap: () => setState(() =>
                      _selected = _selected == 'teacher' ? null : 'teacher'),
                    ),
                    const SizedBox(height: 20),
                    AnimatedOpacity(
                      opacity: _selected != null ? 1.0 : 0.4,
                      duration: const Duration(milliseconds: 200),
                      child: SizedBox(
                        width: double.infinity,
                        child: StyledButton(
                          onTap: _selected != null ? () {
                            context.pushSwipePage(SignupPage(role: _selected == 'teacher' ? Role.teacher : Role.student));
                          } : null,
                            backgroundColor: _selected == 'teacher' ? StuddyBuddyTheme.forest : StuddyBuddyTheme.teal,
                          text: "Next",
                          height: 32,
                          borderRadius: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
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
    );
  }
}

class _RoleButton extends StatelessWidget {
  const _RoleButton({
    required this.role,
    required this.icon,
    required this.label,
    required this.tagline,
    required this.details,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
  });

  final String role, icon, label, tagline;
  final List<String> details;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withAlpha(16) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? accentColor : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: accentColor.withAlpha(32),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(child: Text(icon, style: const TextStyle(fontSize: 18))),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      Text(tagline,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  const Spacer(),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? accentColor : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? accentColor : Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                        : null,
                  ),
                ],
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              child: isSelected
                  ? Column(
                children: [
                  Divider(height: 1, color: Colors.grey.shade200),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    child: Column(
                      children: details.map((d) => Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 5, right: 8),
                              child: Container(
                                width: 6, height: 6,
                                decoration: BoxDecoration(
                                  color: accentColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(d,
                                  style: Theme.of(context).textTheme.bodySmall),
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
                ],
              )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}