import 'dart:async';

import 'package:flutter/material.dart';
import 'package:studdy_buddy_app/frontend/startup/app_shell.dart';
import 'package:studdy_buddy_app/frontend/startup/theme.dart';
import 'package:studdy_buddy_app/util/stream_signal.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(StuddyBuddyApp());
}

class StuddyBuddyApp extends StatelessWidget {
  const StuddyBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: StuddyBuddyTheme.light,
      debugShowCheckedModeBanner: false,
      home: AppShell(),
    );
  }
}