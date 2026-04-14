import 'package:flutter/material.dart';
import 'package:studdy_buddy_app/backend/supabase/supabase_db.dart';
import 'package:studdy_buddy_app/extensions/build_context_extension.dart';
import 'package:studdy_buddy_app/extensions/color_extension.dart';
import 'package:studdy_buddy_app/frontend/startup/home_page.dart';
import 'package:studdy_buddy_app/frontend/startup/theme.dart';
import 'package:studdy_buddy_app/util/stream_signal.dart';

class CreateClassroomCard extends StatefulWidget {
  const CreateClassroomCard({super.key});

  @override
  State<CreateClassroomCard> createState() => _CreateClassroomCardState();
}

class _CreateClassroomCardState extends State<CreateClassroomCard> {
  final _emojiController = TextEditingController(text: '📚');
  final _nameController = TextEditingController();
  final _syllabusController = TextEditingController();

  Color _color = StuddyBuddyTheme.teal;

  static final List<Color> _swatches = [
    Colors.red,
    Colors.deepOrange,
    Colors.orange,
    Colors.yellow,
    Colors.lime,
    Colors.green,
    StuddyBuddyTheme.forest,
    StuddyBuddyTheme.sage,
    StuddyBuddyTheme.skyBlue,
    StuddyBuddyTheme.teal,
    Colors.blue,
    Colors.deepPurple,
    Colors.purple,
    Colors.pink,
    Colors.grey,
    Colors.blueGrey,
    Colors.black,
    Colors.brown,
  ];

  Future<void> _submit() async {
    final String name = _nameController.text;
    try {
      final bool res = await SupabaseDB.createClassroom(
          name: name.isNotEmpty ? name : "Classroom",
          emoji: _emojiController.text,
          syllabus: _syllabusController.text,
          color: _color.toHex());
      if (!res) {
        if (mounted) context.showSnackBar("Failed to create classroom");
        return;
      }
      HomePage.stream.updateStream();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        context.showSnackBar("Error creating classroom: $e", isError: true);
      }
    }
  }

  @override
  void dispose() {
    _emojiController.dispose();
    _nameController.dispose();
    _syllabusController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(String label) => InputDecoration(
        labelText: label,
        floatingLabelStyle: TextStyle(color: _color),
        alignLabelWithHint: true,
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
          borderSide: BorderSide(color: _color, width: 2),
        ),
      );

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
                  'Create Classroom',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Emoji + Name row
                    Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: _color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: EditableText(
                              controller: _emojiController,
                              focusNode: FocusNode(),
                              style: const TextStyle(fontSize: 26),
                              cursorColor: Colors.white,
                              backgroundCursorColor: Colors.white,
                              textAlign: TextAlign.center,
                              onChanged: (v) {
                                if (v.characters.length > 1) {
                                  _emojiController.text =
                                      v.characters.last.toString();
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            decoration: _fieldDecoration('Classroom name'),
                            textCapitalization: TextCapitalization.words,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Color label
                    Text(
                      'Color',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 10),

                    // Color scroll with fade gradients
                    SizedBox(
                      height: 36,
                      child: Stack(
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                const SizedBox(width: 16),
                                ..._swatches.map((c) => GestureDetector(
                                      onTap: () => setState(() => _color = c),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        width: 36,
                                        height: 36,
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          color: c,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: _color == c
                                                ? Colors.black54
                                                : Colors.transparent,
                                            width: 2.5,
                                          ),
                                        ),
                                      ),
                                    )),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                          // Left fade
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            width: 24,
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      StuddyBuddyTheme.surfaceDim,
                                      StuddyBuddyTheme.surfaceDim
                                          .withValues(alpha: 0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Right fade
                          Positioned(
                            right: 0,
                            top: 0,
                            bottom: 0,
                            width: 24,
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerRight,
                                    end: Alignment.centerLeft,
                                    colors: [
                                      StuddyBuddyTheme.surfaceDim,
                                      StuddyBuddyTheme.surfaceDim
                                          .withValues(alpha: 0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Syllabus
                    TextField(
                      controller: _syllabusController,
                      decoration: _fieldDecoration('Syllabus'),
                      maxLines: 6,
                      minLines: 4,
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _color,
                        ),
                        child: const Text('Create classroom'),
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
