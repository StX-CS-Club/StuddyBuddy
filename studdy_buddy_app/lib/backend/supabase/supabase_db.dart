import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:studdy_buddy_app/backend/anthropic/study_engine.dart';
import 'package:studdy_buddy_app/backend/data/assignment.dart';
import 'package:studdy_buddy_app/backend/data/classroom.dart';
import 'package:studdy_buddy_app/backend/files/app_file.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/account.dart';
import '../data/message.dart';
import '../data/sandbox.dart';

class SupabaseDB {
  static late SupabaseClient _supabase;
  static bool _initialized = false;

  static bool get initialized => _initialized;

  static Future<void> init() async {
    final String jsonString =
        await rootBundle.loadString("assets/json_data/supabase.json");
    final Map<String, dynamic> jsonMap =
        Map<String, dynamic>.from(jsonDecode(jsonString));

    final String url = jsonMap["url"] as String;
    final String key = jsonMap["api_key"] as String;
    _supabase = (await Supabase.initialize(url: url, anonKey: key)).client;
    _initialized = true;
  }

  static bool authenticated() {
    return _supabase.auth.currentUser?.id != null;
  }

  static Future<void> fetchData() async {
    await readAccount();
    await readClassrooms();
  }

  static Account? account;
  static final Set<Account> accounts = {};
  static final List<Classroom> classrooms = [];
  static final List<Assignment> assignments = [];
  static final List<Sandbox> sandboxes = [];

  static Future<bool> signUp(String email, String password) async {
    final AuthResponse res =
        await _supabase.auth.signUp(email: email, password: password);
    return res.user?.email != null;
  }

  static Future<bool> signIn(String email, String password) async {
    final AuthResponse res = await _supabase.auth
        .signInWithPassword(email: email, password: password);
    if (res.user?.email != null) {
      await readAccount();
      return true;
    }
    return false;
  }

  static Future<void> signOut() async {
    await _supabase.auth.signOut();
    account = null;
    classrooms.clear();
    assignments.clear();
    sandboxes.clear();
  }

  static Future<Account?> readAccount() async {
    final String? uid = _supabase.auth.currentUser?.id;
    if (uid == null) return null;
    final List<Map<String, dynamic>> res =
        await _supabase.from("account").select().eq("id", uid);
    if (res.isEmpty) return null;
    account = Account.fromJson(res.first);
    return account!;
  }

  static Future<Set<Account>> readAccounts(List<String> ids) async {
    if (account?.id == null) return {};
    final List<Map<String, dynamic>> res =
        await _supabase.from("account").select().inFilter("id", ids);
    final Set<Account> parsedRes = Account.fromList(res);
    accounts.addAll(parsedRes);
    return parsedRes;
  }

  static Future<void> writeAccount({String? name, String? role}) async {
    if (account?.id == null) return;
    final Map<String, String?> data = {"name": name, "role": role}
      ..removeWhere((_, v) => v == null);
    final List<Map<String, dynamic>> res = await _supabase
        .from('account')
        .update(data)
        .eq("id", account!.id)
        .select();
    if (res.isNotEmpty) account = Account.fromJson(res.first);
  }

  static Future<bool> createClassroom(
      {required String name,
      String? syllabus,
      String? emoji,
      String? color}) async {
    if (account?.role?.toLowerCase() != "teacher") {
      return false;
    }
    final List<Map<String, dynamic>> res =
        await _supabase.from('classroom').insert({
      "name": name,
      "syllabus": syllabus,
      "color": color,
      "emoji": emoji,
      "teacher": account?.id
    }).select();
    if (res.isEmpty) return false;
    classrooms.add(Classroom.fromJson(res.first));
    return true;
  }

  static Future<bool> writeClassroom(String id,
      {String? name, String? syllabus, String? emoji, String? color}) async {
    if (account?.role?.toLowerCase() != "teacher") {
      return false;
    }
    final Map<String, dynamic> data = {
      "name": name,
      "syllabus": syllabus,
      "color": color,
      "emoji": emoji
    }..removeWhere((_, v) => v == null);
    final List<Map<String, dynamic>> res =
        await _supabase.from('classroom').update(data).eq("id", id).select();
    if (res.isEmpty) return false;
    return true;
  }

  static Future<bool> joinClassroom(String id) async {
    return await _supabase.rpc("join_classroom", params: {"classroom_id": id});
  }

  static Future<List<Classroom>> readClassrooms() async {
    final List<String> ids = List<String>.from(account?.classroomIds ?? []);
    if (account?.id == null || ids.isEmpty) return [];
    final List<Map<String, dynamic>> res =
        await _supabase.from('classroom').select().inFilter('id', ids);
    classrooms.clear();
    classrooms.addAll(Classroom.fromList(res));
    return classrooms;
  }

