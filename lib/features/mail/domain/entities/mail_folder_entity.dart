import 'package:equatable/equatable.dart';

class MailFolderEntity extends Equatable {
  final String path;
  final String role; // inbox|sent|drafts|junk|trash|custom
  final String name;
  final int total;
  final int unseen;

  const MailFolderEntity({
    required this.path,
    required this.role,
    required this.name,
    required this.total,
    required this.unseen,
  });

  factory MailFolderEntity.fromJson(Map<String, dynamic> json) =>
      MailFolderEntity(
        path: json['path'] as String,
        role: json['role'] as String? ?? 'custom',
        name: json['name'] as String? ?? (json['path'] as String),
        total: (json['total'] as num?)?.toInt() ?? 0,
        unseen: (json['unseen'] as num?)?.toInt() ?? 0,
      );

  @override
  List<Object?> get props => [path, role, name, total, unseen];
}
