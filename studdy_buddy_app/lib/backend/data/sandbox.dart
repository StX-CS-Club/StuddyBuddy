import 'package:studdy_buddy_app/backend/data/assignment.dart';
import 'package:studdy_buddy_app/backend/files/app_file.dart';
import 'package:studdy_buddy_app/backend/data/message.dart';
import 'package:studdy_buddy_app/backend/supabase/supabase_db.dart';

import '../anthropic/study_engine.dart';

class Sandbox {
  final String id;
  final String assignmentId;
  late Assignment assignment;
  final String user;
  final String? instructions;
  final Set<String> messageIds;
  final DateTime? submissionDate;
  late List<Message> messages;

  final Map<String, String> attachments = {};

  Sandbox(
      {required this.id,
        required this.assignmentId,
        required this.user,
        this.instructions,
        this.submissionDate,
        this.messageIds = const {}});

  factory Sandbox.fromJson(Map<String, dynamic> json) {
    return Sandbox(
        id: json['id'],
        assignmentId: json['assignment'],
        user: json['user'],
        submissionDate: DateTime.tryParse(json['submission_date'] ?? ""),
        instructions: json['instructions']);
  }

  static List<Sandbox> fromList(List<Map<String, dynamic>> list) {
    return list.map((m) => Sandbox.fromJson(m)).toList();
  }

  Future<List<Message>> readMessages() async {
    messages = await SupabaseDB.readMessages(id);
    return messages;
  }

  Stream<String> sendMessage(String prompt,
      {Map<String, String>? fileIds}) async* {
    final Message? userMessage = await SupabaseDB.saveMessage(
      sandboxId: id,
      role: "user",
      content: prompt,
      fileIds: attachments,
    );
    if (userMessage != null) messages.add(userMessage);

    attachments.clear();

    final bool hasFiles =
        assignment.fileIds.isNotEmpty || attachments.isNotEmpty;

    final StringBuffer buffer = StringBuffer();
    await for (final delta in streamResponse(
        instructions: instructions ?? '',
        messages: buildClaudeMessages(),
        withFilesApi: hasFiles)) {
      buffer.write(delta);
      yield delta;
    }

    final Message? assistantMessage = await SupabaseDB.saveMessage(
        sandboxId: id, role: "assistant", content: buffer.toString());
    if (assistantMessage != null) messages.add(assistantMessage);
  }

  List<Map<String, dynamic>> buildClaudeMessages() {
    final List<Map<String, dynamic>> claudeMessages =
    messages.map((m) => m.toClaudeMessage()).toList();

    if (claudeMessages.isEmpty) return claudeMessages;

    // Only inject assignment-level files into the first message
    final Map<String, String> fileIds = assignment.fileIds;
    if (fileIds.isEmpty) return claudeMessages;

    final Map<String, dynamic> first = claudeMessages.first;
    final List<Map<String, dynamic>> fileBlocks = fileIds.entries.map((e) {
      final String mimeType = AppFile.extensionToMime(e.key.split('.').last);
      return StudyEngine.fileBlock(e.value, mimeType);
    }).toList();

    final dynamic existingContent = first['content'];
    final List<Map<String, dynamic>> content = [
      ...fileBlocks,
      if (existingContent is String)
        StudyEngine.textBlock(existingContent)
      else if (existingContent is List)
        ...existingContent.cast<Map<String, dynamic>>(),
    ];

    claudeMessages[0] = {'role': 'user', 'content': content};
    return claudeMessages;
  }

  static Stream<String> streamResponse(
      {required String instructions,
        required List<Map<String, dynamic>> messages,
        bool withFilesApi = false}) async* {
    yield* StudyEngine.streamTurn(
        instructions: instructions,
        messages: messages,
        withFilesApi: withFilesApi);
  }

  Assignment? readAssignment() {
    final Assignment? result =
        SupabaseDB.assignments.where((a) => a.id == assignmentId).firstOrNull;
    if (result != null) {
      assignment = result;
      return result;
    }
    return null;
  }

  @override
  bool operator ==(Object other) => other is Sandbox && other.id == id;

  @override
  int get hashCode => id.hashCode;
}