enum Role { student, teacher, admin }

class Account {
  final String id;
  final String? name;
  final Set<String> classroomIds;
  final String? role;

  const Account(
      {required this.id, this.name, this.classroomIds = const {}, this.role});

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
        id: json['id'],
        name: json['name'],
        classroomIds: Set<String>.from(json['classrooms']),
        role: json['role']);
  }

  static Set<Account> fromList(List<Map<String, dynamic>> list) {
    return list.map((m) => Account.fromJson(m)).toSet();
  }

  @override
  bool operator ==(Object other) => other is Account && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
