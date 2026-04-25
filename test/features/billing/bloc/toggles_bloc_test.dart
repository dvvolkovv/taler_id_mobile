import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/api/api_exception.dart';
import 'package:taler_id_mobile/features/billing/domain/entities/feature_toggle_entity.dart';
import 'package:taler_id_mobile/features/billing/domain/repositories/billing_repository.dart';
import 'package:taler_id_mobile/features/billing/presentation/bloc/toggles_bloc.dart';
import 'package:taler_id_mobile/features/billing/presentation/bloc/toggles_event.dart';
import 'package:taler_id_mobile/features/billing/presentation/bloc/toggles_state.dart';

class MockBillingRepository extends Mock implements BillingRepository {}

const _sixToggles = [
  FeatureToggleEntity(featureKey: 'ai.voice', enabled: true),
  FeatureToggleEntity(featureKey: 'ai.outbound', enabled: false),
  FeatureToggleEntity(featureKey: 'ai.twin', enabled: true),
  FeatureToggleEntity(featureKey: 'ai.transcribe', enabled: false),
  FeatureToggleEntity(featureKey: 'ai.summarize', enabled: false),
  FeatureToggleEntity(featureKey: 'ai.web_search', enabled: true),
];

void main() {
  late MockBillingRepository repo;
  late TogglesBloc bloc;

  setUp(() {
    repo = MockBillingRepository();
    bloc = TogglesBloc(repo: repo);
  });

  tearDown(() => bloc.close());

  group('LoadToggles', () {
    blocTest<TogglesBloc, TogglesState>(
      'emits [Loading, Loaded] with 6 toggles',
      build: () {
        when(() => repo.getToggles()).thenAnswer((_) async => _sixToggles);
        return bloc;
      },
      act: (b) => b.add(LoadToggles()),
      expect: () => [
        isA<TogglesLoading>(),
        isA<TogglesLoaded>().having((s) => s.toggles.length, 'count', 6),
      ],
      verify: (_) => verify(() => repo.getToggles()).called(1),
    );

    blocTest<TogglesBloc, TogglesState>(
      'emits [Loading, Error] on ApiException',
      build: () {
        when(() => repo.getToggles()).thenThrow(
          const ApiException(statusCode: 500, message: 'fail'),
        );
        return bloc;
      },
      act: (b) => b.add(LoadToggles()),
      expect: () => [
        isA<TogglesLoading>(),
        isA<TogglesError>().having((s) => s.message, 'message', 'fail'),
      ],
    );

    blocTest<TogglesBloc, TogglesState>(
      'emits failedToLoadToggles key on unknown error',
      build: () {
        when(() => repo.getToggles()).thenThrow(Exception('x'));
        return bloc;
      },
      act: (b) => b.add(LoadToggles()),
      expect: () => [
        isA<TogglesLoading>(),
        isA<TogglesError>().having(
          (s) => s.message,
          'message',
          'error.failedToLoadToggles',
        ),
      ],
    );
  });

  group('ToggleFeature (optimistic)', () {
    blocTest<TogglesBloc, TogglesState>(
      'optimistically flips the value immediately on success',
      build: () {
        when(() => repo.setToggle('ai.outbound', true)).thenAnswer(
          (_) async => const FeatureToggleEntity(
            featureKey: 'ai.outbound',
            enabled: true,
          ),
        );
        return bloc;
      },
      seed: () => TogglesLoaded(_sixToggles),
      act: (b) => b.add(ToggleFeature(featureKey: 'ai.outbound', enabled: true)),
      expect: () => [
        isA<TogglesLoaded>()
            .having(
              (s) => s.toggles.firstWhere((t) => t.featureKey == 'ai.outbound').enabled,
              'ai.outbound enabled',
              true,
            )
            .having(
              // Other toggles remain unchanged.
              (s) => s.toggles.firstWhere((t) => t.featureKey == 'ai.voice').enabled,
              'ai.voice unchanged',
              true,
            )
            .having((s) => s.toggles.length, 'count', 6),
      ],
      verify: (_) =>
          verify(() => repo.setToggle('ai.outbound', true)).called(1),
    );

    blocTest<TogglesBloc, TogglesState>(
      'rolls back + emits error when setToggle throws ApiException',
      build: () {
        when(() => repo.setToggle('ai.twin', false)).thenThrow(
          const ApiException(statusCode: 500, message: 'Server error'),
        );
        return bloc;
      },
      seed: () => TogglesLoaded(_sixToggles),
      act: (b) => b.add(ToggleFeature(featureKey: 'ai.twin', enabled: false)),
      expect: () => [
        // Optimistic: ai.twin flipped to false.
        isA<TogglesLoaded>().having(
          (s) => s.toggles.firstWhere((t) => t.featureKey == 'ai.twin').enabled,
          'optimistic ai.twin',
          false,
        ),
        // Rollback: back to original (enabled=true).
        isA<TogglesLoaded>().having(
          (s) => s.toggles.firstWhere((t) => t.featureKey == 'ai.twin').enabled,
          'rollback ai.twin',
          true,
        ),
        isA<TogglesError>()
            .having((s) => s.message, 'message', 'Server error'),
        // Re-emit stable loaded so UI can function.
        isA<TogglesLoaded>().having(
          (s) => s.toggles.firstWhere((t) => t.featureKey == 'ai.twin').enabled,
          'final ai.twin',
          true,
        ),
      ],
    );

    blocTest<TogglesBloc, TogglesState>(
      'rolls back with failedToSaveToggle on unknown error',
      build: () {
        when(() => repo.setToggle('ai.voice', false))
            .thenThrow(Exception('boom'));
        return bloc;
      },
      seed: () => TogglesLoaded(_sixToggles),
      act: (b) => b.add(ToggleFeature(featureKey: 'ai.voice', enabled: false)),
      expect: () => [
        isA<TogglesLoaded>().having(
          (s) => s.toggles.firstWhere((t) => t.featureKey == 'ai.voice').enabled,
          'optimistic',
          false,
        ),
        isA<TogglesLoaded>().having(
          (s) => s.toggles.firstWhere((t) => t.featureKey == 'ai.voice').enabled,
          'rollback',
          true,
        ),
        isA<TogglesError>().having(
          (s) => s.message,
          'message',
          'error.failedToSaveToggle',
        ),
        isA<TogglesLoaded>(),
      ],
    );

    blocTest<TogglesBloc, TogglesState>(
      'ignores toggle when not in Loaded state',
      build: () {
        when(() => repo.setToggle(any(), any())).thenAnswer(
          (_) async =>
              const FeatureToggleEntity(featureKey: 'ai.voice', enabled: true),
        );
        return bloc;
      },
      // No seed: state is TogglesInitial.
      act: (b) => b.add(ToggleFeature(featureKey: 'ai.voice', enabled: true)),
      expect: () => const <TogglesState>[],
      verify: (_) => verifyNever(() => repo.setToggle(any(), any())),
    );
  });
}
