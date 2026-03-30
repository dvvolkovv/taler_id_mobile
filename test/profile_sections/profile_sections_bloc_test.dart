import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/features/profile_sections/domain/entities/profile_section_entity.dart';
import 'package:taler_id_mobile/features/profile_sections/domain/repositories/i_profile_sections_repository.dart';
import 'package:taler_id_mobile/features/profile_sections/presentation/bloc/profile_sections_bloc.dart';
import 'package:taler_id_mobile/features/profile_sections/presentation/bloc/profile_sections_event.dart';
import 'package:taler_id_mobile/features/profile_sections/presentation/bloc/profile_sections_state.dart';

class MockProfileSectionsRepository extends Mock
    implements IProfileSectionsRepository {}

final _section = ProfileSectionEntity(
  id: 'sec-1',
  userId: 'user-1',
  type: SectionType.skills,
  content: const SectionContent(items: ['Dart', 'Flutter'], freeText: 'Mobile dev'),
  visibility: SectionVisibility.public_,
  updatedAt: DateTime(2026, 1, 1),
);

final _sections = [
  _section,
  ProfileSectionEntity(
    id: 'sec-2',
    userId: 'user-1',
    type: SectionType.interests,
    content: const SectionContent(items: ['AI', 'Crypto']),
    visibility: SectionVisibility.contacts,
    updatedAt: DateTime(2026, 1, 2),
  ),
];

