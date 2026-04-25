# Forwarding + Share-in + Favorites — Design Spec

**Date:** 2026-04-25
**Scope:** Taler ID — активация и доработка существующих, но недоступных пользователю фич: пересылка между всеми типами чатов, приём внешних файлов через ОС share, "Избранное" (Saved Messages, Telegram-стиль).
**Deploy target:** только DEV (мобилка ветка `dev`). PROD — только по явному указанию.

## 1. Цель

Из исходного запроса пользователя:
> Во всех чатах нужно сделать возможность пересылки сообщений из одного в другой. Также, если из вне файл прилетает, чтобы его можно было отправить и в Избранное, и в AI Ассистента и даже в AI обзвон. Передавать в канал в чат, избранное, AI чат, обзвоны.

**Текущее состояние (research findings):**
- Forwarding: реализован end-to-end (BLoC + UI + backend), уже работает для всех типов
- Share-in: iOS Share Extension и Android intent-filter полностью построены, но `ShareIntentService.pendingFilesStream` нигде не слушается → внешний файл "молча" приходит и не открывает экран выбора получателя
- Saved Messages: backend готов (`/messenger/saved` endpoint, `SAVED` ConvType, conv создаётся с `name='Избранное'`), но в мобильном UI не виден — отфильтрован из основного списка чатов и нет pinned-точки входа
- Локальный Hive `'saved_messages'` box дублирует серверный SAVED (legacy, не синхронизируется между устройствами)
- Recipient picker'ы (forward + share-in) могут отфильтровывать AI/CHANNEL — нужно проверить и привести к единому правилу

**User story:** как пользователь, я хочу
- видеть "Избранное" как pinned-чат сверху списка чатов и открыть его одним тапом
- пересылать сообщения и файлы в любой чат, включая AI Аналитика, AI Обзвон, каналы (где у меня есть права постить) и Избранное
- через ОС share-меню отправить файл/текст в Taler ID и выбрать получателя из всех моих чатов
- чтобы локально сохранённое в "Избранное" с прошлой версии приложения автоматически перенеслось на сервер при первом запуске

**Out of scope (на эту итерацию):**
- 6-я вкладка в bottom nav (выбран pinned-tile подход)
- Кастомный экран SAVED с фильтрами All/Photos/Files/Voice/Links — на будущее
- Унификация `_ForwardPickerSheet` и `ShareTargetScreen` в один общий widget — отдельный refactor
- Backend изменения — все нужные endpoints уже существуют

## 2. Архитектурные решения

- **Подход:** точечные минимальные изменения, переиспользование существующей инфраструктуры (~95% уже построено)
- **SAVED entry point:** pinned tile сверху `conversations_screen` (Telegram-style), открывает существующий `chat_room_screen` с conv типа SAVED — никаких новых маршрутов или экранов
- **Hive миграция:** идемпотентный сервис `HiveFavoritesMigrationService.runOnce()` вызывается при старте приложения (через `unawaited`), не блокирует UI; флаг в `flutter_secure_storage` гарантирует one-shot
- **Share-in активация:** `ShareIntentService.pendingFilesStream` слушается в `DashboardScreen.initState`, при получении файлов — `context.go('/share-target', extra: files)`
- **Recipient filter:** новый shared helper `lib/features/messenger/utils/recipient_filters.dart` используется и `_ForwardPickerSheet`, и `ShareTargetScreen` — единый source of truth для "куда можно постить"
- **Включаем все типы:** DIRECT, GROUP, CHANNEL (только OWNER/ADMIN), SAVED, AI_ANALYST, AI_OUTBOUND. Явный пользовательский выбор: ограничения — это потеря фичи, не safeguard
- **Backend: 0 изменений.** Все нужные endpoints (`POST /messenger/saved`, socket `'message'`, `assertCanPostInChannel`) существуют

## 3. Архитектура и поток событий

### 3.1. SAVED pinned tile

