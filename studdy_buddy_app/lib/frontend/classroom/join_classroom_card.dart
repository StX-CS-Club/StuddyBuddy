import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:studdy_buddy_app/backend/supabase/supabase_db.dart';
import 'package:studdy_buddy_app/extensions/build_context_extension.dart';
import 'package:studdy_buddy_app/frontend/startup/home_page.dart';
import 'package:studdy_buddy_app/frontend/startup/theme.dart';
import 'package:studdy_buddy_app/util/stream_signal.dart';
import 'package:studdy_buddy_app/widgets/styled_button.dart';

class JoinClassroomCard extends StatefulWidget {
  const JoinClassroomCard({super.key});

  @override
  State<JoinClassroomCard> createState() => _JoinClassroomCardState();
}

class _JoinClassroomCardState extends State<JoinClassroomCard> {
  final _codeController = TextEditingController();

  bool get _ready => _codeController.text.length == 5;

  Future<void> _submit() async {
    final String code = _codeController.text;
    try {
      final bool res = await SupabaseDB.joinClassroom(code);
      if (!res) {
        if (mounted) context.showSnackBar("No classroom of ID $code found.");
        return;
      }
      await SupabaseDB.readClassrooms();
      HomePage.stream.updateStream();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        context.showSnackBar("Error joining classroom: $e", isError: true);
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.of(context).size;

    return Center(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: screen.width * 0.88,
          decoration: BoxDecoration(
            color: StuddyBuddyTheme.surfaceDim,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: BoxDecoration(
                  color: StuddyBuddyTheme.surfaceBase,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Text(
                  'Join Classroom',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _codeController,
                      onChanged: (_) => setState(() {}),
                      maxLength: 5,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 10,
                      ),
                      inputFormatters: [
                        UpperCaseTextFormatter(),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Join code',
                        alignLabelWithHint: true,
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        floatingLabelStyle: TextStyle(
                          color: _ready
                              ? StuddyBuddyTheme.teal
                              : Colors.grey.shade500,
                        ),
                        hintText: '· · · · ·',
                        hintStyle: TextStyle(
                          fontSize: 28,
                          letterSpacing: 10,
                          color: Colors.grey.shade300,
                        ),
                        counterText: '',
                        filled: true,
                        fillColor: StuddyBuddyTheme.surfaceBase,
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
                          borderSide: BorderSide(
                            color: _ready
                                ? StuddyBuddyTheme.teal
                                : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: _ready ? 1.0 : 0.4,
                        child: StyledButton(
                          onTap: _ready ? _submit : null,
                          backgroundColor: StuddyBuddyTheme.teal,
                          text: "Join",
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
