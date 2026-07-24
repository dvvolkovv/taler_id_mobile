import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/api/api_exception.dart';
import 'package:taler_id_mobile/features/mail/domain/entities/mail_entities.dart';
import 'package:taler_id_mobile/features/mail/domain/entities/mail_folder_entity.dart';
import 'package:taler_id_mobile/features/mail/domain/repositories/i_mail_repository.dart';
import 'package:taler_id_mobile/features/mail/presentation/bloc/mail_bloc.dart';
import 'package:taler_id_mobile/features/mail/presentation/bloc/mail_event.dart';
import 'package:taler_id_mobile/features/mail/presentation/bloc/mail_state.dart';

class MockMailRepository extends Mock implements IMailRepository {}

MailListItemEntity item(int uid, {bool seen = false}) => MailListItemEntity(
      uid: uid,
      from: 'Test Sender',
      fromAddress: 'sender@talerid.io',
      subject: 'Subject $uid',
      date: DateTime(2026, 7, 24),
      seen: seen,
      snippet: 'snippet',
      hasAttachments: false,
    );

MailFolderEntity folderEntity(String path,
        {String role = 'custom', int unseen = 0}) =>
    MailFolderEntity(
        path: path, role: role, name: path, total: 10, unseen: unseen);

void main() {
  late MockMailRepository repo;

  setUp(() => repo = MockMailRepository());

  MailBloc build() => MailBloc(repo: repo);

  group('MailInboxRequested', () {
    blocTest<MailBloc, MailState>(
      'loads first page',
      build: () {
        when(() => repo.getAccount()).thenAnswer((_) async => MailAccountEntity(
            address: 'me@talerid.io',
            localpart: 'me',
            domain: 'talerid.io',
            status: 'ACTIVE'));
        when(() => repo.getMessages(beforeUid: null, folder: 'INBOX'))
            .thenAnswer((_) async => (items: [item(5), item(4)], nextCursor: 4));
        when(() => repo.getFolders()).thenAnswer((_) async => [
              folderEntity('INBOX', role: 'inbox', unseen: 3),
              folderEntity('Sent', role: 'sent'),
            ]);
        return build();
      },
      act: (b) => b.add(const MailInboxRequested()),
      expect: () => [
        isA<MailState>().having((s) => s.isLoading, 'loading', true),
        isA<MailState>()
            .having((s) => s.items.length, 'items', 2)
            .having((s) => s.nextCursor, 'cursor', 4)
            .having((s) => s.account?.address, 'address', 'me@talerid.io')
            .having((s) => s.folders.length, 'folders', 2)
            .having((s) => s.unread, 'unread', 3)
            .having((s) => s.isLoading, 'loading', false),
      ],
      verify: (_) =>
          verify(() => repo.getMessages(beforeUid: null, folder: 'INBOX'))
              .called(1),
    );

    blocTest<MailBloc, MailState>(
      'getFolders error is non-fatal — inbox still loads',
      build: () {
        when(() => repo.getAccount()).thenAnswer((_) async => MailAccountEntity(
            address: 'me@talerid.io',
            localpart: 'me',
            domain: 'talerid.io',
            status: 'ACTIVE'));
        when(() => repo.getMessages(beforeUid: null, folder: 'INBOX'))
            .thenAnswer((_) async => (items: [item(5)], nextCursor: null));
        when(() => repo.getFolders()).thenThrow(Exception('folders down'));
        return build();
      },
      act: (b) => b.add(const MailInboxRequested()),
      expect: () => [
        isA<MailState>().having((s) => s.isLoading, 'loading', true),
        isA<MailState>()
            .having((s) => s.items.length, 'items', 1)
            .having((s) => s.folders, 'folders', isEmpty)
            .having((s) => s.error, 'error', isNull)
            .having((s) => s.isLoading, 'loading', false),
      ],
    );

    blocTest<MailBloc, MailState>(
      'no account (ApiException 404) → noAccount=true, no error',
      build: () {
        when(() => repo.getAccount()).thenThrow(
            const ApiException(statusCode: 404, message: 'not found'));
        return build();
      },
      act: (b) => b.add(const MailInboxRequested()),
      expect: () => [
        isA<MailState>().having((s) => s.isLoading, 'loading', true),
        isA<MailState>()
            .having((s) => s.noAccount, 'noAccount', true)
            .having((s) => s.error, 'error', isNull)
            .having((s) => s.isLoading, 'loading', false),
      ],
    );

    blocTest<MailBloc, MailState>(
      'ApiException 500 → error set, noAccount=false',
      build: () {
        when(() => repo.getAccount()).thenThrow(
            const ApiException(statusCode: 500, message: 'server error'));
        return build();
      },
      act: (b) => b.add(const MailInboxRequested()),
      expect: () => [
        isA<MailState>().having((s) => s.isLoading, 'loading', true),
        isA<MailState>()
            .having((s) => s.error, 'error', isNotNull)
            .having((s) => s.noAccount, 'noAccount', false)
            .having((s) => s.isLoading, 'loading', false),
      ],
    );

    blocTest<MailBloc, MailState>(
      'messages error → error set',
      build: () {
        when(() => repo.getAccount()).thenAnswer((_) async => MailAccountEntity(
            address: 'me@talerid.io',
            localpart: 'me',
            domain: 'talerid.io',
            status: 'ACTIVE'));
        when(() => repo.getMessages(beforeUid: null, folder: 'INBOX'))
            .thenThrow(Exception('network'));
        return build();
      },
      act: (b) => b.add(const MailInboxRequested()),
      expect: () => [
        isA<MailState>().having((s) => s.isLoading, 'loading', true),
        isA<MailState>()
            .having((s) => s.error, 'error', isNotNull)
            .having((s) => s.isLoading, 'loading', false),
      ],
    );
  });

  group('MailLoadMoreRequested', () {
    blocTest<MailBloc, MailState>(
      'appends next page using nextCursor',
      build: () {
        when(() => repo.getMessages(beforeUid: 4, folder: 'INBOX'))
            .thenAnswer((_) async => (items: [item(3)], nextCursor: null));
        return build();
      },
      seed: () => MailState(items: [item(5), item(4)], nextCursor: 4),
      act: (b) => b.add(const MailLoadMoreRequested()),
      expect: () => [
        isA<MailState>().having((s) => s.isLoadingMore, 'more', true),
        isA<MailState>()
            .having((s) => s.items.length, 'items', 3)
            .having((s) => s.nextCursor, 'cursor', null),
      ],
      verify: (_) =>
          verify(() => repo.getMessages(beforeUid: 4, folder: 'INBOX'))
              .called(1),
    );

    blocTest<MailBloc, MailState>(
      'nextCursor == null → emits nothing',
      build: () => build(),
      seed: () => MailState(items: [item(5)], nextCursor: null),
      act: (b) => b.add(const MailLoadMoreRequested()),
      expect: () => <MailState>[],
    );

    blocTest<MailBloc, MailState>(
      'isLoadingMore == true (seed) → emits nothing',
      build: () => build(),
      seed: () => MailState(
          items: [item(5), item(4)], nextCursor: 4, isLoadingMore: true),
      act: (b) => b.add(const MailLoadMoreRequested()),
      expect: () => <MailState>[],
    );

    blocTest<MailBloc, MailState>(
      'isLoading == true (refresh in flight) → emits nothing',
      build: () => build(),
      seed: () => MailState(
          items: [item(5), item(4)], nextCursor: 4, isLoading: true),
      act: (b) => b.add(const MailLoadMoreRequested()),
      expect: () => <MailState>[],
    );
  });

  group('MailMarkSeenRequested', () {
    blocTest<MailBloc, MailState>(
      'optimistically flips seen flag',
      build: () {
        when(() => repo.setSeen(5, true, folder: 'INBOX'))
            .thenAnswer((_) async {});
        return build();
      },
      seed: () => MailState(items: [item(5)]),
      act: (b) => b.add(const MailMarkSeenRequested(uid: 5, seen: true)),
      expect: () => [
        isA<MailState>().having((s) => s.items.first.seen, 'seen', true),
      ],
      verify: (_) =>
          verify(() => repo.setSeen(5, true, folder: 'INBOX')).called(1),
    );
  });

  group('MailDeleteRequested', () {
    blocTest<MailBloc, MailState>(
      'removes item from list',
      build: () {
        when(() => repo.deleteMessage(5, folder: 'INBOX'))
            .thenAnswer((_) async {});
        return build();
      },
      seed: () => MailState(items: [item(5), item(4)]),
      act: (b) => b.add(const MailDeleteRequested(5)),
      expect: () => [
        isA<MailState>().having((s) => s.items.length, 'items', 1),
      ],
      verify: (_) =>
          verify(() => repo.deleteMessage(5, folder: 'INBOX')).called(1),
    );

    blocTest<MailBloc, MailState>(
      'repo.deleteMessage throws → item restored at original index, error set',
      build: () {
        when(() => repo.deleteMessage(4, folder: 'INBOX'))
            .thenThrow(Exception('delete failed'));
        return build();
      },
      seed: () => MailState(items: [item(5), item(4), item(3)]),
      act: (b) => b.add(const MailDeleteRequested(4)),
      expect: () => [
        // optimistic removal
        isA<MailState>()
            .having((s) => s.items.length, 'items', 2)
            .having((s) => s.items.map((i) => i.uid).toList(), 'uids',
                [5, 3]),
        // rollback: item(4) restored at index 1, error set
        isA<MailState>()
            .having((s) => s.items.length, 'items', 3)
            .having((s) => s.items[1].uid, 'restored uid', 4)
            .having((s) => s.error, 'error', isNotNull),
      ],
    );
  });

  group('MailFolderSelected', () {
    blocTest<MailBloc, MailState>(
      'switches currentFolder and reloads items with folder arg',
      build: () {
        when(() => repo.getMessages(beforeUid: null, folder: 'Sent'))
            .thenAnswer((_) async => (items: [item(7)], nextCursor: null));
        return build();
      },
      seed: () => MailState(items: [item(5), item(4)], nextCursor: 4),
      act: (b) => b.add(const MailFolderSelected('Sent')),
      expect: () => [
        isA<MailState>()
            .having((s) => s.currentFolder, 'currentFolder', 'Sent')
            .having((s) => s.items, 'items', isEmpty)
            .having((s) => s.nextCursor, 'cursor', null)
            .having((s) => s.isLoading, 'loading', true),
        isA<MailState>()
            .having((s) => s.currentFolder, 'currentFolder', 'Sent')
            .having((s) => s.items.length, 'items', 1)
            .having((s) => s.items.first.uid, 'uid', 7)
            .having((s) => s.isLoading, 'loading', false),
      ],
      verify: (_) =>
          verify(() => repo.getMessages(beforeUid: null, folder: 'Sent'))
              .called(1),
    );

    blocTest<MailBloc, MailState>(
      'load error in selected folder → error set',
      build: () {
        when(() => repo.getMessages(beforeUid: null, folder: 'Junk'))
            .thenThrow(Exception('network'));
        return build();
      },
      act: (b) => b.add(const MailFolderSelected('Junk')),
      expect: () => [
        isA<MailState>().having((s) => s.isLoading, 'loading', true),
        isA<MailState>()
            .having((s) => s.error, 'error', isNotNull)
            .having((s) => s.isLoading, 'loading', false),
      ],
    );
  });

  group('MailMessageMoved', () {
    blocTest<MailBloc, MailState>(
      'removes moved message from items',
      build: () {
        when(() => repo.moveMessage(5,
            fromFolder: 'INBOX', toFolder: 'Archive')).thenAnswer((_) async {});
        return build();
      },
      seed: () => MailState(items: [item(5), item(4)]),
      act: (b) => b.add(const MailMessageMoved(uid: 5, toFolder: 'Archive')),
      expect: () => [
        isA<MailState>()
            .having((s) => s.items.length, 'items', 1)
            .having((s) => s.items.first.uid, 'uid', 4),
      ],
      verify: (_) => verify(() =>
              repo.moveMessage(5, fromFolder: 'INBOX', toFolder: 'Archive'))
          .called(1),
    );

    blocTest<MailBloc, MailState>(
      'move fails → item restored, error set',
      build: () {
        when(() => repo.moveMessage(4,
                fromFolder: 'INBOX', toFolder: 'Archive'))
            .thenThrow(Exception('move failed'));
        return build();
      },
      seed: () => MailState(items: [item(5), item(4), item(3)]),
      act: (b) => b.add(const MailMessageMoved(uid: 4, toFolder: 'Archive')),
      expect: () => [
        isA<MailState>().having((s) => s.items.length, 'items', 2),
        isA<MailState>()
            .having((s) => s.items.length, 'items', 3)
            .having((s) => s.items[1].uid, 'restored uid', 4)
            .having((s) => s.error, 'error', isNotNull),
      ],
    );
  });

  group('MailFolderCreated / MailFolderDeleted', () {
    blocTest<MailBloc, MailState>(
      'create folder → refreshes folders list',
      build: () {
        when(() => repo.createFolder('Archive')).thenAnswer((_) async {});
        when(() => repo.getFolders()).thenAnswer((_) async => [
              folderEntity('INBOX', role: 'inbox', unseen: 1),
              folderEntity('Archive'),
            ]);
        return build();
      },
      act: (b) => b.add(const MailFolderCreated('Archive')),
      expect: () => [
        isA<MailState>()
            .having((s) => s.folders.length, 'folders', 2)
            .having((s) => s.unread, 'unread', 1),
      ],
      verify: (_) => verify(() => repo.createFolder('Archive')).called(1),
    );

    blocTest<MailBloc, MailState>(
      'delete folder → refreshes folders list',
      build: () {
        when(() => repo.deleteFolder('Archive')).thenAnswer((_) async {});
        when(() => repo.getFolders()).thenAnswer(
            (_) async => [folderEntity('INBOX', role: 'inbox', unseen: 2)]);
        return build();
      },
      seed: () => MailState(
          folders: [
            folderEntity('INBOX', role: 'inbox', unseen: 2),
            folderEntity('Archive'),
          ]),
      act: (b) => b.add(const MailFolderDeleted('Archive')),
      expect: () => [
        isA<MailState>()
            .having((s) => s.folders.length, 'folders', 1)
            .having((s) => s.unread, 'unread', 2),
      ],
      verify: (_) => verify(() => repo.deleteFolder('Archive')).called(1),
    );
  });
}
