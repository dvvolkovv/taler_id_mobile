# AI Analyst Live Status — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Показ прогресса AI Аналитика в чате в реальном времени (фазы "думаю/ищу/читаю файл", streaming-бубль финального ответа, постоянный "шов" с агрегатом шагов), + удаление неиспользуемого модуля `lib/features/chat/`.

**Architecture:** Бэкенд — источник истины: маппит имена тулов Claude Worker в локализованные фразы с эмодзи, стримит статусы через **существующий `typing` event** (та же инфра, что у `AI_OUTBOUND`), сохраняет агрегат шагов в новом поле `Message.metadata`. Мобилка получает готовые фразы, добавляет два новых UI-виджета (`AnalystSeamWidget` + `AnalystStreamingBubble`), использует существующий `_TypingDots`.

**Tech Stack:** NestJS + Prisma + Socket.io (backend, `~/taler-id/`), Flutter + Freezed + BLoC (mobile, `~/Downloads/taler_id_mobile/` ветка `dev`), Jest (backend tests), flutter_test + integration_test (mobile tests).

**Key deviation from spec:** Переиспользуем существующий `typing` event (с эмодзи-префиксом в `typingText`, как уже делает `AI_OUTBOUND`) вместо предложенного нового `analyst_status`. Поведение мобилки идентично спецификации; экономия — отсутствие новой event-сигнатуры и переиспользование auto-clear логики (5 сек без event → статус пропадает).

**Spec:** `docs/superpowers/specs/2026-04-24-ai-analyst-live-status-design.md`

---

## Phase 0: Setup

### Task 0.1: Clone backend repo locally for TDD

**Files:**
- Create: `/Users/dmitry/taler-id/` (local clone)

- [ ] **Step 1: Clone the repo**

