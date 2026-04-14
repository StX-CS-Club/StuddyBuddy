import 'package:flutter/material.dart';
import 'package:studdy_buddy_app/backend/anthropic/study_engine.dart';
import 'package:studdy_buddy_app/backend/supabase/supabase_db.dart';
import 'package:studdy_buddy_app/frontend/startup/home_page.dart';
import 'package:studdy_buddy_app/frontend/welcome/welcome_page.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  static bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width * .75;

    determineDestination(context);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
          child: Image.asset("assets/images/studdy_buddy_graphic.png",
              width: width)),
    );
  }

  void determineDestination(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_initialized) await init();
      if (context.mounted) {
        if (SupabaseDB.authenticated()) {
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => HomePage()), (_) => false);
        } else {
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => WelcomePage()), (_) => false);
        }
      }
    });
  }

  static Future<void> init() async {
    await Future.wait([
      if (!SupabaseDB.initialized) SupabaseDB.init(),
      if (!StudyEngine.initialized) StudyEngine.init()
    ]);

    if(SupabaseDB.authenticated()) await SupabaseDB.fetchData();

    _initialized = true;
  }
}
