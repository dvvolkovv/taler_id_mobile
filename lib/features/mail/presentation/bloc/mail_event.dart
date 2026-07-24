import 'package:equatable/equatable.dart';

abstract class MailEvent extends Equatable {
  const MailEvent();
  @override
  List<Object?> get props => [];
}

class MailInboxRequested extends MailEvent {
  const MailInboxRequested();
}

class MailLoadMoreRequested extends MailEvent {
  const MailLoadMoreRequested();
}

class MailMarkSeenRequested extends MailEvent {
  final int uid;
  final bool seen;
  const MailMarkSeenRequested({required this.uid, required this.seen});
  @override
  List<Object?> get props => [uid, seen];
}

class MailDeleteRequested extends MailEvent {
  final int uid;
  const MailDeleteRequested(this.uid);
  @override
  List<Object?> get props => [uid];
}

class MailFolderSelected extends MailEvent {
  final String path;
  const MailFolderSelected(this.path);
  @override
  List<Object?> get props => [path];
}

class MailMessageMoved extends MailEvent {
  final int uid;
  final String toFolder;
  const MailMessageMoved({required this.uid, required this.toFolder});
  @override
  List<Object?> get props => [uid, toFolder];
}

class MailFolderCreated extends MailEvent {
  final String name;
  const MailFolderCreated(this.name);
  @override
  List<Object?> get props => [name];
}

class MailFolderDeleted extends MailEvent {
  final String path;
  const MailFolderDeleted(this.path);
  @override
  List<Object?> get props => [path];
}
