class Assignment {
  final String id;
  final String classroom;
  final String title;
  final String? instructions;
  final Map<String, String> fileIds;

  Assignment(
      {required this.id,
      required this.classroom,
      required this.title,
      this.instructions,
      this.fileIds = const {}});

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
        id: json['id'],
        title: json['title'],
        classroom: json['classroom'],
        instructions: json['instructions'],
        fileIds: Map<String, String>.from(json['file_ids'] ?? {}));
  }

  static List<Assignment> fromList(List<Map<String, dynamic>> list) {
    return list.map((m) => Assignment.fromJson(m)).toList();
  }

  @override
  bool operator ==(Object other) => other is Assignment && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