```bash
cd /Users/dmitry && git clone https://github.com/dvvolkovv/taler_id.git taler-id && cd taler-id && git checkout dev 2>/dev/null || git checkout -b dev origin/dev
```
Expected: repo cloned, on `dev` branch (or `main` if `dev` doesn't exist — check with `git branch -a`).

- [ ] **Step 2: Install deps**

Run: `cd /Users/dmitry/taler-id && npm install`
Expected: no errors. If Prisma postinstall runs, that's fine.

- [ ] **Step 3: Verify test harness works**

Run: `cd /Users/dmitry/taler-id && npx jest src/auth/auth.service.spec.ts --listTests`
Expected: lists the file, no errors. Confirms Jest is configured.

---

## Phase 1: Backend — tool labels dictionary

### Task 1.1: Create tool labels module (TDD)

**Files:**
- Create: `/Users/dmitry/taler-id/src/ai-analyst/ai-analyst-labels.ts`
- Test: `/Users/dmitry/taler-id/src/ai-analyst/ai-analyst-labels.spec.ts`

- [ ] **Step 1: Write failing test**

Create `src/ai-analyst/ai-analyst-labels.spec.ts`:

```ts
import {
  TOOL_LABELS,
  PHASE_LABELS,
  UNKNOWN_TOOL_LABEL,
  refineBashLabel,
  resolveToolLabel,
  ToolKind,
} from './ai-analyst-labels';

describe('ai-analyst-labels', () => {
  describe('TOOL_LABELS', () => {
    it('maps WebSearch to search kind with ru+en', () => {
      expect(TOOL_LABELS.WebSearch.kind).toBe('search');
      expect(TOOL_LABELS.WebSearch.emoji).toBe('🔍');
      expect(TOOL_LABELS.WebSearch.ru).toBe('Ищу в интернете…');
      expect(TOOL_LABELS.WebSearch.en).toBe('Searching the web…');
    });
    it('maps Bash to cmd kind', () => {
      expect(TOOL_LABELS.Bash.kind).toBe('cmd');
    });
    it('maps Read/Write/Edit/Glob/Grep to file kind', () => {
      for (const t of ['Read', 'Write', 'Edit', 'Glob', 'Grep']) {
        expect(TOOL_LABELS[t].kind).toBe('file');
      }
    });
  });

  describe('refineBashLabel', () => {
    it('recognises generate_image.sh as image', () => {
      const lbl = refineBashLabel('bash /home/dv/agent-env/bin/generate_image.sh --prompt "cat"');
      expect(lbl).not.toBeNull();
      expect(lbl!.kind).toBe('image');
      expect(lbl!.emoji).toBe('🎨');
    });
    it('returns null for other bash commands', () => {
      expect(refineBashLabel('ls -la')).toBeNull();
      expect(refineBashLabel('python script.py')).toBeNull();
    });
  });

  describe('resolveToolLabel', () => {
    it('prefers refineBashLabel over TOOL_LABELS.Bash', () => {
      const lbl = resolveToolLabel('Bash', 'sh generate_image.sh');
      expect(lbl.kind).toBe('image');
    });
    it('falls back to TOOL_LABELS by name', () => {
      const lbl = resolveToolLabel('Read', '/etc/hosts');
      expect(lbl.kind).toBe('file');
    });
    it('returns UNKNOWN_TOOL_LABEL for unknown tool', () => {
      const lbl = resolveToolLabel('SomeCustomTool', '');
      expect(lbl).toBe(UNKNOWN_TOOL_LABEL);
      expect(lbl.kind).toBe('other');
    });
  });

  describe('PHASE_LABELS', () => {
    it('has thinking, preparing, error', () => {
      expect(PHASE_LABELS.thinking.emoji).toBe('🤔');
      expect(PHASE_LABELS.preparing.emoji).toBe('✍️');
      expect(PHASE_LABELS.error.emoji).toBe('❌');
    });
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/dmitry/taler-id && npx jest src/ai-analyst/ai-analyst-labels.spec.ts`
Expected: FAIL with "Cannot find module './ai-analyst-labels'"

- [ ] **Step 3: Create the module**

Create `src/ai-analyst/ai-analyst-labels.ts`:

```ts
export type ToolKind = 'search' | 'file' | 'cmd' | 'image' | 'other';

export interface ToolLabel {
  kind: ToolKind;
  emoji: string;
  ru: string;
  en: string;
}

export const TOOL_LABELS: Record<string, ToolLabel> = {
  WebSearch: { kind: 'search', emoji: '🔍', ru: 'Ищу в интернете…',    en: 'Searching the web…' },
  WebFetch:  { kind: 'search', emoji: '🌐', ru: 'Открываю страницу…',  en: 'Fetching page…' },
  Read:      { kind: 'file',   emoji: '📄', ru: 'Читаю файл…',         en: 'Reading file…' },
  Write:     { kind: 'file',   emoji: '📝', ru: 'Записываю файл…',     en: 'Writing file…' },
  Edit:      { kind: 'file',   emoji: '✏️', ru: 'Редактирую файл…',    en: 'Editing file…' },
  Glob:      { kind: 'file',   emoji: '🗂️', ru: 'Ищу файлы…',          en: 'Listing files…' },
  Grep:      { kind: 'file',   emoji: '🔎', ru: 'Ищу по содержимому…', en: 'Searching contents…' },
  Bash:      { kind: 'cmd',    emoji: '💻', ru: 'Выполняю команду…',   en: 'Running command…' },
};

export const PHASE_LABELS = {
  thinking:  { emoji: '🤔', ru: 'Думаю…',         en: 'Thinking…' },
  preparing: { emoji: '✍️', ru: 'Готовлю ответ…', en: 'Preparing answer…' },
  error:     { emoji: '❌', ru: 'Ошибка',         en: 'Error' },
};

export const UNKNOWN_TOOL_LABEL: ToolLabel = {
  kind: 'other', emoji: '⚙️', ru: 'Работаю…', en: 'Working…',
};

export function refineBashLabel(input: string): ToolLabel | null {
  if (/generate_image\.sh/.test(input)) {
    return { kind: 'image', emoji: '🎨', ru: 'Генерирую картинку…', en: 'Generating image…' };
  }
  return null;
}

export function resolveToolLabel(toolName: string, input: string): ToolLabel {
  if (toolName === 'Bash') {
    const refined = refineBashLabel(input);
    if (refined) return refined;
  }
  return TOOL_LABELS[toolName] ?? UNKNOWN_TOOL_LABEL;
}
```

- [ ] **Step 4: Run tests — all pass**

Run: `cd /Users/dmitry/taler-id && npx jest src/ai-analyst/ai-analyst-labels.spec.ts`
Expected: PASS — 7 tests across 4 describe blocks.

- [ ] **Step 5: Commit**

```bash
cd /Users/dmitry/taler-id && git add src/ai-analyst/ai-analyst-labels.ts src/ai-analyst/ai-analyst-labels.spec.ts && git commit -m "feat(ai-analyst): add tool-name to human-label dictionary"
```

---

## Phase 2: Backend — Prisma migration for Message.metadata

### Task 2.1: Add metadata column

**Files:**
- Modify: `/Users/dmitry/taler-id/prisma/schema.prisma` (line 236 area — Message model)
- Create: `/Users/dmitry/taler-id/prisma/migrations/<timestamp>_message_metadata/migration.sql`

- [ ] **Step 1: Edit schema**

Open `prisma/schema.prisma`, locate the `Message` model (around line 235), add a field `metadata Json?` before `@@index`. After edit, Message model should contain:

```prisma
model Message {
  id                 String            @id @default(uuid())
  // ... (existing fields stay as-is) ...
  topicId            String?
  metadata           Json?              // NEW — per-message structured data (AI Analyst steps, etc.)
  fileRecord         FileRecord?       @relation(...)
  conversation       Conversation      @relation(...)
  sender             User              @relation(...)
  @@index([conversationId, sentAt])
}
```

- [ ] **Step 2: Generate migration**

Run:
```bash
cd /Users/dmitry/taler-id && npx prisma migrate dev --name message_metadata --create-only
```
Expected: creates `prisma/migrations/<timestamp>_message_metadata/migration.sql` with `ALTER TABLE "Message" ADD COLUMN "metadata" JSONB;`.

- [ ] **Step 3: Inspect the generated SQL**

Run: `cat prisma/migrations/*_message_metadata/migration.sql`
Expected output (approximately):
```sql
-- AlterTable
ALTER TABLE "Message" ADD COLUMN "metadata" JSONB;
```
If the SQL does anything destructive (DROP, NOT NULL, default on existing rows), STOP and review.

- [ ] **Step 4: Commit the migration**

```bash
cd /Users/dmitry/taler-id && git add prisma/schema.prisma prisma/migrations && git commit -m "feat(db): add Message.metadata JSONB column"
```

_Note: migration will actually run on DEV during deploy (`npx prisma migrate deploy` in the deploy step). We only generate + commit it here._

---

## Phase 3: Backend — Refactor _dispatchToAnalyst

### Task 3.1: Add getUserLang helper to MessengerGateway

**Files:**
- Modify: `/Users/dmitry/taler-id/src/messenger/messenger.gateway.ts` (add private method, ~line 780 area near `emitToUser`)

- [ ] **Step 1: Add helper**

Inside `MessengerGateway` class, right after `emitToUser()` (line 779), add:

```ts
/** Get user's preferred language from their profile. Defaults to 'en'. */
private async getUserLang(userId: string): Promise<'ru' | 'en'> {
  const profile = await this.prisma.profile.findUnique({
    where: { userId },
    select: { language: true },
  });
  const lang = profile?.language;
  return lang === 'ru' ? 'ru' : 'en';
}
```

- [ ] **Step 2: Verify it compiles**

Run: `cd /Users/dmitry/taler-id && npx tsc --noEmit -p tsconfig.json 2>&1 | head -20`
Expected: no errors related to `getUserLang`.

- [ ] **Step 3: Commit**

```bash
cd /Users/dmitry/taler-id && git add src/messenger/messenger.gateway.ts && git commit -m "feat(messenger): add getUserLang helper reading Profile.language"
```

---

### Task 3.2: Write integration test for new _dispatchToAnalyst behaviour (TDD — failing)

**Files:**
- Create: `/Users/dmitry/taler-id/src/messenger/messenger.gateway.analyst.spec.ts`

- [ ] **Step 1: Write the spec**

Create `src/messenger/messenger.gateway.analyst.spec.ts`:

```ts
import { Test } from '@nestjs/testing';
import { MessengerGateway } from './messenger.gateway';
import { MessengerService } from './messenger.service';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../redis/redis.service';
import { AiTwinService } from './ai-twin.service';
import { AiAnalystService } from '../ai-analyst/ai-analyst.service';
import { OutboundBotService } from '../outbound-bot/outbound-bot.service';
import { FcmService } from '../common/fcm.service';
import { ApnsService } from '../common/apns.service';
import { ConfigService } from '@nestjs/config';

interface SubmitTaskInput {
  onChunk: (text: string) => void;
  onTool?: (tool: string, input: string) => void;
}

describe('MessengerGateway._dispatchToAnalyst', () => {
  let gateway: MessengerGateway;
  let mockAnalyst: AiAnalystService;
  let mockMessenger: MessengerService;
  let emitted: Array<{ room: string; event: string; data: any }> = [];

  beforeEach(async () => {
    emitted = [];
    const mockServer = {
      to: (room: string) => ({
        emit: (event: string, data: any) => { emitted.push({ room, event, data }); },
      }),
    };
    const mod = await Test.createTestingModule({
      providers: [
        MessengerGateway,
        { provide: MessengerService, useValue: {
          createMessage: jest.fn().mockImplementation(async (convId, _userId, content, _f, _fn, isSystem, meta) => ({
            id: 'msg-1', conversationId: convId, senderId: 'bot', content,
            isSystem, metadata: meta ?? null, sentAt: new Date(),
          })),
        }},
        { provide: PrismaService, useValue: {
          profile: { findUnique: jest.fn().mockResolvedValue({ language: 'ru' }) },
        }},
        { provide: RedisService, useValue: {} },
        { provide: AiTwinService, useValue: {} },
        { provide: AiAnalystService, useValue: { submitTask: jest.fn() } },
        { provide: OutboundBotService, useValue: {} },
        { provide: FcmService, useValue: {} },
        { provide: ApnsService, useValue: {} },
        { provide: ConfigService, useValue: { get: () => undefined } },
      ],
    }).compile();
    gateway = mod.get(MessengerGateway);
    (gateway as any).server = mockServer;
    mockAnalyst = mod.get(AiAnalystService);
    mockMessenger = mod.get(MessengerService);
  });

  function replayWorker(callbacks: SubmitTaskInput, script: Array<['tool', string, string] | ['chunk', string]>) {
    for (const step of script) {
      if (step[0] === 'tool') callbacks.onTool?.(step[1], step[2]);
      else callbacks.onChunk(step[1]);
    }
  }

  it('emits typing with thinking emoji before first tool/chunk', async () => {
    (mockAnalyst.submitTask as jest.Mock).mockImplementation(async (input) => {
      replayWorker(input, [['chunk', 'Привет']]);
      return { text: 'Привет', outputFiles: [] };
    });
    await (gateway as any)._dispatchToAnalyst('user-1', 'conv-1', 'hi', []);
    const first = emitted[0];
    expect(first.room).toBe('user:user-1');
    expect(first.event).toBe('typing');
    expect(first.data.typingText).toContain('🤔');
    expect(first.data.typingText).toContain('Думаю');
    expect(first.data.isTyping).toBe(true);
    expect(first.data.conversationId).toBe('conv-1');
  });

  it('emits typing event for each tool with localized label', async () => {
    (mockAnalyst.submitTask as jest.Mock).mockImplementation(async (input) => {
      replayWorker(input, [
        ['tool', 'WebSearch', 'query:cats'],
        ['tool', 'Read', '/etc/hosts'],
        ['chunk', 'done'],
      ]);
      return { text: 'done', outputFiles: [] };
    });
    await (gateway as any)._dispatchToAnalyst('user-1', 'conv-1', 'hi', []);
    const typingEvents = emitted.filter(e => e.event === 'typing' && e.data.isTyping);
    // thinking + WebSearch + Read + preparing
    expect(typingEvents).toHaveLength(4);
    expect(typingEvents[1].data.typingText).toContain('🔍');
    expect(typingEvents[1].data.typingText).toContain('Ищу в интернете');
    expect(typingEvents[2].data.typingText).toContain('📄');
    expect(typingEvents[2].data.typingText).toContain('Читаю файл');
    expect(typingEvents[3].data.typingText).toContain('✍️');
  });

  it('emits analyst_chunk for each delta', async () => {
    (mockAnalyst.submitTask as jest.Mock).mockImplementation(async (input) => {
      replayWorker(input, [['chunk', 'Hello '], ['chunk', 'world']]);
      return { text: 'Hello world', outputFiles: [] };
    });
    await (gateway as any)._dispatchToAnalyst('user-1', 'conv-1', 'hi', []);
    const chunks = emitted.filter(e => e.event === 'analyst_chunk');
    expect(chunks).toHaveLength(2);
    expect(chunks[0].data.text).toBe('Hello ');
    expect(chunks[1].data.text).toBe('world');
  });

  it('persists metadata.steps with correct counts', async () => {
    (mockAnalyst.submitTask as jest.Mock).mockImplementation(async (input) => {
      replayWorker(input, [
        ['tool', 'WebSearch', 'q1'],
        ['tool', 'WebSearch', 'q2'],
        ['tool', 'Read', 'f1'],
        ['tool', 'Bash', 'ls'],
        ['chunk', 'answer'],
      ]);
      return { text: 'answer', outputFiles: [] };
    });
    await (gateway as any)._dispatchToAnalyst('user-1', 'conv-1', 'hi', []);
    const createCall = (mockMessenger.createMessage as jest.Mock).mock.calls[0];
    const metadata = createCall[6];   // 7th arg
    expect(metadata.steps).toEqual(expect.arrayContaining([
      { kind: 'search', count: 2 },
      { kind: 'file',   count: 1 },
      { kind: 'cmd',    count: 1 },
    ]));
    expect(typeof metadata.durationMs).toBe('number');
  });

  it('emits analyst_seam after saving final message', async () => {
    (mockAnalyst.submitTask as jest.Mock).mockImplementation(async (input) => {
      replayWorker(input, [['tool', 'Read', 'f'], ['chunk', 'ok']]);
      return { text: 'ok', outputFiles: [] };
    });
    await (gateway as any)._dispatchToAnalyst('user-1', 'conv-1', 'hi', []);
    const seam = emitted.find(e => e.event === 'analyst_seam');
    expect(seam).toBeDefined();
    expect(seam!.data.messageId).toBe('msg-1');
    expect(seam!.data.steps).toEqual(expect.arrayContaining([{ kind: 'file', count: 1 }]));
  });

  it('emits typing isTyping=false to clear indicator after done', async () => {
    (mockAnalyst.submitTask as jest.Mock).mockImplementation(async (input) => {
      replayWorker(input, [['chunk', 'done']]);
      return { text: 'done', outputFiles: [] };
    });
    await (gateway as any)._dispatchToAnalyst('user-1', 'conv-1', 'hi', []);
    const clears = emitted.filter(e => e.event === 'typing' && e.data.isTyping === false);
    expect(clears.length).toBeGreaterThanOrEqual(1);
  });

  it('on error, emits error typing and saves error message', async () => {
    (mockAnalyst.submitTask as jest.Mock).mockRejectedValue(new Error('worker down'));
    await (gateway as any)._dispatchToAnalyst('user-1', 'conv-1', 'hi', []);
    const errorTyping = emitted.find(e => e.event === 'typing' && e.data.typingText?.includes('❌'));
    expect(errorTyping).toBeDefined();
    const createCall = (mockMessenger.createMessage as jest.Mock).mock.calls[0];
    expect(createCall[2]).toContain('❌');
  });

  it('uses English labels when Profile.language=en', async () => {
    const prisma = (gateway as any).prisma;
    prisma.profile.findUnique.mockResolvedValue({ language: 'en' });
    (mockAnalyst.submitTask as jest.Mock).mockImplementation(async (input) => {
      replayWorker(input, [['tool', 'WebSearch', 'q'], ['chunk', 'done']]);
      return { text: 'done', outputFiles: [] };
    });
    await (gateway as any)._dispatchToAnalyst('user-2', 'conv-2', 'hi', []);
    const searchTyping = emitted.find(e => e.event === 'typing' && e.data.typingText?.includes('🔍'));
    expect(searchTyping!.data.typingText).toContain('Searching the web');
  });
});
```

- [ ] **Step 2: Run to confirm FAIL**

Run: `cd /Users/dmitry/taler-id && npx jest src/messenger/messenger.gateway.analyst.spec.ts`
Expected: FAIL — current `_dispatchToAnalyst` emits `analyst_thinking` (not `typing`), no seam event, no metadata in createMessage, no language support.

- [ ] **Step 3: Commit failing test**

```bash
cd /Users/dmitry/taler-id && git add src/messenger/messenger.gateway.analyst.spec.ts && git commit -m "test(messenger): failing spec for _dispatchToAnalyst live-status behaviour"
```

---

### Task 3.3: Extend MessengerService.createMessage to accept metadata

**Files:**
- Modify: `/Users/dmitry/taler-id/src/messenger/messenger.service.ts` (find `createMessage` method)

- [ ] **Step 1: Read current signature**

Run: `grep -n "createMessage" /Users/dmitry/taler-id/src/messenger/messenger.service.ts | head -5`
Identify current parameter order. Expected something like:
```ts
async createMessage(conversationId, senderId, content, fileUrl?, fileName?, isSystem?, ...)
```

- [ ] **Step 2: Add optional 7th parameter `metadata?: Record<string, any>`**

Locate the method. Add `metadata?: Record<string, any>` after `isSystem` (last current param). Pass `metadata` into the Prisma create: `data: { ..., metadata: metadata ?? undefined }`.

Example:
```ts
async createMessage(
  conversationId: string,
  senderId: string,
  content: string,
  fileUrl?: string,
  fileName?: string,
  isSystem: boolean = false,
  metadata?: Record<string, any>,
) {
  return this.prisma.message.create({
    data: {
      conversationId, senderId, content, fileUrl, fileName,
      isSystem, metadata: metadata ?? undefined,
    },
  });
}
```
Adjust to exact existing signature — preserve all other options.

- [ ] **Step 3: Run TypeScript check**

Run: `cd /Users/dmitry/taler-id && npx tsc --noEmit 2>&1 | grep -E "(error|createMessage)" | head -20`
Expected: if there are call sites that now have a 7th arg mismatch, none should fail — the new param is optional.

- [ ] **Step 4: Commit**

```bash
cd /Users/dmitry/taler-id && git add src/messenger/messenger.service.ts && git commit -m "feat(messenger): allow optional metadata on createMessage"
```

---

### Task 3.4: Implement the new _dispatchToAnalyst

**Files:**
- Modify: `/Users/dmitry/taler-id/src/messenger/messenger.gateway.ts` (lines 858-939 — replace entire method)

- [ ] **Step 1: Add imports**

At the top of the file (near other imports):
```ts
import { TOOL_LABELS, PHASE_LABELS, UNKNOWN_TOOL_LABEL, resolveToolLabel, ToolKind } from '../ai-analyst/ai-analyst-labels';
```

- [ ] **Step 2: Replace the method body**

Replace lines 858-939 with:

```ts
private async _dispatchToAnalyst(
  userId: string,
  conversationId: string,
  messageText: string,
  fileUrls: { url: string; name: string }[],
) {
  const started = Date.now();
  const lang = await this.getUserLang(userId);
  const counts: Record<ToolKind, number> = { search: 0, file: 0, cmd: 0, image: 0, other: 0 };
  let preparingEmitted = false;

  const emitTyping = (emoji: string, label: string) => {
    this.server.to(`user:${userId}`).emit('typing', {
      conversationId,
      userId: 'ai-analyst-bot',
      userName: 'AI Аналитик',
      isTyping: true,
      typingText: `${emoji} ${label}`,
    });
  };
  const clearTyping = () => {
    this.server.to(`user:${userId}`).emit('typing', {
      conversationId,
      userId: 'ai-analyst-bot',
      isTyping: false,
    });
  };

  // Phase: thinking
  emitTyping(PHASE_LABELS.thinking.emoji, PHASE_LABELS.thinking[lang]);

  try {
    const { text, outputFiles } = await this.aiAnalyst.submitTask({
      userId, conversationId, messageText,
      fileUrls: fileUrls.length > 0 ? fileUrls : undefined,
      onTool: (tool, input) => {
        const lbl = resolveToolLabel(tool, input);
        counts[lbl.kind]++;
        emitTyping(lbl.emoji, lbl[lang]);
      },
      onChunk: (chunkText) => {
        if (!preparingEmitted) {
          emitTyping(PHASE_LABELS.preparing.emoji, PHASE_LABELS.preparing[lang]);
          preparingEmitted = true;
        }
        this.server.to(`user:${userId}`).emit('analyst_chunk', {
          conversationId, text: chunkText,
        });
      },
    });

    // Append output files list (existing behaviour preserved)
    let content = text;
    if (outputFiles.length > 0) {
      const fileList = outputFiles
        .map((f: any) => `📎 [${f.name}](http://5.101.115.184:3033${f.url})`)
        .join('\n');
      content += '\n\n' + fileList;
    }

    const durationMs = Date.now() - started;
    const steps = (Object.entries(counts) as [ToolKind, number][])
      .filter(([_, v]) => v > 0)
      .map(([kind, count]) => ({ kind, count }));
    const metadata = { steps, durationMs };

    const botMsg = await this.service.createMessage(
      conversationId, userId, content, undefined, undefined,
      true, metadata,
    );

    clearTyping();
    this.server.to(`user:${userId}`).emit('new_message', {
      ...botMsg, senderName: 'AI Аналитик', isSystem: true,
    });
    this.server.to(`user:${userId}`).emit('analyst_seam', {
      conversationId, messageId: botMsg.id, steps, durationMs,
    });
  } catch (e) {
    const err = e as Error;
    this.logger.error(`[AI Analyst] dispatch failed: ${err.message}`);
    emitTyping(PHASE_LABELS.error.emoji, `${PHASE_LABELS.error[lang]}: ${err.message}`);
    try {
      const errMsg = await this.service.createMessage(
        conversationId, userId,
        `❌ ${lang === 'ru' ? 'Ошибка анализа' : 'Analysis error'}: ${err.message}`,
        undefined, undefined, true,
        { steps: [], durationMs: Date.now() - started, error: true },
      );
      clearTyping();
      this.server.to(`user:${userId}`).emit('new_message', {
        ...errMsg, senderName: 'AI Аналитик', isSystem: true,
      });
    } catch {
      clearTyping();
    }
  }
}
```

- [ ] **Step 3: Remove old events from caller site**

Search for any other places that reference `analyst_thinking`, `analyst_tool`, `analyst_done` in the backend:

```bash
grep -rn "analyst_thinking\|analyst_tool\|analyst_done" /Users/dmitry/taler-id/src/
```

Expected: no other matches (all three were only emitted by `_dispatchToAnalyst`). If any appear, report them — do NOT silently delete.

- [ ] **Step 4: Run gateway tests**

Run: `cd /Users/dmitry/taler-id && npx jest src/messenger/messenger.gateway.analyst.spec.ts`
Expected: PASS — all 8 tests.

- [ ] **Step 5: Typecheck whole project**

Run: `cd /Users/dmitry/taler-id && npx tsc --noEmit 2>&1 | head -30`
Expected: no new errors. Pre-existing errors (if any) are fine, just don't add new ones.

- [ ] **Step 6: Commit**

```bash
cd /Users/dmitry/taler-id && git add src/messenger/messenger.gateway.ts && git commit -m "feat(ai-analyst): emit live-status via typing event + analyst_seam + metadata"
```

---

### Task 3.5: Add 3-minute timeout wrapper around submitTask

**Rationale:** Per spec §7 "Timeout > 3 мин без событий | Бэк сам эмитит error и сохраняет timeout-сообщение". `AiAnalystService.submitTask` has no built-in timeout (confirmed in prior research) — if Claude Worker stalls, the promise never resolves. Wrap it at the call site so behaviour matches the error branch we already implemented.

**Files:**
- Modify: `/Users/dmitry/taler-id/src/messenger/messenger.gateway.ts` (inside `_dispatchToAnalyst`)

- [ ] **Step 1: Add failing test**

Append to `src/messenger/messenger.gateway.analyst.spec.ts`:

```ts
it('times out after 3 minutes and emits error typing', async () => {
  jest.useFakeTimers();
  (mockAnalyst.submitTask as jest.Mock).mockImplementation(() => new Promise(() => {}));
  const p = (gateway as any)._dispatchToAnalyst('user-1', 'conv-1', 'hi', []);
  jest.advanceTimersByTime(3 * 60 * 1000 + 100);
  await p;
  const errorTyping = emitted.find(e => e.event === 'typing' && e.data.typingText?.includes('❌'));
  expect(errorTyping).toBeDefined();
  const createArgs = (mockMessenger.createMessage as jest.Mock).mock.calls[0];
  expect(createArgs[2]).toMatch(/timeout|Ошибка/i);
  jest.useRealTimers();
});
```

- [ ] **Step 2: Run — FAIL**

Run: `cd /Users/dmitry/taler-id && npx jest src/messenger/messenger.gateway.analyst.spec.ts -t "times out"`
Expected: FAIL — current code awaits `submitTask` forever.

- [ ] **Step 3: Wrap submitTask call**

In `_dispatchToAnalyst` (the code from Task 3.4), change the `await this.aiAnalyst.submitTask(...)` call to race it with a 3-min timeout. Replace:

```ts
const { text, outputFiles } = await this.aiAnalyst.submitTask({
  userId, conversationId, messageText,
  fileUrls: fileUrls.length > 0 ? fileUrls : undefined,
  onTool: ...,
  onChunk: ...,
});
```

with:

```ts
const submitPromise = this.aiAnalyst.submitTask({
  userId, conversationId, messageText,
  fileUrls: fileUrls.length > 0 ? fileUrls : undefined,
  onTool: (tool, input) => { /* same as before */ },
  onChunk: (chunkText) => { /* same as before */ },
});
const timeoutPromise = new Promise<never>((_, reject) =>
  setTimeout(() => reject(new Error('AI Analyst timeout (180 s)')), 180_000),
);
const { text, outputFiles } = await Promise.race([submitPromise, timeoutPromise]);
```

Keep the `catch (e)` branch unchanged — it already handles the timeout Error by emitting error typing + saving a system message.

- [ ] **Step 4: Run tests — PASS**

Run: `cd /Users/dmitry/taler-id && npx jest src/messenger/messenger.gateway.analyst.spec.ts`
Expected: all 9 tests PASS (8 from Task 3.2 + 1 new).

- [ ] **Step 5: Commit**

```bash
cd /Users/dmitry/taler-id && git add src/messenger/messenger.gateway.ts src/messenger/messenger.gateway.analyst.spec.ts && git commit -m "feat(ai-analyst): enforce 3-minute timeout on worker dispatch"
```

---

## Phase 4: Mobile — MessageEntity.metadata field

### Task 4.1: Add metadata to MessageEntity (generated code)

**Files:**
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/messenger/domain/entities/message_entity.dart`
- Regenerate: `.freezed.dart`, `.g.dart`

