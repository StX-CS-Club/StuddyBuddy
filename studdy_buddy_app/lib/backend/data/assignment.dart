import 'package:studdy_buddy_app/backend/data/sandbox.dart';

import '../supabase/supabase_db.dart';

class Assignment {
  final String id;
  final String classroom;
  final String title;
  final String? instructions;
  final Map<String, String> fileIds;
  final Set<String> sandboxIds;
  late List<Sandbox> sandboxes;
  late Sandbox sandbox;

  Assignment(
      {required this.id,
      required this.classroom,
      required this.title,
      this.instructions,
      this.sandboxIds = const {},
      this.fileIds = const {}});

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
        id: json['id'],
        title: json['title'],
        classroom: json['classroom'],
        instructions: json['instructions'],
        sandboxIds: Set<String>.from(json['sandboxes'] ?? {}),
        fileIds: Map<String, String>.from(json['file_ids'] ?? {}));
  }

  static List<Assignment> fromList(List<Map<String, dynamic>> list) {
    return list.map((m) => Assignment.fromJson(m)).toList();
  }

  Future<List<Sandbox>> readSandboxes() async {
    sandboxes = await SupabaseDB.readSandboxes(ids: sandboxIds);
    return sandboxes;
  }

  Future<Sandbox?> openSandbox() async {
    final Sandbox? res = await SupabaseDB.openSandbox(id);
    if (res != null) sandbox = res;
    return res;
  }

  @override
  bool operator ==(Object other) => other is Assignment && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
