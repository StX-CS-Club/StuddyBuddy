import 'package:studdy_buddy_app/backend/data/account.dart';
import 'package:studdy_buddy_app/backend/data/assignment.dart';
import 'package:studdy_buddy_app/backend/data/sandbox.dart';
import 'package:studdy_buddy_app/backend/supabase/supabase_db.dart';

class Classroom {
  Classroom(
      {required this.id,
      required this.name,
      required this.syllabus,
      required this.teacherId,
      this.assignmentIds = const {},
      this.studentIds = const {},
      this.emoji,
      this.colorId});

  final String name;
  final String? syllabus;
  final String id;
  final String teacherId;
  late Account teacher;
  final String? emoji;
  final String? colorId;
  final Set<String> assignmentIds;
  late List<Assignment> assignments;
  final Set<String> studentIds;
  late Set<Account> students;

  factory Classroom.fromJson(Map<String, dynamic> json) {
    return Classroom(
        id: json['id'],
        name: json['name'],
        syllabus: json['syllabus'],
        teacherId: json['teacher'],
        colorId: json['color'],
        emoji: json['emoji'],
        studentIds: Set<String>.from(json['students'] ?? {}),
        assignmentIds: Set<String>.from(json['assignments'] ?? {}),);
  }

  static Set<Classroom> fromList(List<Map<String, dynamic>> list) {
    return list.map((m) => Classroom.fromJson(m)).toSet();
  }

  Future<List<Assignment>> readAssignments() async {
    assignments = await SupabaseDB.readAssignments(ids: assignmentIds);
    return assignments;
  }

  Future<Account> readTeacher() async {
    teacher = (await SupabaseDB.readAccounts([teacherId])).first;
    return teacher;
  }

  Future<Set<Account>> readStudents() async {
    students = await SupabaseDB.readAccounts(studentIds.toList());
    return students;
  }

  @override
  bool operator ==(Object other) => other is Classroom && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