- [ ] **Step 1: Add field**

Open `message_entity.dart`, add `Map<String, dynamic>? metadata` at end of the factory parameter list (before the closing `}) = _MessageEntity;`):

```dart
required String id,
// ... existing fields ...
String? topicId,
Map<String, dynamic>? metadata,   // NEW
}) = _MessageEntity;
```

- [ ] **Step 2: Regenerate**

Run:
```bash
cd /Users/dmitry/Downloads/taler_id_mobile && dart run build_runner build --delete-conflicting-outputs 2>&1 | tail -10
```
Expected: success, `.freezed.dart` and `.g.dart` updated for `message_entity`.

- [ ] **Step 3: Verify flutter analyze**

Run: `cd /Users/dmitry/Downloads/taler_id_mobile && flutter analyze lib/features/messenger/domain/entities/message_entity.dart 2>&1 | head -20`
Expected: no issues.

- [ ] **Step 4: Run existing flutter tests to confirm no regression**

Run: `cd /Users/dmitry/Downloads/taler_id_mobile && flutter test test/ 2>&1 | tail -10`
Expected: all existing tests still pass. If there's a test that constructs MessageEntity with positional args, adjust it (should be all named, so safe).

- [ ] **Step 5: Commit**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && git add lib/features/messenger/domain/entities/message_entity.dart lib/features/messenger/domain/entities/message_entity.freezed.dart lib/features/messenger/domain/entities/message_entity.g.dart && git commit -m "feat(messenger): add optional metadata to MessageEntity"
```

---

## Phase 5: Mobile — AnalystSeam entity + datasource events

### Task 5.1: Create AnalystSeam + AnalystChunk entities (TDD-lite)

**Files:**
- Create: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/messenger/domain/entities/analyst_events.dart`
- Test: `/Users/dmitry/Downloads/taler_id_mobile/test/features/messenger/domain/entities/analyst_events_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/features/messenger/domain/entities/analyst_events_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/analyst_events.dart';

void main() {
  group('AnalystSeam.fromJson', () {
    test('parses steps with kind+count and durationMs', () {
      final seam = AnalystSeam.fromJson({
        'conversationId': 'c1',
        'messageId': 'm1',
        'steps': [
          {'kind': 'search', 'count': 2},
          {'kind': 'file', 'count': 3},
        ],
        'durationMs': 12345,
      });
      expect(seam.conversationId, 'c1');
      expect(seam.messageId, 'm1');
      expect(seam.steps, hasLength(2));
      expect(seam.steps[0].kind, 'search');
      expect(seam.steps[0].count, 2);
      expect(seam.durationMs, 12345);
    });
  });

  group('AnalystChunk.fromJson', () {
    test('parses conversationId and text', () {
      final chunk = AnalystChunk.fromJson({'conversationId': 'c', 'text': 'hi'});
      expect(chunk.conversationId, 'c');
      expect(chunk.text, 'hi');
    });
  });

  group('AnalystSeam.fromMetadata', () {
    test('builds seam from Message.metadata', () {
      final seam = AnalystSeam.fromMetadata(
        conversationId: 'c', messageId: 'm',
        metadata: {
          'steps': [{'kind': 'cmd', 'count': 4}],
          'durationMs': 500,
        },
      );
      expect(seam.steps.first.kind, 'cmd');
      expect(seam.durationMs, 500);
    });
    test('returns null when metadata has no steps', () {
      expect(AnalystSeam.fromMetadata(conversationId: 'c', messageId: 'm', metadata: null), null);
      expect(AnalystSeam.fromMetadata(conversationId: 'c', messageId: 'm', metadata: {}), null);
      expect(AnalystSeam.fromMetadata(conversationId: 'c', messageId: 'm', metadata: {'steps': []}), null);
    });
  });
}
```