```
conversations_screen (ListView)
  ┌──────────────────────────────────┐
  │ [⭐] Избранное · Ваше личное облако ›│  ← SavedPinnedTile (новый)
  └──────────────────────────────────┘
  ─── Divider ───
  │ DIRECT, GROUP, CHANNEL ...       │  ← существующий список
  │   (фильтр SAVED, AI_*, не показ.)│
```

Tap → `IMessengerRepository.getOrCreateSavedConversation()` → `POST /messenger/saved` → `context.go('/dashboard/messenger/{convId}')` → существующий `chat_room_screen` рендерит чат с `name='Избранное'`.

### 3.2. Hive миграция при старте

```
main.dart
  └─ setupDependencies()
  └─ unawaited(sl<HiveFavoritesMigrationService>().runOnce())
  └─ runApp(...)

HiveFavoritesMigrationService.runOnce()
  • прочитать prefs['saved_migrated_v1']
  • если true → return
  • если Hive.boxExists('saved_messages') == false → set flag, return
  • открыть box, прочитать entries
  • если empty → deleteFromDisk, set flag, return
  • repo.getOrCreateSavedConversation() → convId
  • для каждого entry (sorted by savedAt asc):
      repo.sendMessage(convId, content, fileUrl?, fileName?, fileType?, fileSize?)
  • box.deleteFromDisk()
  • set flag = 'true'
  • любая ошибка — caught и logged, флаг НЕ выставляется → ретрай при следующем запуске
```

### 3.3. Share-in активация

```
DashboardScreen.initState()
  ├─ _shareSub = ShareIntentService.instance.pendingFilesStream.listen(_onSharedFiles)
  └─ post-frame: getInitialMedia() → если non-empty → _onSharedFiles(initial)

_onSharedFiles(List<SharedMediaFile> files)
  └─ context.go('/share-target', extra: files)

GoRoute('/share-target')
  └─ ShareTargetScreen(initialFiles: extra)
       ├─ pinned: SavedShareShortcut → tap → POST /messenger/saved → chat_room с files
       └─ recipients: filterRecipients(state.conversations) → tap → chat_room с files
```

### 3.4. Recipient filter

```
filterRecipients(List<ConversationEntity>) → List<ConversationEntity>
  · DIRECT, GROUP — всегда
  · CHANNEL — только если myRole ∈ {OWNER, ADMIN}
  · SAVED, AI_ANALYST, AI_OUTBOUND — всегда
  · deletedAt != null → исключить
  · неизвестный type → исключить

Используется:
  · _ForwardPickerSheet (chat_room_screen.dart)
  · ShareTargetScreen (share_target_screen.dart)
```

## 4. Mobile — конкретные файлы

### 4.1. Новые файлы

**`lib/features/messenger/utils/recipient_filters.dart`**
```dart
import '../domain/entities/conversation_entity.dart';

const _channelPostingRoles = {'OWNER', 'ADMIN'};

List<ConversationEntity> filterRecipients(List<ConversationEntity> all) {
  return all.where(_canPost).toList(growable: false);
}

bool _canPost(ConversationEntity c) {
  if (c.deletedAt != null) return false;
  switch (c.type) {
    case 'DIRECT':
    case 'GROUP':
    case 'SAVED':
    case 'AI_ANALYST':
    case 'AI_OUTBOUND':
      return true;
    case 'CHANNEL':
      return _channelPostingRoles.contains(c.myRole);
    default:
      return false;
  }
}
```

**`lib/features/messenger/services/hive_favorites_migration_service.dart`**

Класс `HiveFavoritesMigrationService` с методом `runOnce()`. См. раздел 3.1 в design discussion для полного псевдокода. Ключевые особенности:
- Idempotent через `prefs['saved_migrated_v1']`
- Best-effort: ловит и логирует, никогда не throw
- Если sendMessage падает — флаг НЕ ставится, ретрай на следующем запуске
- Использует существующий `IMessengerRepository.sendMessage()`

**`lib/features/messenger/presentation/widgets/saved_pinned_tile.dart`**

