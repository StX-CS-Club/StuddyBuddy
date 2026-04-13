import 'package:studdy_buddy_app/backend/assignment.dart';
import 'package:studdy_buddy_app/backend/supabase/supabase_db.dart';

class Classroom {
  Classroom(
      {required this.id,
      required this.name,
      required this.syllabus,
        required this.teacher,
      this.assignmentIds = const {}});

  final String name;
  final String? syllabus;
  final String id;
  final String teacher;
  final Set<String> assignmentIds;
  late List<Assignment> assignments;

  factory Classroom.fromJson(Map<String, dynamic> json) {
    return Classroom(
        id: json['id'],
        name: json['name'],
        syllabus: json['syllabus'],
        teacher: json['teacher'],
        assignmentIds: Set<String>.from(json['assignments'] ?? {}));
  }

  static Set<Classroom> fromList(List<Map<String, dynamic>> list) {
    return list.map((m) => Classroom.fromJson(m)).toSet();
  }

  Future<List<Assignment>> readAssignments() async {
    assignments = await SupabaseDB.readAssignments(ids: assignmentIds);
    return assignments;
  }

  @override
  bool operator ==(Object other) => other is Classroom && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
