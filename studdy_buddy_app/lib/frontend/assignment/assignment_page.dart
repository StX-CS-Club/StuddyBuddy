import 'package:flutter/material.dart';
import 'package:studdy_buddy_app/backend/data/assignment.dart';
import 'package:studdy_buddy_app/backend/data/sandbox.dart';
import 'package:studdy_buddy_app/backend/supabase/supabase_db.dart';
import 'package:studdy_buddy_app/extensions/build_context_extension.dart';
import 'package:studdy_buddy_app/frontend/startup/theme.dart';
import '../../backend/files/app_file.dart';
import '../../widgets/avatar_stack.dart';
import '../file/app_file_tile.dart';

class AssignmentPage extends StatefulWidget {
  const AssignmentPage({super.key, required this.assignment, required this.color});

  final Assignment assignment;
  final Color color;

  @override
  State<AssignmentPage> createState() => _AssignmentPageState();
}

class _AssignmentPageState extends State<AssignmentPage> {
  bool get _isTeacher => SupabaseDB.account?.role == 'teacher';

  Future<void> _openSandbox() async {
    final Sandbox? sandbox = await widget.assignment.openSandbox();
    if (sandbox == null) {
      if (mounted) context.showSnackBar('Failed to open sandbox', isError: true);
    }
  }

  Widget _section(BuildContext context, String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        child,
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Assignment a = widget.assignment;

    return Scaffold(
      backgroundColor: StuddyBuddyTheme.surfaceDim,
      appBar: AppBar(
        backgroundColor: StuddyBuddyTheme.surfaceBase,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: StuddyBuddyTheme.teal,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AvatarStack(),
            const SizedBox(width: 10),
            RichText(
              text: TextSpan(
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w600),
                children: [
                  TextSpan(
                    text: 'Studdy',
                    style: TextStyle(color: StuddyBuddyTheme.teal),
                  ),
                  TextSpan(
                    text: 'Buddy',
                    style: TextStyle(color: StuddyBuddyTheme.forest),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Icon(Icons.account_circle_outlined,
                  color: StuddyBuddyTheme.teal),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              a.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),

            // Instructions
            if (a.instructions != null)
              _section(
                context,
                'Instructions',
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: StuddyBuddyTheme.surfaceBase,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    a.instructions!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),

            // Files
            if (a.fileIds.isNotEmpty)
              _section(
                context,
                'Files',
                Column(
                  children: a.fileIds.entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: AppFileTile(
                      file: AppFile.fromUrl(url: e.value, fileName: e.key),
                      onView: () {},
                    ),
                  )).toList(),
                ),
              ),

            // Open sandbox button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openSandbox,
                icon: const Icon(Icons.terminal_outlined),
                label: const Text('Open sandbox'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.color,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Teacher-only sandbox list
            if (_isTeacher)
              _section(
                context,
                'Sandboxes',
                FutureBuilder<List<Sandbox>>(
                  future: widget.assignment.readSandboxes(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(color: widget.color),
                      );
                    }
                    if (snapshot.hasError) {
                      return Text(
                        'Failed to load sandboxes',
                        style: Theme.of(context).textTheme.bodySmall,
                      );
                    }
                    final List<Sandbox> sandboxes = snapshot.data ?? [];
                    if (sandboxes.isEmpty) {
                      return Text(
                        'No submissions yet',
                        style: Theme.of(context).textTheme.bodySmall,
                      );
                    }
                    return Column(
                      children: sandboxes.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: widget.color,
                              child: const Icon(Icons.terminal_outlined,
                                  color: Colors.white, size: 18),
                            ),
                            title: Text('Sandbox ${s.id}'),
                            trailing: const Icon(Icons.chevron_right),
                          ),
                        ),
                      )).toList(),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}