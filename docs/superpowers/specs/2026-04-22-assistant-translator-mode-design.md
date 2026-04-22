# Assistant Translator Mode — Design

**Date:** 2026-04-22
**Scope:** Mobile app only (`taler_id_mobile`, branch `dev`). Backend unchanged.
**Status:** Approved, ready for plan.

## Problem

Two people meet offline, speak different languages, and want to use the phone's Assistant as a real-time translator between them — phone lies on the table between them. The Assistant must translate every utterance in both directions and stay in that role until the phone owner explicitly exits.

Existing Assistant already has "modes" (coach, psychologist, HR, chat). But these modes drift — the model keeps breaking out of role, answering as an assistant when it was supposed to stay in character. A translator mode built the same way would have the same problem, but worse: the whole point is that the model must NOT respond to anything.

## Goals

1. Voice-activated translator mode inside the existing Assistant screen.
2. Auto-detect the language pair from the first utterances.
3. Translate every utterance (A→B, B→A), with zero commentary.
4. Stay in role until the owner says an explicit exit phrase — and only then.
5. Show both original and translation in the transcript.

## Non-goals (out of scope for v1)

- Manual language selection (auto-detect only).
- Persistence of translation history (ephemeral, same as other modes).
- Dedicated UI button / modal for activation (voice only).
- 3+ participants simultaneously.
- Offline translation.

## Approach: isolated session reconfigure

When translator mode is entered, the app issues a **new `session.update`** with a completely replaced short/strict instruction prompt and a minimal tool set (one tool: `exit_translator_mode`). To prevent the previous normal-mode context from leaking into model behavior, the app **drops the WebSocket and opens a new one** before issuing the new `session.update`. On exit, same thing in reverse: reconnect with the original normal-mode prompt.

This isolates the model from the temptation of its other capabilities. Key rationale: the existing "role drift" problem stems from a long prompt where the model knows it has many tools and many modes. Minimizing the prompt and the tool surface minimizes drift.

### Why not a single prompt with a translator section?

Tried conceptually. The existing coach/psychologist/HR modes already drift this way, and their rules are softer ("don't give advice" → model still occasionally gives advice). Translator rules are absolute ("translate everything, respond to nothing"), so a drifting model destroys the product.

### Why reconnect vs. just `session.update`?

OpenAI Realtime keeps prior conversation items when instructions change. The model can still see "earlier I was helping with the profile" and drift back. Clean reconnect = clean slate. Cost: ~1-2s pause on mode switch, imperceptible since the user is speaking the activation command anyway.

## Architecture

### State (Flutter, in `_AssistantScreenState`)

```dart
enum _AssistantMode { normal, translator }

_AssistantMode _mode = _AssistantMode.normal;
String? _langA; // ISO code auto-detected from first utterance
String? _langB; // ISO code auto-detected from second utterance with different lang
```

### State-flow

```
[normal mode, connected, full system prompt sent]
        │
        │  user: "включи переводчика"
        ▼
model invokes tool enter_translator_mode()
        │
        ▼
Flutter:
  - _mode = translator, _langA = null, _langB = null
  - close current WebSocket
  - open new WebSocket
  - send session.update with _translatorPrompt() + tools=[exit_translator_mode]
  - UI shows badge "🌐 Translator · detecting languages…"
        │
        ▼
users speak; Whisper transcribes user audio with language field;
  Flutter fills _langA / _langB from first two distinct languages;
  badge updates to "🌐 Translator · 🇷🇺 ⇄ 🇩🇪"
        │
        │  owner says: "Ассистент, стоп"
        ▼
model invokes tool exit_translator_mode()
        │
        ▼
Flutter:
  - _mode = normal, _langA = null, _langB = null
  - close current WebSocket
  - open new WebSocket
  - send session.update with _systemPrompt(locale) + full tool set
  - UI removes badge
```

### Why two tools (enter and exit) instead of one

The mode switch is a side-effecting state change in Flutter. The only reliable signal from the Realtime API for "the model decided X" is a tool call. Parsing transcript text for "activating translator now" is fragile. One tool per direction = explicit and cheap.

### Tool-call response on mode switch

When the model calls `enter_translator_mode` or `exit_translator_mode`, the app **does not** send a `conversation.item.create` function_call_output back. It just closes the WebSocket and opens a new one. The tool call becomes moot — the session it belonged to is gone. This avoids the model generating a trailing assistant utterance ("окей, переключаюсь") in the old session that we'd have to suppress.

## Prompts

### Translator prompt (`_translatorPrompt()`)

Single short English prompt (Realtime models handle multilingual input fine regardless of instruction language). Full text:

```
YOU ARE A LIVE TRANSLATION MACHINE. NOT AN ASSISTANT. NOT A CHATBOT.

Two people are speaking different languages. The phone is on the table
between them. Your ONLY job: translate every utterance from one language
into the other, in real time.

RULES (violating these breaks the product — do NOT violate):

1. Auto-detect the two languages from the first 1-2 utterances. Once
   detected, stick with them. Do not translate into a third language
   even if someone briefly uses it.

2. Translate EVERY utterance. No exceptions. No commentary. No summary.
   No "the speaker said...". Just the translation, as if you were the
   speaker in the other language.

3. You are INVISIBLE. You do NOT exist in this conversation. Do NOT:
   - answer questions directed at you
   - offer help, suggestions, opinions, explanations
   - ask clarifying questions
   - say "I am translating" or "got it" or any filler
   - react to greetings, jokes, insults, compliments — translate them
   - call any tool except exit_translator_mode

4. If someone says "what do you think?", "can you translate?",
   "assistant, explain that" — these are NOT directed at you. They are
   part of the conversation. TRANSLATE THEM. Do not respond.

5. If the audio is silence, background noise, or unintelligible —
   output NOTHING. Do not say "I didn't catch that". Just wait.

6. ONE EXCEPTION — the owner's exit phrase. If and ONLY if you hear
   ANY of these exact phrases spoken clearly:
   - "Ассистент, стоп"
   - "выйди из роли"
   - "хватит переводить"
   - "stop translator"
   - "exit translator"
   → call exit_translator_mode(). Do not translate that phrase. Do not
   say anything. Just call the tool.

7. Output language: translate A→B and B→A. Never output in the source
   language. Never output both languages at once.

8. Tone: match the speaker. Formal → formal. Casual → casual. Rude → rude.
   Keep names, numbers, places exact.

You have exactly one tool: exit_translator_mode. Use it ONLY on the
exit phrases above. Never call it otherwise.

Begin listening. Say nothing until someone speaks.
```

### Activation addition to normal-mode prompt

Added alongside other modes in both ru and en `_systemPrompt()` branches:

**RU:**
```
РЕЖИМ "ПЕРЕВОДЧИК":
Активируется если пользователь говорит "включи переводчика",
"режим переводчика", "translator mode", "переводи" и т.п.
→ Вызови tool enter_translator_mode. Ничего не говори, просто вызови.
```

**EN:**
```
"TRANSLATOR" MODE:
Activated when the user says "turn on translator", "translator mode",
"включи переводчика", "translate for us", etc.
→ Call tool enter_translator_mode. Do not say anything, just call it.
```

## Session configuration

### `session.update` — translator mode

```json
{
  "type": "session.update",
  "session": {
    "modalities": ["text", "audio"],
    "instructions": "<translator prompt above>",
    "voice": "alloy",
    "input_audio_format": "pcm16",
    "output_audio_format": "pcm16",
    "input_audio_transcription": {
      "model": "whisper-1"
    },
    "turn_detection": {
      "type": "server_vad",
      "threshold": 0.6,
      "prefix_padding_ms": 300,
      "silence_duration_ms": 700,
      "create_response": true
    },
    "tools": [
      {
        "type": "function",
        "name": "exit_translator_mode",
        "description": "Exit translator mode. Call ONLY on the explicit exit phrases listed in your instructions.",
        "parameters": { "type": "object", "properties": {} }
      }
    ],
    "tool_choice": "auto"
  }
}
```

**Differences from normal-mode `session.update`:**

| Field | Normal | Translator |
|---|---|---|
| `instructions` | full prompt (~5000 chars) | translator prompt (~1500) |
| `input_audio_transcription.language` | pinned to locale | omitted (auto-detect) |
| `turn_detection.threshold` | 0.5 | 0.6 |
| `turn_detection.silence_duration_ms` | 500 | 700 |
| `tools` | ~20 tools | 1 tool (`exit_translator_mode`) |

### New tool in normal mode

`enter_translator_mode` added to the normal-mode tool list (empty params):

```json
{
  "type": "function",
  "name": "enter_translator_mode",
  "description": "Enter live translator mode between two people speaking different languages. Call when user says 'включи переводчика', 'translator mode', etc.",
  "parameters": { "type": "object", "properties": {} }
}
```

## UI changes

### Header badge (translator mode only)

A pill widget above the transcript:
- Before detection (en locale): `🌐 Translator · detecting languages…`
- Before detection (ru locale): `🌐 Переводчик · определяю языки…`
- After both languages detected: `🌐 Translator · 🇷🇺 ⇄ 🇩🇪` (label follows app locale)
- Color: accent (same as AI-speaking pulse)
- Hidden in normal mode

Flag emoji from ISO language code via a simple map (`ru→🇷🇺`, `en→🇬🇧`, `de→🇩🇪`, `es→🇪🇸`, `fr→🇫🇷`, `it→🇮🇹`, `pt→🇵🇹`, `zh→🇨🇳`, `ja→🇯🇵`, `ko→🇰🇷`, `ar→🇸🇦`, `tr→🇹🇷`, `uk→🇺🇦`, `pl→🇵🇱`). Unknown language → fall back to the ISO code text.

### Language detection logic