- [ ] **Step 2: Run to confirm FAIL**

Run: `cd /Users/dmitry/Downloads/taler_id_mobile && flutter test test/features/messenger/domain/entities/analyst_events_test.dart 2>&1 | tail -10`
Expected: FAIL — module not found.

- [ ] **Step 3: Create entities**

Create `lib/features/messenger/domain/entities/analyst_events.dart`:

```dart
class SeamStep {
  final String kind;   // 'search' | 'file' | 'cmd' | 'image' | 'other'
  final int count;
  const SeamStep({required this.kind, required this.count});

  factory SeamStep.fromJson(Map<String, dynamic> json) => SeamStep(
        kind: json['kind'] as String,
        count: (json['count'] as num).toInt(),
      );
}

class AnalystSeam {
  final String conversationId;
  final String messageId;
  final List<SeamStep> steps;
  final int durationMs;

  const AnalystSeam({
    required this.conversationId,
    required this.messageId,
    required this.steps,
    required this.durationMs,
  });

  factory AnalystSeam.fromJson(Map<String, dynamic> json) => AnalystSeam(
        conversationId: json['conversationId'] as String,
        messageId: json['messageId'] as String,
        steps: (json['steps'] as List<dynamic>)
            .map((e) => SeamStep.fromJson(e as Map<String, dynamic>))
            .toList(),
        durationMs: (json['durationMs'] as num).toInt(),
      );

  /// Build a seam from an already-persisted message's metadata.
  static AnalystSeam? fromMetadata({
    required String conversationId,
    required String messageId,
    required Map<String, dynamic>? metadata,
  }) {
    if (metadata == null) return null;
    final stepsRaw = metadata['steps'];
    if (stepsRaw is! List || stepsRaw.isEmpty) return null;
    final steps = stepsRaw
        .map((e) => SeamStep.fromJson(e as Map<String, dynamic>))
        .toList();
    final durationMs = (metadata['durationMs'] as num?)?.toInt() ?? 0;
    return AnalystSeam(
      conversationId: conversationId,
      messageId: messageId,
      steps: steps,
      durationMs: durationMs,
    );
  }
}

class AnalystChunk {
  final String conversationId;
  final String text;
  const AnalystChunk({required this.conversationId, required this.text});

  factory AnalystChunk.fromJson(Map<String, dynamic> json) => AnalystChunk(
        conversationId: json['conversationId'] as String,
        text: json['text'] as String,
      );
}
```

- [ ] **Step 4: Run test — PASS**

Run: `cd /Users/dmitry/Downloads/taler_id_mobile && flutter test test/features/messenger/domain/entities/analyst_events_test.dart 2>&1 | tail -10`
Expected: all 4 tests pass.

- [ ] **Step 5: Commit**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && git add lib/features/messenger/domain/entities/analyst_events.dart test/features/messenger/domain/entities/analyst_events_test.dart && git commit -m "feat(messenger): add AnalystSeam + AnalystChunk entities"
```

---

### Task 5.2: Add socket subscriptions for analyst_chunk + analyst_seam

**Files:**
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/messenger/data/datasources/messenger_remote_datasource.dart`

- [ ] **Step 1: Add imports + controllers**

Near top imports, add:
```dart
import '../../domain/entities/analyst_events.dart';
```

In the field declarations block (around lines 13-47), add two new `StreamController`s:
```dart
final _analystChunkCtrl = StreamController<AnalystChunk>.broadcast();
final _analystSeamCtrl  = StreamController<AnalystSeam>.broadcast();
```

- [ ] **Step 2: Subscribe inside connect()**

After the existing `socket.on('typing', ...)` handler (line 152), add:

```dart
socket.on('analyst_chunk', (data) {
  try {
    _analystChunkCtrl.add(AnalystChunk.fromJson(Map<String, dynamic>.from(data as Map)));
  } catch (e) { /* ignore malformed */ }
});
socket.on('analyst_seam', (data) {
  try {
    _analystSeamCtrl.add(AnalystSeam.fromJson(Map<String, dynamic>.from(data as Map)));
  } catch (e) { /* ignore malformed */ }
});
```

- [ ] **Step 3: Expose public streams**

In the public-getters block (around lines 187-217), add:
```dart
Stream<AnalystChunk> get analystChunkStream => _analystChunkCtrl.stream;
Stream<AnalystSeam>  get analystSeamStream  => _analystSeamCtrl.stream;
```

- [ ] **Step 4: Close controllers in dispose()**

In `dispose()` (around line 557), add:
```dart
_analystChunkCtrl.close();
_analystSeamCtrl.close();
```

- [ ] **Step 5: Verify compile**

