# Assistant Translator Mode Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a voice-activated live-translator mode to the Assistant screen. Two people speak different languages; the phone translates every utterance and stays in role until the owner says an explicit exit phrase.

**Architecture:** When the model calls `enter_translator_mode`, the app drops the WebSocket and opens a new one, sends a replacement `session.update` with a short strict translator-only prompt and a single `exit_translator_mode` tool. This isolates the model's context. On exit, same dance in reverse back to the normal prompt/tools. Language pair is auto-detected from Whisper transcriptions.

**Tech Stack:** Flutter (Dart), OpenAI Realtime API over WebSocket proxy (`/voice/realtime-proxy`), Whisper for transcription. All changes in one Dart file.

**Spec:** [docs/superpowers/specs/2026-04-22-assistant-translator-mode-design.md](../specs/2026-04-22-assistant-translator-mode-design.md)

**Branch:** `dev` (already checked out).

**Deploy:** DEV only. No backend changes.

---

## File Structure

**Single file changes:**
- `lib/features/assistant/presentation/screens/assistant_screen.dart` (~2762 lines today)

The spec limits scope to one file on purpose. The file is large, but all mode-switching concerns are local to this screen. Splitting into new files (e.g. `translator_prompt.dart`) would be premature until a second consumer needs the prompt.

## Background: existing code landmarks

For reference while editing:

| Symbol | Lines |
|---|---|
| `_cleanup()` | 217-227 |
| `_connect()` | 236-294 |
| `_systemPrompt(locale)` | 296-511 (ru: 301-390, en: 393-510) |
| `_onChannelOpen()` | 513-1038 (session.update: 517-1002, briefing inject: 1004-1037) |
| `_sendEvent()` | 1059-1061 |
| `_appendTranscript()` | 1064-1075 |
| `_replaceTranscript()` | 1078-1089 |
| `_onMessage()` | 1103-1149 |
| `_handleFunctionCall()` | 1248-1728 |
| `_buildConnected()` / transcript render | 2187-2243 |
| `_TranscriptMessage` class | 2752-2762 |

Expect line numbers to shift as tasks progress — navigate by symbol/regex, not by exact line.

---

## Task 1: State & transcript model extensions

**Files:**
- Modify: `lib/features/assistant/presentation/screens/assistant_screen.dart`

- [ ] **Step 1: Add `_AssistantMode` enum**

Right next to the existing `_CallState` enum (near line 28), add:

```dart
enum _AssistantMode { normal, translator }
```

- [ ] **Step 2: Add state fields in `_AssistantScreenState`**

Just after `_CallState _state = _CallState.idle;` (near line 46), add:

```dart
_AssistantMode _mode = _AssistantMode.normal;
String? _langA;  // ISO code of first detected language in translator mode
String? _langB;  // ISO code of second detected language (≠ _langA)
bool _switchingMode = false;  // true during WebSocket reconnect for mode switch
```

- [ ] **Step 3: Extend `_TranscriptMessage` class (near line 2752)**

Replace the entire class body with:

```dart
class _TranscriptMessage {
  final String role;          // 'user' or 'assistant'
  final String text;
  final String? itemId;
  final String? originalLang; // ISO code, set for user items in translator mode
  final String? pairedItemId; // itemId of assistant translation that pairs with this user item
  const _TranscriptMessage({
    required this.role,
    required this.text,
    this.itemId,
    this.originalLang,
    this.pairedItemId,
  });
  _TranscriptMessage copyWith({
    String? text,
    String? originalLang,
    String? pairedItemId,
  }) =>
      _TranscriptMessage(
        role: role,
        text: text ?? this.text,
        itemId: itemId,
        originalLang: originalLang ?? this.originalLang,
        pairedItemId: pairedItemId ?? this.pairedItemId,
      );
}
```

- [ ] **Step 4: Verify compile**

Run: `cd /Users/dmitry/Downloads/taler_id_mobile && flutter analyze lib/features/assistant/presentation/screens/assistant_screen.dart`