  static Future<Assignment?> createAssignment(
      {required String classroomId,
        required String title,
        String? instructions}) async {
    print('🟡 createAssignment called');
    print('  classroomId: $classroomId');
    print('  title: $title');
    print('  account: ${account?.id}');
    print('  account role: ${account?.role}');
    print('  classrooms: ${classrooms.map((c) => c.id).toList()}');

    if (account?.role?.toLowerCase() != "teacher") {
      print('❌ blocked: account role is not teacher (role=${account?.role})');
      return null;
    }

    if (classrooms.where((c) => c.id == classroomId).isEmpty) {
      print('❌ blocked: classroomId $classroomId not found in local classrooms');
      return null;
    }

    print('✅ passed checks, inserting...');

    final Map<String, dynamic> data = {
      "classroom": classroomId,
      "title": title,
      "instructions": instructions
    }..removeWhere((_, v) => v == null);

    print('  data: $data');

    try {
      final List<Map<String, dynamic>> debugRes = await _supabase
          .from('classroom')
          .select()
          .eq('id', classroomId);
      print('🔍 classroom from db: $debugRes');

      final String? uid = _supabase.auth.currentUser?.id;
      print('🔍 auth.uid(): $uid');

      print('🔍 session: ${_supabase.auth.currentSession}');
      print('🔍 access token: ${_supabase.auth.currentSession?.accessToken}');

      final List<Map<String, dynamic>> res =
      await _supabase.from("assignment").insert(data).select();
      print('  res: $res');
      if (res.isEmpty) {
        print('❌ insert returned empty');
        return null;
      }
      final Assignment parsedRes = Assignment.fromJson(res.first);
      assignments.add(parsedRes);
      classrooms
          .firstWhere((c) => c.id == classroomId)
          .assignmentIds
          .add(parsedRes.id);
      print('✅ assignment created: ${parsedRes.id}');
      return parsedRes;
    } catch (e) {
      print('❌ exception during insert: $e');
      return null;
    }
  }

  static Future<bool> writeAssignment(String id,
      {String? title,
      String? pdfUrl,
      String? instructions,
      Map<String, String>? fileIds}) async {
    if (account?.role?.toLowerCase() != "teacher" ||
        classrooms.where((c) => c.assignmentIds.contains(id)).isEmpty) {
      return false;
    }
    final Map<String, dynamic> data = {
      "title": title,
      "pdf_url": pdfUrl,
      "instructions": instructions,
      "file_ids": fileIds
    }..removeWhere((_, v) => v == null);

    final List<Map<String, dynamic>> res =
        await _supabase.from("assignment").update(data).eq("id", id).select();
    if (res.isEmpty) return false;
    await readClassrooms();
    return true;
  }

  static Future<AppFile?> uploadAssignmentFile(
      {required String assignmentId,
      required File file,
      String? mimeType}) async {
    if (account?.role?.toLowerCase() != "teacher" ||
        classrooms
            .where((c) =>
                c.assignmentIds.contains(assignmentId) &&
                c.teacherId == account?.id)
            .isEmpty) {
      return null;
    }

    final String filePath = "$assignmentId/${file.uri.pathSegments.last}";

    await _supabase.storage.from("assignment").upload(filePath, file,
        fileOptions: FileOptions(contentType: mimeType, upsert: true));

    final AppFile supabaseFile = AppFile.fromUrl(
        url: await _supabase.storage
            .from("assignment")
            .createSignedUrl(filePath, 3600),
        fileName: filePath.split("/").last);

    final Map<String, String> anthropicFile =
        await StudyEngine.uploadSupabaseFiles([supabaseFile]);

    final Assignment assignment =
        assignments.firstWhere((a) => a.id == assignmentId);
    assignment.fileIds.addAll(anthropicFile);
    await writeAssignment(assignmentId, fileIds: assignment.fileIds);

    return supabaseFile;
  }

  static Future<List<AppFile>> readAssignmentFiles(String assignmentId) async {
    final List<FileObject> files =
        await _supabase.storage.from('assignment').list(path: assignmentId);
    final List<String> fileUrls = await Future.wait(files.map((f) async =>
        await _supabase.storage
            .from('assignment')
            .createSignedUrl('$assignmentId/${f.name}', 3600)));

    return List.generate(files.length,
        (i) => AppFile.fromUrl(url: fileUrls[i], fileName: files[i].name));
  }

  static Future<List<Assignment>> readAssignments({Set<String>? ids}) async {
    if (account?.id == null) return [];
    late List<Map<String, dynamic>> res;
    if (ids != null) {
      res = await _supabase
          .from('assignment')
          .select()
          .inFilter('id', ids.toList());
    } else {
      final Set<String> assignmentIds = {};
      for (Classroom classroom in classrooms) {
        assignmentIds.addAll(classroom.assignmentIds);
      }
      if (assignmentIds.isEmpty) return [];
      res = await _supabase
          .from('assignment')
          .select()
          .inFilter("id", assignmentIds.toList());
    }
    final List<Assignment> parsedRes = Assignment.fromList(res);
    if (ids == null) assignments.clear();
    assignments.addAll(parsedRes);
    return parsedRes;
  }

