import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:studdy_buddy_app/backend/supabase/supabase_file.dart';

class StudyEngine {
  static const String _claudeApiUrl = 'https://api.anthropic.com/v1/messages';
  static const String _claudeFileApiUrl = 'https://api.anthropic.com/v1/files';
  static const String _anthropicVersion = '2023-06-01';
  static const String _anthropicFilesApiBeta = 'files-api-2025-04-14';

  static late String apiKey;
  static late String model;
  static late Map<String, dynamic> defaultParams;

  static Future<void> loadFromFile(String path) async {
    final File file = File(path);
    if (!await file.exists()) throw Exception('Config file not found: $path');
    final Map<String, dynamic> jsonMap =
        Map<String, dynamic>.from(jsonDecode(await file.readAsString()));
    apiKey = jsonMap['api_key'];
    model = jsonMap['model'];
    defaultParams = Map<String, dynamic>.from(jsonMap['params']);
  }

  // ---------------------------------------------------------------------------
  // Content block builders
  // ---------------------------------------------------------------------------

  /// Returns a plain text content block.
  static Map<String, dynamic> textBlock(String text) => {
        'type': 'text',
        'text': text,
      };

  /// Returns a file content block for a previously-uploaded file.
  ///
  /// [fileId]   – the `id` returned by [uploadBytes] / [uploadFile].
  /// [mimeType] – must match the MIME type used when uploading.
  ///              Common values: 'application/pdf', 'image/png', 'image/jpeg'.
  static Map<String, dynamic> fileBlock(String fileId, String mimeType) {
    final bool isImage = mimeType.startsWith('image/');

    if (isImage) {
      return {
        'type': 'image',
        'source': {
          'type': 'file',
          'file_id': fileId,
        },
      };
    }
    return {
      'type': 'document',
      'source': {
        'type': 'file',
        'file_id': fileId,
      },
    };
  }

  /// Builds a user message whose content is a mix of text and file blocks.
  ///
  /// [text]  – optional text to prepend before the files.
  /// [files] – map of { fileId → mimeType } for files to attach.
  ///
  /// Example:
  /// ```dart
  /// final msg = StudyEngine.userMessageWithFiles(
  ///   text: 'Please summarise these notes.',
  ///   files: {'file_abc123': 'application/pdf'},
  /// );
  /// ```
  static Map<String, dynamic> userMessageWithFiles({
    String? text,
    Map<String, String> files = const {},
  }) {
    final List<Map<String, dynamic>> content = [];
    if (text != null && text.isNotEmpty) content.add(textBlock(text));
    for (final MapEntry<String, String> entry in files.entries) {
      content.add(fileBlock(entry.key, entry.value));
    }
    return {'role': 'user', 'content': content};
  }

  /// Convenience: builds a plain user text message (no files).
  static Map<String, dynamic> userMessage(String text) =>
      {'role': 'user', 'content': text};

  /// Convenience: wraps an assistant reply as a history turn.
  static Map<String, dynamic> assistantMessage(String text) =>
      {'role': 'assistant', 'content': text};

  // ---------------------------------------------------------------------------
  // API headers
  // ---------------------------------------------------------------------------

  /// Returns headers for the Messages API.
  ///
  /// [withFilesApi] must be `true` whenever the request body references
  /// file content blocks (i.e. any message built with [fileBlock]).
  static Map<String, String> _headers({
    required bool stream,
    bool withFilesApi = false,
  }) =>
      {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': _anthropicVersion,
        if (stream) 'Accept': 'text/event-stream',
        if (withFilesApi) 'anthropic-beta': _anthropicFilesApiBeta,
      };

  // ---------------------------------------------------------------------------
  // Streaming turn
  // ---------------------------------------------------------------------------

