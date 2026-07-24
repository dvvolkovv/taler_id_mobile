import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/api/api_exception.dart';
import 'package:taler_id_mobile/features/mail/domain/entities/mail_entities.dart';
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
        when(() => repo.getMessages(beforeUid: null))
            .thenAnswer((_) async => (items: [item(5), item(4)], nextCursor: 4));
        return build();
      },
      act: (b) => b.add(const MailInboxRequested()),
      expect: () => [
        isA<MailState>().having((s) => s.isLoading, 'loading', true),
        isA<MailState>()
            .having((s) => s.items.length, 'items', 2)
            .having((s) => s.nextCursor, 'cursor', 4)
            .having((s) => s.account?.address, 'address', 'me@talerid.io')
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
        when(() => repo.getMessages(beforeUid: null))
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
        when(() => repo.getMessages(beforeUid: 4))
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
        when(() => repo.setSeen(5, true)).thenAnswer((_) async {});
        return build();
      },
      seed: () => MailState(items: [item(5)]),
      act: (b) => b.add(const MailMarkSeenRequested(uid: 5, seen: true)),
      expect: () => [
        isA<MailState>().having((s) => s.items.first.seen, 'seen', true),
      ],
    );
  });

  group('MailDeleteRequested', () {
    blocTest<MailBloc, MailState>(
      'removes item from list',
      build: () {
        when(() => repo.deleteMessage(5)).thenAnswer((_) async {});
        return build();
      },
      seed: () => MailState(items: [item(5), item(4)]),
      act: (b) => b.add(const MailDeleteRequested(5)),
      expect: () => [
        isA<MailState>().having((s) => s.items.length, 'items', 1),
      ],
    );

    blocTest<MailBloc, MailState>(
      'repo.deleteMessage throws → item restored at original index, error set',
      build: () {
        when(() => repo.deleteMessage(4))
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
}
