enum ChatRole { system, user, assistant, tool }

class ChatTurn {
  final ChatRole role;
  final String text;
  final String? responseId;
  final DateTime timestamp;
  final Map<String, dynamic> meta;

  ChatTurn({
    required this.role,
    required this.text,
    this.responseId,
    DateTime? timestamp,
    Map<String, dynamic>? meta,
  })  : timestamp = timestamp ?? DateTime.now(),
        meta = meta ?? const {};

  Map<String, dynamic> toJson() => {
    "role": role.name,
    "text": text,
    "responseId": responseId,
    "timestamp": timestamp.toIso8601String(),
    "meta": meta,
  };
}

class Sandbox {
  String syllabus;
  String? conversationId;
  String? lastResponseId;
  final List<String> responseIds = [];
  final List<ChatTurn> transcript = [];
  Map<String, dynamic> defaultParams;

  int? _activeAssistantIndex;

  Sandbox({
    required this.syllabus,
    this.defaultParams = const {},
  });

  void addUser(String text, {Map<String, dynamic>? meta}) {
    transcript.add(ChatTurn(role: ChatRole.user, text: text, meta: meta));
  }

  void beginAssistant({Map<String, dynamic>? meta}) {
    transcript.add(ChatTurn(role: ChatRole.assistant, text: "", meta: meta));
    _activeAssistantIndex = transcript.length - 1;
  }

  void appendAssistantDelta(String delta) {
    final idx = _activeAssistantIndex;
    if (idx == null) return;
    final turn = transcript[idx];

    transcript[idx] = ChatTurn(
      role: turn.role,
      text: turn.text + delta,
      responseId: turn.responseId,
      timestamp: turn.timestamp,
      meta: turn.meta,
    );
  }

  void attachAssistantResponseId(String responseId) {
    lastResponseId = responseId;
    responseIds.add(responseId);

    final idx = _activeAssistantIndex;
    if (idx == null) return;

    final turn = transcript[idx];
    transcript[idx] = ChatTurn(
      role: turn.role,
      text: turn.text,
      responseId: responseId,
      timestamp: turn.timestamp,
      meta: turn.meta,
    );
  }

  void finalizeAssistant() {
    _activeAssistantIndex = null;
  }

  String get latestAssistantText {
    for (int i = transcript.length - 1; i >= 0; i--) {
      final t = transcript[i];
      if (t.role == ChatRole.assistant) return t.text;
    }
    return "";
  }

  void reset({bool keepSyllabus = true}) {
    conversationId = null;
    lastResponseId = null;
    responseIds.clear();
    transcript.clear();
    _activeAssistantIndex = null;
    if (!keepSyllabus) syllabus = "";
  }

  Map<String, dynamic> toJson() => {
    '"syllabus"': '"$syllabus"',
    '"conversationId"': '"$conversationId"',
    '"lastResponseId"': '"$lastResponseId"',
    '"responseIds"': '"$responseIds"',
    '"defaultParams"': '"$defaultParams"',
    '"transcript"': '"${transcript.map((t) => t.toJson()).toList()}"',
  };
}