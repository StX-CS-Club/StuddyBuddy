import 'package:studdy_buddy_app/backend/files/app_file.dart';
import 'package:studdy_buddy_app/backend/data/sandbox.dart';

import '../anthropic/study_engine.dart';

enum Source { user, assistant }

class Message {
  final String id;
  final String sandboxId;
  late Sandbox sandbox;
  final Source role;
  final String content;
  final DateTime createdAt;
  final Map<String, String> fileIds;

  Message({
    required this.id,
    required this.sandboxId,
    required this.role,
    this.content = "",
    this.fileIds = const {},
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
        id: json['id'],
        sandboxId: json['sandbox'],
        role: json['role'].toString().toLowerCase() == "user"
            ? Source.user
            : Source.assistant,
        fileIds: Map<String, String>.from(json['file_ids'] ?? {}),
        content: json['content']);
  }

  static List<Message> fromList(List<Map<String, dynamic>> list) {
    return list.map((m) => Message.fromJson(m)).toList();
  }

  Map<String, dynamic> toClaudeMessage() {
    if (fileIds.isEmpty) return {"role": role.name, "content": content};

    final List<Map<String, dynamic>> contentBlocks = [
      ...fileIds.entries.map((e) {
        final String mimeType = AppFile.extensionToMime(e.key.split('.').last);
        return StudyEngine.fileBlock(e.value, mimeType);
      }),
      StudyEngine.textBlock(content),
    ];

    return {"role": role.name, "content": contentBlocks};
  }

  @override
  bool operator ==(Object other) => other is Message && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
