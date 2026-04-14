import 'package:flutter/material.dart';
import 'package:studdy_buddy_app/extensions/build_context_extension.dart';
import 'package:studdy_buddy_app/frontend/welcome/login_page.dart';
import 'package:studdy_buddy_app/frontend/welcome/role_page.dart';
import 'package:studdy_buddy_app/widgets/styled_button.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  static const List<Color> gradient = [Color(0xFFd4f3f6), Color(0xFFdff2e7)];

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    "assets/images/studdy_buddy_logo.png",
                    width: size.width * 0.65,
                    fit: BoxFit.fill,
                  ),
                ),
              ),
              const Spacer(flex: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: StyledButton(
                  text: "Sign up",
                  height: 48,
                  borderRadius: 14,
                  backgroundColor: colorScheme.primary.withAlpha(228),
                  onTap: () => context.pushSwipePage(RolePage()),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: StyledButton(
                  text: "Log in",
                  height: 48,
                  borderRadius: 14,
                  backgroundColor: colorScheme.secondary.withAlpha(180),
                  onTap: () => context.pushSwipePage(LoginPage()),
                ),
              ),
              const SizedBox(height: 52),
            ],
          ),
        ),
      ),
    );
  }
}