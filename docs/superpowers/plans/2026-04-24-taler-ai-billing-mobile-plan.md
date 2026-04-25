# Taler AI Billing — Mobile UI Implementation Plan (Plan 2)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Flutter mobile UI for TAL-token AI billing. Surface balance, wallet, 3 packages, per-feature toggles, paywall on HTTP 402, and live balance updates from Socket.io. Integrate with existing voice assistant (billingSessionId + heartbeat + close).

**Architecture:** New Clean Architecture feature module `lib/features/billing/` (data/domain/presentation) following existing project patterns. Global Dio interceptor maps HTTP 402 to a bottom-sheet paywall. Socket.io events (`billing_balance_changed`, `ai_session_terminated`, `billing_low_balance_warning`) handled via existing `MessengerSocketService`.

**Tech Stack:** Flutter 3.x, BLoC (flutter_bloc), GetIt (DI), Freezed (entities), Dio (HTTP), existing Socket.io client. Dart ≥3.6.

**Branch:** `feat/billing-ui` off `dev`. Worktree at `.worktrees/billing-ui`. Will merge into `dev` only after testing on emulator + iPhone.

**Backend contract:** shipped on DEV in Plan 1. Endpoints under `/billing/*` and `/metering/*` documented in `/Users/dmitry/Downloads/taler_id/docs/superpowers/specs/2026-04-24-taler-ai-billing-design.md` §6 + §7.

---

## File Structure

### New files (`lib/features/billing/`)

```
billing/
├── data/
│   ├── datasources/
│   │   └── billing_remote_datasource.dart     # Dio-based REST calls
│   └── repositories/
│       └── billing_repository_impl.dart        # Implements domain interface
├── domain/
│   ├── entities/
│   │   ├── billing_package.dart                # Freezed: 3 packages
│   │   ├── billing_transaction.dart            # Freezed: tx record
│   │   ├── feature_toggle.dart                 # Freezed: { featureKey, enabled }
│   │   ├── pricebook_item.dart                 # Freezed: pricebook row
│   │   └── wallet_balance.dart                 # Freezed: { balancePlanck, balanceMicroTal, custodialAddress? }
│   └── repositories/
│       └── billing_repository.dart             # Abstract interface
└── presentation/
    ├── bloc/
    │   ├── balance_bloc.dart                   # Loads balance + listens to billing_balance_changed
    │   ├── packages_bloc.dart                  # Loads 3 packages, handles purchase
    │   ├── toggles_bloc.dart                   # Loads + PATCH feature toggles
    │   └── transactions_bloc.dart              # Paginated tx history
    ├── screens/
    │   ├── wallet_screen.dart                  # Balance + 3 packages + recent tx
    │   ├── purchase_screen.dart                # 3-card package picker with CTA
    │   ├── transactions_screen.dart            # Full history
    │   ├── pricebook_screen.dart               # Feature prices for reference
    │   └── ai_toggles_screen.dart              # 6 toggle switches
    └── widgets/
        ├── balance_chip.dart                   # AppBar chip: "X μTAL"
        ├── insufficient_funds_sheet.dart       # 402 paywall bottom sheet
        └── low_balance_banner.dart             # Warning banner during active AI session
```

### Existing files modified

| File | Change |
|---|---|
| `lib/core/api/dio_client.dart` | Add `BillingPaywallInterceptor` — on 402, show `InsufficientFundsSheet` via global navigator key |
| `lib/core/api/billing_paywall_interceptor.dart` | **New** — the interceptor class |
| `lib/core/di/service_locator.dart` | Register `BillingRepository`, `BalanceBloc`, `TogglesBloc`, etc. |
| `lib/core/router/app_router.dart` | Add routes for 5 new screens |
| `lib/features/settings/presentation/screens/settings_screen.dart` | Add "Кошелёк и баланс" + "AI-функции" menu items |
| `lib/features/dashboard/presentation/screens/dashboard_screen.dart` (or main scaffold) | Add `BalanceChip` to AppBar |
| `lib/features/voice/data/datasources/voice_remote_datasource.dart` | Receive `billingSessionId` from `/voice/session`; add `/voice/session/:sessionId/close` call |
| `lib/features/voice/presentation/bloc/voice_bloc.dart` (or equivalent) | Start heartbeat timer; stop on hangup |
| `lib/features/voice/presentation/screens/voice_call_screen.dart` | Listen for `ai_session_terminated` → close WebRTC |
| `lib/features/profile/presentation/screens/ai_twin_screen.dart` | Migrate `aiTwinEnabled` save to new `/billing/settings/toggles/ai_twin` endpoint |
| `lib/features/assistant/…` | Add OpenAI Realtime tools: `get_balance`, `get_packages`, `list_recent_transactions`, `toggle_feature` |
| `lib/l10n/app_ru.arb` + `app_en.arb` | All new strings with `billing_` prefix |
| `lib/core/services/messenger_socket_service.dart` (or wherever Socket.io client lives) | Listen for `billing_balance_changed`, `ai_session_terminated`, `billing_low_balance_warning` |

### Tests to add

| File | Covers |
|---|---|
| `test/features/billing/bloc/balance_bloc_test.dart` | Initial load, socket update, error state |
| `test/features/billing/bloc/toggles_bloc_test.dart` | Load, patch success/failure, 6 features default |
| `test/features/billing/bloc/packages_bloc_test.dart` | Load, purchase success/failure |
| `test/features/billing/widgets/insufficient_funds_sheet_test.dart` | Shows required/available amounts, CTA tap |
| `test/features/billing/widgets/balance_chip_test.dart` | Rebuilds on balance change event |

---

## Task Overview

| Task | Part | Description |
|---|---|---|
| 1 | A — Foundation | Freezed domain entities + repository interface |
| 2 | B — Data | Remote datasource (Dio) + repository impl |
| 3 | C — BLoC | 4 BLoCs (balance, packages, toggles, transactions) with tests |
| 4 | D — Widgets | `balance_chip`, `insufficient_funds_sheet`, `low_balance_banner` + widget tests |
| 5 | E — Screens 1 | `wallet_screen` + `purchase_screen` |
| 6 | E — Screens 2 | `transactions_screen` + `pricebook_screen` + `ai_toggles_screen` |
| 7 | F — Interceptor | `BillingPaywallInterceptor` on DioClient |
| 8 | F — Socket | Live balance + session events via existing Socket.io client |
| 9 | G — Integration | Settings menu items + Dashboard AppBar chip + routing + ai_twin_screen migration |
| 10 | H — Voice | `/voice/session` return shape + heartbeat + close endpoint |
| 11 | I — Assistant tools | 4 OpenAI Realtime tools for voice control |
| 12 | J — l10n + final test | Translate ru/en + run flutter test + emulator smoke |

