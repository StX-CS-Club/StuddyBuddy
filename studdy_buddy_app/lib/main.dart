import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:studdy_buddy_app/backend/anthropic/study_engine.dart';
import 'package:studdy_buddy_app/backend/assignment.dart';
import 'package:studdy_buddy_app/backend/classroom.dart';
import 'package:studdy_buddy_app/backend/files/file_picker.dart';
import 'package:studdy_buddy_app/backend/sandbox.dart';
import 'package:studdy_buddy_app/backend/supabase/supabase_db.dart';
import 'package:studdy_buddy_app/backend/supabase/supabase_file.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'backend/message.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CliApp());
}

final supabase = Supabase.instance.client;

class CliApp extends StatelessWidget {
  const CliApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CliScreen(),
    );
  }
}

class CliScreen extends StatefulWidget {
  const CliScreen({super.key});

  @override
  State<CliScreen> createState() => _CliScreenState();
}

class _CliScreenState extends State<CliScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final List<_Line> _lines = [];
  Sandbox? _sandbox;

  @override
  void initState() {
    super.initState();
    _print('StuddyBuddy CLI Tester', system: true);
  }

  // ── Print helpers ──────────────────────────────────────────────────────────

  void _print(String text, {bool system = false, bool error = false, bool linebreak = true}) {
    setState(() {
      if (!linebreak && _lines.isNotEmpty) {
        final _Line last = _lines.last;
        _lines[_lines.length - 1] = _Line(
          last.text + text,
          system: last.system,
          error: last.error,
        );
      } else {
        _lines.add(_Line(text, system: system, error: error));
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Command runner ─────────────────────────────────────────────────────────

  Future<void> _run(String input) async {
    final String trimmed = input.trim();
    if (trimmed.isEmpty) return;
    _print('> $trimmed');

    final List<String> parts = trimmed.split(' ');
    final String cmd = parts[0].toLowerCase();

    try {
      switch (cmd) {
        case 'clear':
          setState(() => _lines.clear());

        case 'init':
          await SupabaseDB.loadFromFile("assets/json_data/supabase.json");
          await StudyEngine.loadFromFile("assets/json_data/anthropic.json");
          _print("Initialized", system: true);

        case 'signup':
          if (parts.length < 3) {
            _print('Usage: signUp <email> <password>', error: true);
            break;
          }
          final bool res = await SupabaseDB.signUp(parts[1], parts[2]);
          if (!res) {
            _print("Failed to create account.", error: true);
          } else {
            _print("Signed up successfully.");
          }

        case 'signin':
          if (parts.length < 3) {
            _print('Usage: signIn <email> <password>', error: true);
            break;
          }
          final bool res = await SupabaseDB.signIn(parts[1], parts[2]);
          if (!res) {
            _print("Failed to sign in.", error: true);
          } else {
            _print("Signed in successfully.");
          }

        case 'signout':
          await SupabaseDB.signOut();
          _print("Signed out.");

        case 'readaccount':
          _print((await SupabaseDB.readAccount())?.name ?? "");

        case 'writeaccount':
          if (parts.length < 3) {
            _print('Usage: writeAccount <name> <role>', error: true);
            break;
          }
          await SupabaseDB.writeAccount(name: parts[1], role: parts[2]);
          _print("Account updated.");

        case 'createclassroom':
          if (parts.length < 2) {
            _print('Usage: createClassroom <name>', error: true);
            break;
          }
          final bool res = await SupabaseDB.createClassroom(name: parts[1]);
          if (res) {
            _print("Successfully created classroom ${parts[1]}");
          } else {
            _print("Failed to create classroom.", error: true);
          }

        case 'joinclassroom':
          if (parts.length < 2) {
            _print('Usage: joinClassroom <ID>', error: true);
            break;
          }
          final bool res = await SupabaseDB.joinClassroom(parts[1]);
          if (res) {
            _print("Successfully joined classroom ${parts[1]}");
          } else {
            _print("Failed to join classroom.", error: true);
          }

        case 'writeclassroom':
          if (parts.length < 4) {
            _print('Usage: writeClassroom <ID> <name> <syllabus>', error: true);
            break;
          }
          await SupabaseDB.writeClassroom(parts[1], name: parts[2], syllabus: parts[3]);
          _print("Classroom updated.");

        case 'readclassrooms':
          final List<Classroom> res = await SupabaseDB.readClassrooms();
          if (res.isEmpty) {
            _print("No classrooms found.", system: true);
          }
          for (final Classroom classroom in res) {
            _print(classroom.id);
          }

        case 'createassignment':
          if (parts.length < 3) {
            _print('Usage: createAssignment <classroom> <title>', error: true);
            break;
          }
          final bool res = await SupabaseDB.createAssignment(
              classroomId: parts[1], title: parts[2]);
          if (res) {
            _print("Successfully created assignment.");
          } else {
            _print("Failed to create assignment.", error: true);
          }

        case 'writeassignment':
          if (parts.length < 4) {
            _print(
                'Usage: writeAssignment <assignment> <title> <instructions>',
                error: true);
            break;
          }
          final bool res = await SupabaseDB.writeAssignment(parts[1],
              title: parts[2], instructions: parts[3]);
          if (res) {
            _print("Successfully updated assignment.");
          } else {
            _print("Failed to update assignment.", error: true);
          }

        case 'readassignments':
          if (parts.length < 2) {
            _print('Usage: readAssignments <classroom>', error: true);
            break;
          }
          final Classroom? classroom = SupabaseDB.classrooms
              .where((c) => c.id == parts[1])
              .firstOrNull;
          if (classroom == null) {
            _print("Classroom not found.", error: true);
            break;
          }
          final List<Assignment> res = await classroom.readAssignments();
          if (res.isEmpty) {
            _print("No assignments found.", system: true);
          }
          for (final Assignment assignment in res) {
            _print('${assignment.id} — ${assignment.title}');
          }

        case 'readsandboxes':
          final List<Sandbox> res = await SupabaseDB.readSandboxes();
          _print("${res.length} sandboxes read.");

        case 'readsandbox':
          if (parts.length < 2) {
            _print('Usage: readSandbox <id>', error: true);
            break;
          }
          final List<Message> res = await SupabaseDB.readMessages(parts[1]);

          for(Message message in res) {
            _print("${message.role.name} > ${message.content}");
          }


        case 'opensandbox':
          if (parts.length < 2) {
            _print('Usage: openSandbox <assignment>', error: true);
            break;
          }
          final Classroom? classroom = SupabaseDB.classrooms
              .where((c) => c.assignmentIds.contains(parts[1]))
              .firstOrNull;
          if (classroom == null) {
            _print('Assignment not found in loaded classrooms.', error: true);
            break;
          }
          final Assignment? assignment = SupabaseDB.assignments
              .where((a) => a.id == parts[1])
              .firstOrNull;
          final String instructions =
              (classroom.syllabus ?? '') + (assignment?.instructions ?? '');
          final Sandbox? res =
          await SupabaseDB.openSandbox(parts[1], instructions: instructions);
          if (res != null) {
            _sandbox = res;
            await _sandbox!.readMessages();
            _sandbox!.readAssignment();
            _print(
                "Opened sandbox (${_sandbox!.messages.length} existing messages).",
                system: true);
          } else {
            _print("Failed to open sandbox.", error: true);
          }

        case "message":
          if (parts.length < 2) {
            _print('Usage: message <content>', error: true);
            break;
          }
          if (_sandbox == null) {
            _print("No sandbox selected.", error: true);
            break;
          }
          _print('Claude: ');
          await for (final String delta
          in _sandbox!.sendMessage(parts.sublist(1).join(' '))) {
            _print(delta, linebreak: false);
          }
          _print('');

        case 'pickfile':
          final FilePick? res = await pickFile(PickSource.library);
          if(res != null) _print(res.path);

        case 'uploadassignment':
          if (parts.length < 2) {
            _print('Usage: uploadAssignment <assignmentId>', error: true);
            break;
          }

          final FilePick? pick = await pickFile(PickSource.library);
          if(pick == null) break;
          _print(pick.path);

          await SupabaseDB.uploadAssignmentFile(assignmentId: parts[1], file: File(pick.path));

        case 'readassignment':
          if (parts.length < 2) {
            _print('Usage: readAssignment <assignmentId>', error: true);
            break;
          }

          final List<SupabaseFile> res = await SupabaseDB.readAssignmentFiles(parts[1]);

          for(SupabaseFile file in res) {
            print('${file.name} ${file.fileType}:${file.url}');
          }

        case 'attach':
          final FilePick? pick = await pickFile(PickSource.library);
          if(pick == null) break;
          _print(pick.path);

          if (_sandbox == null) {
            _print("No sandbox selected.", error: true);
            break;
          }

          await SupabaseDB.uploadSandboxFile(sandboxId: _sandbox!.id, file: File(pick.path));


        default:
          _print('Unknown command: $cmd', error: true);
      }
    } catch (e) {
      _print('Error: $e', error: true);
    }
  }

  void _submit() {
    final String text = _inputController.text;
    _inputController.clear();
    _focusNode.requestFocus();
    _run(text);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: _lines.length,
                itemBuilder: (_, int i) {
                  final _Line line = _lines[i];
                  return Text(
                    line.text,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      height: 1.6,
                      color: line.error
                          ? const Color(0xFFFF6B6B)
                          : line.system
                          ? const Color(0xFF888888)
                          : const Color(0xFFD4D4D4),
                    ),
                  );
                },
              ),
            ),
            Container(
              color: const Color(0xFF2D2D2D),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Text('> ',
                      style: TextStyle(
                          color: Color(0xFF4EC9B0),
                          fontFamily: 'monospace',
                          fontSize: 13)),
                  Expanded(
                    child: KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: (KeyEvent e) {
                        if (e is KeyDownEvent &&
                            e.logicalKey == LogicalKeyboardKey.enter) {
                          _submit();
                        }
                      },
                      child: TextField(
                        controller: _inputController,
                        focusNode: _focusNode,
                        autofocus: true,
                        style: const TextStyle(
                            color: Color(0xFFD4D4D4),
                            fontFamily: 'monospace',
                            fontSize: 13),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          hintText: 'type a command...',
                          hintStyle: TextStyle(
                              color: Color(0xFF555555),
                              fontFamily: 'monospace',
                              fontSize: 13),
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _submit,
                    child: const Text('↵',
                        style: TextStyle(
                            color: Color(0xFF555555), fontSize: 16)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}

class _Line {
  final String text;
  final bool system;
  final bool error;

  const _Line(this.text, {this.system = false, this.error = false});
}