Whisper returns a `language` field on `conversation.item.input_audio_transcription.completed` events. In translator mode:
- If `_langA == null` and transcription language is non-empty → `_langA = language`
- Else if `_langB == null` and language differs from `_langA` → `_langB = language`
- After both filled, no further updates

If Whisper fails to return language, badge stays on "detecting…" — translation still works because the model auto-detects internally.

### Transcript rendering

Extend existing `_TranscriptMessage`:

```dart
class _TranscriptMessage {
  final String role;              // 'user' | 'assistant'
  final String text;
  final String? itemId;
  final String? originalLang;     // NEW — set for user items in translator mode
  final String? pairedItemId;     // NEW — itemId of the assistant translation of this user item
}
```

In normal mode: render unchanged.

In translator mode: group each user item with its paired assistant response into a single card with two lines:

```
┌──────────────────────────────────┐
│ 🇷🇺  Привет, как дела?            │
│ 🇩🇪  Hallo, wie geht's?           │
└──────────────────────────────────┘
```

### Pairing user→assistant items

OpenAI Realtime doesn't give a direct user-item → response link. Practical rule: when a `response.done` event arrives, find the most recent user item in `_transcript` without a `pairedItemId` and set its `pairedItemId = <this response's first assistant item id>`. This is robust because translator prompt forbids unsolicited assistant utterances — every assistant response is a reply to a user item in order.

### Untouched UI

- Orbit animation, connect/disconnect button, mute, speaker — unchanged.
- Wake-word trigger — unchanged (translator is entered via voice while connected, not via wake word).

## Edge cases and mitigations

1. **Model drifts out of role.** Primary defense is the prompt + minimal tools + clean reconnect. If testing reveals drift, escalate to manual-response mode (disable `create_response`, send explicit `response.create` per translation). Not implemented in v1.

2. **Background noise triggers VAD falsely.** `threshold 0.6` + `silence_duration_ms 700` reduce false positives. Can tighten if needed.

3. **Exit phrase spoken inside content.** E.g. Russian speaker says "я сказал ему: хватит переводить эту книгу". Model may exit. v1 accepts this risk. Future mitigation: require "Ассистент" prefix or a clear pause.

4. **Whisper misdetects language.** Badge stays on "detecting…" but translation still works. Graceful UI degradation.

5. **Third language.** Prompt says "stick with the pair". If a phrase in a third language appears, model translates it into one of the pair. Acceptable.

6. **Long utterances (>30s).** VAD handles chunking. No special handling.

7. **Multiple normal↔translator switches in one session.** Two reconnects per switch. Reset `_langA/_langB` each entry. Tested mechanic (reconnect already used on failure paths).

8. **User disconnects while in translator mode.** Normal WebSocket close. On next connect, starts in normal mode. No persisted state.

9. **App in background.** Microphone keeps running as in normal Assistant (existing behavior). No changes.

## Testing

### Flutter unit tests

None added. Mode switching is a state machine with WebSocket I/O — not worth mocking at this scope.

### Manual test checklist (DEV emulator or DEV APK)

| # | Scenario | Expected |
|---|---|---|
| 1 | Normal → say "включи переводчика" | Badge appears; `exit_translator_mode` not fired |
| 2 | Speak in Russian | Card with 🇷🇺 original and 🇩🇪 translation |
| 3 | Speak in German | Card with 🇩🇪 original and 🇷🇺 translation |
| 4 | Ask "ты умеешь переводить?" inside translator | Translated as utterance, not answered |
| 5 | Say "что ты думаешь об этом?" | Translated, not answered |
| 6 | Say "Ассистент, стоп" | Badge gone, normal mode, profile tools work again |
| 7 | Normal → translator → normal → translator (2x) | Works without artifacts |
| 8 | 15s silence in translator | Assistant stays silent, stays in role |
| 9 | Profanity in one language | Translated without censorship |
| 10 | "Позвони Андрею" inside translator | Translated, no call started |

### Integration test

Existing `integration_test/app_test.dart` unchanged. A dedicated translator E2E test is not feasible without audio simulation.

### Pre-deploy tests (from CLAUDE.md)

Before pushing DEV:
- `flutter test`
- Existing `integration_test/app_test.dart` on emulator
- `npm test` in `taler_id_tests` (backend smoke — backend unchanged but run per procedure)

Backend voice/assistant/files tests — backend not modified, but run for the procedure.

## Deployment

- Branch: `dev` only.
- Artifact: Dev APK (via build-server `138.124.61.221`, see CLAUDE.md).
- Production: only on explicit user instruction after manual checklist passes.
- Backend: **no changes**. No Prisma migrations, no new env vars.

## Files that will change

- `lib/features/assistant/presentation/screens/assistant_screen.dart` — all changes (prompt, state, tools, UI, reconnect logic).

Single-file change keeps the blast radius small. If it grows during implementation (e.g. a dedicated `translator_prompt.dart`), the plan can split it, but default is single-file.