**Total: 12 tasks** (less than Plan 1's 19 because no migrations/blockchain/agents).

---

## Part A — Foundation

### Task 1: Domain entities + repository interface

**Files:**
- Create: `lib/features/billing/domain/entities/wallet_balance.dart`
- Create: `lib/features/billing/domain/entities/billing_package.dart`
- Create: `lib/features/billing/domain/entities/billing_transaction.dart`
- Create: `lib/features/billing/domain/entities/pricebook_item.dart`
- Create: `lib/features/billing/domain/entities/feature_toggle.dart`
- Create: `lib/features/billing/domain/repositories/billing_repository.dart`

- [ ] **Step 1: WalletBalance entity**

```dart
// lib/features/billing/domain/entities/wallet_balance.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'wallet_balance.freezed.dart';
part 'wallet_balance.g.dart';

@freezed
class WalletBalance with _$WalletBalance {
  const factory WalletBalance({
    required String balancePlanck,      // big-int as string
    required String balanceMicroTal,    // "X.XX"
    String? custodialAddress,
    @Default(<BillingTransaction>[]) List<BillingTransaction> recentTx,
  }) = _WalletBalance;

  factory WalletBalance.fromJson(Map<String, dynamic> json) =>
      _$WalletBalanceFromJson(json);
}
```

- [ ] **Step 2: BillingPackage entity**

```dart
// lib/features/billing/domain/entities/billing_package.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'billing_package.freezed.dart';
part 'billing_package.g.dart';

@freezed
class BillingPackage with _$BillingPackage {
  const factory BillingPackage({
    required String id,                 // 'starter' | 'pro' | 'business'
    required String amountPlanck,
    required int priceEurCents,
    required Map<String, String> label,
    required Map<String, List<String>> highlights,
  }) = _BillingPackage;

  factory BillingPackage.fromJson(Map<String, dynamic> json) =>
      _$BillingPackageFromJson(json);
}
```

- [ ] **Step 3: BillingTransaction entity**

```dart
// lib/features/billing/domain/entities/billing_transaction.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'billing_transaction.freezed.dart';
part 'billing_transaction.g.dart';

@freezed
class BillingTransaction with _$BillingTransaction {
  const factory BillingTransaction({
    required String id,
    required String type,               // TOPUP_STUB | SPEND | REFUND | ...
    required String amountPlanck,
    String? featureKey,
    String? sessionId,
    required String createdAt,          // ISO 8601
    @Default('COMPLETED') String status,
    Map<String, dynamic>? metadata,
  }) = _BillingTransaction;

  factory BillingTransaction.fromJson(Map<String, dynamic> json) =>
      _$BillingTransactionFromJson(json);
}
```

- [ ] **Step 4: PricebookItem entity**

```dart
// lib/features/billing/domain/entities/pricebook_item.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'pricebook_item.freezed.dart';
part 'pricebook_item.g.dart';

@freezed
class PricebookItem with _$PricebookItem {
  const factory PricebookItem({
    required String featureKey,
    required String unit,
    required String costUsdPerUnit,
    required String markupMultiplier,
    required String minReservePlanck,
  }) = _PricebookItem;

  factory PricebookItem.fromJson(Map<String, dynamic> json) =>
      _$PricebookItemFromJson(json);
}
```

- [ ] **Step 5: FeatureToggle entity**

```dart
// lib/features/billing/domain/entities/feature_toggle.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'feature_toggle.freezed.dart';
part 'feature_toggle.g.dart';

@freezed
class FeatureToggle with _$FeatureToggle {
  const factory FeatureToggle({
    required String featureKey,
    required bool enabled,
  }) = _FeatureToggle;

  factory FeatureToggle.fromJson(Map<String, dynamic> json) =>
      _$FeatureToggleFromJson(json);
}
```

- [ ] **Step 6: BillingRepository interface**

```dart
// lib/features/billing/domain/repositories/billing_repository.dart
import '../entities/wallet_balance.dart';
import '../entities/billing_package.dart';
import '../entities/billing_transaction.dart';
import '../entities/pricebook_item.dart';
import '../entities/feature_toggle.dart';

abstract class BillingRepository {
  Future<WalletBalance> getBalance();
  Future<List<BillingPackage>> getPackages();
  Future<WalletBalance> purchase(String packageId);
  Future<String> getWalletAddress();
  Future<List<BillingTransaction>> getTransactions();
  Future<List<PricebookItem>> getPricebook();
  Future<List<FeatureToggle>> getToggles();
  Future<FeatureToggle> setToggle(String featureKey, bool enabled);
}
```

- [ ] **Step 7: Run build_runner**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile/.worktrees/billing-ui
flutter pub run build_runner build --delete-conflicting-outputs 2>&1 | tail -10
```
Expected: 5 `.freezed.dart` + 5 `.g.dart` files generated. If `build_runner` isn't in `pubspec.yaml` dev_dependencies, install it first.

- [ ] **Step 8: Type-check**

```bash
flutter analyze lib/features/billing/ 2>&1 | tail -10
```
Expected: no errors.

- [ ] **Step 9: Commit**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile/.worktrees/billing-ui
git add lib/features/billing/domain/
git commit -m "feat(billing): domain entities + repository interface"
```

---

## Part B — Data Layer

### Task 2: Remote datasource + repository implementation

**Files:**
- Create: `lib/features/billing/data/datasources/billing_remote_datasource.dart`
- Create: `lib/features/billing/data/repositories/billing_repository_impl.dart`

- [ ] **Step 1: Write the datasource**

```dart
// lib/features/billing/data/datasources/billing_remote_datasource.dart
import 'package:dio/dio.dart';
import '../../domain/entities/wallet_balance.dart';
import '../../domain/entities/billing_package.dart';
import '../../domain/entities/billing_transaction.dart';
import '../../domain/entities/pricebook_item.dart';
import '../../domain/entities/feature_toggle.dart';

class BillingRemoteDatasource {
  final Dio _dio;
  BillingRemoteDatasource(this._dio);

  Future<WalletBalance> getBalance() async {
    final r = await _dio.get('/billing/balance');
    return WalletBalance.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<BillingPackage>> getPackages() async {
    final r = await _dio.get('/billing/packages');
    return (r.data as List).map((p) => BillingPackage.fromJson(p as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> purchase(String packageId) async {
    final r = await _dio.post('/billing/purchase/$packageId');
    return r.data as Map<String, dynamic>;
  }

  Future<String> getWalletAddress() async {
    final r = await _dio.get('/billing/wallet');
    return (r.data as Map<String, dynamic>)['custodialAddress'] as String;
  }

  Future<List<BillingTransaction>> getTransactions() async {
    final r = await _dio.get('/billing/transactions');
    return (r.data as List).map((t) => BillingTransaction.fromJson(t as Map<String, dynamic>)).toList();
  }

  Future<List<PricebookItem>> getPricebook() async {
    final r = await _dio.get('/billing/pricebook');
    return (r.data as List).map((p) => PricebookItem.fromJson(p as Map<String, dynamic>)).toList();
  }

  Future<List<FeatureToggle>> getToggles() async {
    final r = await _dio.get('/billing/settings/toggles');
    return (r.data as List).map((t) => FeatureToggle.fromJson(t as Map<String, dynamic>)).toList();
  }

  Future<FeatureToggle> setToggle(String featureKey, bool enabled) async {
    final r = await _dio.patch('/billing/settings/toggles/$featureKey', data: {'enabled': enabled});
    return FeatureToggle.fromJson(r.data as Map<String, dynamic>);
  }
}
```

- [ ] **Step 2: Write the repository implementation**

```dart
// lib/features/billing/data/repositories/billing_repository_impl.dart
import '../../domain/entities/wallet_balance.dart';
import '../../domain/entities/billing_package.dart';
import '../../domain/entities/billing_transaction.dart';
import '../../domain/entities/pricebook_item.dart';
import '../../domain/entities/feature_toggle.dart';
import '../../domain/repositories/billing_repository.dart';
import '../datasources/billing_remote_datasource.dart';

class BillingRepositoryImpl implements BillingRepository {
  final BillingRemoteDatasource _remote;
  BillingRepositoryImpl(this._remote);

  @override
  Future<WalletBalance> getBalance() => _remote.getBalance();

  @override
  Future<List<BillingPackage>> getPackages() => _remote.getPackages();

  @override
  Future<WalletBalance> purchase(String packageId) async {
    await _remote.purchase(packageId);
    return _remote.getBalance();
  }

  @override
  Future<String> getWalletAddress() => _remote.getWalletAddress();

  @override
  Future<List<BillingTransaction>> getTransactions() => _remote.getTransactions();

  @override
  Future<List<PricebookItem>> getPricebook() => _remote.getPricebook();

  @override
  Future<List<FeatureToggle>> getToggles() => _remote.getToggles();

  @override
  Future<FeatureToggle> setToggle(String featureKey, bool enabled) =>
      _remote.setToggle(featureKey, enabled);
}
```

- [ ] **Step 3: Register in service_locator**

Open `lib/core/di/service_locator.dart`. Near other repository registrations, add:

```dart
// Billing
import '../../features/billing/data/datasources/billing_remote_datasource.dart';
import '../../features/billing/data/repositories/billing_repository_impl.dart';
import '../../features/billing/domain/repositories/billing_repository.dart';

// Inside setupDependencies(), with other datasources:
sl.registerLazySingleton<BillingRemoteDatasource>(
  () => BillingRemoteDatasource(sl<Dio>()),
);

// With other repositories:
sl.registerLazySingleton<BillingRepository>(
  () => BillingRepositoryImpl(sl<BillingRemoteDatasource>()),
);
```

Match the exact style of existing registrations (section header comments, order, lazy vs eager).

- [ ] **Step 4: Analyze + commit**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile/.worktrees/billing-ui
flutter analyze lib/features/billing/ lib/core/di/ 2>&1 | tail -5
git add lib/features/billing/data/ lib/core/di/
git commit -m "feat(billing): remote datasource + repository impl + DI registration"
```

---

## Part C — BLoC Layer

### Task 3: 4 BLoCs with unit tests

**Files:**
- Create: `lib/features/billing/presentation/bloc/balance_bloc.dart`
- Create: `lib/features/billing/presentation/bloc/packages_bloc.dart`
- Create: `lib/features/billing/presentation/bloc/toggles_bloc.dart`
- Create: `lib/features/billing/presentation/bloc/transactions_bloc.dart`
- Create: `test/features/billing/bloc/balance_bloc_test.dart`
- Create: `test/features/billing/bloc/toggles_bloc_test.dart`
- Create: `test/features/billing/bloc/packages_bloc_test.dart`

TDD: write 1 failing test per BLoC first, then impl, then more tests.

- [ ] **Step 1: BalanceBloc + event/state**

```dart
// lib/features/billing/presentation/bloc/balance_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/wallet_balance.dart';
import '../../domain/repositories/billing_repository.dart';

sealed class BalanceEvent {}
class LoadBalance extends BalanceEvent {}
class BalanceChangedExternally extends BalanceEvent {
  final String balancePlanck;
  BalanceChangedExternally(this.balancePlanck);
}

sealed class BalanceState {}
class BalanceInitial extends BalanceState {}
class BalanceLoading extends BalanceState {}
class BalanceLoaded extends BalanceState {
  final WalletBalance balance;
  BalanceLoaded(this.balance);
}
class BalanceError extends BalanceState {
  final String message;
  BalanceError(this.message);
}

class BalanceBloc extends Bloc<BalanceEvent, BalanceState> {
  final BillingRepository _repo;

  BalanceBloc(this._repo) : super(BalanceInitial()) {
    on<LoadBalance>(_onLoad);
    on<BalanceChangedExternally>(_onChanged);
  }

  Future<void> _onLoad(LoadBalance e, Emitter<BalanceState> emit) async {
    emit(BalanceLoading());
    try {
      final b = await _repo.getBalance();
      emit(BalanceLoaded(b));
    } catch (err) {
      emit(BalanceError(err.toString()));
    }
  }

  Future<void> _onChanged(BalanceChangedExternally e, Emitter<BalanceState> emit) async {
    // Socket event: reload balance from backend (source of truth).
    try {
      final b = await _repo.getBalance();
      emit(BalanceLoaded(b));
    } catch (_) {
      // Keep existing state on transient errors
    }
  }
}
```

- [ ] **Step 2: BalanceBloc test**

```dart
// test/features/billing/bloc/balance_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/features/billing/domain/entities/wallet_balance.dart';
import 'package:taler_id_mobile/features/billing/domain/repositories/billing_repository.dart';
import 'package:taler_id_mobile/features/billing/presentation/bloc/balance_bloc.dart';

class MockBillingRepo extends Mock implements BillingRepository {}

void main() {
  late BillingRepository repo;
  const balance = WalletBalance(
    balancePlanck: '430000000',
    balanceMicroTal: '430.00',
  );

  setUp(() { repo = MockBillingRepo(); });

  blocTest<BalanceBloc, BalanceState>(
    'emits Loading then Loaded on LoadBalance success',
    build: () {
      when(() => repo.getBalance()).thenAnswer((_) async => balance);
      return BalanceBloc(repo);
    },
    act: (b) => b.add(LoadBalance()),
    expect: () => [isA<BalanceLoading>(), isA<BalanceLoaded>().having((s) => s.balance, 'balance', balance)],
  );

  blocTest<BalanceBloc, BalanceState>(
    'emits Error on LoadBalance failure',
    build: () {
      when(() => repo.getBalance()).thenThrow(Exception('network'));
      return BalanceBloc(repo);
    },
    act: (b) => b.add(LoadBalance()),
    expect: () => [isA<BalanceLoading>(), isA<BalanceError>()],
  );

  blocTest<BalanceBloc, BalanceState>(
    'BalanceChangedExternally refetches and emits new Loaded',
    build: () {
      when(() => repo.getBalance()).thenAnswer((_) async => balance);
      return BalanceBloc(repo);
    },
    act: (b) => b.add(BalanceChangedExternally('500000000')),
    expect: () => [isA<BalanceLoaded>()],
  );
}
```

If `bloc_test` + `mocktail` aren't in `dev_dependencies`, add them:
```bash
flutter pub add --dev bloc_test mocktail
```

- [ ] **Step 3: Run test — expect PASS (impl already written)**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile/.worktrees/billing-ui
flutter test test/features/billing/bloc/balance_bloc_test.dart 2>&1 | tail -10
```

- [ ] **Step 4: TogglesBloc + test**

```dart
// lib/features/billing/presentation/bloc/toggles_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/feature_toggle.dart';
import '../../domain/repositories/billing_repository.dart';

sealed class TogglesEvent {}
class LoadToggles extends TogglesEvent {}
class ToggleFeature extends TogglesEvent {
  final String featureKey;
  final bool enabled;
  ToggleFeature(this.featureKey, this.enabled);
}

sealed class TogglesState {}
class TogglesInitial extends TogglesState {}
class TogglesLoading extends TogglesState {}
class TogglesLoaded extends TogglesState {
  final List<FeatureToggle> toggles;
  TogglesLoaded(this.toggles);
}
class TogglesError extends TogglesState {
  final String message;
  TogglesError(this.message);
}

class TogglesBloc extends Bloc<TogglesEvent, TogglesState> {
  final BillingRepository _repo;

  TogglesBloc(this._repo) : super(TogglesInitial()) {
    on<LoadToggles>(_onLoad);
    on<ToggleFeature>(_onToggle);
  }

  Future<void> _onLoad(LoadToggles e, Emitter<TogglesState> emit) async {
    emit(TogglesLoading());
    try {
      emit(TogglesLoaded(await _repo.getToggles()));
    } catch (err) {
      emit(TogglesError(err.toString()));
    }
  }

  Future<void> _onToggle(ToggleFeature e, Emitter<TogglesState> emit) async {
    final current = state;
    if (current is! TogglesLoaded) return;

    // Optimistic update
    final optimistic = current.toggles
        .map((t) => t.featureKey == e.featureKey
            ? FeatureToggle(featureKey: t.featureKey, enabled: e.enabled)
            : t)
        .toList();
    emit(TogglesLoaded(optimistic));

    try {
      await _repo.setToggle(e.featureKey, e.enabled);
    } catch (err) {
      // Rollback on failure
      emit(TogglesLoaded(current.toggles));
      emit(TogglesError('Не удалось сохранить настройку: $err'));
      emit(TogglesLoaded(current.toggles));
    }
  }
}
```

- [ ] **Step 5: TogglesBloc test**

```dart
// test/features/billing/bloc/toggles_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/features/billing/domain/entities/feature_toggle.dart';
import 'package:taler_id_mobile/features/billing/domain/repositories/billing_repository.dart';
import 'package:taler_id_mobile/features/billing/presentation/bloc/toggles_bloc.dart';

class MockBillingRepo extends Mock implements BillingRepository {}

void main() {
  late BillingRepository repo;
  final toggles6 = [
    const FeatureToggle(featureKey: 'voice_assistant', enabled: true),
    const FeatureToggle(featureKey: 'web_search', enabled: true),
    const FeatureToggle(featureKey: 'ai_twin', enabled: true),
    const FeatureToggle(featureKey: 'outbound_call', enabled: true),
    const FeatureToggle(featureKey: 'whisper_transcribe', enabled: true),
    const FeatureToggle(featureKey: 'meeting_summary', enabled: true),
  ];

  setUp(() { repo = MockBillingRepo(); });

  blocTest<TogglesBloc, TogglesState>(
    'loads 6 toggles',
    build: () {
      when(() => repo.getToggles()).thenAnswer((_) async => toggles6);
      return TogglesBloc(repo);
    },
    act: (b) => b.add(LoadToggles()),
    expect: () => [
      isA<TogglesLoading>(),
      isA<TogglesLoaded>().having((s) => s.toggles.length, 'length', 6),
    ],
  );

  blocTest<TogglesBloc, TogglesState>(
    'optimistic toggle + server confirm',
    build: () {
      when(() => repo.getToggles()).thenAnswer((_) async => toggles6);
      when(() => repo.setToggle('web_search', false))
          .thenAnswer((_) async => const FeatureToggle(featureKey: 'web_search', enabled: false));
      return TogglesBloc(repo)..add(LoadToggles());
    },
    wait: const Duration(milliseconds: 10),
    act: (b) => b.add(ToggleFeature('web_search', false)),
    skip: 2,  // skip initial Loading + Loaded
    expect: () => [
      isA<TogglesLoaded>().having(
        (s) => s.toggles.firstWhere((t) => t.featureKey == 'web_search').enabled,
        'web_search enabled',
        false,
      ),
    ],
  );
}
```

- [ ] **Step 6: PackagesBloc + test + TransactionsBloc**

PackagesBloc similar shape: `LoadPackages` → `PackagesLoaded(List<BillingPackage>)`, `PurchasePackage(pkgId)` → `PurchaseInProgress` → `PurchaseSuccess(newBalance)` | `PurchaseFailed`.

TransactionsBloc similar: `LoadTransactions` → `TransactionsLoaded(List<BillingTransaction>)`.

Both implementations + tests follow the BalanceBloc pattern. Write them the same way.

(Full code omitted here to keep this doc compact — use BalanceBloc as the template.)

- [ ] **Step 7: Register BLoCs in service_locator**

In `lib/core/di/service_locator.dart`, register all 4 BLoCs as `registerFactory` (new instance per screen):

```dart
sl.registerFactory(() => BalanceBloc(sl<BillingRepository>()));
sl.registerFactory(() => PackagesBloc(sl<BillingRepository>()));
sl.registerFactory(() => TogglesBloc(sl<BillingRepository>()));
sl.registerFactory(() => TransactionsBloc(sl<BillingRepository>()));
```

- [ ] **Step 8: Run all billing tests**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile/.worktrees/billing-ui
flutter test test/features/billing/ 2>&1 | tail -10
```
Expected: all green.

- [ ] **Step 9: Commit**

```bash
git add lib/features/billing/presentation/bloc/ test/features/billing/ lib/core/di/
git commit -m "feat(billing): add 4 BLoCs (balance, packages, toggles, transactions) with tests"
```

---

## Part D — Widgets

### Task 4: BalanceChip + InsufficientFundsSheet + LowBalanceBanner

**Files:**
- Create: `lib/features/billing/presentation/widgets/balance_chip.dart`
- Create: `lib/features/billing/presentation/widgets/insufficient_funds_sheet.dart`
- Create: `lib/features/billing/presentation/widgets/low_balance_banner.dart`
- Create: `test/features/billing/widgets/insufficient_funds_sheet_test.dart`

- [ ] **Step 1: BalanceChip widget**

```dart
// lib/features/billing/presentation/widgets/balance_chip.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/router/app_router.dart';   // or however routing is done
import '../bloc/balance_bloc.dart';

class BalanceChip extends StatelessWidget {
  const BalanceChip({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BalanceBloc, BalanceState>(
      builder: (context, state) {
        final text = switch (state) {
          BalanceLoaded s => '${s.balance.balanceMicroTal} μTAL',
          BalanceLoading _ => '…',
          _ => '—',
        };
        return InkWell(
          onTap: () => Navigator.pushNamed(context, '/billing/wallet'),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_balance_wallet_outlined, size: 16),
                const SizedBox(width: 4),
                Text(text, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 2: InsufficientFundsSheet**

```dart
// lib/features/billing/presentation/widgets/insufficient_funds_sheet.dart
import 'package:flutter/material.dart';

class InsufficientFundsSheet extends StatelessWidget {
  final String featureKey;
  final String requiredPlanck;
  final String availablePlanck;
  final String? suggestedPackage;

  const InsufficientFundsSheet({
    super.key,
    required this.featureKey,
    required this.requiredPlanck,
    required this.availablePlanck,
    this.suggestedPackage,
  });

  static Future<void> show(
    BuildContext context, {
    required String featureKey,
    required String requiredPlanck,
    required String availablePlanck,
    String? suggestedPackage,
  }) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => InsufficientFundsSheet(
          featureKey: featureKey,
          requiredPlanck: requiredPlanck,
          availablePlanck: availablePlanck,
          suggestedPackage: suggestedPackage,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.account_balance_wallet, size: 48),
          const SizedBox(height: 16),
          Text(
            'Недостаточно средств',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Для использования этой функции нужно пополнить баланс.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/billing/purchase',
                  arguments: {'preferred': suggestedPackage ?? 'starter'});
            },
            child: const Text('Пополнить'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: LowBalanceBanner**

```dart
// lib/features/billing/presentation/widgets/low_balance_banner.dart
import 'package:flutter/material.dart';

class LowBalanceBanner extends StatelessWidget {
  final String balanceMicroTal;

  const LowBalanceBanner({super.key, required this.balanceMicroTal});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.orange.shade100,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Баланс на исходе: $balanceMicroTal μTAL'),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/billing/wallet'),
              child: const Text('Пополнить'),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Widget test for InsufficientFundsSheet**

```dart
// test/features/billing/widgets/insufficient_funds_sheet_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/billing/presentation/widgets/insufficient_funds_sheet.dart';

void main() {
  testWidgets('InsufficientFundsSheet shows title + CTA', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => InsufficientFundsSheet.show(
                  ctx,
                  featureKey: 'voice_assistant',
                  requiredPlanck: '26000000',
                  availablePlanck: '1000000',
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Недостаточно средств'), findsOneWidget);
    expect(find.text('Пополнить'), findsOneWidget);
  });
}
```

- [ ] **Step 5: Run + commit**

```bash
flutter test test/features/billing/widgets/ 2>&1 | tail -5
git add lib/features/billing/presentation/widgets/ test/features/billing/widgets/
git commit -m "feat(billing): balance_chip + insufficient_funds_sheet + low_balance_banner"
```

---

## Part E — Screens

### Task 5: wallet_screen + purchase_screen

**Files:**
- Create: `lib/features/billing/presentation/screens/wallet_screen.dart`
- Create: `lib/features/billing/presentation/screens/purchase_screen.dart`

- [ ] **Step 1: wallet_screen**

```dart
// lib/features/billing/presentation/screens/wallet_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../bloc/balance_bloc.dart';
import '../bloc/packages_bloc.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => GetIt.I<BalanceBloc>()..add(LoadBalance())),
        BlocProvider(create: (_) => GetIt.I<PackagesBloc>()..add(LoadPackages())),
      ],
      child: Scaffold(
        appBar: AppBar(title: const Text('Кошелёк')),
        body: RefreshIndicator(
          onRefresh: () async {
            context.read<BalanceBloc>().add(LoadBalance());
            context.read<PackagesBloc>().add(LoadPackages());
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _BalanceCard(),
              const SizedBox(height: 24),
              Text('Пакеты',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              _PackagesList(),
              const SizedBox(height: 24),
              Text('Последние операции',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              _RecentTxList(),
              ListTile(
                title: const Text('Все операции'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/billing/transactions'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BalanceBloc, BalanceState>(
      builder: (context, state) {
        final balanceText = switch (state) {
          BalanceLoaded s => s.balance.balanceMicroTal,
          _ => '…',
        };
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Баланс'),
                const SizedBox(height: 8),
                Text('$balanceText μTAL',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/billing/purchase'),
                        child: const Text('Купить пакет'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PackagesList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PackagesBloc, PackagesState>(
      builder: (context, state) {
        if (state is PackagesLoaded) {
          return Column(
            children: state.packages
                .map((p) => Card(
                      child: ListTile(
                        title: Text(p.label['ru'] ?? p.id),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: (p.highlights['ru'] ?? [])
                              .map((h) => Text('• $h'))
                              .toList(),
                        ),
                        trailing: Text('€${(p.priceEurCents / 100).toStringAsFixed(2)}'),
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/billing/purchase',
                          arguments: {'preferred': p.id},
                        ),
                      ),
                    ))
                .toList(),
          );
        }
        return const Center(child: Padding(
          padding: EdgeInsets.all(8),
          child: CircularProgressIndicator(),
        ));
      },
    );
  }
}

class _RecentTxList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BalanceBloc, BalanceState>(
      builder: (context, state) {
        if (state is BalanceLoaded) {
          final txs = state.balance.recentTx.take(5).toList();
          if (txs.isEmpty) return const Text('Операций нет');
          return Column(
            children: txs.map((t) => ListTile(
              dense: true,
              title: Text(t.type),
              subtitle: Text(t.featureKey ?? ''),
              trailing: Text(
                '${t.type.contains('TOPUP') || t.type == 'REFUND' ? '+' : '−'}${t.amountPlanck}',
              ),
            )).toList(),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
```

- [ ] **Step 2: purchase_screen**

```dart
// lib/features/billing/presentation/screens/purchase_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../bloc/packages_bloc.dart';

class PurchaseScreen extends StatelessWidget {
  const PurchaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.I<PackagesBloc>()..add(LoadPackages()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Купить пакет')),
        body: BlocConsumer<PackagesBloc, PackagesState>(
          listener: (context, state) {
            if (state is PurchaseSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Пакет куплен')),
              );
              Navigator.pop(context);
            }
            if (state is PurchaseFailed) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Ошибка: ${state.message}')),
              );
            }
          },
          builder: (context, state) {
            if (state is PackagesLoaded) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: state.packages.map((p) => Card(
                  child: ListTile(
                    title: Text(p.label['ru'] ?? p.id),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: (p.highlights['ru'] ?? [])
                          .map((h) => Text('• $h'))
                          .toList(),
                    ),
                    trailing: FilledButton(
                      onPressed: () =>
                          context.read<PackagesBloc>().add(PurchasePackage(p.id)),
                      child: Text('€${(p.priceEurCents / 100).toStringAsFixed(2)}'),
                    ),
                  ),
                )).toList(),
              );
            }
            if (state is PurchaseInProgress) {
              return const Center(child: CircularProgressIndicator());
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Add routes**

In `lib/core/router/app_router.dart`, add:

```dart
case '/billing/wallet':
  return MaterialPageRoute(builder: (_) => const WalletScreen());
case '/billing/purchase':
  return MaterialPageRoute(builder: (_) => const PurchaseScreen());
```

Match the existing router style (may use go_router instead — adapt).

- [ ] **Step 4: Commit**

```bash
flutter analyze lib/features/billing/ 2>&1 | tail -5
git add lib/features/billing/presentation/screens/ lib/core/router/
git commit -m "feat(billing): wallet_screen + purchase_screen + routes"
```

### Task 6: transactions + pricebook + ai_toggles screens

**Files:**
- Create: `lib/features/billing/presentation/screens/transactions_screen.dart`
- Create: `lib/features/billing/presentation/screens/pricebook_screen.dart`
- Create: `lib/features/billing/presentation/screens/ai_toggles_screen.dart`

- [ ] **Step 1: TransactionsScreen** — full paginated list. Uses `TransactionsBloc`. Each row shows type, feature, amount, timestamp.

- [ ] **Step 2: PricebookScreen** — list all 6 features with their cost per unit. Read-only.

- [ ] **Step 3: AiTogglesScreen** — 6 switches, wired to `TogglesBloc`:

```dart
class AiTogglesScreen extends StatelessWidget {
  const AiTogglesScreen({super.key});

  static const featureLabels = {
    'voice_assistant': 'Голосовой ассистент',
    'web_search': 'Веб‑поиск ассистента',
    'ai_twin': 'Голосовой двойник (AI Twin)',
    'outbound_call': 'Outbound‑бот обзвона',
    'whisper_transcribe': 'Транскрипция звонков',
    'meeting_summary': 'AI‑резюме звонков',
  };

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.I<TogglesBloc>()..add(LoadToggles()),
      child: Scaffold(
        appBar: AppBar(title: const Text('AI‑функции')),
        body: BlocBuilder<TogglesBloc, TogglesState>(
          builder: (context, state) {
            if (state is TogglesLoaded) {
              return ListView(
                children: state.toggles.map((t) => SwitchListTile(
                  title: Text(featureLabels[t.featureKey] ?? t.featureKey),
                  value: t.enabled,
                  onChanged: (v) =>
                      context.read<TogglesBloc>().add(ToggleFeature(t.featureKey, v)),
                )).toList(),
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Routes + commit**

Add `/billing/transactions`, `/billing/pricebook`, `/settings/ai-toggles` routes. Commit each file group.

---

## Part F — Cross-cutting

### Task 7: Dio paywall interceptor

**Files:**
- Create: `lib/core/api/billing_paywall_interceptor.dart`
- Modify: `lib/core/api/dio_client.dart`
- Modify: `lib/main.dart` (or wherever global navigator key is) if not present

- [ ] **Step 1: Global navigator key**

Check if the project already has a global navigator key in `main.dart`. If not, add:

```dart
// in main.dart
final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

// attach to MaterialApp:
MaterialApp(
  navigatorKey: globalNavigatorKey,
  // ...
)
```

Make it accessible from `billing_paywall_interceptor.dart` via import.

- [ ] **Step 2: Interceptor**

```dart
// lib/core/api/billing_paywall_interceptor.dart
import 'package:dio/dio.dart';
import '../../features/billing/presentation/widgets/insufficient_funds_sheet.dart';
import '../../main.dart';   // globalNavigatorKey

class BillingPaywallInterceptor extends Interceptor {
  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 402) {
      final data = err.response?.data as Map<String, dynamic>?;
      final ctx = globalNavigatorKey.currentContext;
      if (ctx != null && data != null && data['error'] == 'insufficient_funds') {
        await InsufficientFundsSheet.show(
          ctx,
          featureKey: data['featureKey'] as String? ?? 'unknown',
          requiredPlanck: data['requiredPlanck'] as String? ?? '0',
          availablePlanck: data['availablePlanck'] as String? ?? '0',
          suggestedPackage: data['suggestedPackage'] as String?,
        );
      }
    }
    handler.next(err);   // keep bubbling so callers can handle their own state
  }
}
```

- [ ] **Step 3: Register on Dio**

Modify `lib/core/api/dio_client.dart`. In the interceptor chain, add after AuthInterceptor:

```dart
dio.interceptors.add(BillingPaywallInterceptor());
```

- [ ] **Step 4: Commit**

```bash
flutter analyze 2>&1 | tail -5
git add lib/core/ lib/main.dart
git commit -m "feat(billing): Dio 402 interceptor → InsufficientFundsSheet"
```

---

### Task 8: Socket.io live events

**Files:**
- Modify: existing Socket.io client service (likely `lib/core/services/messenger_socket_service.dart` or similar)
- Maybe: `lib/features/billing/data/services/billing_socket_listener.dart` (new, wraps the socket)

- [ ] **Step 1: Inspect existing socket client**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile/.worktrees/billing-ui
grep -rn "socket\.io\|Socket\.io\|io_client\|connect.*wss" lib/core/ lib/features/messenger/ 2>/dev/null | head -10
```

Report findings before edits. The socket likely authenticates via JWT and joins `user:${userId}` room.

- [ ] **Step 2: Add billing event subscriptions**

In the socket service's connection setup, add:

```dart
socket.on('billing_balance_changed', (data) {
  // Use GetIt to find BalanceBloc if registered globally, otherwise emit via a stream service
  if (GetIt.I.isRegistered<BalanceBloc>()) {
    GetIt.I<BalanceBloc>().add(
      BalanceChangedExternally((data as Map)['balancePlanck'] as String),
    );
  }
});

socket.on('ai_session_terminated', (data) {
  // Broadcast via a stream that screens can listen to
  _aiSessionTerminatedController.add(data as Map<String, dynamic>);
});

socket.on('billing_low_balance_warning', (data) {
  _lowBalanceWarningController.add(data as Map<String, dynamic>);
});
```

**Note:** `BalanceBloc` is registered as `registerFactory` (new instance per screen) in Task 3 Step 7 — can't push events to it from a singleton socket. Either register a singleton `BalanceBloc` for global use, OR push balance updates via a `StreamController<WalletBalance>` that the factory-created BLoC subscribes to.

Cleaner approach: introduce `BillingEventBus` as a singleton service with `Stream<double> balanceChanges`, `Stream<AiSessionTerminated> sessionTerminated`, etc. Socket pushes into it. BLoCs subscribe on construction.

Implement `BillingEventBus` in `lib/features/billing/data/services/billing_event_bus.dart`:

```dart
class BillingEventBus {
  final _balance = StreamController<String>.broadcast();
  final _terminated = StreamController<AiSessionTerminatedEvent>.broadcast();
  final _lowBalance = StreamController<LowBalanceEvent>.broadcast();

  Stream<String> get onBalanceChanged => _balance.stream;
  Stream<AiSessionTerminatedEvent> get onSessionTerminated => _terminated.stream;
  Stream<LowBalanceEvent> get onLowBalance => _lowBalance.stream;

  void pushBalance(String planck) => _balance.add(planck);
  void pushTerminated(AiSessionTerminatedEvent e) => _terminated.add(e);
  void pushLowBalance(LowBalanceEvent e) => _lowBalance.add(e);

  void dispose() {
    _balance.close();
    _terminated.close();
    _lowBalance.close();
  }
}
```

Register as singleton in DI. Socket pushes to it. `BalanceBloc` subscribes in its constructor and emits `BalanceChangedExternally` on each event.

- [ ] **Step 3: Commit**

```bash
git add lib/core/ lib/features/billing/
git commit -m "feat(billing): BillingEventBus + socket listeners for live balance/session events"
```

---

## Part G — Integration

### Task 9: Settings + Dashboard integration + ai_twin migration

**Files:**
- Modify: `lib/features/settings/presentation/screens/settings_screen.dart`
- Modify: `lib/features/dashboard/presentation/screens/dashboard_screen.dart` (or wherever AppBar lives)
- Modify: `lib/features/profile/presentation/screens/ai_twin_screen.dart`

- [ ] **Step 1: Settings menu items**

In `settings_screen.dart`, add two new menu items near profile/language settings:

```dart
ListTile(
  leading: const Icon(Icons.account_balance_wallet),
  title: const Text('Кошелёк и баланс'),
  trailing: const Icon(Icons.chevron_right),
  onTap: () => Navigator.pushNamed(context, '/billing/wallet'),
),
ListTile(
  leading: const Icon(Icons.smart_toy),
  title: const Text('AI‑функции'),
  trailing: const Icon(Icons.chevron_right),
  onTap: () => Navigator.pushNamed(context, '/settings/ai-toggles'),
),
```

- [ ] **Step 2: Dashboard AppBar chip**

Find the dashboard screen's AppBar and wrap it with a BlocProvider for BalanceBloc (register as singleton for this use), adding `BalanceChip` to `actions`.

Need a GLOBAL BalanceBloc for the chip. Update DI in `service_locator.dart`:

```dart
sl.registerLazySingleton(() => BalanceBloc(sl<BillingRepository>())..add(LoadBalance()));
```

Subscribe BalanceBloc to `BillingEventBus.onBalanceChanged` in its constructor so socket events refresh the chip.

- [ ] **Step 3: ai_twin_screen migration**

Open `lib/features/profile/presentation/screens/ai_twin_screen.dart`. Currently it saves `aiTwinEnabled` through `ProfileRepository.update(…)`. Migrate:

- Remove `aiTwinEnabled` from the profile PATCH call
- Add a parallel call to `BillingRepository.setToggle('ai_twin', enabled)` on save
- Optionally: when loading the screen, fetch the current toggle state from `/billing/settings/toggles` alongside the profile

Keep other AI Twin settings (`aiTwinTimeoutSeconds`, `aiTwinPrompt`, `aiTwinVoiceId`) in profile — those stay as Profile fields per spec.

- [ ] **Step 4: Commit**

```bash
flutter analyze 2>&1 | tail -5
git add lib/features/settings/ lib/features/dashboard/ lib/features/profile/ lib/core/di/
git commit -m "feat(billing): Settings menu + Dashboard chip + AI Twin toggle migration"
```

---

### Task 10: Voice assistant integration

**Files:**
- Modify: `lib/features/voice/data/datasources/voice_remote_datasource.dart`
- Modify: `lib/features/voice/presentation/bloc/voice_bloc.dart` (or wherever session lifecycle is managed)
- Modify: `lib/features/voice/presentation/screens/voice_call_screen.dart`

- [ ] **Step 1: Update /voice/session response handling**

`createVoiceSession` now returns `{ clientSecret, billingSessionId }`. Extend the return type and propagate `billingSessionId` to the BLoC.

- [ ] **Step 2: Heartbeat + close**

Add to VoiceBloc:
- Start a 10-second heartbeat timer on session start: `POST /metering/heartbeat { sessionId: billingSessionId }`
- On session close: `POST /voice/session/$billingSessionId/close { durationSec }`

Both fire-and-forget — errors logged but not user-facing.

- [ ] **Step 3: Listen for ai_session_terminated**

In `voice_call_screen.dart` initState, subscribe to `BillingEventBus.onSessionTerminated`. When event for current session fires:
- If `reason == 'no_funds'`: show snackbar "Баланс закончился"
- Close WebRTC connection
- Pop the screen

- [ ] **Step 4: Commit**

```bash
git add lib/features/voice/
git commit -m "feat(billing): voice assistant heartbeat + close + termination handler"
```

---

## Part H — Assistant-first Tools

### Task 11: OpenAI Realtime tools

**Files:**
- Modify: wherever assistant tools are registered (grep for `web_search` or `function_call` definitions)

- [ ] **Step 1: Find existing tool registration**

```bash
grep -rn "web_search\|function_call\|tools:" lib/features/assistant/ 2>/dev/null | head -10
```

- [ ] **Step 2: Add 4 new tools**

```dart
{
  'type': 'function',
  'name': 'get_balance',
  'description': 'Получить текущий баланс TAL-кошелька пользователя',
  'parameters': { 'type': 'object', 'properties': {}, 'required': [] },
},
{
  'type': 'function',
  'name': 'get_packages',
  'description': 'Получить список пакетов для пополнения баланса',
  'parameters': { 'type': 'object', 'properties': {}, 'required': [] },
},
{
  'type': 'function',
  'name': 'list_recent_transactions',
  'description': 'Последние операции по балансу',
  'parameters': {
    'type': 'object',
    'properties': { 'limit': { 'type': 'integer' } },
    'required': [],
  },
},
{
  'type': 'function',
  'name': 'toggle_feature',
  'description': 'Включить или выключить AI-функцию (voice_assistant, web_search, ai_twin, outbound_call, whisper_transcribe, meeting_summary)',
  'parameters': {
    'type': 'object',
    'properties': {
      'featureKey': { 'type': 'string' },
      'enabled': { 'type': 'boolean' },
    },
    'required': ['featureKey', 'enabled'],
  },
},
```

- [ ] **Step 3: Tool handlers**

Each handler calls the corresponding `BillingRepository` method and returns the result as JSON to the assistant. Explicitly DO NOT register `purchase` or `withdraw` tools — those require explicit UI confirmation.

- [ ] **Step 4: Commit**

```bash
git add lib/features/assistant/
git commit -m "feat(billing): assistant-first tools (get_balance, get_packages, list_recent, toggle_feature)"
```

---

## Part I — Final

### Task 12: l10n + final test

**Files:**
- Modify: `lib/l10n/app_ru.arb`, `lib/l10n/app_en.arb`
- Verify all screens

- [ ] **Step 1: Translate all strings**

Replace hardcoded Russian strings in new screens with l10n lookups. Add `billing_` prefixed keys to both `.arb` files.

- [ ] **Step 2: flutter test**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile/.worktrees/billing-ui
flutter test 2>&1 | tail -10
```
Expected: no new failures (baseline may have pre-existing).

- [ ] **Step 3: Build dev APK and run on emulator**

```bash
flutter emulators --launch Pixel_XL_API_33
# wait ~15 sec
flutter run --flavor dev -t lib/main_dev.dart \
  --dart-define=FLAVOR=dev \
  --dart-define=BASE_URL=https://staging.id.taler.tirol \
  -d emulator-5554
```

Manually verify:
- Settings → "Кошелёк и баланс" opens wallet_screen with balance 50 μTAL
- Tap "Купить пакет" → Starter purchase succeeds, balance becomes 480 μTAL
- Settings → "AI‑функции" shows 6 toggles, PATCH works
- Trigger 402 somehow (easier: drain balance via test user's debit, then retry) → paywall sheet appears

- [ ] **Step 4: Commit l10n + polish**

```bash
git add lib/l10n/
git commit -m "feat(billing): l10n strings + final polish"
```

---

## Acceptance

After Task 12:
- Backend on DEV still dry-run (`BILLING_ENFORCED=false`)
- Mobile on `feat/billing-ui` branch — NOT in `dev` yet
- All billing endpoints reachable + shown in UI
- Emulator smoke green
- Ready to merge `feat/billing-ui` → `dev` for wider testing (APK build + iOS testflight dev flavor)

Before merging to `dev`:
- Manual QA on real device (iOS + Android)
- At least one full cycle: install → login → purchase → use assistant → see balance drop → see 402 → paywall → top up → continue