  static Stream<String> streamTurn({
    required String instructions,
    required List<Map<String, dynamic>> messages,
    bool withFilesApi = false,
  }) async* {
    final http.Client client = http.Client();
    try {
      final http.Request request =
          http.Request('POST', Uri.parse(_claudeApiUrl));
      request.headers
          .addAll(_headers(stream: true, withFilesApi: withFilesApi));
      request.body = jsonEncode({
        'model': model,
        'max_tokens': 1024,
        'stream': true,
        if (instructions.isNotEmpty)
          'system': [
            {
              'type': 'text',
              'text': instructions,
              'cache_control': {'type': 'ephemeral'},
            }
          ],
        'messages': messages,
        'cache_control': {'type': 'ephemeral'},
        ...defaultParams,
      });

      final http.StreamedResponse streamed = await client.send(request);

      if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
        final String body = await streamed.stream.bytesToString();
        throw Exception('Claude HTTP ${streamed.statusCode}: $body');
      }

      final Stream<String> lines = streamed.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final String line in lines) {
        if (!line.startsWith('data:')) continue;
        final String dataStr = line.substring('data:'.length).trim();
        if (dataStr == '[DONE]' || dataStr.isEmpty) continue;

        Map<String, dynamic> data;
        try {
          data = Map<String, dynamic>.from(jsonDecode(dataStr));
        } catch (_) {
          continue;
        }

        final String? type = data['type'] as String?;

        if (type == 'content_block_delta') {
          final Map<String, dynamic> delta =
              Map<String, dynamic>.from(data['delta'] ?? {});
          if (delta.isNotEmpty && delta['type'] == 'text_delta') {
            final String text = (delta['text'] as String?) ?? '';
            if (text.isNotEmpty) yield text;
          }
        }
      }
    } finally {
      client.close();
    }
  }

  // ---------------------------------------------------------------------------
  // Single-turn (non-streaming)
  // ---------------------------------------------------------------------------

  static Future<String> sendTurnOnce({
    required String syllabus,
    required List<Map<String, dynamic>> messages,
    String? overrideModel,
    Map<String, dynamic> extraParams = const {},
    int maxTokens = 1024,
    bool withFilesApi = false,
  }) async {
    final http.Response res = await http.post(
      Uri.parse(_claudeApiUrl),
      headers: _headers(stream: false, withFilesApi: withFilesApi),
      body: jsonEncode({
        'model': overrideModel ?? model,
        'max_tokens': maxTokens,
        'stream': false,
        'system': [
          {
            'type': 'text',
            'text': syllabus,
            'cache_control': {'type': 'ephemeral'},
          }
        ],
        'messages': messages,
        'cache_control': {'type': 'ephemeral'},
        ...defaultParams,
        ...extraParams,
      }),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
          'Claude HTTP ${res.statusCode}: ${utf8.decode(res.bodyBytes)}');
    }

    final Map<String, dynamic> data =
        Map<String, dynamic>.from(jsonDecode(utf8.decode(res.bodyBytes)));
    return _extractText(data) ?? '';
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  static String? _extractText(Map<String, dynamic> data) {
    final List content = List.from(data['content'] ?? []);
    if (content.isEmpty) return null;
    for (final dynamic block in content) {
      if (block is Map && block['type'] == 'text') {
        return block['text'];
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // File upload helpers
  // ---------------------------------------------------------------------------

  static Future<String?> uploadFile(File file, String mimeType) async {
    final Uint8List bytes = await file.readAsBytes();
    return await uploadBytes(
      bytes: bytes,
      fileName: file.uri.pathSegments.last,
      mimeType: mimeType,
    );
  }

  static Future<Map<String, String>> uploadSupabaseFiles(
      List<SupabaseFile> files) async {
    final Map<String, String> result = {};

    await Future.wait(files.map((f) async {
      try {
        final http.Response fileResponse = await http.get(Uri.parse(f.url));
        final String? fileId = await uploadBytes(
          bytes: fileResponse.bodyBytes,
          fileName: f.fileName,
          mimeType: f.mimeType,
        );
        if (fileId != null) {
          result[f.fileName] = fileId; // { fileName → fileId }
        }
      } catch (e) {
        print('Failed to upload ${f.name}: $e');
      }
    }));

    return result;
  }

  static Future<String?> uploadBytes({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    final http.MultipartRequest request = http.MultipartRequest(
      'POST',
      Uri.parse(_claudeFileApiUrl),
    );
    request.headers.addAll({
      'x-api-key': apiKey,
      'anthropic-version': _anthropicVersion,
      'anthropic-beta': _anthropicFilesApiBeta,
    });
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: fileName,
      contentType: http.MediaType.parse(mimeType),
    ));

    final http.StreamedResponse response = await request.send();
    final Map<String, dynamic> body = Map<String, dynamic>.from(
        jsonDecode(await response.stream.bytesToString()));

    if (response.statusCode < 200 || response.statusCode >= 300) return null;
    return body['id'] as String?;
  }
}