Expected: `No issues found!` — we haven't used the new fields yet so nothing should break. If there's a warning about unused fields/enum values, ignore it (they'll be used in later tasks).

- [ ] **Step 5: Commit**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile
git add lib/features/assistant/presentation/screens/assistant_screen.dart
git commit -m "feat(assistant): scaffold translator-mode state and transcript fields

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: Translator prompt + activation text in normal prompts

**Files:**
- Modify: `lib/features/assistant/presentation/screens/assistant_screen.dart` (inside `_systemPrompt()`, add new static method `_translatorPrompt()`)

- [ ] **Step 1: Add `_translatorPrompt()` static method**

Just after the `_systemPrompt(String locale)` method closing brace (near line 511, before `void _onChannelOpen()`), add:

```dart
static String _translatorPrompt() {
  return 'YOU ARE A LIVE TRANSLATION MACHINE. NOT AN ASSISTANT. NOT A CHATBOT.\n\n'
      'Two people are speaking different languages. The phone is on the table '
      'between them. Your ONLY job: translate every utterance from one language '
      'into the other, in real time.\n\n'
      'RULES (violating these breaks the product — do NOT violate):\n\n'
      '1. Auto-detect the two languages from the first 1-2 utterances. Once '
      'detected, stick with them. Do not translate into a third language '
      'even if someone briefly uses it.\n\n'
      '2. Translate EVERY utterance. No exceptions. No commentary. No summary. '
      'No "the speaker said...". Just the translation, as if you were the '
      'speaker in the other language.\n\n'
      '3. You are INVISIBLE. You do NOT exist in this conversation. Do NOT:\n'
      '   - answer questions directed at you\n'
      '   - offer help, suggestions, opinions, explanations\n'
      '   - ask clarifying questions\n'
      '   - say "I am translating" or "got it" or any filler\n'
      '   - react to greetings, jokes, insults, compliments — translate them\n'
      '   - call any tool except exit_translator_mode\n\n'
      '4. If someone says "what do you think?", "can you translate?", '
      '"assistant, explain that" — these are NOT directed at you. They are '
      'part of the conversation. TRANSLATE THEM. Do not respond.\n\n'
      '5. If the audio is silence, background noise, or unintelligible — '
      'output NOTHING. Do not say "I didn\'t catch that". Just wait.\n\n'
      '6. ONE EXCEPTION — the owner\'s exit phrase. If and ONLY if you hear '
      'ANY of these exact phrases spoken clearly:\n'
      '   - "Ассистент, стоп"\n'
      '   - "выйди из роли"\n'
      '   - "хватит переводить"\n'
      '   - "stop translator"\n'
      '   - "exit translator"\n'
      '   → call exit_translator_mode(). Do not translate that phrase. Do not '
      'say anything. Just call the tool.\n\n'
      '7. Output language: translate A→B and B→A. Never output in the source '
      'language. Never output both languages at once.\n\n'
      '8. Tone: match the speaker. Formal → formal. Casual → casual. Rude → rude. '
      'Keep names, numbers, places exact.\n\n'
      'You have exactly one tool: exit_translator_mode. Use it ONLY on the '
      'exit phrases above. Never call it otherwise.\n\n'
      'Begin listening. Say nothing until someone speaks.';
}
```

- [ ] **Step 2: Add activation section to ru branch of `_systemPrompt`**

Find the block in `_systemPrompt` (around line 341-344):

```dart
          'ПЕРЕКЛЮЧЕНИЕ РЕЖИМОВ:\n'
          '- При входе в режим — подтверди голосом какой режим активирован\n'
          '- "Сменить роль" / "выйди из роли" / "хватит" → вернись в обычный режим ассистента\n'
          '- Если пользователь просит что-то из основного режима (профиль, KYC) — спроси, хочет ли он выйти из текущего режима\n\n'
```

Insert BEFORE it (right after the "СОБЕСЕДНИК" mode block, which ends at line 340):

```dart
          'РЕЖИМ "ПЕРЕВОДЧИК":\n'
          'Активируется если пользователь говорит "включи переводчика", "режим переводчика", "translator mode", "переводи нам", "переведи нас" и т.п.\n'
          'В этом режиме телефон лежит между двумя людьми, говорящими на разных языках, и переводит их речь.\n'
          '→ Вызови tool enter_translator_mode. Ничего не говори — просто вызови tool.\n\n'
```

- [ ] **Step 3: Add activation section to en branch of `_systemPrompt`**

Find the corresponding block in the en branch (around line 434-438):

```dart
        'MODE SWITCHING:\n'
        '- When entering a mode — confirm by voice which mode is activated\n'
        '- "Switch role" / "exit role" / "enough" → return to normal assistant mode\n'
        '- If the user asks for something from the main mode (profile, KYC) — ask if they want to exit current mode\n\n'
```

Insert BEFORE it (right after the "CASUAL CHAT" mode block which ends around line 434):

```dart
        '"TRANSLATOR" MODE:\n'
        'Activated when the user says "turn on translator", "translator mode", "включи переводчика", "translate for us", etc.\n'
        'In this mode the phone sits between two people speaking different languages and translates their speech.\n'
        '→ Call tool enter_translator_mode. Do not say anything — just call the tool.\n\n'
```

- [ ] **Step 4: Verify compile**

Run: `cd /Users/dmitry/Downloads/taler_id_mobile && flutter analyze lib/features/assistant/presentation/screens/assistant_screen.dart`

Expected: `No issues found!` (or only pre-existing warnings — nothing new from our changes).

- [ ] **Step 5: Commit**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile
git add lib/features/assistant/presentation/screens/assistant_screen.dart
git commit -m "feat(assistant): translator mode prompt and activation text

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: Translator-mode session config + `enter_translator_mode` in normal tools

**Why:** `_onChannelOpen` currently sends a large inline `session.update` for normal mode. We **do not** rewrite that — we leave the normal path intact. We add a small helper that builds the *translator* session map (will be called during mode switch), and we add one tool (`enter_translator_mode`) into the existing normal-mode inline tools array.

**Files:**
- Modify: `lib/features/assistant/presentation/screens/assistant_screen.dart`

- [ ] **Step 1: Add `enter_translator_mode` tool to the existing inline normal-mode tools**

Inside `_onChannelOpen`, find the inline `'tools': [` array (starts around line 535). The first tool in the array is currently `end_session`. Insert a new tool entry **at the top** of that array (right after `'tools': [`, before the `end_session` entry):

```dart
          {
            'type': 'function',
            'name': 'enter_translator_mode',
            'description':
                'Enter live translator mode between two people speaking different languages. Call when user says "включи переводчика", "translator mode", "переводи нам", etc.',
            'parameters': {'type': 'object', 'properties': {}},
          },
```

This is the only change inside the big `tools` array. Do not touch anything else in `_onChannelOpen` in this step.

- [ ] **Step 2: Add `_translatorSessionConfig()` helper**

Add this method right before `void _onChannelOpen()` (just after `_translatorPrompt()`, near line 511):

```dart
Map<String, dynamic> _translatorSessionConfig() {
  return {
    'modalities': ['text', 'audio'],
    'instructions': _translatorPrompt(),
    'voice': 'alloy',
    'input_audio_format': 'pcm16',
    'output_audio_format': 'pcm16',
    // No language pin — we want Whisper to auto-detect each speaker.
    'input_audio_transcription': {'model': 'whisper-1'},
    'turn_detection': {
      'type': 'server_vad',
      'threshold': 0.6,
      'prefix_padding_ms': 300,
      'silence_duration_ms': 700,
      'create_response': true,
    },
    'tools': [
      {
        'type': 'function',
        'name': 'exit_translator_mode',
        'description':
            'Exit translator mode. Call ONLY when you hear one of the exit phrases listed in your instructions. Never call otherwise.',
        'parameters': {'type': 'object', 'properties': {}},
      },
    ],
    'tool_choice': 'auto',
  };
}
```

- [ ] **Step 3: Teach `_onChannelOpen` to branch by mode**

At the top of `_onChannelOpen` (line 513), replace:

```dart
void _onChannelOpen() {
  if (_sessionConfigured) return;
  _sessionConfigured = true;
  final locale = Localizations.localeOf(context).languageCode;
  _sendEvent({
    'type': 'session.update',
    'session': {
      // ... existing big inline map ...
    },
  });

  // Auto-briefing on session start: greet briefly, then check for unread/missed
  final briefingPrompt = locale == 'ru' ...
  ...
  _sendEvent({'type': 'response.create'});
}
```

with:

```dart
void _onChannelOpen() {
  if (_sessionConfigured) return;
  _sessionConfigured = true;
  final locale = Localizations.localeOf(context).languageCode;

  // Translator mode — send the minimal translator session and return.
  // No briefing prompt: translator must stay silent until someone speaks.
  if (_mode == _AssistantMode.translator) {
    _sendEvent({
      'type': 'session.update',
      'session': _translatorSessionConfig(),
    });
    return;
  }

  // Normal mode — keep the existing large inline session.update payload AS IS.
  _sendEvent({
    'type': 'session.update',
    'session': {
      // ... keep the ENTIRE existing inline map unchanged, including the modified tools
      //     array from Step 1 (which now has enter_translator_mode at the top) ...
    },
  });

  // Auto-briefing on session start: greet briefly, then check for unread/missed
  final briefingPrompt = locale == 'ru' ...
  ...
  _sendEvent({'type': 'response.create'});
}
```

**Do not** rewrite the existing normal-mode session map or the briefing block. The only two surgical edits in this step are:
1. Add the `if (_mode == _AssistantMode.translator) { ... return; }` block at the top of the method (right after the locale line).
2. Leave everything else in the method intact.

- [ ] **Step 4: Verify compile**

Run: `cd /Users/dmitry/Downloads/taler_id_mobile && flutter analyze lib/features/assistant/presentation/screens/assistant_screen.dart`

Expected: `No issues found!`. The new methods (`_translatorPrompt`, `_translatorSessionConfig`) are unused outside the same file at this point — since they're called from `_onChannelOpen`, they are used and should not trigger `unused_element`.

- [ ] **Step 5: Smoke-test normal mode**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile
flutter run --flavor dev -t lib/main_dev.dart --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol -d emulator-5554
```

Open Assistant tab → tap connect → say "Привет". Expected: normal assistant greets back and the briefing kicks in as before. This checks the branch didn't break normal mode.

- [ ] **Step 6: Commit**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile
git add lib/features/assistant/presentation/screens/assistant_screen.dart
git commit -m "feat(assistant): translator session config + enter tool in normal mode

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 4: Mode switch reconnect

**Files:**
- Modify: `lib/features/assistant/presentation/screens/assistant_screen.dart`

- [ ] **Step 1: Guard existing `_connect()` onDone against mode-switch triggered closures**

In `_connect()` (line 236), find the WebSocket listener `onDone`:

```dart
        onDone: () {
          if (mounted && _state == _CallState.connected && !_navigatingToCall) _endCall();
        },
```

Replace with:

```dart
        onDone: () {
          // During mode switch we intentionally close the old WebSocket — don't end the session.
          if (mounted && _state == _CallState.connected && !_navigatingToCall && !_switchingMode) _endCall();
        },
```

Without this guard, closing the WebSocket inside `_switchMode` would fire the old listener's `onDone` and call `_endCall`, which resets `_state` to idle and breaks the mode switch.

- [ ] **Step 2: Add `_switchMode(_AssistantMode target)` method**

Add this method just after `_onChannelOpen`, near line 1040 (after the briefing block):

```dart
Future<void> _switchMode(_AssistantMode target) async {
  if (!mounted) return;
  if (_switchingMode) return; // guard against double triggers
  debugPrint('[Assistant] switchMode $_mode → $target');

  setState(() {
    _switchingMode = true;
    _aiSpeaking = false;
    _mode = target;
    if (target == _AssistantMode.translator) {
      _langA = null;
      _langB = null;
    }
  });

  // Stop audio and recording cleanly
  await _player.stop();
  _audioBuffer.clear();
  await _recordSub?.cancel();
  _recordSub = null;
  try { await _recorder.stop(); } catch (_) {}

  // Close current WebSocket
  await _ws?.close();
  _ws = null;
  _sessionConfigured = false;

  // Reopen new WebSocket + configure for target mode
  try {
    final token = await sl<SecureStorageService>().getAccessToken();
    if (token == null) throw Exception('Not authenticated');
    final wsUrl = Uri(
      scheme: 'wss',
      host: Uri.parse(ApiConstants.baseUrl).host,
      path: '/voice/realtime-proxy',
      queryParameters: {'token': token},
    ).toString();
    _ws = await WebSocket.connect(wsUrl);
    _ws!.listen(
      (data) => _onMessage(data as String),
      onDone: () {
        // Same guard as in _connect — ignore close events triggered by mode switch.
        if (mounted && _state == _CallState.connected && !_navigatingToCall && !_switchingMode) _endCall();
      },
      onError: (e) {
        if (mounted) {
          setState(() {
            _state = _CallState.error;
            _errorMessage = e.toString();
          });
        }
      },
    );
    _onChannelOpen(); // uses _mode internally
    await _startRecording();
  } catch (e) {
    debugPrint('[Assistant] switchMode failed: $e');
    if (mounted) {
      setState(() {
        _state = _CallState.error;
        _errorMessage = e.toString();
      });
    }
  } finally {
    if (mounted) setState(() => _switchingMode = false);
  }
}
```

- [ ] **Step 3: Verify compile**

Run: `cd /Users/dmitry/Downloads/taler_id_mobile && flutter analyze lib/features/assistant/presentation/screens/assistant_screen.dart`

Expected: `No issues found!`. The method is unused as of this task — dart analyzer may warn `unused_element`. If so: that's fine, it'll be called in the next task. If it errors, fix before moving on.

- [ ] **Step 4: Commit**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile
git add lib/features/assistant/presentation/screens/assistant_screen.dart
git commit -m "feat(assistant): mode-switch reconnect method

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 5: Handle `enter_translator_mode` / `exit_translator_mode` tool calls

**Files:**
- Modify: `lib/features/assistant/presentation/screens/assistant_screen.dart` (inside `_handleFunctionCall`, near line 1253)

- [ ] **Step 1: Add branches at the top of `_handleFunctionCall`**

Inside `_handleFunctionCall`, right after the try { and before the existing `if (name == 'end_session')` branch (around line 1253), insert:

```dart
    // Translator mode switches — handled specially.
    // We do NOT send function_call_output because we're about to drop the WebSocket;
    // the call id becomes moot in the new session.
    if (name == 'enter_translator_mode') {
      debugPrint('[Assistant] tool enter_translator_mode (callId=$callId)');
      // Fire-and-forget: schedule the switch without awaiting inside the handler.
      Future.microtask(() => _switchMode(_AssistantMode.translator));
      return;
    }
    if (name == 'exit_translator_mode') {
      debugPrint('[Assistant] tool exit_translator_mode (callId=$callId)');
      Future.microtask(() => _switchMode(_AssistantMode.normal));
      return;
    }
```

The `return;` before the `else if` cascade prevents the default path at the end (`_sendEvent({'type': 'conversation.item.create', 'item': {...function_call_output...}})`) from firing for these two tools.

- [ ] **Step 2: Verify compile**

Run: `cd /Users/dmitry/Downloads/taler_id_mobile && flutter analyze lib/features/assistant/presentation/screens/assistant_screen.dart`

Expected: `No issues found!`.

- [ ] **Step 3: Manual smoke test**

Run app on emulator:

```bash
cd /Users/dmitry/Downloads/taler_id_mobile
flutter run --flavor dev -t lib/main_dev.dart --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol -d emulator-5554
```

Open Assistant → connect → say **"включи переводчика"**. Expected in logs (flutter run console): `[Assistant] tool enter_translator_mode ...` followed by `[Assistant] switchMode normal → translator`. Microphone should stay alive.

Say a short Russian phrase like "Привет, как дела?". Expected: model responds with translated text+audio (assuming model picked English as second language; this is OK at this stage even if the translation goes into an unexpected language, we're just checking the mode switch fires).

Say **"Ассистент, стоп"**. Expected: `[Assistant] tool exit_translator_mode` → `switchMode translator → normal` → next utterances go through normal assistant again.

- [ ] **Step 4: Commit**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile
git add lib/features/assistant/presentation/screens/assistant_screen.dart
git commit -m "feat(assistant): wire enter/exit translator mode tool calls to reconnect

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 6: Language detection from Whisper transcriptions

**Files:**
- Modify: `lib/features/assistant/presentation/screens/assistant_screen.dart` (inside `_onMessage`, `conversation.item.input_audio_transcription.completed` branch, near line 1125)

- [ ] **Step 1: Update the transcription-completed handler**

Replace the current branch (lines 1125-1130):

```dart
      } else if (type == 'conversation.item.input_audio_transcription.completed') {
        // User speech transcript (after whisper finishes)
        final transcript = event['transcript'] as String? ?? '';
        final itemId = event['item_id'] as String? ?? '';
        debugPrint('[Assistant] user.done item=$itemId text=$transcript');
        if (transcript.isNotEmpty) _replaceTranscript('user', transcript, 'user:$itemId');
```

with:

```dart
      } else if (type == 'conversation.item.input_audio_transcription.completed') {
        // User speech transcript (after whisper finishes)
        final transcript = event['transcript'] as String? ?? '';
        final itemId = event['item_id'] as String? ?? '';
        final lang = event['language'] as String?; // Whisper returns ISO code (e.g. 'ru', 'de')
        debugPrint('[Assistant] user.done item=$itemId lang=$lang text=$transcript');
        if (transcript.isNotEmpty) {
          _replaceTranscript('user', transcript, 'user:$itemId', originalLang: lang);
          if (_mode == _AssistantMode.translator) _updateLanguagePair(lang);
        }
      }