Run: `cd /Users/dmitry/Downloads/taler_id_mobile && flutter analyze lib/features/messenger/data/datasources/messenger_remote_datasource.dart 2>&1 | head -20`
Expected: no errors.

- [ ] **Step 6: Commit**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && git add lib/features/messenger/data/datasources/messenger_remote_datasource.dart && git commit -m "feat(messenger): subscribe to analyst_chunk and analyst_seam events"
```

---

### Task 5.3: Expose streams through IMessengerRepository

**Files:**
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/messenger/domain/repositories/i_messenger_repository.dart`
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/messenger/data/repositories/messenger_repository_impl.dart`

- [ ] **Step 1: Add abstract getters to interface**

In `i_messenger_repository.dart`, add imports and getters:
```dart
import '../entities/analyst_events.dart';
// ...
abstract class IMessengerRepository {
  // ... existing ...
  Stream<AnalystChunk> get analystChunkStream;
  Stream<AnalystSeam>  get analystSeamStream;
}
```

- [ ] **Step 2: Implement in repository**

In `messenger_repository_impl.dart`:
```dart
@override
Stream<AnalystChunk> get analystChunkStream => _remote.analystChunkStream;

@override
Stream<AnalystSeam> get analystSeamStream => _remote.analystSeamStream;
```

- [ ] **Step 3: Verify compile**

Run: `cd /Users/dmitry/Downloads/taler_id_mobile && flutter analyze lib/features/messenger/ 2>&1 | head -20`
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && git add lib/features/messenger/domain/repositories/i_messenger_repository.dart lib/features/messenger/data/repositories/messenger_repository_impl.dart && git commit -m "feat(messenger): expose analyst streams via repository"
```

---

## Phase 6: Mobile — MessengerBloc handling

### Task 6.1: Add analyst events + state fields (TDD)

**Files:**
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/messenger/presentation/bloc/messenger_event.dart`
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/messenger/presentation/bloc/messenger_state.dart`
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/messenger/presentation/bloc/messenger_bloc.dart`
- Test: `/Users/dmitry/Downloads/taler_id_mobile/test/features/messenger/presentation/bloc/messenger_bloc_analyst_test.dart`

- [ ] **Step 1: Write failing BLoC test**

Create `test/features/messenger/presentation/bloc/messenger_bloc_analyst_test.dart`:

```dart
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/analyst_events.dart';
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_bloc.dart';
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_event.dart';
import 'package:taler_id_mobile/features/messenger/presentation/bloc/messenger_state.dart';
import 'package:taler_id_mobile/features/messenger/domain/repositories/i_messenger_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements IMessengerRepository {}

void main() {
  late _MockRepo repo;
  late StreamController<AnalystChunk> chunkCtrl;
  late StreamController<AnalystSeam> seamCtrl;

  setUp(() {
    repo = _MockRepo();
    chunkCtrl = StreamController<AnalystChunk>.broadcast();
    seamCtrl = StreamController<AnalystSeam>.broadcast();
    when(() => repo.analystChunkStream).thenAnswer((_) => chunkCtrl.stream);
    when(() => repo.analystSeamStream).thenAnswer((_) => seamCtrl.stream);
    // Stub the other streams the bloc subscribes to, returning empty broadcast streams.
    when(() => repo.messageStream).thenAnswer((_) => const Stream.empty());
    when(() => repo.typingStream).thenAnswer((_) => const Stream.empty());
    // Add stubs for every other stream the bloc subscribes to in _onConnect
    // — keep them as empty broadcast streams. (See messenger_bloc.dart _onConnect for the full list.)
  });

  tearDown(() async {
    await chunkCtrl.close();
    await seamCtrl.close();
  });

  test('AnalystChunkReceived appends to pendingAnalystText', () async {
    final bloc = MessengerBloc(repo: repo);
    bloc.add(const AnalystChunkReceived(conversationId: 'c', text: 'Hello '));
    await Future.delayed(const Duration(milliseconds: 10));
    expect(bloc.state.pendingAnalystText['c'], 'Hello ');
    bloc.add(const AnalystChunkReceived(conversationId: 'c', text: 'world'));
    await Future.delayed(const Duration(milliseconds: 10));
    expect(bloc.state.pendingAnalystText['c'], 'Hello world');
    await bloc.close();
  });

  test('AnalystSeamReceived stores seam by messageId', () async {
    final bloc = MessengerBloc(repo: repo);
    bloc.add(AnalystSeamReceived(
      seam: const AnalystSeam(
        conversationId: 'c', messageId: 'm', steps: [SeamStep(kind: 'file', count: 3)],
        durationMs: 100,
      ),
    ));
    await Future.delayed(const Duration(milliseconds: 10));
    expect(bloc.state.analystSeams['m']?.steps.first.kind, 'file');
    await bloc.close();
  });

  test('MessageReceived for AI_ANALYST bot clears pendingAnalystText for that conv', () async {
    // ... See full implementation below in "Implementation details".
  });
}
```

- [ ] **Step 2: Run test — FAIL**

Run: `cd /Users/dmitry/Downloads/taler_id_mobile && flutter test test/features/messenger/presentation/bloc/messenger_bloc_analyst_test.dart 2>&1 | tail -10`
Expected: FAIL — `AnalystChunkReceived` not defined.

- [ ] **Step 3: Add events to `messenger_event.dart`**

At the bottom of event classes:

```dart
class AnalystChunkReceived extends MessengerEvent {
  final String conversationId;
  final String text;
  const AnalystChunkReceived({required this.conversationId, required this.text});
  @override
  List<Object?> get props => [conversationId, text];
}

class AnalystSeamReceived extends MessengerEvent {
  final AnalystSeam seam;
  const AnalystSeamReceived({required this.seam});
  @override
  List<Object?> get props => [seam];
}

class AnalystPendingTextCleared extends MessengerEvent {
  final String conversationId;
  const AnalystPendingTextCleared({required this.conversationId});
  @override
  List<Object?> get props => [conversationId];
}
```

Import `analyst_events.dart` at the top.

- [ ] **Step 4: Extend state in `messenger_state.dart`**

Add fields:
```dart
import '../../domain/entities/analyst_events.dart';
// ...
class MessengerState extends Equatable {
  // ... existing fields ...
  final Map<String, String> pendingAnalystText;   // convId → accumulated text
  final Map<String, AnalystSeam> analystSeams;    // messageId → seam
  // ...
  const MessengerState({
    // ... existing ...
    this.pendingAnalystText = const {},
    this.analystSeams = const {},
  });
  MessengerState copyWith({
    // ... existing ...
    Map<String, String>? pendingAnalystText,
    Map<String, AnalystSeam>? analystSeams,
  }) => MessengerState(
    // ... existing ...
    pendingAnalystText: pendingAnalystText ?? this.pendingAnalystText,
    analystSeams: analystSeams ?? this.analystSeams,
  );
  @override
  List<Object?> get props => [
    // ... existing ...
    pendingAnalystText, analystSeams,
  ];
}
```

- [ ] **Step 5: Handle events in bloc**

In `messenger_bloc.dart`, inside constructor register handlers:

```dart
on<AnalystChunkReceived>(_onAnalystChunk);
on<AnalystSeamReceived>(_onAnalystSeam);
on<AnalystPendingTextCleared>(_onAnalystPendingTextCleared);
```

Implement:
```dart
Future<void> _onAnalystChunk(AnalystChunkReceived e, Emitter<MessengerState> emit) async {
  final current = state.pendingAnalystText[e.conversationId] ?? '';
  emit(state.copyWith(pendingAnalystText: {
    ...state.pendingAnalystText,
    e.conversationId: current + e.text,
  }));
}

Future<void> _onAnalystSeam(AnalystSeamReceived e, Emitter<MessengerState> emit) async {
  emit(state.copyWith(analystSeams: {
    ...state.analystSeams,
    e.seam.messageId: e.seam,
  }));
}

Future<void> _onAnalystPendingTextCleared(AnalystPendingTextCleared e, Emitter<MessengerState> emit) async {
  if (!state.pendingAnalystText.containsKey(e.conversationId)) return;
  final next = Map<String, String>.from(state.pendingAnalystText)..remove(e.conversationId);
  emit(state.copyWith(pendingAnalystText: next));
}
```

Subscribe to the two streams in `_onConnect()` (near existing `_msgSub = ...`):

```dart
_analystChunkSub = _repo.analystChunkStream.listen(
  (c) => add(AnalystChunkReceived(conversationId: c.conversationId, text: c.text)),
);
_analystSeamSub = _repo.analystSeamStream.listen(
  (s) => add(AnalystSeamReceived(seam: s)),
);
```

Add the two `StreamSubscription<>` fields and close them in the bloc's `close()` method alongside existing subscriptions.

In `_onMessageReceived` (line 552 per research), after the message is applied to state, if it's an AI_ANALYST bot message clear the pending text:
```ts
// AT END of _onMessageReceived, before emit/return:
if (m.isSystem && state.pendingAnalystText.containsKey(m.conversationId)) {
  final next = Map<String, String>.from(state.pendingAnalystText)..remove(m.conversationId);
  // fold into the main emit: include pendingAnalystText: next in copyWith
}
```

Adjust the final emit of `_onMessageReceived` to include `pendingAnalystText: next ?? state.pendingAnalystText`. Keep existing fields intact.

- [ ] **Step 6: Run the failing test**

Run: `cd /Users/dmitry/Downloads/taler_id_mobile && flutter test test/features/messenger/presentation/bloc/messenger_bloc_analyst_test.dart 2>&1 | tail -10`
Expected: PASS — both first two tests. Extend the `MessageReceived` test now:

```dart
test('MessageReceived for AI_ANALYST bot clears pendingAnalystText for that conv', () async {
  final bloc = MessengerBloc(repo: repo);
  bloc.add(const AnalystChunkReceived(conversationId: 'c', text: 'hi'));
  await Future.delayed(const Duration(milliseconds: 10));
  expect(bloc.state.pendingAnalystText['c'], 'hi');

  final msg = MessageEntity(
    id: 'm', conversationId: 'c', senderId: 'bot',
    content: 'final answer', sentAt: DateTime.now(), isSystem: true,
  );
  bloc.add(MessageReceived(msg));
  await Future.delayed(const Duration(milliseconds: 10));
  expect(bloc.state.pendingAnalystText.containsKey('c'), false);
  await bloc.close();
});
```

Run test again — should PASS.

- [ ] **Step 7: Commit**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && git add lib/features/messenger/presentation/bloc/ test/features/messenger/presentation/bloc/messenger_bloc_analyst_test.dart && git commit -m "feat(messenger): handle analyst_chunk and analyst_seam in MessengerBloc"
```

