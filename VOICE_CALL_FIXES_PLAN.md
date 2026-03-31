# План исправления звонков — Voice Call Fixes

## Баг 1: На iPhone не слышно ассистента (во всех разделах)

### Проблема
AI-ассистент воспроизводит ответы через `AudioPlayer` (пакет `audioplayers`), записывая PCM16 → WAV → temp file. На iOS audio session в режиме `.playAndRecord` + `.voiceChat` может подавлять воспроизведение через AudioPlayer, т.к. `.voiceChat` оптимизирует для телефонного разговора (AGC, echo cancellation, низкий volume cap).

На Android это работает, т.к. Android AudioFocus менее агрессивен.

### Диагностика
1. Проверить, что `AudioPlayer.play()` не кидает исключение (добавить логирование)
2. Проверить audio session category в момент воспроизведения
3. Проверить `volume` и `output route` на iOS

### План исправления

**Вариант A (быстрый):** Перед воспроизведением ассистента на iOS — переключить audio session на `.playback` или `.playAndRecord` с mode `.default` вместо `.voiceChat`:
```swift
// В AppDelegate.swift — новый метод
case "setAudioSessionForAssistant":
  try session.setCategory(.playAndRecord, mode: .default,
    options: [.allowBluetooth, .defaultToSpeaker])
  try session.setActive(true)
```
И вызывать через method channel перед `player.play()`.

**Вариант B (надёжный):** Использовать `just_audio` вместо `audioplayers` — он лучше работает с iOS audio sessions и поддерживает StreamAudioSource для прямого PCM потока.

**Вариант C (native):** Воспроизводить WAV через нативный iOS `AVAudioPlayer` через method channel, что даёт полный контроль над audio session.

### Файлы для изменения
- `ios/Runner/AppDelegate.swift` — добавить метод переключения audio session
- `lib/features/assistant/presentation/screens/assistant_screen.dart` — вызов method channel перед playback
- `lib/features/voice/presentation/screens/voice_call_screen.dart` — аналогично для in-call assistant
- `lib/features/notes/presentation/screens/notes_screen.dart` — аналогично
- `lib/features/calendar/presentation/screens/calendar_screen.dart` — аналогично
- `lib/features/profile_sections/presentation/screens/profile_sections_screen.dart` — аналогично

### Приоритет: ВЫСОКИЙ
### Оценка: 2-3 часа

---

## Баг 2: "Звонок уже идёт" при попытке позвонить после hold

### Проблема
`chat_room_screen.dart` и другие экраны проверяют `CallStateService.instance.isInCall` перед началом нового звонка. `isInCall` возвращает `true` если `_lines.isNotEmpty` — включая held lines. Поэтому при активном звонке на hold нельзя начать новый.

### План исправления
1. Изменить логику проверки: вместо полной блокировки — использовать `holdAndSwitch`:
   - Если есть активный звонок → предложить поставить на hold и позвонить
   - Или автоматически ставить на hold текущий и начинать новый (как при входящем)
2. Добавить проверку `lineCount >= maxLines` вместо `isInCall`

### Изменения в коде

**`call_state_service.dart`:**
```dart
// Новый метод
bool get canAddLine => _lines.length < maxLines;
```

**`chat_room_screen.dart` (и другие экраны с _startCall):**
```dart
// Было:
if (CallStateService.instance.isInCall) { showError(); return; }

// Стало:
final callService = CallStateService.instance;
if (callService.isInCall && !callService.canAddLine) {
  showError("Максимум звонков"); return;
}
if (callService.isInCall) {
  // Поставить текущий на hold
  final currentRoom = callService.activeLine?.roomName;
  if (currentRoom != null) {
    await callService.holdAndSwitch(newRoomName); // будет вызвано после создания комнаты
  }
}
```

### Файлы для изменения
- `lib/core/services/call_state_service.dart` — добавить `canAddLine`
- `lib/features/messenger/presentation/screens/chat_room_screen.dart` — изменить guard
- `lib/features/call_history/presentation/screens/call_history_screen.dart` — аналогично
- `lib/features/messenger/presentation/screens/user_profile_screen.dart` — аналогично
- `lib/features/tenant/presentation/screens/organization_detail_screen.dart` — аналогично

### Приоритет: ВЫСОКИЙ
### Оценка: 1-2 часа

---

## Баг 3: Нужно видеть несколько активных комнат + переключаться

### Проблема
`CallStateService` уже поддерживает до 3 линий, но UI не показывает список активных линий. Пользователь не может переключаться между held звонками.

### План исправления

**Шаг 1: UI индикатор активных линий**
В `dashboard_screen.dart` уже есть баннер "Активный звонок". Расширить его:
- Показывать количество активных линий
- При нажатии — открывать bottom sheet со списком линий
- Каждая линия: имя собеседника, статус (active/held), кнопки (switch/end)

**Шаг 2: Bottom sheet для переключения линий**
```dart
void _showCallLinesSheet() {
  final lines = CallStateService.instance.allLines;
  showModalBottomSheet(
    builder: (ctx) => ListView(
      children: lines.map((line) => ListTile(
        title: Text(line.calleeName),
        subtitle: Text(line.isOnHold ? "На удержании" : "Активный"),
        trailing: Row(children: [
          IconButton(icon: Icon(Icons.swap_calls), onTap: () => holdAndSwitch(line.roomName)),
          IconButton(icon: Icon(Icons.call_end), onTap: () => endLine(line.roomName)),
        ]),
      )).toList(),
    ),
  );
}
```