```

- [ ] **Step 2: Update `_replaceTranscript` to accept `originalLang`**

Replace the existing `_replaceTranscript` method (lines 1078-1089) with:

```dart
void _replaceTranscript(String role, String text, String itemId, {String? originalLang}) {
  if (!mounted) return;
  setState(() {
    final idx = _transcript.indexWhere((m) => m.itemId == itemId && m.role == role);
    if (idx >= 0) {
      _transcript[idx] = _transcript[idx].copyWith(text: text, originalLang: originalLang);
    } else {
      _transcript.add(_TranscriptMessage(
        role: role,
        text: text,
        itemId: itemId,
        originalLang: originalLang,
      ));
    }
  });
  _scrollTranscriptToBottom();
}
```

(The second positional-args call site at line 1130 already passes 3 args; now we add a named `originalLang`. Existing AI-side callsite at line 1124 doesn't pass it — fine.)

- [ ] **Step 3: Add `_updateLanguagePair` method**

Add this helper just above `_scrollTranscriptToBottom` (near line 1091):

```dart
void _updateLanguagePair(String? lang) {
  if (lang == null || lang.isEmpty) return;
  if (_langA == null) {
    setState(() => _langA = lang);
    return;
  }
  if (_langB == null && lang != _langA) {
    setState(() => _langB = lang);
  }
}
```

- [ ] **Step 4: Verify compile**

Run: `cd /Users/dmitry/Downloads/taler_id_mobile && flutter analyze lib/features/assistant/presentation/screens/assistant_screen.dart`

Expected: `No issues found!`.

- [ ] **Step 5: Commit**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile
git add lib/features/assistant/presentation/screens/assistant_screen.dart
git commit -m "feat(assistant): detect language pair from Whisper in translator mode

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 7: Pair user items with assistant responses

**Files:**
- Modify: `lib/features/assistant/presentation/screens/assistant_screen.dart` (inside `_onMessage`, `response.done` branch, near line 1133)

- [ ] **Step 1: Track the last assistant item in a response**

We need the `item_id` of the first assistant item in each response. The `response.done` event carries `response.output[].id` values. Simplest approach: when `response.audio_transcript.done` fires (line 1120), store the `itemId` in a new field `_lastAssistantItemId`. Then on `response.done`, pair it.

Add a field (next to `_pendingCallId` near line 86):

```dart
String? _lastAssistantItemId;  // most recent assistant item id, used for translator-mode pairing
```

- [ ] **Step 2: Capture the itemId in the AI-transcript branch**

Modify the existing `response.audio_transcript.done` branch (lines 1120-1124):

```dart
      } else if (type == 'response.audio_transcript.done') {
        final transcript = event['transcript'] as String? ?? '';
        final itemId = event['item_id'] as String? ?? '';
        debugPrint('[Assistant] ai.done item=$itemId text=$transcript');
        if (transcript.isNotEmpty) _replaceTranscript('assistant', transcript, 'ai:$itemId');
        if (itemId.isNotEmpty) _lastAssistantItemId = 'ai:$itemId';
```

- [ ] **Step 3: Pair in the `response.done` branch**

Modify the existing `response.done` branch (lines 1133-1134):

```dart
      } else if (type == 'response.done') {
        if (_audioBuffer.isNotEmpty) _playBufferedAudio();
        if (_mode == _AssistantMode.translator && _lastAssistantItemId != null) {
          _pairLastUserWithAssistant(_lastAssistantItemId!);
        }
        _lastAssistantItemId = null;
```

- [ ] **Step 4: Add `_pairLastUserWithAssistant` method**

Add next to `_updateLanguagePair` (near line 1091):

```dart
void _pairLastUserWithAssistant(String assistantItemId) {
  if (!mounted) return;
  setState(() {
    // Find the most recent user message without a pair, walking backwards.
    for (int i = _transcript.length - 1; i >= 0; i--) {
      final m = _transcript[i];
      if (m.role == 'user' && m.pairedItemId == null) {
        _transcript[i] = m.copyWith(pairedItemId: assistantItemId);
        break;
      }
    }
  });
}
```

- [ ] **Step 5: Verify compile**

Run: `cd /Users/dmitry/Downloads/taler_id_mobile && flutter analyze lib/features/assistant/presentation/screens/assistant_screen.dart`

Expected: `No issues found!`.

- [ ] **Step 6: Commit**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile
git add lib/features/assistant/presentation/screens/assistant_screen.dart
git commit -m "feat(assistant): pair user transcripts with translator responses

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 8: Translator-mode badge widget

**Files:**
- Modify: `lib/features/assistant/presentation/screens/assistant_screen.dart` (inside `_buildConnected`, near line 2194)

- [ ] **Step 1: Add a language-flag helper**

Add this static helper inside `_AssistantScreenState` (near the top of helpers, above `_buildConnected` — for instance right after `_toggleSpeaker` near line 1744):

```dart
static const Map<String, String> _langFlagMap = {
  'ru': '🇷🇺',
  'en': '🇬🇧',
  'de': '🇩🇪',
  'es': '🇪🇸',
  'fr': '🇫🇷',
  'it': '🇮🇹',
  'pt': '🇵🇹',
  'zh': '🇨🇳',
  'ja': '🇯🇵',
  'ko': '🇰🇷',
  'ar': '🇸🇦',
  'tr': '🇹🇷',
  'uk': '🇺🇦',
  'pl': '🇵🇱',
};

String _langDisplay(String? code) {
  if (code == null || code.isEmpty) return '';
  return _langFlagMap[code] ?? code.toUpperCase();
}
```

- [ ] **Step 2: Build the badge widget**

Add this method right after `_langDisplay`:

```dart
Widget _buildTranslatorBadge(BuildContext context) {
  final colors = AppColors.of(context);
  final locale = Localizations.localeOf(context).languageCode;
  final title = locale == 'ru' ? 'Переводчик' : 'Translator';
  final detecting = locale == 'ru' ? 'определяю языки…' : 'detecting languages…';

  final hasPair = _langA != null && _langB != null;
  final right = hasPair
      ? '${_langDisplay(_langA)} ⇄ ${_langDisplay(_langB)}'
      : detecting;

  return Container(
    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: colors.primary.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: colors.primary.withValues(alpha: 0.4)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🌐', style: TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            color: colors.primary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        Text('·', style: TextStyle(color: colors.primary)),
        const SizedBox(width: 6),
        Text(
          right,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 3: Render badge in `_buildConnected`**

Inside `_buildConnected` (line 2187), at the very top of the `Column` children list (before the `Expanded` that holds the transcript at line 2194):

```dart
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      if (_mode == _AssistantMode.translator)
        Align(
          alignment: Alignment.center,
          child: _buildTranslatorBadge(context),
        ),
      // Full-screen transcript
      Expanded(
        ...
```

- [ ] **Step 4: Verify compile**

Run: `cd /Users/dmitry/Downloads/taler_id_mobile && flutter analyze lib/features/assistant/presentation/screens/assistant_screen.dart`

Expected: `No issues found!`.

- [ ] **Step 5: Visual check**

Emulator test: enter translator mode as in Task 5's smoke test. Expected: badge appears at top of the screen saying `🌐 Переводчик · определяю языки…` (ru locale) or the English equivalent. After one Russian utterance the badge updates to `🌐 Переводчик · 🇷🇺` — after the model's German reply is transcribed, ideally Whisper picks up the German in subsequent user turns. If the second language doesn't appear after 2-3 turns, that's acceptable for v1 (depends on Whisper).

- [ ] **Step 6: Commit**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile
git add lib/features/assistant/presentation/screens/assistant_screen.dart
git commit -m "feat(assistant): translator mode badge with detected language pair

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 9: Paired-card transcript rendering in translator mode

**Files:**
- Modify: `lib/features/assistant/presentation/screens/assistant_screen.dart` (inside `_buildConnected`'s `ListView.builder`, lines 2214-2242)

- [ ] **Step 1: Compute render items in translator mode**

In translator mode, we need to skip assistant items that are already paired with a user item (they will be rendered inside that user's card). Build the list of render entries before `ListView.builder`.

Inside `_buildConnected`, just above the `child: ListView.builder(...)` (around line 2214), add:

```dart
final isTranslator = _mode == _AssistantMode.translator;
// In translator mode, we show one card per user item (with its paired translation).
// Skip assistant items that are already paired — they get rendered inside their user card.
final pairedAssistantIds = isTranslator
    ? _transcript
        .where((m) => m.role == 'user' && m.pairedItemId != null)
        .map((m) => m.pairedItemId!)
        .toSet()
    : const <String>{};
final renderItems = isTranslator
    ? _transcript
        .where((m) =>
            m.role == 'user' ||
            (m.role == 'assistant' &&
                m.itemId != null &&
                !pairedAssistantIds.contains(m.itemId)))
        .toList()
    : _transcript;
```

- [ ] **Step 2: Replace `ListView.builder` itemCount and itemBuilder**

Replace the existing builder:

```dart
child: ListView.builder(
  controller: _transcriptCtrl,
  padding: const EdgeInsets.symmetric(vertical: 4),
  itemCount: _transcript.length,
  itemBuilder: (_, i) {
    final m = _transcript[i];
    final isUser = m.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? colors.primary.withValues(alpha: 0.15) : colors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: LinkifiedText(
          text: m.text,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  },
),
```

with:

```dart
child: ListView.builder(
  controller: _transcriptCtrl,
  padding: const EdgeInsets.symmetric(vertical: 4),
  itemCount: renderItems.length,
  itemBuilder: (_, i) {
    final m = renderItems[i];
    final isUser = m.role == 'user';

    if (isTranslator && isUser) {
      // Paired card: user original + translation below.
      final paired = m.pairedItemId != null
          ? _transcript.firstWhere(
              (x) => x.itemId == m.pairedItemId,
              orElse: () => const _TranscriptMessage(role: 'assistant', text: ''),
            )
          : const _TranscriptMessage(role: 'assistant', text: '');
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colors.card.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    _langDisplay(m.originalLang),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                Expanded(
                  child: LinkifiedText(
                    text: m.text,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            if (paired.text.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      // The translation's language is "the other one".
                      _langDisplay(_otherLang(m.originalLang)),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  Expanded(
                    child: LinkifiedText(
                      text: paired.text,
                      style: TextStyle(
                        color: colors.textPrimary.withValues(alpha: 0.85),
                        fontSize: 14,
                        height: 1.4,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    }

    // Normal-mode card (or orphan assistant card in translator mode).
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? colors.primary.withValues(alpha: 0.15) : colors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: LinkifiedText(
          text: m.text,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  },
),
```

- [ ] **Step 3: Add `_otherLang` helper**

Add next to `_langDisplay` (same area):

```dart
String? _otherLang(String? currentLang) {
  if (currentLang == null) return null;
  if (currentLang == _langA) return _langB;
  if (currentLang == _langB) return _langA;
  // Fallback — return whichever we have that isn't the current.
  return _langA == currentLang ? _langB : _langA;
}
```

- [ ] **Step 4: Verify compile**

Run: `cd /Users/dmitry/Downloads/taler_id_mobile && flutter analyze lib/features/assistant/presentation/screens/assistant_screen.dart`

Expected: `No issues found!`.

- [ ] **Step 5: Visual check on emulator**

Enter translator mode and run through scenarios 1-3 from the spec checklist. Verify paired cards render with flags on left and translation below.

- [ ] **Step 6: Commit**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile
git add lib/features/assistant/presentation/screens/assistant_screen.dart
git commit -m "feat(assistant): paired card rendering for translator transcript

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Task 10: Manual test checklist (pre-deploy)

- [ ] **Step 1: Run Flutter unit tests**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && flutter test
```

Expected: all pass (no changes to test suite).

- [ ] **Step 2: Run existing integration test on emulator**

```bash
# Launch emulator if not running
flutter emulators --launch Pixel_XL_API_33
# wait ~15 sec
~/Library/Android/sdk/platform-tools/adb devices
```

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && flutter test integration_test/app_test.dart --flavor dev --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol -d emulator-5554
```

Expected: pass. This checks nothing in Assistant regressed.

- [ ] **Step 3: Run backend API smoke tests**

```bash
cd ~/Downloads/taler_id_tests && npm test
```

Expected: 29/29 pass. Backend unchanged, but runs per procedure.

- [ ] **Step 4: Run voice and assistant tests on DEV**

```bash
cd ~/Downloads/taler_id_tests && npm run test:voice && npm run test:assistant && npm run test:files
```

Expected: all pass (voice 10/10, assistant 8/8, files 12/12).

- [ ] **Step 5: Manual translator-mode checklist on emulator**

Run `flutter run` in dev flavor on `emulator-5554`. Walk through the 10 scenarios from the spec section "Manual test checklist":

| # | Scenario | Expected |
|---|---|---|
| 1 | Normal → "включи переводчика" | Badge appears; `exit_translator_mode` not fired |
| 2 | Speak in Russian | Paired card with 🇷🇺 original and translation below |
| 3 | Speak in German | Paired card with 🇩🇪 original and translation below |
| 4 | Ask "ты умеешь переводить?" inside translator | Translated as utterance, not answered |
| 5 | Say "что ты думаешь об этом?" | Translated, not answered |
| 6 | Say "Ассистент, стоп" | Badge gone, normal mode, profile tools work again |
| 7 | Normal → translator → normal → translator (2x) | Works without artifacts |
| 8 | 15s silence in translator | Assistant stays silent, stays in role |
| 9 | Profanity in one language | Translated without censorship |
| 10 | "Позвони Андрею" inside translator | Translated, no call started |

Any failure → fix before deploy.

- [ ] **Step 6: Push to `origin/dev`**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile
git push origin dev
```

- [ ] **Step 7: Build dev APK on build-server**

Per CLAUDE.md:

```bash
ssh dvolkov@138.124.61.221
cd ~/taler_id_mobile && git checkout dev && git pull
flutter build apk --flavor dev --release -t lib/main_dev.dart --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol
cp build/app/outputs/flutter-apk/app-dev-release.apk /var/www/downloads/taler-id-dev.apk
```

Public URL: https://id.taler.tirol/download/taler-id-dev.apk

- [ ] **Step 8: Do NOT deploy to PROD**

Per CLAUDE.md rule: only deploy to PROD on explicit user instruction. Stop here and report that dev APK is live; wait for user to approve PROD deploy.

---

## Notes for the implementer

- **No backend changes.** Do not touch `~/taler-id/` or any NestJS code.
- **All work on branch `dev`.** Never commit to `main`.
- **If the model still drifts out of role** during scenario 4 or 5 in Task 10 manual testing: the spec's fallback (disable `create_response: true`, manual `response.create` per turn) is the escalation. That's a plan revision conversation, not something to patch into this implementation.
- **If Whisper doesn't return `language` field** in the Realtime event: the badge will stay on "detecting…" indefinitely. Graceful — translation still works. Not a blocker.
- **If `_switchMode` fails to reconnect** (network blip): the screen ends up in `_state == error`. User taps "reconnect". Acceptable.
