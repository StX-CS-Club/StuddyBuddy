import 'dart:io';

import 'package:studdy_buddy_app/backend/sandbox.dart';
import 'package:studdy_buddy_app/backend/study_engine.dart';

void main() async {

  await StudyEngine.loadFromFile("./assets/jsonData/open_ai.json");

  final Sandbox sandbox = Sandbox(syllabus: "This is being sent over the OpenAI API from a dart CLI app. Help me debug by writing unique responses, whatever you want to say!");

  while(true){
    stdout.write("\n\nStudent > ");

    final String? input = stdin.readLineSync();

    if (input == null || input.trim().toLowerCase() == "exit") {
      break;
    }

    stdout.write("\nAssistant > ");

    final sub = StudyEngine.streamTurn(
      sandbox: sandbox,
      prompt: input,
    ).listen(
          (delta) {
        stdout.write("$delta");
      },
      onError: (e) {
        stderr.writeln("\n[ERROR] $e");
      },
      onDone: () {
        stdout.writeln("\n");
      },
    );

    await sub.asFuture<void>();
  }

  final logFile = File("session_log.json");
  await logFile.writeAsString(
    sandbox.toJson().toString(),
  );

  stdout.writeln("Session saved to session_log.json");
}