---

## Phase 7: Mobile — UI widgets

### Task 7.1: Extract _TypingDots to reusable widget

**Files:**
- Create: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/messenger/presentation/widgets/typing_dots.dart`
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/messenger/presentation/screens/chat_room_screen.dart` (replace private `_TypingDots` usage with import)

- [ ] **Step 1: Copy the widget**

Copy the class `_TypingDots` from `chat_room_screen.dart:4628-4682` into a new file `lib/features/messenger/presentation/widgets/typing_dots.dart`. Rename to `TypingDots`, keep implementation identical.

- [ ] **Step 2: Import and use**

In `chat_room_screen.dart` top imports:
```dart
import '../widgets/typing_dots.dart';
```
Replace every `_TypingDots(...)` usage with `TypingDots(...)`. Delete the private `_TypingDots` class from the file.

- [ ] **Step 3: Verify compile + existing typing works**

Run: `cd /Users/dmitry/Downloads/taler_id_mobile && flutter analyze lib/features/messenger/ 2>&1 | head -20`
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && git add lib/features/messenger/presentation/widgets/typing_dots.dart lib/features/messenger/presentation/screens/chat_room_screen.dart && git commit -m "refactor(messenger): extract TypingDots to reusable widget"
```

---

### Task 7.2: AnalystStreamingBubble widget (TDD)

**Files:**
- Create: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/messenger/presentation/widgets/analyst_streaming_bubble.dart`
- Test: `/Users/dmitry/Downloads/taler_id_mobile/test/features/messenger/presentation/widgets/analyst_streaming_bubble_test.dart`

- [ ] **Step 1: Write failing widget test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taler_id_mobile/features/messenger/presentation/widgets/analyst_streaming_bubble.dart';