Виджет `SavedPinnedTile` — bookmark-icon в gradient-кружке, title "Избранное", subtitle "Ваше личное облако", chevron. Tap → `repo.getOrCreateSavedConversation()` → navigate. Использует `AppColorsExtension` (как existing pinned widgets) и `AppLocalizations`.

**`lib/features/messenger/presentation/widgets/saved_share_shortcut.dart`** (опционально, если визуальный shortcut в share-target нужен отдельным виджетом)

Маленький tile-shortcut "Save to Favorites" в верху `ShareTargetScreen`.

### 4.2. Изменения в существующих файлах

**`lib/features/messenger/domain/repositories/i_messenger_repository.dart`**
```dart
Future<String> getOrCreateSavedConversation();   // NEW
```

**`lib/features/messenger/data/repositories/messenger_repository_impl.dart`**
```dart
@override
Future<String> getOrCreateSavedConversation() async {
  final response = await _dio.post('/messenger/saved');
  return response.data['conversationId'] as String;
}
```

**`lib/core/di/service_locator.dart`**
```dart
sl.registerLazySingleton(() => HiveFavoritesMigrationService(
  repo: sl<IMessengerRepository>(),
  storage: sl<SecureStorageService>(),
));
```

**`lib/main.dart` и `lib/main_dev.dart`**
После `setupDependencies()`:
```dart
unawaited(sl<HiveFavoritesMigrationService>().runOnce());
```

**`lib/core/router/app_router.dart`** (только если ещё нет)
```dart
GoRoute(
  path: '/share-target',
  builder: (context, state) {
    final files = state.extra as List<SharedMediaFile>?;
    return ShareTargetScreen(initialFiles: files ?? const []);
  },
),
```

**`lib/features/dashboard/presentation/screens/dashboard_screen.dart`**

Добавить `StreamSubscription<List<SharedMediaFile>>? _shareSub` поле.

В `initState`:
```dart
_shareSub = ShareIntentService.instance.pendingFilesStream.listen(_onSharedFiles);
WidgetsBinding.instance.addPostFrameCallback((_) async {
  final initial = await ShareIntentService.instance.getInitialMedia();
  if (initial.isNotEmpty) _onSharedFiles(initial);
});
```

В `dispose`:
```dart
_shareSub?.cancel();
```

Метод:
```dart
void _onSharedFiles(List<SharedMediaFile> files) {
  if (files.isEmpty) return;
  context.go('/share-target', extra: files);
}
```

**`lib/features/messenger/presentation/screens/conversations_screen.dart`**

Перед основным `ListView.builder`:
```dart
const SavedPinnedTile(),
const Divider(height: 1, thickness: 0.5),
```

Существующий фильтр `c.type != 'SAVED' && c.type != 'AI_ANALYST' && c.type != 'AI_OUTBOUND'` оставить как есть (SAVED теперь в pinned, AI_* в их вкладках).

**`lib/features/messenger/presentation/screens/chat_room_screen.dart`**

1. Удалить локальный Hive `_saveToFavorites()` (строки ~3291-3319) и любые ссылки на Hive box `'saved_messages'`. Удалить connected unused imports.

2. В `_ForwardPickerSheet` (около строки 3780-3950): заменить текущую логику фильтрации `state.conversations` на:
```dart
import '../utils/recipient_filters.dart';
// ...
final recipients = filterRecipients(state.conversations);
```
Сохранить существующий "Save to Favorites" pinned-shortcut в верху picker'а.

3. Для SAVED-чата (когда `conv.type == 'SAVED'`) в заголовке `chat_room_screen` отображать:
- Локализованный title `AppLocalizations.of(context)!.savedTitle` (вместо `conv.name`, т.к. бэк хранит русское "Избранное" без перевода)
- Bookmark-иконку с gradient (как в `SavedPinnedTile`)
- Без online-status, без typing-indicator (single-participant)

**`lib/features/messenger/presentation/screens/share_target_screen.dart`**

