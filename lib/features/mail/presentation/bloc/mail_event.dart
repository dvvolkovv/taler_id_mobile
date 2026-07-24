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