**Шаг 3: В VoiceCallScreen — индикатор held линий**
Показывать чип/баннер с количеством линий на hold и кнопкой переключения.

### Файлы для изменения
- `lib/core/services/call_state_service.dart` — добавить `calleeName` в `CallLine`
- `lib/features/dashboard/presentation/dashboard_screen.dart` — расширить баннер
- `lib/features/voice/presentation/screens/voice_call_screen.dart` — добавить UI переключения линий

### Приоритет: СРЕДНИЙ
### Оценка: 3-4 часа

---

## Баг 4: При hold собеседник слышит звук от того, кто поставил hold

### Проблема
`_toggleHold()` отключает свой микрофон (`setMicrophoneEnabled(false)`), но **не отключает приём аудио от собеседника**. Собеседник не слышит нас (микрофон выключен), но мы слышим его. А нужно наоборот — собеседник должен быть "отключён" от нашего аудио и слышать hold music.

На самом деле текущее поведение: при hold мы НЕ слышим собеседника? Нет — мы слышим, потому что remote audio tracks остаются подписанными. Hold music играет поверх.

### План исправления

**При нажатии Hold:**
1. Отключить свой микрофон ✓ (уже есть)
2. Отключить свою камеру ✓ (уже есть)
3. **Замутить входящий аудио** — unsubscribe от remote audio tracks ИЛИ поставить volume=0
4. Играть hold music локально ✓ (уже есть)

**При Resume:**
1. Включить микрофон ✓
2. Включить камеру ✓
3. **Размутить входящий аудио** — resubscribe к remote audio tracks
4. Остановить hold music ✓

### Реализация mute входящего аудио
```dart
// В _toggleHold():
// При hold:
for (final p in _room!.remoteParticipants.values) {
  for (final pub in p.audioTrackPublications) {
    try { pub.unsubscribe(); } catch (_) {}
  }
}

// При resume:
for (final p in _room!.remoteParticipants.values) {
  for (final pub in p.audioTrackPublications) {
    try { pub.subscribe(); } catch (_) {}
  }
}
```

### Файлы для изменения
- `lib/features/voice/presentation/screens/voice_call_screen.dart` — `_toggleHold()`

### Приоритет: ВЫСОКИЙ
### Оценка: 30 мин

---

## Баг 5: Кто на hold — должен слышать музыку Vivaldi

### Проблема
Сейчас hold music играет **у того, кто нажал hold** (локально). Нужно чтобы **собеседник** (которого поставили на hold) слышал музыку.

### Варианты реализации

**Вариант A: Серверный (рекомендуемый)**
LiveKit Server SDK позволяет публиковать аудиотреки в комнату через API. Бэкенд при получении сигнала "hold" может:
1. Получить event от клиента через REST или socket
2. Подключить "hold music bot" к комнате
3. Bot публикует audio track с Vivaldi

Плюсы: надёжно, не зависит от клиента
Минусы: требует изменения бэкенда

**Вариант B: Клиентский — публикация custom audio track**
LiveKit Flutter SDK поддерживает публикацию custom audio tracks:
```dart
// Создать LocalAudioTrack из файла/генератора
final track = await lk.LocalAudioTrack.create(
  lk.AudioCaptureOptions(source: customSource),
);
await _room!.localParticipant?.publishAudioTrack(track);
```
Но: `audioplayers` → LiveKit track — нет прямого пути. Нужно:
1. Декодировать MP3 в PCM
2. Создать custom `AudioSource` для LiveKit
3. Публиковать как audio track вместо микрофона

Плюсы: только клиент
Минусы: сложная реализация, качество может страдать

**Вариант C: Гибридный (серверный endpoint + клиентский trigger)**
1. Клиент вызывает `POST /voice/rooms/{roomName}/hold` при нажатии hold
2. Бэкенд подключает hold-music-agent к комнате (аналог livekit-ai-agent)
3. Hold music agent стримит Vivaldi.mp3 в комнату
4. При resume — клиент вызывает `POST /voice/rooms/{roomName}/resume`, бэкенд отключает hold-music-agent

### Рекомендация
**Вариант C** — самый чистый. Требует:
- Бэкенд: 2 новых endpoint'а + hold-music worker
- Клиент: вызов API при hold/resume

### Файлы для изменения
**Бэкенд (`~/taler-id/`):**
- `src/voice/voice.controller.ts` — добавить PUT /voice/rooms/:name/hold и /resume
- `src/voice/voice.service.ts` — логика подключения hold music agent
- Новый файл: hold-music-agent (Node.js + LiveKit Server SDK)

**Клиент:**
- `lib/features/voice/presentation/screens/voice_call_screen.dart` — вызов API при hold/resume
- `lib/features/voice/data/datasources/voice_remote_datasource.dart` — новые API методы

### Приоритет: СРЕДНИЙ
### Оценка: 4-6 часов (с бэкендом)

---

## Порядок реализации

1. **Баг 1** — Ассистент на iPhone (блокирует работу) — 2-3ч
2. **Баг 4** — Mute входящего аудио при hold — 30 мин
3. **Баг 2** — Разрешить новый звонок при held — 1-2ч
4. **Баг 3** — UI для нескольких линий — 3-4ч
5. **Баг 5** — Hold music для собеседника (Vivaldi) — 4-6ч

**Итого: ~11-16 часов**