В формировании списка targets:
```dart
import '../utils/recipient_filters.dart';
// ...
final targets = filterRecipients(state.conversations);
```

В верху списка добавить `SavedShareShortcut` или ручной inline-tile, который вызывает `repo.getOrCreateSavedConversation()` и навигирует в `chat_room` с предзаполненными `files`.

**Защита от unauthenticated:** в начале build — если `currentUserId == null` → показать "Войдите чтобы поделиться" вместо списка.

### 4.3. Локализация

Новые ARB ключи (`lib/l10n/app_en.arb` + `app_ru.arb`):
- `savedTitle`: "Saved Messages" / "Избранное"
- `savedSubtitle`: "Your private cloud" / "Ваше личное облако"
- `savedOpenError`: "Couldn't open Saved Messages" / "Не удалось открыть Избранное"
- `shareToSaved`: "Save to Favorites" / "Сохранить в Избранное"

После изменения ARB — `flutter gen-l10n`.

## 5. Edge cases

| Сценарий | Поведение |
|---|---|
| Юзер не залогинен → share-in приходит | DashboardScreen routing работает; `ShareTargetScreen` сам guards `currentUserId == null` → "Войдите чтобы поделиться" |
| Hive box есть, юзер оффлайн при старте → миграция падает | exception caught + logged; флаг НЕ ставится; Hive box не удаляется; повтор на следующем запуске |
| Двойной запуск миграции (race) | Один `unawaited` call + флаг в конце; worst case — N повторных отправок в SAVED (visible duplicates). Mutex overkill для one-shot операции |
| Очень большой Hive (1000+) | Background через `unawaited`, app responsive; `sendMessage` последовательно; 1000 сообщений ≈ 5 минут. Типичный случай (<50) — секунды |
| Юзер открывает SAVED-tile до завершения миграции | Открывается SAVED conv; миграция продолжается фоном; новые сообщения постепенно появляются (через socket `new_message`) |
| `state.conversations` пуст (новый юзер) | Forward picker: только pinned "Save to Favorites". Share-target: pinned shortcut + сообщение "Список чатов пуст" |
| Канал, где юзер SUBSCRIBER → не предлагается | `filterRecipients` отсекает; юзер не видит этот канал в списке picker'а |
| Forward в AI_ANALYST text-сообщения | Backend получает обычный socket `'message'` → `_dispatchToAnalyst` → AI обрабатывает текст; live-status events (Фича 1) работают штатно |
| Forward файла в AI_ANALYST > 20 МБ | Existing защита: backend отсекает файлы > 20 МБ из контекста для воркера; user-visible сообщение `❌ Файл «...» слишком большой...` |
| Forward в CHANNEL без прав (юзер обходит фильтр) | Backend `assertCanPostInChannel` отклоняет → socket `error` → SnackBar в мобилке |
| Share-in приходит до того, как conversations загружены | `state.isLoading=true` → ShareTargetScreen показывает spinner; после `LoadConversations` → список наполнится |
| Юзер закрывает share-target screen | Файлы дропаются из ShareIntentService буфера (shoot-and-forget). OK — юзер мог изменить мнение |
| Recursive forward (forward сообщения, которое было forward-нуто) | Работает как обычное copy-message-and-send; цепочка forwards не отслеживается (как сейчас) |

## 6. Тесты

### Flutter unit-tests

1. **`recipient_filters_test.dart`**
   - DIRECT, GROUP включены
   - CHANNEL с OWNER/ADMIN включён, с SUBSCRIBER исключён
   - SAVED, AI_ANALYST, AI_OUTBOUND включены
   - `deletedAt != null` → исключён
   - Неизвестный type → исключён

2. **`hive_favorites_migration_service_test.dart`**
   - `saved_migrated_v1=true` → no-op (storage write не вызывается на флаг — только если уже стоит)
   - Hive box не существует → флаг ставится, sendMessage не вызывается
   - Hive box с N сообщений → создаёт SAVED conv, отправляет N сообщений в порядке `savedAt asc`, удаляет box, ставит флаг
   - sendMessage кидает → флаг НЕ ставится, Hive box НЕ удалён, метод не пробрасывает

