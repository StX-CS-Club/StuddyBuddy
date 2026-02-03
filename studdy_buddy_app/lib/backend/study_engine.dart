import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:studdy_buddy_app/backend/sandbox.dart';

/// OpenAI client (Responses API) with streaming + Conversations API state.
/// NOTE: do not embed your API key in a real student app.
class StudyEngine {
  static late String apiUrl; // should be https://api.openai.com/v1/responses
  static late String apiKey;
  static late String model;

  /// Optional global defaults; per-sandbox defaults live on sandbox.defaultParams
  static Map<String, dynamic> defaultParams = {};

  // ---- Conversations API ----

  static Future<String> createConversationId() async {
    final resp = await http.post(
      Uri.parse("https://api.openai.com/v1/conversations"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $apiKey",
      },
      body: jsonEncode({}),
    );

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception(
        "Create conversation failed: ${resp.statusCode} ${utf8.decode(resp.bodyBytes)}",
      );
    }

    final data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    final id = data["id"];
    if (id is! String || id.isEmpty) {
      throw Exception("Create conversation failed: missing id in response");
    }
    return id;
  }

  static Future<void> _ensureConversation(Sandbox sandbox) async {
    if (sandbox.conversationId != null && sandbox.conversationId!.isNotEmpty) {
      return;
    }
    sandbox.conversationId = await createConversationId();
  }

  // ---- Config ----

  static Future<void> loadFromFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw Exception("Config file not found: $path");
    }

    final jsonMap = jsonDecode(await file.readAsString());

    apiKey = jsonMap["api_key"];
    apiUrl = jsonMap["api_url"]; // expect /v1/responses
    model = jsonMap["model"] ?? model;

    final p = jsonMap["params"];
    if (p is Map) defaultParams = p.cast<String, dynamic>();
  }

  /// Streams assistant text deltas for one user turn.
  /// Updates sandbox transcript + ids as it goes.
  static Stream<String> streamTurn({
    required Sandbox sandbox,
    required String prompt,
    Map<String, dynamic>? metaUser,
    Map<String, dynamic>? metaAssistant,
    Map<String, dynamic> extraParams = const {},
    String? overrideModel,
  }) async* {
    // 1) Update local transcript immediately
    sandbox.addUser(prompt, meta: metaUser);
    sandbox.beginAssistant(meta: metaAssistant);

    final client = http.Client();
    String? lastSeenResponseId;

    try {
      // 2) Ensure we have a conversation id (Option B)
      await _ensureConversation(sandbox);

      final request = http.Request("POST", Uri.parse(apiUrl));
      request.headers.addAll({
        "Content-Type": "application/json",
        "Authorization": "Bearer $apiKey",
        "Accept": "text/event-stream",
      });

      final payload = <String, dynamic>{
        "model": overrideModel ?? model,
        "stream": true,

        // Teacher syllabus:
        "instructions": sandbox.syllabus,

        // Student prompt:
        "input": prompt,

        // ✅ Correct Conversation shape (Option B)
        "conversation": {"id": sandbox.conversationId},

        // Merge params: global < sandbox < per-call
        ...defaultParams,
        ...sandbox.defaultParams,
        ...extraParams,
      };

      request.body = jsonEncode(payload);

      final streamed = await client.send(request);

      if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
        final body = await streamed.stream.bytesToString();
        sandbox.finalizeAssistant();
        throw Exception("OpenAI HTTP ${streamed.statusCode}: $body");
      }

      final lines = streamed.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      String? currentEventName;

      await for (final line in lines) {
        if (line.isEmpty) {
          currentEventName = null;
          continue;
        }

        if (line.startsWith("event:")) {
          currentEventName = line.substring("event:".length).trim();
          continue;
        }

        if (!line.startsWith("data:")) continue;

        final dataStr = line.substring("data:".length).trim();
        if (dataStr == "[DONE]") break;

        Map<String, dynamic> data;
        try {
          data = jsonDecode(dataStr) as Map<String, dynamic>;
        } catch (_) {
          continue;
        }

        // Update sandbox IDs as soon as we can
        final ids = _extractIds(data);

        // conversationId may come back; keep it if present
        if (ids.conversationId != null) sandbox.conversationId = ids.conversationId;

        if (ids.responseId != null) {
          lastSeenResponseId = ids.responseId;
          if (sandbox.lastResponseId != ids.responseId) {
            sandbox.attachAssistantResponseId(ids.responseId!);
          }
        }

        // Extract delta text and yield
        final delta = _extractTextDelta(data, currentEventName);
        if (delta != null && delta.isNotEmpty) {
          sandbox.appendAssistantDelta(delta);
          yield delta;
        }
      }

      // If stream ended but we never attached response id, do a best-effort attach now.
      if (lastSeenResponseId != null &&
          (sandbox.lastResponseId != lastSeenResponseId)) {
        sandbox.attachAssistantResponseId(lastSeenResponseId!);
      }

      sandbox.finalizeAssistant();
    } catch (e) {
      sandbox.finalizeAssistant();
      rethrow;
    } finally {
      client.close();
    }
  }

  /// Non-streaming single-turn call (uses Conversations API state).
  static Future<String> sendTurnOnce({
    required Sandbox sandbox,
    required String prompt,
    Map<String, dynamic>? metaUser,
    Map<String, dynamic>? metaAssistant,
    Map<String, dynamic> extraParams = const {},
    String? overrideModel,
  }) async {
    sandbox.addUser(prompt, meta: metaUser);
    sandbox.beginAssistant(meta: metaAssistant);

    http.Response resp;
    try {
      await _ensureConversation(sandbox);

      final payload = <String, dynamic>{
        "model": overrideModel ?? model,
        "stream": false,
        "instructions": sandbox.syllabus,
        "input": prompt,

        // ✅ Correct shape
        "conversation": {"id": sandbox.conversationId},

        ...defaultParams,
        ...sandbox.defaultParams,
        ...extraParams,
      };

      resp = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $apiKey",
        },
        body: jsonEncode(payload),
      );
    } catch (e) {
      sandbox.finalizeAssistant();
      throw Exception("Network error: $e");
    }

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      sandbox.finalizeAssistant();
      throw Exception(
        "OpenAI HTTP ${resp.statusCode}: ${utf8.decode(resp.bodyBytes)}",
      );
    }

    final Map<String, dynamic> data =
    jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;

    // Update ids from the full response object if present
    final ids = _extractIds(data);
    if (ids.conversationId != null) sandbox.conversationId = ids.conversationId;
    if (ids.responseId != null) sandbox.attachAssistantResponseId(ids.responseId!);

    final text = _extractFinalTextFromNonStream(data) ?? "";
    if (text.isNotEmpty) sandbox.appendAssistantDelta(text);

    sandbox.finalizeAssistant();
    return sandbox.latestAssistantText;
  }

  // ---------- Extraction helpers ----------

  static _Ids _extractIds(Map<String, dynamic> data) {
    String? responseId;
    String? conversationId;

    // Streaming: data["response"] often exists
    final resp = data["response"];
    if (resp is Map) {
      final rid = resp["id"];
      if (rid is String) responseId = rid;

      final conv = resp["conversation"];
      if (conv is String) conversationId = conv;
      if (conv is Map && conv["id"] is String) conversationId = conv["id"] as String;
    }

    // Non-stream: top-level id/conversation
    final topId = data["id"];
    if (topId is String) responseId ??= topId;

    final topConv = data["conversation"];
    if (topConv is String) conversationId ??= topConv;
    if (topConv is Map && topConv["id"] is String) conversationId ??= topConv["id"] as String;

    return _Ids(responseId: responseId, conversationId: conversationId);
  }

  static String? _extractTextDelta(Map<String, dynamic> data, String? eventName) {
    final type = (data["type"] ?? eventName);
    if (type is! String) return null;

    // Only handle true deltas
    if (!type.contains("output_text") || !type.contains("delta")) return null;

    final d = data["delta"];
    if (d is String) return d;

    final text = data["text"];
    if (text is Map && text["delta"] is String) return text["delta"] as String;

    return null;
  }


  static String? _extractFinalTextFromNonStream(Map<String, dynamic> data) {
    final output = data["output"];
    if (output is! List) return null;

    final buf = StringBuffer();
    for (final item in output) {
      if (item is! Map) continue;
      if (item["type"] != "message") continue;
      if (item["role"] != "assistant") continue;

      final content = item["content"];
      if (content is! List) continue;

      for (final c in content) {
        if (c is Map && c["type"] == "output_text" && c["text"] is String) {
          buf.write(c["text"] as String);
        }
      }
      if (buf.isNotEmpty) break;
    }
    final s = buf.toString().trim();
    return s.isEmpty ? null : s;
  }
}

class _Ids {
  final String? responseId;
  final String? conversationId;
  _Ids({required this.responseId, required this.conversationId});
}