void main() {
  late MockProfileSectionsRepository repo;
  late ProfileSectionsBloc bloc;

  setUp(() {
    repo = MockProfileSectionsRepository();
    bloc = ProfileSectionsBloc(repo);
  });

  tearDown(() => bloc.close());

  setUpAll(() {
    registerFallbackValue(SectionType.skills);
    registerFallbackValue(const SectionContent(items: []));
    registerFallbackValue(SectionVisibility.public_);
  });

  // ── LoadMySections ──────────────────────────────────────────────────────

  group('LoadMySections', () {
    blocTest<ProfileSectionsBloc, ProfileSectionsState>(
      'emits [Loading, Loaded] on success',
      build: () {
        when(() => repo.getMySections()).thenAnswer((_) async => _sections);
        return bloc;
      },
      act: (b) => b.add(LoadMySections()),
      expect: () => [
        isA<ProfileSectionsLoading>(),
        isA<ProfileSectionsLoaded>()
            .having((s) => s.sections.length, 'count', 2)
            .having((s) => s.sections.first.type, 'first type', SectionType.skills),
      ],
    );

    blocTest<ProfileSectionsBloc, ProfileSectionsState>(
      'emits [Loading, Loaded] with empty list',
      build: () {
        when(() => repo.getMySections()).thenAnswer((_) async => []);
        return bloc;
      },
      act: (b) => b.add(LoadMySections()),
      expect: () => [
        isA<ProfileSectionsLoading>(),
        isA<ProfileSectionsLoaded>().having((s) => s.sections, 'sections', isEmpty),
      ],
    );

    blocTest<ProfileSectionsBloc, ProfileSectionsState>(
      'emits [Loading, Error] on failure',
      build: () {
        when(() => repo.getMySections()).thenThrow(Exception('Network error'));
        return bloc;
      },
      act: (b) => b.add(LoadMySections()),
      expect: () => [
        isA<ProfileSectionsLoading>(),
        isA<ProfileSectionsError>()
            .having((s) => s.message, 'message', contains('Network error')),
      ],
    );
  });

  // ── UpsertSection ───────────────────────────────────────────────────────

  group('UpsertSection', () {
    blocTest<ProfileSectionsBloc, ProfileSectionsState>(
      'upserts then reloads sections',
      build: () {
        when(() => repo.upsertSection(
              any(),
              any(),
              any(),
            )).thenAnswer((_) async => _section);
        when(() => repo.getMySections()).thenAnswer((_) async => _sections);
        return bloc;
      },
      act: (b) => b.add(UpsertSection(
        type: SectionType.skills,
        content: const SectionContent(items: ['Dart']),
        visibility: SectionVisibility.public_,
      )),
      // After upsert, bloc adds LoadMySections → Loading → Loaded
      expect: () => [
        isA<ProfileSectionsLoading>(),
        isA<ProfileSectionsLoaded>(),
      ],
      verify: (_) {
        verify(() => repo.upsertSection(
              SectionType.skills,
              const SectionContent(items: ['Dart']),
              SectionVisibility.public_,
            )).called(1);
        verify(() => repo.getMySections()).called(1);
      },
    );

    blocTest<ProfileSectionsBloc, ProfileSectionsState>(
      'emits [Error] when upsert fails',
      build: () {
        when(() => repo.upsertSection(any(), any(), any()))
            .thenThrow(Exception('Server error'));
        return bloc;
      },
      act: (b) => b.add(UpsertSection(
        type: SectionType.skills,
        content: const SectionContent(items: ['Dart']),
        visibility: SectionVisibility.public_,
      )),
      expect: () => [
        isA<ProfileSectionsError>()
            .having((s) => s.message, 'message', contains('Server error')),
      ],
    );
  });

  // ── DeleteSection ───────────────────────────────────────────────────────

  group('DeleteSection', () {
    blocTest<ProfileSectionsBloc, ProfileSectionsState>(
      'deletes then reloads sections',
      build: () {
        when(() => repo.deleteSection(any())).thenAnswer((_) async {});
        when(() => repo.getMySections()).thenAnswer((_) async => [_sections[1]]);
        return bloc;
      },
      act: (b) => b.add(DeleteSection(SectionType.skills)),
      expect: () => [
        isA<ProfileSectionsLoading>(),
        isA<ProfileSectionsLoaded>()
            .having((s) => s.sections.length, 'count', 1),
      ],
      verify: (_) {
        verify(() => repo.deleteSection(SectionType.skills)).called(1);
      },
    );

    blocTest<ProfileSectionsBloc, ProfileSectionsState>(
      'emits [Error] when delete fails',
      build: () {
        when(() => repo.deleteSection(any())).thenThrow(Exception('Forbidden'));
        return bloc;
      },
      act: (b) => b.add(DeleteSection(SectionType.skills)),
      expect: () => [
        isA<ProfileSectionsError>()
            .having((s) => s.message, 'message', contains('Forbidden')),
      ],
    );
  });

  // ── UpdateSectionVisibility ─────────────────────────────────────────────

  group('UpdateSectionVisibility', () {
    blocTest<ProfileSectionsBloc, ProfileSectionsState>(
      'updates visibility then reloads',
      build: () {
        when(() => repo.updateVisibility(any(), any())).thenAnswer((_) async {});
        when(() => repo.getMySections()).thenAnswer((_) async => _sections);
        return bloc;
      },
      act: (b) => b.add(UpdateSectionVisibility(
        type: SectionType.skills,
        visibility: SectionVisibility.private_,
      )),
      expect: () => [
        isA<ProfileSectionsLoading>(),
        isA<ProfileSectionsLoaded>(),
      ],
      verify: (_) {
        verify(() => repo.updateVisibility(
              SectionType.skills,
              SectionVisibility.private_,
            )).called(1);
      },
    );

    blocTest<ProfileSectionsBloc, ProfileSectionsState>(
      'emits [Error] when update visibility fails',
      build: () {
        when(() => repo.updateVisibility(any(), any()))
            .thenThrow(Exception('Not found'));
        return bloc;
      },
      act: (b) => b.add(UpdateSectionVisibility(
        type: SectionType.skills,
        visibility: SectionVisibility.private_,
      )),
      expect: () => [
        isA<ProfileSectionsError>(),
      ],
    );
  });

  // ── LoadUserSections ────────────────────────────────────────────────────

  group('LoadUserSections', () {
    blocTest<ProfileSectionsBloc, ProfileSectionsState>(
      'emits [Loading, Loaded] for another user',
      build: () {
        when(() => repo.getUserSections('user-2'))
            .thenAnswer((_) async => [_section]);
        return bloc;
      },
      act: (b) => b.add(LoadUserSections('user-2')),
      expect: () => [
        isA<ProfileSectionsLoading>(),
        isA<ProfileSectionsLoaded>()
            .having((s) => s.sections.length, 'count', 1),
      ],
    );

    blocTest<ProfileSectionsBloc, ProfileSectionsState>(
      'emits [Loading, Error] when user not found',
      build: () {
        when(() => repo.getUserSections(any()))
            .thenThrow(Exception('User not found'));
        return bloc;
      },
      act: (b) => b.add(LoadUserSections('unknown')),
      expect: () => [
        isA<ProfileSectionsLoading>(),
        isA<ProfileSectionsError>(),
      ],
    );
  });
}
