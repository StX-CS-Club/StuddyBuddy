import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:studdy_buddy_app/backend/data/assignment.dart';
import 'package:studdy_buddy_app/backend/supabase/supabase_db.dart';
import 'package:studdy_buddy_app/extensions/build_context_extension.dart';
import 'package:studdy_buddy_app/frontend/startup/theme.dart';

import '../../backend/files/app_file.dart';
import '../file/app_file_tile.dart';
import '../file/file_view_page.dart';

class CreateAssignmentCard extends StatefulWidget {
  const CreateAssignmentCard(
      {super.key, required this.classroomId, required this.color});

  final String classroomId;
  final Color color;

  @override
  State<CreateAssignmentCard> createState() => _CreateAssignmentCardState();
}

class _CreateAssignmentCardState extends State<CreateAssignmentCard> {
  final _titleController = TextEditingController();
  final _instructionsController = TextEditingController();

  List<AppFile> _pickedFiles = [];

  bool get _ready => _titleController.text.trim().isNotEmpty;

  Future<void> _pickFiles() async {
    final FilePickerResult? result = await FilePicker.pickFiles(
      allowMultiple: true,
    );
    if (result == null) return;
    setState(() => _pickedFiles = [
          ..._pickedFiles,
          ...result.files.map((f) => AppFile.fromPath(
                path: f.path,
                fileName: f.name,
              )),
        ]);
  }

  void _removeFile(AppFile file) {
    setState(() => _pickedFiles.remove(file));
  }

  Future<void> _submit() async {
    final String title = _titleController.text.trim();
    final String instructions = _instructionsController.text.trim();

    try {
      print(SupabaseDB.account?.id);
      print(widget.classroomId);

      final Assignment? res = await SupabaseDB.createAssignment(
          classroomId: widget.classroomId,
          title: title,
          instructions: instructions);
      if (res == null) {
        if (mounted) context.showSnackBar("Failed to create assignment");
        return;
      }

      for (AppFile file in _pickedFiles) {
        await SupabaseDB.uploadAssignmentFile(
            assignmentId: res.id, file: file.file!);
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        context.showSnackBar("Error creating assignment: $e", isError: true);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(String label) => InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        floatingLabelStyle: TextStyle(color: widget.color),
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
          borderSide: BorderSide(color: widget.color, width: 2),
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
                  'Create Assignment',
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
                      controller: _titleController,
                      onChanged: (_) => setState(() {}),
                      decoration: _fieldDecoration('Title'),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _instructionsController,
                      decoration: _fieldDecoration('Instructions'),
                      maxLines: 6,
                      minLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _pickFiles,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: StuddyBuddyTheme.surfaceBase,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _pickedFiles.isNotEmpty
                                ? widget.color
                                : Colors.grey.shade200,
                            width: _pickedFiles.isNotEmpty ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.upload_file_outlined,
                              color: _pickedFiles.isNotEmpty
                                  ? widget.color
                                  : Colors.grey.shade400,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Attach files',
                              style: TextStyle(
                                color: _pickedFiles.isNotEmpty
                                    ? widget.color
                                    : Colors.grey.shade400,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_pickedFiles.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ..._pickedFiles.map((f) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: AppFileTile(
                              file: f,
                              onRemove: () => _removeFile(f),
                              onView: () =>
                                  context.pushSwipePage(FileViewPage(file: f)),
                            ),
                          )),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: _ready ? 1.0 : 0.4,
                        child: ElevatedButton(
                          onPressed: _ready ? _submit : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.color,
                            disabledBackgroundColor:
                                widget.color.withValues(alpha: 0.4),
                          ),
                          child: const Text('Create assignment'),
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