void main() {
  testWidgets('renders pending text and a blinking cursor', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: AnalystStreamingBubble(text: 'Hello world')),
    ));
    expect(find.text('Hello world'), findsOneWidget);
    // Cursor widget has key
    expect(find.byKey(const Key('analyst-streaming-cursor')), findsOneWidget);
  });

  testWidgets('re-renders when text grows', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: AnalystStreamingBubble(text: 'Hello')),
    ));
    expect(find.text('Hello'), findsOneWidget);
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: AnalystStreamingBubble(text: 'Hello, world')),
    ));
    expect(find.text('Hello, world'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run to FAIL**

Run: `cd /Users/dmitry/Downloads/taler_id_mobile && flutter test test/features/messenger/presentation/widgets/analyst_streaming_bubble_test.dart 2>&1 | tail -10`
Expected: FAIL — module not found.

- [ ] **Step 3: Create the widget**

```dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class AnalystStreamingBubble extends StatefulWidget {
  final String text;
  const AnalystStreamingBubble({super.key, required this.text});

  @override
  State<AnalystStreamingBubble> createState() => _AnalystStreamingBubbleState();
}

class _AnalystStreamingBubbleState extends State<AnalystStreamingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(widget.text, style: TextStyle(color: colors.textPrimary, fontSize: 15)),
            FadeTransition(
              key: const Key('analyst-streaming-cursor'),
              opacity: _blink,
              child: Container(
                margin: const EdgeInsets.only(left: 2),
                width: 2, height: 16,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run — PASS**

Run: `cd /Users/dmitry/Downloads/taler_id_mobile && flutter test test/features/messenger/presentation/widgets/analyst_streaming_bubble_test.dart 2>&1 | tail -10`
Expected: both tests pass.

- [ ] **Step 5: Commit**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && git add lib/features/messenger/presentation/widgets/analyst_streaming_bubble.dart test/features/messenger/presentation/widgets/analyst_streaming_bubble_test.dart && git commit -m "feat(messenger): AnalystStreamingBubble widget"
```

---

### Task 7.3: AnalystSeamWidget (TDD)

**Files:**
- Create: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/messenger/presentation/widgets/analyst_seam_widget.dart`
- Test: `/Users/dmitry/Downloads/taler_id_mobile/test/features/messenger/presentation/widgets/analyst_seam_widget_test.dart`

- [ ] **Step 1: Add localization keys**

In `lib/l10n/app_en.arb`, add near the end (before the closing `}`):
```json
"analystSeamSearches": "{count} {count, plural, =1{search} other{searches}}",
"@analystSeamSearches": { "placeholders": { "count": { "type": "int" } } },
"analystSeamFiles": "{count} {count, plural, =1{file} other{files}}",
"@analystSeamFiles": { "placeholders": { "count": { "type": "int" } } },
"analystSeamCommands": "{count} {count, plural, =1{command} other{commands}}",
"@analystSeamCommands": { "placeholders": { "count": { "type": "int" } } },
"analystSeamImages": "{count} {count, plural, =1{image} other{images}}",
"@analystSeamImages": { "placeholders": { "count": { "type": "int" } } },
"analystSeamOther": "{count} {count, plural, =1{step} other{steps}}",
"@analystSeamOther": { "placeholders": { "count": { "type": "int" } } },
"analystSeamDurationSeconds": "{seconds}s",
"@analystSeamDurationSeconds": { "placeholders": { "seconds": { "type": "int" } } },
```

In `lib/l10n/app_ru.arb` add the Russian equivalents:
```json
"analystSeamSearches": "{count, plural, =1{{count} поиск} few{{count} поиска} many{{count} поисков} other{{count} поиска}}",
"analystSeamFiles": "{count, plural, =1{{count} файл} few{{count} файла} many{{count} файлов} other{{count} файла}}",
"analystSeamCommands": "{count, plural, =1{{count} команда} few{{count} команды} many{{count} команд} other{{count} команды}}",
"analystSeamImages": "{count, plural, =1{{count} картинка} few{{count} картинки} many{{count} картинок} other{{count} картинки}}",
"analystSeamOther": "{count, plural, =1{{count} шаг} few{{count} шага} many{{count} шагов} other{{count} шага}}",
"analystSeamDurationSeconds": "{seconds} с",
```

Regenerate: `cd /Users/dmitry/Downloads/taler_id_mobile && flutter gen-l10n 2>&1 | tail -5`
Expected: success, `app_localizations_*.dart` updated.

- [ ] **Step 2: Write failing widget test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:taler_id_mobile/l10n/app_localizations.dart';
import 'package:taler_id_mobile/features/messenger/domain/entities/analyst_events.dart';
import 'package:taler_id_mobile/features/messenger/presentation/widgets/analyst_seam_widget.dart';

Widget _wrap(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('renders English pluralized labels and duration', (tester) async {
    await tester.pumpWidget(_wrap(const AnalystSeamWidget(seam: AnalystSeam(
      conversationId: 'c', messageId: 'm',
      steps: [SeamStep(kind: 'search', count: 2), SeamStep(kind: 'file', count: 1)],
      durationMs: 12400,
    ))));
    await tester.pump();
    expect(find.textContaining('2 searches'), findsOneWidget);
    expect(find.textContaining('1 file'), findsOneWidget);
    expect(find.textContaining('12s'), findsOneWidget);
  });

  testWidgets('renders Russian pluralized labels (few form)', (tester) async {
    await tester.pumpWidget(_wrap(const AnalystSeamWidget(seam: AnalystSeam(
      conversationId: 'c', messageId: 'm',
      steps: [SeamStep(kind: 'cmd', count: 3)],
      durationMs: 5000,
    )), locale: const Locale('ru')));
    await tester.pump();
    expect(find.textContaining('3 команды'), findsOneWidget);
    expect(find.textContaining('5 с'), findsOneWidget);
  });
}
```

- [ ] **Step 3: Run — FAIL**

Run: `cd /Users/dmitry/Downloads/taler_id_mobile && flutter test test/features/messenger/presentation/widgets/analyst_seam_widget_test.dart 2>&1 | tail -10`
Expected: FAIL — widget not found.

- [ ] **Step 4: Create the widget**

```dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/analyst_events.dart';

class AnalystSeamWidget extends StatelessWidget {
  final AnalystSeam seam;
  const AnalystSeamWidget({super.key, required this.seam});

  String _labelFor(SeamStep step, AppLocalizations l10n) {
    switch (step.kind) {
      case 'search': return l10n.analystSeamSearches(step.count);
      case 'file':   return l10n.analystSeamFiles(step.count);
      case 'cmd':    return l10n.analystSeamCommands(step.count);
      case 'image':  return l10n.analystSeamImages(step.count);
      default:       return l10n.analystSeamOther(step.count);
    }
  }

  String _emojiFor(String kind) {
    switch (kind) {
      case 'search': return '🔍';
      case 'file':   return '📄';
      case 'cmd':    return '💻';
      case 'image':  return '🎨';
      default:       return '⚙️';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = AppColors.of(context);
    final parts = <String>[
      for (final s in seam.steps) '${_emojiFor(s.kind)} ${_labelFor(s, l10n)}',
      '⏱ ${l10n.analystSeamDurationSeconds((seam.durationMs / 1000).round())}',
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.card.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        parts.join(' · '),
        style: TextStyle(color: colors.textSecondary, fontSize: 11),
      ),
    );
  }
}
```

- [ ] **Step 5: Run — PASS**

Run: `cd /Users/dmitry/Downloads/taler_id_mobile && flutter test test/features/messenger/presentation/widgets/analyst_seam_widget_test.dart 2>&1 | tail -10`
Expected: both tests PASS.

- [ ] **Step 6: Commit**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && git add lib/features/messenger/presentation/widgets/analyst_seam_widget.dart test/features/messenger/presentation/widgets/analyst_seam_widget_test.dart lib/l10n/ && git commit -m "feat(messenger): AnalystSeamWidget with ru/en pluralization"
```

---

## Phase 8: Mobile — Wire everything in ChatRoomScreen

### Task 8.1: Render streaming bubble + seam in chat_room_screen

**Files:**
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/messenger/presentation/screens/chat_room_screen.dart`

- [ ] **Step 1: Add imports**

```dart
import '../widgets/analyst_streaming_bubble.dart';
import '../widgets/analyst_seam_widget.dart';
import '../../domain/entities/analyst_events.dart';
```

- [ ] **Step 2: Render streaming bubble in message list**

In the ListView.builder (line 1908-1923), since it's `reverse: true` with `chronIdx = messages.length - 1 - index`, we need to show the streaming bubble at `index == 0` (top of list visually = latest item). Adjust `itemCount` and `itemBuilder`:

Find the `ListView.builder(...)` call. Wrap current `itemCount` with:
```dart
final pendingText = state.pendingAnalystText[conversationId] ?? '';
final hasStreaming = analystChat && pendingText.isNotEmpty;
return ListView.builder(
  // ... existing props ...
  itemCount: messages.length + (hasStreaming ? 1 : 0),
  itemBuilder: (context, index) {
    if (hasStreaming && index == 0) {
      return AnalystStreamingBubble(text: pendingText);
    }
    final messageIndex = hasStreaming ? index - 1 : index;
    final chronIdx = messages.length - 1 - messageIndex;
    // ... rest unchanged, using chronIdx ...
  },
);
```

Verify `state.pendingAnalystText` is read inside the parent `BlocBuilder<MessengerBloc, MessengerState>` that wraps the ListView. If not, add the dependency.

- [ ] **Step 3: Render seam above AI_ANALYST bot bubbles**

In `itemBuilder`, inside the existing `_MessageBubble` rendering block (around line 1987), if `conv.type == 'AI_ANALYST'` and `msg.isSystem`, wrap the bubble in a Column:

```dart
if (analystChat && msg.isSystem) {
  // Prefer live seam from state, fall back to metadata
  final liveSeam = state.analystSeams[msg.id];
  final metaSeam = AnalystSeam.fromMetadata(
    conversationId: msg.conversationId,
    messageId: msg.id,
    metadata: msg.metadata,
  );
  final seam = liveSeam ?? metaSeam;
  if (seam != null) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnalystSeamWidget(seam: seam),
        _MessageBubble( /* existing args */ ),
      ],
    );
  }
}
return _MessageBubble( /* existing args */ );
```

- [ ] **Step 4: Run flutter analyze**

Run: `cd /Users/dmitry/Downloads/taler_id_mobile && flutter analyze lib/features/messenger/presentation/screens/chat_room_screen.dart 2>&1 | head -20`
Expected: no errors. If there are minor unused-import warnings, keep going.

- [ ] **Step 5: Commit**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && git add lib/features/messenger/presentation/screens/chat_room_screen.dart && git commit -m "feat(messenger): render streaming bubble and seam in AI_ANALYST chat"
```

---

## Phase 9: Remove unused chat module

### Task 9.1: Delete lib/features/chat/ and references

**Files:**
- Delete: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/chat/` (entire tree — 10 files per research)
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/lib/core/di/service_locator.dart` (lines around 166-172 and 198)
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/lib/core/router/app_router.dart` (line 28 import, lines 106-109 route)
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/lib/core/utils/constants.dart` (line 37 — `RouteConstants.chat`)

- [ ] **Step 1: Verify no external references**

Run:
```bash
cd /Users/dmitry/Downloads/taler_id_mobile && grep -rn "ChatBloc\|features/chat\|RouteConstants.chat" lib/ --include="*.dart"
```
Expected: matches only inside `lib/features/chat/`, `service_locator.dart:198`, `app_router.dart:28+107`, and `constants.dart:37`. If there are OTHER references, STOP — investigate.

- [ ] **Step 2: Remove DI registration**

In `service_locator.dart`, remove:
- Line 198: `sl.registerFactory(() => ChatBloc(repo: sl<IChatRepository>()));`
- Lines ~166-172: the chat datasource + repository registrations (read first to confirm)
- Any `import '../../features/chat/...'` lines

- [ ] **Step 3: Remove route + import**

In `app_router.dart`:
- Delete line 28 (`import '../../features/chat/presentation/screens/chat_screen.dart';`)
- Delete lines 106-109 (the `/chat` GoRoute)

- [ ] **Step 4: Remove RouteConstants.chat**

In `lib/core/utils/constants.dart:37`, delete the `static const chat = '/chat';` line. (If other things reference it, grep will have caught them.)

- [ ] **Step 5: Delete the feature directory**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && rm -rf lib/features/chat/
```

- [ ] **Step 6: Remove chat-only l10n keys (if any)**

Grep remaining ARB keys that might be chat-specific:
```bash
grep -n "chatSendButton\|chatTitle\|chatClear\|chatInput" lib/l10n/*.arb lib/
```
Any keys used only by deleted `ChatScreen` → remove from both arb files + regenerate `flutter gen-l10n`.

- [ ] **Step 7: Verify build**

Run: `cd /Users/dmitry/Downloads/taler_id_mobile && flutter analyze 2>&1 | tail -20`
Expected: no errors related to chat. Warnings/info OK.

Run: `cd /Users/dmitry/Downloads/taler_id_mobile && flutter test 2>&1 | tail -10`
Expected: all tests pass.

- [ ] **Step 8: Commit**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && git add -A lib/ && git commit -m "chore: remove unused lib/features/chat/ module"
```

---

## Phase 10: Deploy to DEV + pre-deploy regression

### Task 10.1: Push backend changes + deploy to DEV server

**Files:** (changes done in `/Users/dmitry/taler-id/`)

- [ ] **Step 1: Push backend to GitHub**

```bash
cd /Users/dmitry/taler-id && git push origin dev 2>&1 | tail -5
```
Expected: success, or fast-forward.

- [ ] **Step 2: Deploy to DEV server (backend)**

```bash
ssh dvolkov@89.169.55.217 'cd ~/taler-id && git pull && npx prisma migrate deploy && npm run build && pm2 restart taler-id-dev && pm2 logs taler-id-dev --lines 30 --nostream'
```
Expected: git pull succeeds; migration applies `Message.metadata`; `pm2 restart` OK; last 30 log lines show clean startup (no errors about missing column or failing gateway).

If the migration fails, STOP and investigate. Do NOT deploy to PROD.

- [ ] **Step 3: Smoke-test analyst chat via API**

Run: `cd /Users/dmitry/Downloads/taler_id_tests && npm run test:analyst 2>&1 | tail -20`
Expected: existing size-limit test passes (regression check — our changes shouldn't break it).

---

### Task 10.2: Build mobile dev APK + push

- [ ] **Step 1: Push mobile changes**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && git push origin dev 2>&1 | tail -5
```
Expected: success.

- [ ] **Step 2: Build dev APK (on PROD server — only place with Flutter SDK)**

```bash
ssh dvolkov@138.124.61.221 'cd ~/taler_id_mobile && git fetch && git checkout dev && git pull && flutter build apk --flavor dev --release -t lib/main_dev.dart --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol'
```
Expected: success, APK at `build/app/outputs/flutter-apk/app-dev-release.apk`.

- [ ] **Step 3: Publish APK**

```bash
ssh dvolkov@138.124.61.221 'sudo cp ~/taler_id_mobile/build/app/outputs/flutter-apk/app-dev-release.apk /var/www/downloads/taler-id-dev.apk && sudo chmod 644 /var/www/downloads/taler-id-dev.apk'
```
Expected: no errors. URL `https://id.taler.tirol/download/taler-id-dev.apk` serves the new APK.

---

### Task 10.3: Run full pre-deploy regression (from CLAUDE.md §🧪)

All tests below MUST pass. **If any fail, STOP. Do not release.**

- [ ] **Step 1: Flutter unit tests**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && flutter test
```
Expected: all green, including the new tests.

- [ ] **Step 2: Flutter integration test (with AI_ANALYST extension)**

Start emulator:
```bash
flutter emulators --launch Pixel_XL_API_33
sleep 20
~/Library/Android/sdk/platform-tools/adb devices
```

Run:
```bash
cd /Users/dmitry/Downloads/taler_id_mobile && flutter test integration_test/app_test.dart --flavor dev --dart-define=FLAVOR=dev --dart-define=BASE_URL=https://staging.id.taler.tirol -d emulator-5554
```
Expected: full test passes. (The test currently walks all 5 tabs; it does NOT yet visit AI Analyst chat. Extending it is a nice-to-have — see Task 10.4 — but not required for first DEV release.)

- [ ] **Step 3: Two-emulator call test**

```bash
flutter emulators --launch Pixel_XL_API_33
~/Library/Android/sdk/emulator/emulator -avd Pixel_XL_2_API_33 -port 5556 -read-only &
sleep 20
~/Library/Android/sdk/platform-tools/adb -s emulator-5554 shell pm grant tirol.taler.taler_id_mobile.dev android.permission.RECORD_AUDIO
~/Library/Android/sdk/platform-tools/adb -s emulator-5556 shell pm grant tirol.taler.taler_id_mobile.dev android.permission.RECORD_AUDIO
cd /Users/dmitry/Downloads/taler_id_mobile && bash integration_test/run_call_test.sh
```
Expected: passes. (Known flaky on emulator — if it fails with `HandshakeException`, run on real devices per CLAUDE.md.)

- [ ] **Step 4: Extend `test:analyst` to validate new events**

**Files:**
- Modify: `/Users/dmitry/Downloads/taler_id_tests/ai_analyst_size_limit_test.ts`

Before running the full regression, add a new test block that opens a socket to `/messenger`, sends a message to an existing AI_ANALYST conversation, and asserts that it receives:
1. at least one `typing` event with `typingText` containing one of the expected emojis (`🤔`, `🔍`, `📄`, `💻`, `✍️`)
2. exactly one `analyst_seam` event with `steps` array and `messageId`
3. a final `new_message` whose `metadata.steps` matches the `analyst_seam.steps`

Append (adjust to match existing test harness — it already has login + token machinery):

```ts
// === AI Analyst live-status smoke test ===
console.log('\n=== Live-status events test ===');
const socket = io(`${BASE_URL.replace(/^https?:/, 'wss:')}/messenger`, {
  auth: { token: accessToken }, transports: ['websocket'],
});
const events: Array<{ event: string; data: any }> = [];
socket.on('typing', (d) => events.push({ event: 'typing', data: d }));
socket.on('analyst_seam', (d) => events.push({ event: 'analyst_seam', data: d }));
socket.on('new_message', (d) => events.push({ event: 'new_message', data: d }));

await new Promise((resolve) => socket.on('connect', resolve));
// Find or create the AI_ANALYST conversation — reuse logic from existing size-limit test.
const analystConv = await findOrCreateAnalystConversation(accessToken);
socket.emit('join', { conversationId: analystConv.id });
socket.emit('message', { conversationId: analystConv.id, content: 'say hi in 3 words' });

// Wait up to 60 s for analyst_seam + new_message
const deadline = Date.now() + 60_000;
while (Date.now() < deadline) {
  if (events.some(e => e.event === 'analyst_seam') && events.some(e => e.event === 'new_message')) break;
  await new Promise(r => setTimeout(r, 500));
}

// Assertions
const typingEvents = events.filter(e => e.event === 'typing' && /[🤔🔍📄💻✍️]/.test(e.data.typingText ?? ''));
assert(typingEvents.length >= 1, `Expected at least one emoji typing event, got ${typingEvents.length}`);

const seam = events.find(e => e.event === 'analyst_seam');
assert(seam, 'Expected analyst_seam event');
assert(Array.isArray(seam.data.steps), 'analyst_seam.steps must be array');
assert(typeof seam.data.messageId === 'string', 'analyst_seam.messageId must be string');

const finalMsg = events.find(e => e.event === 'new_message' && e.data.isSystem);
assert(finalMsg, 'Expected new_message (system=true)');
assert(finalMsg.data.metadata?.steps, 'Final message must have metadata.steps');

socket.disconnect();
console.log('✓ Live-status test passed');
```

Add `findOrCreateAnalystConversation(accessToken)` helper near the top if it doesn't exist — it should GET `/messenger/conversations` and return the one with `type === 'AI_ANALYST'` (the backend auto-creates it per user on first request).

- [ ] **Step 5: Run the extended test**

Run: `cd /Users/dmitry/Downloads/taler_id_tests && npm run test:analyst`
Expected: both the size-limit assertions AND the new live-status assertions pass.

- [ ] **Step 6: Run full backend regression**

```bash
cd /Users/dmitry/Downloads/taler_id_tests && npm test && npm run test:voice && npm run test:assistant && npm run test:files && npm run test:channels && npm run test:billing && npm run test:analyst
```
Expected: all pass against DEV.

- [ ] **Step 7: Manual smoke test (phone or emulator)**

1. Install the new `taler-id-dev.apk`
2. Log in as `integration_test@taler-test.com`
3. Open AI Аналитик chat
4. Send: "найди мне три кафе рядом с Большим театром"
5. Verify:
   - "🤔 Думаю…" typing indicator appears immediately
   - "🔍 Ищу в интернете…" appears when web search happens
   - (possibly) "📄 Читаю файл…" if worker fetches pages
   - "✍️ Готовлю ответ…" appears before text starts streaming
   - Text streams into a bubble token-by-token with a blinking cursor
   - On completion, cursor disappears; compact seam `🔍 1 поиск · ⏱ N с` appears above bubble
   - Kill the app, reopen chat — seam still visible on the bot's message

Report back any deviations before marking this checkpoint complete.

---

### Task 10.4: (Optional, recommended) Extend integration_test with AI Analyst step

**Files:**
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/integration_test/app_test.dart`

Add a test step that opens the AI Аналитик chat, sends a message, waits for the typing indicator, then waits for a message to arrive.

- [ ] **Step 1: Add step**

Inside the existing `testWidgets('Login → Dashboard → All screens → Sub-screens', ...)`, after the Messenger tab check, add:

```dart
// === AI Analyst typing indicator check ===
// Navigate to Messenger tab (already there in prior step)
// Find AI Аналитик conversation tile (senderName 'AI Аналитик')
final analystTile = find.text('AI Аналитик').first;
if (analystTile.evaluate().isNotEmpty) {
  await tester.safeTap(analystTile);
  await tester.pumpFor(const Duration(seconds: 2));

  // Find text input, send a simple message
  final inputField = find.byType(TextField).last;
  await tester.enterText(inputField, 'say hi');
  await tester.pumpFor(const Duration(milliseconds: 500));
  // find send button
  final sendBtn = find.byIcon(Icons.send).first;
  await tester.safeTap(sendBtn);

  // Wait up to 15s for typing indicator to appear (has 🤔 or 🔍 or ✍️)
  await tester.waitFor(
    () => find.textContaining(RegExp(r'[🤔🔍📄💻✍️]')).evaluate().isNotEmpty,
    timeout: const Duration(seconds: 15),
  );
  print('✓ AI Analyst typing indicator appeared');

  // Wait up to 60s for final message (typing indicator gone + new bubble)
  await tester.pumpFor(const Duration(seconds: 60));
  print('✓ AI Analyst responded');

  await tester.goHome();
}
```

- [ ] **Step 2: Run to verify**

Run same command as Task 10.3 Step 2. Expected: passes.

- [ ] **Step 3: Commit**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && git add integration_test/app_test.dart && git commit -m "test(integration): add AI Analyst live-status smoke step" && git push origin dev
```

---

## Phase 11: PROD deploy — ONLY when user explicitly says so

**Do NOT run this phase automatically.** Wait for user to say "deploy to PROD" or equivalent.

### Task 11.1: PROD deploy checklist

- [ ] **Step 1: Wait for explicit user OK for PROD**

- [ ] **Step 2: Merge dev → main**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && git checkout main && git pull && git merge dev && git push origin main
cd /Users/dmitry/taler-id && git checkout main && git pull && git merge dev && git push origin main
```

- [ ] **Step 3: Backend PROD deploy**

```bash
ssh dvolkov@138.124.61.221 'cd ~/taler-id && git pull && npx prisma migrate deploy && npm run build && pm2 restart taler-id'
```

- [ ] **Step 4: Mobile PROD APK build**

```bash
ssh dvolkov@138.124.61.221 'cd ~/taler_id_mobile && git checkout main && git pull && flutter build apk --flavor prod --release --dart-define=FLAVOR=prod && sudo cp build/app/outputs/flutter-apk/app-prod-release.apk /var/www/downloads/taler-id.apk && sudo chmod 644 /var/www/downloads/taler-id.apk'
```

- [ ] **Step 5: iOS TestFlight (optional)**

Per CLAUDE.md §iOS (TestFlight).

- [ ] **Step 6: Run PROD regression**

```bash
cd /Users/dmitry/Downloads/taler_id_tests && npm run test:prod && npm run test:voice:prod && npm run test:assistant:prod && npm run test:files:prod && npm run test:channels:prod && npm run test:billing:prod
```
Expected: all green.

---

## Appendix — Files summary

### Backend (`/Users/dmitry/taler-id/`)

Created:
- `src/ai-analyst/ai-analyst-labels.ts`
- `src/ai-analyst/ai-analyst-labels.spec.ts`
- `src/messenger/messenger.gateway.analyst.spec.ts`
- `prisma/migrations/<timestamp>_message_metadata/migration.sql`

Modified:
- `prisma/schema.prisma` (Message model)
- `src/messenger/messenger.service.ts` (createMessage signature)
- `src/messenger/messenger.gateway.ts` (getUserLang helper, `_dispatchToAnalyst` rewrite, imports)

### Mobile (`/Users/dmitry/Downloads/taler_id_mobile/`)

Created:
- `lib/features/messenger/domain/entities/analyst_events.dart`
- `lib/features/messenger/presentation/widgets/typing_dots.dart`
- `lib/features/messenger/presentation/widgets/analyst_streaming_bubble.dart`
- `lib/features/messenger/presentation/widgets/analyst_seam_widget.dart`
- `test/features/messenger/domain/entities/analyst_events_test.dart`
- `test/features/messenger/presentation/bloc/messenger_bloc_analyst_test.dart`
- `test/features/messenger/presentation/widgets/analyst_streaming_bubble_test.dart`
- `test/features/messenger/presentation/widgets/analyst_seam_widget_test.dart`

Modified:
- `lib/features/messenger/domain/entities/message_entity.dart` (+ .freezed.dart + .g.dart regenerated)
- `lib/features/messenger/data/datasources/messenger_remote_datasource.dart`
- `lib/features/messenger/domain/repositories/i_messenger_repository.dart`
- `lib/features/messenger/data/repositories/messenger_repository_impl.dart`
- `lib/features/messenger/presentation/bloc/messenger_event.dart`
- `lib/features/messenger/presentation/bloc/messenger_state.dart`
- `lib/features/messenger/presentation/bloc/messenger_bloc.dart`
- `lib/features/messenger/presentation/screens/chat_room_screen.dart`
- `lib/l10n/app_en.arb` + `app_ru.arb` (+ regenerated localizations)
- `integration_test/app_test.dart` (Task 10.4, optional)

Deleted:
- `lib/features/chat/` (entire tree)
- `lib/core/di/service_locator.dart` (chat registrations)
- `lib/core/router/app_router.dart` (chat import + route)
- `lib/core/utils/constants.dart` (RouteConstants.chat)