3. **Widget-test `SavedPinnedTile`**
   - Рендерит title, subtitle, bookmark-icon
   - Tap → вызывает `repo.getOrCreateSavedConversation()` (через mock) и navigation

### Integration test (расширение `app_test.dart`)

Добавить шаг после login + Messenger tab:
- Найти `SavedPinnedTile`
- Тап → открывается `chat_room_screen` с заголовком `savedTitle`
- Long-press на любом сообщении (если есть существующий чат с историей) → forward → выбрать "Избранное" → сообщение появляется в SAVED chat (проверить через next message arrival)

### Manual smoke test (Android, обязательно перед DEV-релизом)

1. Открыть Files / Gallery
2. Выбрать файл → "Поделиться" → "Taler ID Dev"
3. Должен открыться `ShareTargetScreen` с превью
4. Выбрать "Save to Favorites" shortcut → файл в SAVED
5. Повторить с обычным контактом → файл в DIRECT
6. iOS — тот же сценарий через Share Extension

### Pre-deploy regression (CLAUDE.md §🧪)

Полный пакет: `flutter test` (mobile unit), `npm test`, `test:voice`, `test:assistant`, `test:files`, `test:channels`, `test:billing`, `test:analyst`. Integration test обязателен.

## 7. Деплой

**Только мобильные изменения. 0 backend.**

1. Все коммиты в `dev` ветку мобилки (push на origin)
2. Сборка `taler-id-dev.apk` на сервере 138.124.61.221: `flutter build apk --flavor dev --release -t lib/main_dev.dart --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol`
3. `sudo cp build/.../app-dev-release.apk /var/www/downloads/taler-id-dev.apk`
4. Прогон Flutter unit + integration test
5. Manual share-in smoke на Android (минимум) + iOS (если время)
6. Прогон API regression
7. PROD — **только по явному указанию**

## 8. Критерии готовности

- [ ] `SavedPinnedTile` отображается сверху списка чатов после логина
- [ ] Tap на SavedPinnedTile открывает chat_room с заголовком "Избранное"
- [ ] Forward picker включает: DIRECT, GROUP, CHANNEL (только OWNER/ADMIN), SAVED, AI_ANALYST, AI_OUTBOUND
- [ ] Forward в SAVED: сообщение появляется в SAVED chat
- [ ] Forward в AI_ANALYST text → AI отвечает, live-status events приходят
- [ ] Внешний файл, расшаренный из другого приложения (Files / Gallery), открывает `ShareTargetScreen`
- [ ] ShareTargetScreen имеет shortcut "Save to Favorites" + список всех recipient-чатов
- [ ] Share файла в чат любого типа → файл успешно отправляется
- [ ] При первом запуске после апдейта: если был Hive `saved_messages` box с N сообщений, они появляются в SAVED chat (порядок по `savedAt`)
- [ ] Hive box `'saved_messages'` физически удалён после успешной миграции
- [ ] Локальный `_saveToFavorites()` метод удалён из `chat_room_screen.dart`
- [ ] Все Flutter unit-тесты зелёные, integration_test проходит
- [ ] Backend pre-deploy regression зелёный

## 9. Future work (вне этой итерации)

- Кастомный SAVED-screen с фильтрами (All / Photos / Files / Voice / Links) — Telegram-стиль
- Унификация `_ForwardPickerSheet` и `ShareTargetScreen` в общий `ChatPickerWidget` (modal sheet vs full screen режимы)
- Pinned-сортировка SAVED в conversations cache (чтобы при оффлайне tile отрисовался моментально из cached state)
- Глобальный поиск по содержимому SAVED (если объёмы вырастут — сейчас стандартный chat-search достаточен)
- "Forward chain" tracking (показывать "Forwarded from @user" над сообщением) — сейчас нет в скоупе