  static Future<Sandbox?> createSandbox(String assignment,
      {String? instructions}) async {
    if (account?.id == null ||
        classrooms.where((c) => c.assignmentIds.contains(assignment)).isEmpty) {
      return null;
    }
    final Map<String, dynamic> data = {
      "assignment": assignment,
      "user": account?.id,
      "instructions": instructions
    }..removeWhere((_, v) => v == null);
    final List<Map<String, dynamic>> res =
        await _supabase.from('sandbox').insert(data).select();
    if (res.isEmpty) return null;
    final Sandbox result = Sandbox.fromJson(res.first);
    sandboxes.add(result);
    return result;
  }

  static Future<Sandbox?> openSandbox(String assignment,
      {String? instructions}) async {
    if (account?.id == null ||
        classrooms.where((c) => c.assignmentIds.contains(assignment)).isEmpty) {
      return null;
    }
    List<Map<String, dynamic>> res = await _supabase
        .from('sandbox')
        .select()
        .eq("assignment", assignment)
        .eq("user", account!.id);
    if (res.isEmpty) {
      return await createSandbox(assignment, instructions: instructions);
    }
    final Sandbox result = Sandbox.fromJson(res.first);
    sandboxes.add(result);
    return result;
  }

  static Future<AppFile?> uploadSandboxFile(
      {required String sandboxId, required File file, String? mimeType}) async {
    if (sandboxes
        .where((s) => s.user == account?.id && s.id == sandboxId)
        .isEmpty) {
      return null;
    }

    final String filePath = "$sandboxId/${file.uri.pathSegments.last}";

    await _supabase.storage.from("sandbox").upload(filePath, file,
        fileOptions: FileOptions(contentType: mimeType, upsert: true));

    final AppFile supabaseFile = AppFile.fromUrl(
        url: await _supabase.storage
            .from("sandbox")
            .createSignedUrl(filePath, 3600),
        fileName: filePath.split("/").last);

    final Map<String, String> anthropicFile =
        await StudyEngine.uploadSupabaseFiles([supabaseFile]);

    final Sandbox sandbox = sandboxes.firstWhere((s) => s.id == sandboxId);
    sandbox.attachments.addAll(anthropicFile);

    return supabaseFile;
  }

  static Future<AppFile?> uploadSubmissionFile(
      {required String sandboxId, required File file, String? mimeType}) async {
    if (sandboxes
        .where((s) => s.user == account?.id && s.id == sandboxId)
        .isEmpty) {
      return null;
    }

    final String filePath = "$sandboxId/${file.uri.pathSegments.last}";

    await _supabase.storage.from("submission").upload(filePath, file,
        fileOptions: FileOptions(contentType: mimeType, upsert: true));

    final AppFile supabaseFile = AppFile.fromUrl(
        url: await _supabase.storage
            .from("submission")
            .createSignedUrl(filePath, 3600),
        fileName: filePath.split("/").last);

    await _supabase
        .from('sandbox')
        .update({"submission_date": DateTime.now().toIso8601String()}).eq(
            "id", sandboxId);

    return supabaseFile;
  }

  static Future<List<Sandbox>> readSandboxes({Set<String>? ids}) async {
    if (account?.id == null) return [];
    late List<Map<String, dynamic>> res;
    if (ids != null) {
      res =
          await _supabase.from('sandbox').select().inFilter('id', ids.toList());
    } else if (account?.role?.toLowerCase() == "teacher") {
      final Set<String> assignmentIds = {};
      for (Classroom classroom in classrooms) {
        if (classroom.teacherId == account?.id) {
          assignmentIds.addAll(classroom.assignmentIds);
        }
      }
      if (assignmentIds.isEmpty) return [];
      res = await _supabase
          .from('sandbox')
          .select()
          .inFilter("assignment", assignmentIds.toList());
    } else {
      res = await _supabase.from('sandbox').select().eq("user", account!.id);
    }
    final List<Sandbox> parsedRes = Sandbox.fromList(res);
    if (ids == null) sandboxes.clear();
    sandboxes.addAll(parsedRes);
    return parsedRes;
  }

  static Future<List<Message>> readMessages(String sandboxId) async {
    final Sandbox? sandbox =
        sandboxes.where((s) => s.id == sandboxId).firstOrNull;
    if (sandbox == null ||
        sandbox.user != account?.id &&
            classrooms
                .where((c) =>
                    c.assignmentIds.contains(sandbox.assignmentId) &&
                    c.teacherId == account?.id)
                .isEmpty) {
      return [];
    }
    final List<Map<String, dynamic>> res =
        await _supabase.from('message').select().eq('sandbox', sandboxId);
    return Message.fromList(res);
  }

  static Future<Message?> saveMessage(
      {required String sandboxId,
      required String role,
      required String content,
      Map<String, String>? fileIds,
      DateTime? createdAt}) async {
    if (account?.id == null ||
        sandboxes.where((s) => s.id == sandboxId).isEmpty) {
      return null;
    }
    final Map<String, dynamic> data = {
      "sandbox": sandboxId,
      "role": role,
      "content": content,
      "file_ids": fileIds,
      "created_at": createdAt
    }..removeWhere((_, v) => v == null);
    final List<Map<String, dynamic>> res =
        await _supabase.from('message').insert(data).select();
    if (res.isEmpty) return null;
    return Message.fromJson(res.first);
  }
}
