# Taler ID Agent Shell — Phase 0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Validate end-to-end architecture (OpenAI Realtime → `agent_task` tool → Claude Agent Loop → echo tool → spoken response) by building a thin spike: Anthropic API proxy in the NestJS backend, Claude Agent Loop in Dart, one trivial `echo` tool, basic chat UI, and launcher-mode intent filter. After Phase 0 Дмитрий switches his Pixel to Taler ID as default home and starts journaling pain points.

**Architecture:** Backend gains a JWT-protected `POST /agent/claude` proxy that forwards Anthropic Messages API requests and hides the API key. Flutter gains a `core/agent` module with `AnthropicClient` (Dio wrapper), `AgentLoop` (Messages-API tool_use cycle), `ToolRegistry` (`echo` only in Phase 0), `AgentBloc` (chat state), and `AgentShellHomeScreen`. The existing OpenAI Realtime session in `assistant_screen.dart` gets one new tool `agent_task(goal)` whose handler delegates to `AgentLoop` and returns the result back to Realtime for speech synthesis.

**Tech Stack:** Flutter (Dart ≥3.6.0), `flutter_bloc`, `freezed`, `dio`, `mocktail` (tests), `go_router`, `get_it`. Backend: NestJS, Jest + supertest, `node-fetch` (or built-in `fetch`), `@nestjs/common`/`@nestjs/passport`. Claude model default: `claude-sonnet-4-6`.

**Spec reference:** `docs/superpowers/specs/2026-05-18-taler-agent-shell-design.md`

**Branches:**
- Mobile: `feature/agent-shell-phase-0` off `dev` in `/Users/dmitry/Downloads/taler_id_mobile/`
- Backend: `feature/agent-shell-phase-0` off `main` in `/Users/dmitry/Downloads/taler_id/`

**Deploy target:** DEV only (`dvolkov@89.169.55.217`). PROD untouched. Per CLAUDE.md rule.

**Out of scope for Phase 0** (explicit, do NOT add):
- Any tools other than `echo` (no system.*, no call.*, no dev.* — those come in Phase 1+)
- Wake-word / Porcupine
- Accessibility Service
- Dynamic UI widgets beyond plain text bubbles
- iOS support
- Daily-driver hardening (foreground service, battery audit, etc.) — Phase 6

---

## Task 1: Create feature branches and verify clean working trees

**Files:** No code changes. Branch setup only.

- [ ] **Step 1.1: Verify mobile repo clean state**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && git status
```

Expected: working tree clean (or only the pre-existing `ios/Podfile.lock` modification untracked). If your own modifications exist, stash them first: `git stash push -m "pre-agent-shell"`.

- [ ] **Step 1.2: Create mobile feature branch off `dev`**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile
git checkout dev
git pull origin dev
git checkout -b feature/agent-shell-phase-0
```

- [ ] **Step 1.3: Verify backend repo clean state**

```bash
cd /Users/dmitry/Downloads/taler_id && git status
```

Expected: clean.

- [ ] **Step 1.4: Create backend feature branch off `main`**

```bash
cd /Users/dmitry/Downloads/taler_id
git checkout main
git pull origin main
git checkout -b feature/agent-shell-phase-0
```

- [ ] **Step 1.5: Confirm both branches active**

```bash
git -C /Users/dmitry/Downloads/taler_id_mobile branch --show-current
git -C /Users/dmitry/Downloads/taler_id branch --show-current
```

Expected output:
```
feature/agent-shell-phase-0
feature/agent-shell-phase-0
```

No commit yet — branches are empty deltas.

---

## Task 2: Backend — Add Anthropic API key to env

**Files:**
- Modify: `/Users/dmitry/Downloads/taler_id/.env.example` (or `.env` if no example exists)
- Modify: `/Users/dmitry/Downloads/taler_id/.env` on DEV server

- [ ] **Step 2.1: Get the Anthropic API key**

Use the existing Anthropic console key (Дмитрий's). Generate one if needed at https://console.anthropic.com/. Save as `ANTHROPIC_API_KEY=sk-ant-...`.

Also decide if proxying through DigitalOcean is needed (AEZA RU IP может блокироваться Anthropic). For Phase 0 — try direct first; if 403/connection refused, add `ANTHROPIC_BASE_URL=http://167.172.181.34:PORT` (we'd set up a passthrough nginx). For now skip; only add if direct call fails during Task 5 verification.

- [ ] **Step 2.2: Add to local `.env`** (in `/Users/dmitry/Downloads/taler_id/.env` — never commit `.env`)

Append:
```
ANTHROPIC_API_KEY=sk-ant-actual-key-here
ANTHROPIC_BASE_URL=https://api.anthropic.com
ANTHROPIC_MODEL_DEFAULT=claude-sonnet-4-6
ANTHROPIC_MAX_TOKENS_DEFAULT=4096
```

- [ ] **Step 2.3: Add to `.env.example`** (or create if absent — this IS committed)

Check existence:
```bash
ls /Users/dmitry/Downloads/taler_id/.env.example 2>&1
```

If exists — append. If not — create a new `.env.example` with just the new vars (we don't want to copy private values):
```
ANTHROPIC_API_KEY=
ANTHROPIC_BASE_URL=https://api.anthropic.com
ANTHROPIC_MODEL_DEFAULT=claude-sonnet-4-6
ANTHROPIC_MAX_TOKENS_DEFAULT=4096
```

- [ ] **Step 2.4: Commit `.env.example` change only** (verify `.env` is in `.gitignore` first)

```bash
cd /Users/dmitry/Downloads/taler_id
grep -q "^\.env$" .gitignore || echo "WARN: .env not in gitignore — fix before commit"
git add .env.example
git commit -m "chore(agent): add ANTHROPIC_* env config placeholders"
```

---

## Task 3: Backend — Create AgentModule with `/agent/claude` proxy endpoint (TDD)

**Files:**
- Create: `/Users/dmitry/Downloads/taler_id/src/agent/agent.module.ts`
- Create: `/Users/dmitry/Downloads/taler_id/src/agent/agent.controller.ts`
- Create: `/Users/dmitry/Downloads/taler_id/src/agent/agent.service.ts`
- Create: `/Users/dmitry/Downloads/taler_id/src/agent/dto/claude-request.dto.ts`
- Create: `/Users/dmitry/Downloads/taler_id/src/agent/dto/claude-response.dto.ts`
- Create: `/Users/dmitry/Downloads/taler_id/src/agent/agent.service.spec.ts`
- Modify: `/Users/dmitry/Downloads/taler_id/src/app.module.ts` — register AgentModule

- [ ] **Step 3.1: Write the failing test for AgentService.proxyClaude**

Create `/Users/dmitry/Downloads/taler_id/src/agent/agent.service.spec.ts`:

```typescript
import { Test, TestingModule } from '@nestjs/testing';
import { AgentService } from './agent.service';

describe('AgentService', () => {
  let service: AgentService;
  let originalFetch: typeof globalThis.fetch;

  beforeAll(() => {
    originalFetch = globalThis.fetch;
    process.env.ANTHROPIC_API_KEY = 'sk-ant-test';
    process.env.ANTHROPIC_BASE_URL = 'https://api.anthropic.com';
    process.env.ANTHROPIC_MODEL_DEFAULT = 'claude-sonnet-4-6';
    process.env.ANTHROPIC_MAX_TOKENS_DEFAULT = '4096';
  });

  afterAll(() => {
    globalThis.fetch = originalFetch;
  });

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [AgentService],
    }).compile();
    service = module.get<AgentService>(AgentService);
  });

  it('forwards messages payload to Anthropic and returns raw response', async () => {
    const fakeResponse = {
      id: 'msg_01',
      type: 'message',
      role: 'assistant',
      content: [{ type: 'text', text: 'Hi.' }],
      stop_reason: 'end_turn',
      usage: { input_tokens: 5, output_tokens: 2 },
    };
    globalThis.fetch = jest.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => fakeResponse,
      text: async () => JSON.stringify(fakeResponse),
    }) as any;

    const result = await service.proxyClaude({
      messages: [{ role: 'user', content: 'Hi' }],
    });

    expect(globalThis.fetch).toHaveBeenCalledWith(
      'https://api.anthropic.com/v1/messages',
      expect.objectContaining({
        method: 'POST',
        headers: expect.objectContaining({
          'x-api-key': 'sk-ant-test',
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        }),
      }),
    );
    expect(result).toEqual(fakeResponse);
  });

  it('throws on non-2xx response with status code preserved', async () => {
    globalThis.fetch = jest.fn().mockResolvedValue({
      ok: false,
      status: 429,
      json: async () => ({ error: { message: 'rate limited' } }),
      text: async () => '{"error":{"message":"rate limited"}}',
    }) as any;

    await expect(
      service.proxyClaude({ messages: [{ role: 'user', content: 'Hi' }] }),
    ).rejects.toThrow(/429/);
  });

  it('uses default model and max_tokens when not provided', async () => {
    const captured: any = {};
    globalThis.fetch = jest.fn(async (_, init: any) => {
      captured.body = JSON.parse(init.body);
      return {
        ok: true,
        status: 200,
        json: async () => ({ content: [], stop_reason: 'end_turn' }),
        text: async () => '{}',
      };
    }) as any;

    await service.proxyClaude({
      messages: [{ role: 'user', content: 'Hi' }],
    });

    expect(captured.body.model).toBe('claude-sonnet-4-6');
    expect(captured.body.max_tokens).toBe(4096);
  });
});
```

- [ ] **Step 3.2: Run the failing test to confirm**

```bash
cd /Users/dmitry/Downloads/taler_id
npm test -- src/agent/agent.service.spec.ts
```

Expected: FAIL with `Cannot find module './agent.service'`.

- [ ] **Step 3.3: Create the DTO files**

`/Users/dmitry/Downloads/taler_id/src/agent/dto/claude-request.dto.ts`:
```typescript
export interface ClaudeMessage {
  role: 'user' | 'assistant';
  content: string | Array<Record<string, unknown>>;
}

export interface ClaudeTool {
  name: string;
  description?: string;
  input_schema: Record<string, unknown>;
}

export class ClaudeRequestDto {
  messages!: ClaudeMessage[];
  model?: string;
  max_tokens?: number;
  system?: string;
  tools?: ClaudeTool[];
  tool_choice?: Record<string, unknown>;
  temperature?: number;
}
```

`/Users/dmitry/Downloads/taler_id/src/agent/dto/claude-response.dto.ts`:
```typescript
export interface ClaudeContentBlock {
  type: 'text' | 'tool_use' | string;
  text?: string;
  id?: string;
  name?: string;
  input?: Record<string, unknown>;
}

export interface ClaudeResponseDto {
  id?: string;
  type?: string;
  role?: string;
  model?: string;
  content: ClaudeContentBlock[];
  stop_reason: 'end_turn' | 'tool_use' | 'max_tokens' | 'stop_sequence' | string;
  usage?: { input_tokens: number; output_tokens: number };
}
```

- [ ] **Step 3.4: Implement AgentService**

`/Users/dmitry/Downloads/taler_id/src/agent/agent.service.ts`:
```typescript
import { Injectable, Logger } from '@nestjs/common';
import { ClaudeRequestDto } from './dto/claude-request.dto';
import { ClaudeResponseDto } from './dto/claude-response.dto';

@Injectable()
export class AgentService {
  private readonly logger = new Logger(AgentService.name);

  async proxyClaude(req: ClaudeRequestDto): Promise<ClaudeResponseDto> {
    const apiKey = process.env.ANTHROPIC_API_KEY || '';
    const baseUrl = process.env.ANTHROPIC_BASE_URL || 'https://api.anthropic.com';
    const defaultModel = process.env.ANTHROPIC_MODEL_DEFAULT || 'claude-sonnet-4-6';
    const defaultMaxTokens = parseInt(process.env.ANTHROPIC_MAX_TOKENS_DEFAULT || '4096', 10);

    if (!apiKey) {
      throw new Error('ANTHROPIC_API_KEY not configured');
    }

    const body = {
      model: req.model || defaultModel,
      max_tokens: req.max_tokens ?? defaultMaxTokens,
      messages: req.messages,
      ...(req.system ? { system: req.system } : {}),
      ...(req.tools ? { tools: req.tools } : {}),
      ...(req.tool_choice ? { tool_choice: req.tool_choice } : {}),
      ...(req.temperature !== undefined ? { temperature: req.temperature } : {}),
    };

    const res = await fetch(`${baseUrl}/v1/messages`, {
      method: 'POST',
      headers: {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: JSON.stringify(body),
    });

    if (!res.ok) {
      const text = await res.text();
      this.logger.error(`Claude API ${res.status}: ${text.slice(0, 500)}`);
      throw new Error(`Claude API error ${res.status}: ${text.slice(0, 200)}`);
    }

    return (await res.json()) as ClaudeResponseDto;
  }
}
```

- [ ] **Step 3.5: Run tests to verify they pass**

```bash
cd /Users/dmitry/Downloads/taler_id
npm test -- src/agent/agent.service.spec.ts
```

Expected: 3 tests pass.

- [ ] **Step 3.6: Create AgentController**

`/Users/dmitry/Downloads/taler_id/src/agent/agent.controller.ts`:
```typescript
import { Body, Controller, Logger, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { AgentService } from './agent.service';
import { ClaudeRequestDto } from './dto/claude-request.dto';

@Controller('agent')
export class AgentController {
  private readonly logger = new Logger(AgentController.name);
  constructor(private readonly agent: AgentService) {}

  @UseGuards(JwtAuthGuard)
  @Post('claude')
  async claude(@CurrentUser() user: any, @Body() body: ClaudeRequestDto) {
    this.logger.debug(`agent/claude for user ${user?.sub} model=${body.model || 'default'}`);
    return this.agent.proxyClaude(body);
  }
}
```

**Note:** Verify exact path of `CurrentUser` decorator. If not at `src/common/decorators/current-user.decorator.ts`, grep:
```bash
grep -rn "export.*CurrentUser" /Users/dmitry/Downloads/taler_id/src/
```
and adjust import accordingly.

- [ ] **Step 3.7: Create AgentModule**

`/Users/dmitry/Downloads/taler_id/src/agent/agent.module.ts`:
```typescript
import { Module } from '@nestjs/common';
import { AgentController } from './agent.controller';
import { AgentService } from './agent.service';

@Module({
  controllers: [AgentController],
  providers: [AgentService],
  exports: [AgentService],
})
export class AgentModule {}
```

- [ ] **Step 3.8: Register AgentModule in AppModule**

Open `/Users/dmitry/Downloads/taler_id/src/app.module.ts`. Find the `imports: [...]` array. Add `AgentModule` to it; add the import line at the top:
```typescript
import { AgentModule } from './agent/agent.module';
```

- [ ] **Step 3.9: Build to verify no compile errors**

```bash
cd /Users/dmitry/Downloads/taler_id && npm run build
```

Expected: clean build, no TS errors.

- [ ] **Step 3.10: Commit**

```bash
cd /Users/dmitry/Downloads/taler_id
git add src/agent/ src/app.module.ts
git commit -m "feat(agent): add /agent/claude proxy with JWT auth + tests"
```

---

## Task 4: Backend — Deploy to DEV and verify endpoint live

**Files:** No new code. Operational verification.

- [ ] **Step 4.1: Push branch to remote**

```bash
cd /Users/dmitry/Downloads/taler_id
git push -u origin feature/agent-shell-phase-0
```

- [ ] **Step 4.2: Pull on DEV server**

```bash
ssh dvolkov@89.169.55.217 'cd ~/taler-id && git fetch origin && git checkout feature/agent-shell-phase-0 && git pull'
```

- [ ] **Step 4.3: Update DEV `.env` with ANTHROPIC_* vars**

```bash
ssh dvolkov@89.169.55.217
# In the SSH session:
cd ~/taler-id
nano .env  # add ANTHROPIC_API_KEY, ANTHROPIC_BASE_URL, ANTHROPIC_MODEL_DEFAULT, ANTHROPIC_MAX_TOKENS_DEFAULT
# Ctrl-O, Enter, Ctrl-X
```

- [ ] **Step 4.4: Build + restart on DEV**

```bash
ssh dvolkov@89.169.55.217 'cd ~/taler-id && npm run build && pm2 restart taler-id-dev'
```

Expected: pm2 shows `taler-id-dev` online status with new PID.

- [ ] **Step 4.5: Test endpoint with curl (requires a valid JWT)**

Obtain a JWT from the existing test account (`integration_test@taler-test.com` per CLAUDE.md):
```bash
curl -X POST https://staging.id.taler.tirol/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"integration_test@taler-test.com","password":"IntegrationTest123!"}' \
  | jq -r '.access_token' > /tmp/jwt.txt
```

Then call the new endpoint:
```bash
curl -X POST https://staging.id.taler.tirol/agent/claude \
  -H "Authorization: Bearer $(cat /tmp/jwt.txt)" \
  -H 'Content-Type: application/json' \
  -d '{"messages":[{"role":"user","content":"Say only the word: pong"}],"max_tokens":50}' \
  | jq
```

Expected: JSON with `content: [{ type: "text", text: "pong" }]` and `stop_reason: "end_turn"`.

If 502/connection error: AEZA RU IP blocked by Anthropic. Fallback: set up nginx passthrough on DO at 167.172.181.34, update `ANTHROPIC_BASE_URL` on DEV to `https://167.172.181.34/anthropic-proxy/`, restart, retry. (Detailed DO nginx config out of scope for this plan — note as deferred and proceed with direct connection if working.)

- [ ] **Step 4.6: Document verified endpoint URL**

Append to your daily-driver journal (or a simple note in repo `docs/agent-shell-phase-0-notes.md`):
```
DEV endpoint verified: POST https://staging.id.taler.tirol/agent/claude
Model: claude-sonnet-4-6
First test: pong (round-trip ~Xms)
```

---

## Task 5: Flutter — Define Anthropic message types (Freezed)

**Files:**
- Create: `/Users/dmitry/Downloads/taler_id_mobile/lib/core/agent/models/agent_message.dart`
- Create: `/Users/dmitry/Downloads/taler_id_mobile/lib/core/agent/models/agent_tool.dart`
- Create: `/Users/dmitry/Downloads/taler_id_mobile/lib/core/agent/models/agent_response.dart`

- [ ] **Step 5.1: Verify Freezed + json_serializable already in pubspec**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && grep -E "(freezed|json_serializable|json_annotation)" pubspec.yaml
```

Expected: lines for `freezed`, `freezed_annotation`, `json_annotation`, `json_serializable`. If missing, add to pubspec:
```yaml
dependencies:
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0
dev_dependencies:
  freezed: ^2.5.7
  json_serializable: ^6.8.0
  build_runner: ^2.4.13
```
and run `flutter pub get`.

- [ ] **Step 5.2: Create `agent_message.dart`**

```dart
// lib/core/agent/models/agent_message.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'agent_message.freezed.dart';
part 'agent_message.g.dart';

@freezed
class AgentMessage with _$AgentMessage {
  const factory AgentMessage({
    required String role, // 'user' | 'assistant'
    required dynamic content, // String OR List<Map<String, dynamic>>
  }) = _AgentMessage;

  factory AgentMessage.fromJson(Map<String, dynamic> json) =>
      _$AgentMessageFromJson(json);

  factory AgentMessage.userText(String text) =>
      AgentMessage(role: 'user', content: text);

  factory AgentMessage.assistantBlocks(List<Map<String, dynamic>> blocks) =>
      AgentMessage(role: 'assistant', content: blocks);

  factory AgentMessage.toolResult(String toolUseId, dynamic result) =>
      AgentMessage(
        role: 'user',
        content: [
          {
            'type': 'tool_result',
            'tool_use_id': toolUseId,
            'content': result is String ? result : result.toString(),
          },
        ],
      );
}
```

- [ ] **Step 5.3: Create `agent_tool.dart`**

```dart
// lib/core/agent/models/agent_tool.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'agent_tool.freezed.dart';
part 'agent_tool.g.dart';

@freezed
class AgentToolDef with _$AgentToolDef {
  const factory AgentToolDef({
    required String name,
    required String description,
    required Map<String, dynamic> inputSchema,
  }) = _AgentToolDef;

  factory AgentToolDef.fromJson(Map<String, dynamic> json) =>
      _$AgentToolDefFromJson(json);

  /// Anthropic API shape — note `input_schema` key (snake)
  Map<String, dynamic> toAnthropic() => {
        'name': name,
        'description': description,
        'input_schema': inputSchema,
      };
}

@freezed
class AgentToolUseBlock with _$AgentToolUseBlock {
  const factory AgentToolUseBlock({
    required String id,
    required String name,
    required Map<String, dynamic> input,
  }) = _AgentToolUseBlock;

  factory AgentToolUseBlock.fromJson(Map<String, dynamic> json) =>
      _$AgentToolUseBlockFromJson(json);
}
```

- [ ] **Step 5.4: Create `agent_response.dart`**

```dart
// lib/core/agent/models/agent_response.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'agent_response.freezed.dart';
part 'agent_response.g.dart';

@freezed
class AgentResponse with _$AgentResponse {
  const factory AgentResponse({
    String? id,
    String? model,
    required String stopReason, // 'end_turn' | 'tool_use' | ...
    required List<Map<String, dynamic>> content,
  }) = _AgentResponse;

  factory AgentResponse.fromJson(Map<String, dynamic> json) => AgentResponse(
        id: json['id'] as String?,
        model: json['model'] as String?,
        stopReason: json['stop_reason'] as String? ?? 'unknown',
        content: ((json['content'] as List?) ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
      );
}
```

- [ ] **Step 5.5: Run build_runner**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile
dart run build_runner build --delete-conflicting-outputs
```

Expected: success, generates `.freezed.dart` and `.g.dart` files next to each model.

- [ ] **Step 5.6: Commit**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile
git add lib/core/agent/models/
git commit -m "feat(agent): add Freezed types for Claude Agent Loop"
```

---

## Task 6: Flutter — AnthropicClient + AgentLoop + EchoTool (TDD)

**Files:**
- Create: `/Users/dmitry/Downloads/taler_id_mobile/lib/core/agent/anthropic_client.dart`
- Create: `/Users/dmitry/Downloads/taler_id_mobile/lib/core/agent/tools/agent_tool_handler.dart`
- Create: `/Users/dmitry/Downloads/taler_id_mobile/lib/core/agent/tools/tool_registry.dart`
- Create: `/Users/dmitry/Downloads/taler_id_mobile/lib/core/agent/tools/echo_tool.dart`
- Create: `/Users/dmitry/Downloads/taler_id_mobile/lib/core/agent/agent_loop.dart`
- Create: `/Users/dmitry/Downloads/taler_id_mobile/test/core/agent/agent_loop_test.dart`

- [ ] **Step 6.1: Verify mocktail is available**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && grep mocktail pubspec.yaml
```

If absent — add to `dev_dependencies`: `mocktail: ^1.0.4`, then `flutter pub get`.

- [ ] **Step 6.2: Write the failing AgentLoop test**

`/Users/dmitry/Downloads/taler_id_mobile/test/core/agent/agent_loop_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/agent/agent_loop.dart';
import 'package:taler_id_mobile/core/agent/anthropic_client.dart';
import 'package:taler_id_mobile/core/agent/models/agent_message.dart';
import 'package:taler_id_mobile/core/agent/models/agent_response.dart';
import 'package:taler_id_mobile/core/agent/models/agent_tool.dart';
import 'package:taler_id_mobile/core/agent/tools/agent_tool_handler.dart';
import 'package:taler_id_mobile/core/agent/tools/echo_tool.dart';
import 'package:taler_id_mobile/core/agent/tools/tool_registry.dart';

class _MockAnthropicClient extends Mock implements AnthropicClient {}

void main() {
  late _MockAnthropicClient client;
  late ToolRegistry registry;
  late AgentLoop loop;

  setUp(() {
    client = _MockAnthropicClient();
    registry = ToolRegistry()..register(EchoTool());
    loop = AgentLoop(client: client, registry: registry);
  });

  test('ends turn directly when Claude returns end_turn', () async {
    when(() => client.createMessage(
          messages: any(named: 'messages'),
          tools: any(named: 'tools'),
          system: any(named: 'system'),
        )).thenAnswer((_) async => const AgentResponse(
          stopReason: 'end_turn',
          content: [
            {'type': 'text', 'text': 'Hello there.'},
          ],
        ));

    final result = await loop.run(userGoal: 'Hi');

    expect(result.finalText, 'Hello there.');
    expect(result.toolCalls, isEmpty);
    verify(() => client.createMessage(
          messages: any(named: 'messages'),
          tools: any(named: 'tools'),
          system: any(named: 'system'),
        )).called(1);
  });

  test('executes a single echo tool_use and loops to a final answer', () async {
    final calls = <List<AgentMessage>>[];
    when(() => client.createMessage(
          messages: any(named: 'messages'),
          tools: any(named: 'tools'),
          system: any(named: 'system'),
        )).thenAnswer((invocation) async {
      final msgs = invocation.namedArguments[#messages] as List<AgentMessage>;
      calls.add(List.of(msgs));
      if (calls.length == 1) {
        return const AgentResponse(
          stopReason: 'tool_use',
          content: [
            {
              'type': 'tool_use',
              'id': 'tu_1',
              'name': 'echo',
              'input': {'text': 'ping'},
            },
          ],
        );
      }
      return const AgentResponse(
        stopReason: 'end_turn',
        content: [
          {'type': 'text', 'text': 'echoed: ping'},
        ],
      );
    });

    final result = await loop.run(userGoal: 'echo ping');

    expect(result.finalText, 'echoed: ping');
    expect(result.toolCalls.length, 1);
    expect(result.toolCalls.first.name, 'echo');
    expect(result.toolCalls.first.result, 'ping');
    expect(calls.length, 2,
        reason: 'must call API twice: initial + after tool_result');
  });

  test('aborts loop after maxIterations to prevent infinite cycles',
      () async {
    when(() => client.createMessage(
          messages: any(named: 'messages'),
          tools: any(named: 'tools'),
          system: any(named: 'system'),
        )).thenAnswer((_) async => const AgentResponse(
          stopReason: 'tool_use',
          content: [
            {
              'type': 'tool_use',
              'id': 'tu_x',
              'name': 'echo',
              'input': {'text': 'loop'},
            },
          ],
        ));

    final result = await loop.run(userGoal: 'never ends', maxIterations: 3);
    expect(result.toolCalls.length, 3);
    expect(result.aborted, isTrue);
  });
}
```

- [ ] **Step 6.3: Run test — expect compile failure**

```bash
flutter test test/core/agent/agent_loop_test.dart
```

Expected: FAIL — missing imports.

- [ ] **Step 6.4: Create AnthropicClient**

`/Users/dmitry/Downloads/taler_id_mobile/lib/core/agent/anthropic_client.dart`:
```dart
import 'package:dio/dio.dart';
import 'models/agent_message.dart';
import 'models/agent_response.dart';
import 'models/agent_tool.dart';

class AnthropicClient {
  final Dio _dio;

  AnthropicClient(this._dio);

  Future<AgentResponse> createMessage({
    required List<AgentMessage> messages,
    List<AgentToolDef> tools = const [],
    String? system,
    String? model,
    int? maxTokens,
    double? temperature,
  }) async {
    final body = <String, dynamic>{
      'messages': messages.map((m) => m.toJson()).toList(),
      if (tools.isNotEmpty) 'tools': tools.map((t) => t.toAnthropic()).toList(),
      if (system != null && system.isNotEmpty) 'system': system,
      if (model != null) 'model': model,
      if (maxTokens != null) 'max_tokens': maxTokens,
      if (temperature != null) 'temperature': temperature,
    };

    final resp = await _dio.post<Map<String, dynamic>>(
      '/agent/claude',
      data: body,
    );

    return AgentResponse.fromJson(resp.data ?? const {});
  }
}
```

- [ ] **Step 6.5: Create ToolHandler abstraction**

`/Users/dmitry/Downloads/taler_id_mobile/lib/core/agent/tools/agent_tool_handler.dart`:
```dart
import '../models/agent_tool.dart';

abstract class AgentToolHandler {
  AgentToolDef get definition;
  Future<String> handle(Map<String, dynamic> input);
}
```

- [ ] **Step 6.6: Create ToolRegistry**

`/Users/dmitry/Downloads/taler_id_mobile/lib/core/agent/tools/tool_registry.dart`:
```dart
import '../models/agent_tool.dart';
import 'agent_tool_handler.dart';

class ToolRegistry {
  final Map<String, AgentToolHandler> _handlers = {};

  void register(AgentToolHandler handler) {
    _handlers[handler.definition.name] = handler;
  }

  List<AgentToolDef> get definitions =>
      _handlers.values.map((h) => h.definition).toList();

  Future<String> dispatch(String name, Map<String, dynamic> input) async {
    final handler = _handlers[name];
    if (handler == null) {
      return 'ERROR: unknown tool $name';
    }
    try {
      return await handler.handle(input);
    } catch (e) {
      return 'ERROR: tool $name threw: $e';
    }
  }
}
```

- [ ] **Step 6.7: Create EchoTool**

`/Users/dmitry/Downloads/taler_id_mobile/lib/core/agent/tools/echo_tool.dart`:
```dart
import '../models/agent_tool.dart';
import 'agent_tool_handler.dart';

class EchoTool implements AgentToolHandler {
  @override
  AgentToolDef get definition => const AgentToolDef(
        name: 'echo',
        description:
            'Returns the provided text verbatim. Used to validate the agent-loop plumbing end-to-end.',
        inputSchema: {
          'type': 'object',
          'properties': {
            'text': {
              'type': 'string',
              'description': 'Text to echo back',
            },
          },
          'required': ['text'],
        },
      );

  @override
  Future<String> handle(Map<String, dynamic> input) async {
    final text = input['text'];
    if (text is! String) return 'ERROR: input.text must be a string';
    return text;
  }
}
```

- [ ] **Step 6.8: Create AgentLoop**

`/Users/dmitry/Downloads/taler_id_mobile/lib/core/agent/agent_loop.dart`:
```dart
import 'anthropic_client.dart';
import 'models/agent_message.dart';
import 'models/agent_response.dart';
import 'tools/tool_registry.dart';

class AgentToolCall {
  final String id;
  final String name;
  final Map<String, dynamic> input;
  final String result;
  AgentToolCall({
    required this.id,
    required this.name,
    required this.input,
    required this.result,
  });
}

class AgentResult {
  final String finalText;
  final List<AgentToolCall> toolCalls;
  final bool aborted;
  AgentResult({
    required this.finalText,
    required this.toolCalls,
    required this.aborted,
  });
}

class AgentLoop {
  final AnthropicClient client;
  final ToolRegistry registry;
  final String systemPrompt;

  AgentLoop({
    required this.client,
    required this.registry,
    this.systemPrompt =
        'You are a helpful agent embedded in the Taler ID mobile app. Use the available tools when they help complete the user goal. Keep replies short.',
  });

  Future<AgentResult> run({
    required String userGoal,
    int maxIterations = 8,
  }) async {
    final messages = <AgentMessage>[AgentMessage.userText(userGoal)];
    final toolCalls = <AgentToolCall>[];

    for (var i = 0; i < maxIterations; i++) {
      final resp = await client.createMessage(
        messages: messages,
        tools: registry.definitions,
        system: systemPrompt,
      );

      messages.add(AgentMessage.assistantBlocks(resp.content));

      if (resp.stopReason == 'end_turn') {
        final text = _extractText(resp.content);
        return AgentResult(
          finalText: text,
          toolCalls: toolCalls,
          aborted: false,
        );
      }

      if (resp.stopReason == 'tool_use') {
        final uses = resp.content.where((b) => b['type'] == 'tool_use');
        final toolResultBlocks = <Map<String, dynamic>>[];
        for (final use in uses) {
          final id = use['id'] as String;
          final name = use['name'] as String;
          final input = Map<String, dynamic>.from(use['input'] as Map? ?? {});
          final result = await registry.dispatch(name, input);
          toolCalls.add(AgentToolCall(
            id: id,
            name: name,
            input: input,
            result: result,
          ));
          toolResultBlocks.add({
            'type': 'tool_result',
            'tool_use_id': id,
            'content': result,
          });
        }
        messages.add(AgentMessage(role: 'user', content: toolResultBlocks));
        continue;
      }

      // Unknown stop reason → abort gracefully
      return AgentResult(
        finalText: _extractText(resp.content),
        toolCalls: toolCalls,
        aborted: true,
      );
    }

    return AgentResult(
      finalText: '(agent loop exceeded $maxIterations iterations)',
      toolCalls: toolCalls,
      aborted: true,
    );
  }

  String _extractText(List<Map<String, dynamic>> blocks) {
    final parts = <String>[];
    for (final b in blocks) {
      if (b['type'] == 'text' && b['text'] is String) {
        parts.add(b['text'] as String);
      }
    }
    return parts.join('\n').trim();
  }
}
```

- [ ] **Step 6.9: Run tests — verify they pass**

```bash
flutter test test/core/agent/agent_loop_test.dart
```

Expected: 3 tests pass.

- [ ] **Step 6.10: Commit**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile
git add lib/core/agent/ test/core/agent/
git commit -m "feat(agent): AgentLoop + AnthropicClient + ToolRegistry + EchoTool with tests"
```

---

## Task 7: Flutter — Register AnthropicClient + ToolRegistry + AgentLoop in DI

**Files:**
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/lib/core/di/service_locator.dart`

- [ ] **Step 7.1: Find DI setup section**

Open `service_locator.dart`. Find the `setupDependencies()` function and locate a logical place near other "core" registrations (around line 242 where DioClient is registered, per recon).

- [ ] **Step 7.2: Add registrations**

After existing core registrations (look for `sl.registerLazySingleton<DioClient>` and add immediately AFTER its block):

```dart
// === Agent Shell (Phase 0) ===
import 'package:.../core/agent/anthropic_client.dart';            // ← top of file
import 'package:.../core/agent/agent_loop.dart';                  // ← top of file
import 'package:.../core/agent/tools/tool_registry.dart';         // ← top of file
import 'package:.../core/agent/tools/echo_tool.dart';             // ← top of file

// Inside setupDependencies(), after DioClient:
sl.registerLazySingleton<AnthropicClient>(
  () => AnthropicClient(sl<DioClient>().dio),
);
sl.registerLazySingleton<ToolRegistry>(
  () => ToolRegistry()..register(EchoTool()),
);
sl.registerLazySingleton<AgentLoop>(
  () => AgentLoop(
    client: sl<AnthropicClient>(),
    registry: sl<ToolRegistry>(),
  ),
);
```

**Note:** Replace `package:.../` with the actual package name. Check `pubspec.yaml` for `name:` line. Probably `package:taler_id_mobile/`.

**Note:** `DioClient.dio` — verify accessor. If DioClient exposes the underlying `Dio` via a different getter (e.g. `instance` or `client`), use that. Worst case: pass DioClient itself and have AnthropicClient call `dioClient.post(...)`.

- [ ] **Step 7.3: Verify compile**

```bash
flutter analyze lib/core/di/service_locator.dart
```

Expected: no errors.

- [ ] **Step 7.4: Commit**

```bash
git add lib/core/di/service_locator.dart
git commit -m "feat(agent): register AnthropicClient/AgentLoop/ToolRegistry in DI"
```

---

## Task 8: Flutter — AgentBloc + AgentShellHomeScreen

**Files:**
- Create: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/agent_shell/presentation/bloc/agent_shell_bloc.dart`
- Create: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/agent_shell/presentation/bloc/agent_shell_state.dart`
- Create: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/agent_shell/presentation/bloc/agent_shell_event.dart`
- Create: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/agent_shell/presentation/screens/agent_shell_home_screen.dart`
- Create: `/Users/dmitry/Downloads/taler_id_mobile/test/features/agent_shell/agent_shell_bloc_test.dart`

- [ ] **Step 8.1: Write failing test for bloc**

```dart
// test/features/agent_shell/agent_shell_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/agent/agent_loop.dart';
import 'package:taler_id_mobile/features/agent_shell/presentation/bloc/agent_shell_bloc.dart';

class _MockAgentLoop extends Mock implements AgentLoop {}

void main() {
  late _MockAgentLoop loop;

  setUp(() {
    loop = _MockAgentLoop();
  });

  blocTest<AgentShellBloc, AgentShellState>(
    'appends user + agent messages on submit',
    build: () {
      when(() => loop.run(userGoal: any(named: 'userGoal'))).thenAnswer(
        (_) async => AgentResult(
          finalText: 'echoed: hi',
          toolCalls: const [],
          aborted: false,
        ),
      );
      return AgentShellBloc(loop: loop);
    },
    act: (bloc) => bloc.add(const AgentShellSubmit('hi')),
    expect: () => [
      isA<AgentShellState>()
          .having((s) => s.messages.length, 'messages.length', 1)
          .having((s) => s.busy, 'busy', true),
      isA<AgentShellState>()
          .having((s) => s.messages.length, 'messages.length', 2)
          .having((s) => s.busy, 'busy', false)
          .having((s) => s.messages.last.text, 'last.text', 'echoed: hi'),
    ],
  );
}
```

Verify `bloc_test` is in pubspec dev_dependencies; if not, add `bloc_test: ^9.1.7`.

- [ ] **Step 8.2: Run failing test**

```bash
flutter test test/features/agent_shell/agent_shell_bloc_test.dart
```

Expected: FAIL — missing imports.

- [ ] **Step 8.3: Create event + state**

`lib/features/agent_shell/presentation/bloc/agent_shell_event.dart`:
```dart
import 'package:equatable/equatable.dart';

abstract class AgentShellEvent extends Equatable {
  const AgentShellEvent();
  @override
  List<Object?> get props => const [];
}

class AgentShellSubmit extends AgentShellEvent {
  final String text;
  const AgentShellSubmit(this.text);
  @override
  List<Object?> get props => [text];
}
```

`lib/features/agent_shell/presentation/bloc/agent_shell_state.dart`:
```dart
import 'package:equatable/equatable.dart';

class AgentShellMessage extends Equatable {
  final String role; // 'user' | 'agent'
  final String text;
  final DateTime ts;
  const AgentShellMessage({
    required this.role,
    required this.text,
    required this.ts,
  });
  @override
  List<Object?> get props => [role, text, ts];
}

class AgentShellState extends Equatable {
  final List<AgentShellMessage> messages;
  final bool busy;
  final String? error;
  const AgentShellState({
    required this.messages,
    required this.busy,
    this.error,
  });
  factory AgentShellState.initial() =>
      const AgentShellState(messages: [], busy: false);
  AgentShellState copyWith({
    List<AgentShellMessage>? messages,
    bool? busy,
    String? error,
  }) =>
      AgentShellState(
        messages: messages ?? this.messages,
        busy: busy ?? this.busy,
        error: error,
      );
  @override
  List<Object?> get props => [messages, busy, error];
}
```

- [ ] **Step 8.4: Create bloc**

`lib/features/agent_shell/presentation/bloc/agent_shell_bloc.dart`:
```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/agent/agent_loop.dart';
import 'agent_shell_event.dart';
import 'agent_shell_state.dart';

export 'agent_shell_event.dart';
export 'agent_shell_state.dart';

class AgentShellBloc extends Bloc<AgentShellEvent, AgentShellState> {
  final AgentLoop loop;
  AgentShellBloc({required this.loop}) : super(AgentShellState.initial()) {
    on<AgentShellSubmit>(_onSubmit);
  }

  Future<void> _onSubmit(
      AgentShellSubmit event, Emitter<AgentShellState> emit) async {
    final userMsg = AgentShellMessage(
      role: 'user',
      text: event.text,
      ts: DateTime.now(),
    );
    emit(state.copyWith(
      messages: [...state.messages, userMsg],
      busy: true,
      error: null,
    ));
    try {
      final result = await loop.run(userGoal: event.text);
      final agentMsg = AgentShellMessage(
        role: 'agent',
        text: result.finalText.isEmpty ? '(empty response)' : result.finalText,
        ts: DateTime.now(),
      );
      emit(state.copyWith(
        messages: [...state.messages, agentMsg],
        busy: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        busy: false,
        error: e.toString(),
      ));
    }
  }
}
```

- [ ] **Step 8.5: Run bloc test — verify passes**

```bash
flutter test test/features/agent_shell/agent_shell_bloc_test.dart
```

Expected: 1 test passes.

- [ ] **Step 8.6: Create AgentShellHomeScreen widget**

`lib/features/agent_shell/presentation/screens/agent_shell_home_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../bloc/agent_shell_bloc.dart';
import '../../../../core/agent/agent_loop.dart';

class AgentShellHomeScreen extends StatelessWidget {
  const AgentShellHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AgentShellBloc(loop: GetIt.I<AgentLoop>()),
      child: const _AgentShellScaffold(),
    );
  }
}

class _AgentShellScaffold extends StatefulWidget {
  const _AgentShellScaffold();
  @override
  State<_AgentShellScaffold> createState() => _AgentShellScaffoldState();
}

class _AgentShellScaffoldState extends State<_AgentShellScaffold> {
  final TextEditingController _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    context.read<AgentShellBloc>().add(AgentShellSubmit(text));
    _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Taler ID Agent (Phase 0 spike)'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: BlocBuilder<AgentShellBloc, AgentShellState>(
                builder: (context, state) {
                  if (state.messages.isEmpty) {
                    return const Center(
                      child: Text(
                        'Скажи что-нибудь — попробует echo инструмент.',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: state.messages.length + (state.busy ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i >= state.messages.length) {
                        return const Padding(
                          padding: EdgeInsets.all(12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Думаю…'),
                          ),
                        );
                      }
                      final msg = state.messages[i];
                      final isUser = msg.role == 'user';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Align(
                          alignment: isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 320),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(msg.text),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            BlocBuilder<AgentShellBloc, AgentShellState>(
              builder: (context, state) => Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        enabled: !state.busy,
                        decoration: const InputDecoration(
                          hintText: 'Echo this...',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _submit(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: state.busy ? null : () => _submit(context),
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
            BlocBuilder<AgentShellBloc, AgentShellState>(
              builder: (_, s) => s.error != null
                  ? Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        s.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 8.7: Run analyzer**

```bash
flutter analyze lib/features/agent_shell/
```

Expected: no errors. Warnings are OK.

- [ ] **Step 8.8: Commit**

```bash
git add lib/features/agent_shell/ test/features/agent_shell/
git commit -m "feat(agent-shell): AgentShellBloc + home screen widget"
```

---

## Task 9: Flutter — Add `/agent-shell` route in GoRouter

**Files:**
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/lib/core/router/app_router.dart`
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/lib/core/router/route_constants.dart` (or equivalent file holding `RouteConstants`)

- [ ] **Step 9.1: Find RouteConstants definitions**

```bash
grep -rn "class RouteConstants" /Users/dmitry/Downloads/taler_id_mobile/lib/
```

Open that file.

- [ ] **Step 9.2: Add new constant**

Inside `class RouteConstants`, add:
```dart
static const String agentShell = '/agent-shell';
```

- [ ] **Step 9.3: Register route in app_router.dart**

Open `/Users/dmitry/Downloads/taler_id_mobile/lib/core/router/app_router.dart`. Find the routes array (after the splash route per recon, line ~70). Add:
```dart
GoRoute(
  path: RouteConstants.agentShell,
  builder: (_, __) => const AgentShellHomeScreen(),
),
```

Add the import at top of file:
```dart
import '../../features/agent_shell/presentation/screens/agent_shell_home_screen.dart';
```

- [ ] **Step 9.4: Sanity check by navigating manually**

Temporarily change `initialLocation` (around line 67) from `RouteConstants.splash` to `RouteConstants.agentShell` to test directly. Run on emulator:
```bash
flutter run -d emulator-5554 --flavor dev -t lib/main_dev.dart \
  --dart-define=FLAVOR=dev \
  --dart-define=BASE_URL=https://staging.id.taler.tirol
```

Verify the chat screen opens immediately. Restore `initialLocation` to splash (so normal flow works after login).

- [ ] **Step 9.5: Commit**

```bash
git add lib/core/router/
git commit -m "feat(agent-shell): register /agent-shell route"
```

---

## Task 10: Flutter — Manual end-to-end smoke test (UI only, no voice yet)

**Files:** No code changes; manual verification.

- [ ] **Step 10.1: Launch on emulator authenticated**

```bash
flutter emulators --launch Pixel_XL_API_33
# wait ~20 seconds
~/Library/Android/sdk/platform-tools/adb devices
```

Then run app:
```bash
cd /Users/dmitry/Downloads/taler_id_mobile
flutter run -d emulator-5554 --flavor dev -t lib/main_dev.dart \
  --dart-define=FLAVOR=dev \
  --dart-define=BASE_URL=https://staging.id.taler.tirol
```

- [ ] **Step 10.2: Login with test account**

Email: `integration_test@taler-test.com`
Password: `IntegrationTest123!`

- [ ] **Step 10.3: Navigate to /agent-shell**

Open Android emulator's `adb shell` to deep-link directly:
```bash
~/Library/Android/sdk/platform-tools/adb -s emulator-5554 shell am start \
  -a android.intent.action.VIEW \
  -d "talerid:///agent-shell"
```

If the custom scheme doesn't route correctly, simply edit `initialLocation` to `RouteConstants.agentShell` for this test pass (revert after).

- [ ] **Step 10.4: Type "Echo back the word 'pong' using the echo tool"**

Submit. Expected:
- User bubble appears with the text
- "Думаю…" indicator
- After 1-3 sec, agent bubble appears with text like `echoed: pong` or similar

In the run logs you should see the POST `/agent/claude` flying. If 401 — token issue, re-login. If 502/timeout — Anthropic blocking (handle per Task 4 fallback).

- [ ] **Step 10.5: Record one-line note**

In your daily-driver journal, write:
```
PHASE-0 SMOKE: agent-shell route responding. First echo round-trip XX ms.
```

- [ ] **Step 10.6: (No commit — this was verification only)**

---

## Task 11: Android — Make Taler ID eligible as default launcher (intent filter)

**Files:**
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/android/app/src/main/AndroidManifest.xml`

- [ ] **Step 11.1: Open AndroidManifest.xml and locate MainActivity intent-filter for MAIN/LAUNCHER**

Per recon: lines 61-64. It looks like:
```xml
<intent-filter>
  <action android:name="android.intent.action.MAIN" />
  <category android:name="android.intent.category.LAUNCHER" />
</intent-filter>
```

- [ ] **Step 11.2: Add a NEW intent-filter immediately after the LAUNCHER one, behind a build flag**

We want to be able to ship without home-launcher behaviour for prod for now. Use a manifest placeholder controlled by `--dart-define` is not possible directly, so we use a Gradle build type / flavor flag. Simplest for Phase 0 spike: add the new filter **only behind dev flavor** by gating it via a placeholder.

Open `/Users/dmitry/Downloads/taler_id_mobile/android/app/build.gradle`. Find `productFlavors { dev { ... } prod { ... } }`. Inside `dev { ... }`, add:
```gradle
manifestPlaceholders = [
    appLauncherCategories: '<category android:name="android.intent.category.HOME" /><category android:name="android.intent.category.DEFAULT" />'
]
```

Inside `prod { ... }`, add:
```gradle
manifestPlaceholders = [
    appLauncherCategories: ''
]
```

If `manifestPlaceholders` already exists, merge entries rather than overwrite.

In `AndroidManifest.xml`, immediately after the existing LAUNCHER intent-filter, add:
```xml
<intent-filter>
  <action android:name="android.intent.action.MAIN" />
  ${appLauncherCategories}
</intent-filter>
```

Note: This is unusual but the simplest gating. An alternative is duplicating the manifest under `android/app/src/dev/AndroidManifest.xml` — Flutter merges them. Pick whichever feels cleaner.

- [ ] **Step 11.3: Re-run on emulator**

```bash
flutter run -d emulator-5554 --flavor dev -t lib/main_dev.dart \
  --dart-define=FLAVOR=dev \
  --dart-define=BASE_URL=https://staging.id.taler.tirol
```

Then press the Home button on the emulator. Expected: Android shows a chooser dialog asking which launcher to use (Pixel Launcher vs Taler ID Dev). If you don't see Taler ID Dev in the list — manifest filter didn't apply. Check `flutter build apk --flavor dev` output for manifest merger errors; inspect generated `build/app/intermediates/merged_manifests/devRelease/AndroidManifest.xml` to confirm both `LAUNCHER` and `HOME`+`DEFAULT` filters are present.

- [ ] **Step 11.4: Pick Taler ID Dev as default launcher in the chooser**

Tap "Taler ID Dev" → "Always". Press Home again — should land on whatever your `initialLocation` is. For the spike, you want Home button → `/agent-shell`.

If `initialLocation` is `splash` and splash redirects to home, you'll see standard Taler ID dashboard. We need home-button-press to route to `/agent-shell` specifically.

- [ ] **Step 11.5: Add launcher-mode detection in main_dev.dart**

This is the small "feels right" piece for spike — when launched via HOME intent, jump straight to `/agent-shell` instead of splash. Quick approach: in `lib/main_dev.dart` (or wherever `runApp` is called for dev), set a global flag based on the launch intent. The cleanest path is a platform channel that queries the originating Intent's categories.

For Phase 0 SPIKE, simplest: set `initialLocation = RouteConstants.agentShell` permanently in dev flavor by adding an env check in `app_router.dart`:
```dart
final isAgentShellLauncher =
    const String.fromEnvironment('AGENT_SHELL_AS_HOME', defaultValue: 'false') ==
        'true';
final initial = isAgentShellLauncher
    ? RouteConstants.agentShell
    : RouteConstants.splash;
```

Then run with `--dart-define=AGENT_SHELL_AS_HOME=true` during the spike. Production behavior unchanged.

Update your run command:
```bash
flutter run -d emulator-5554 --flavor dev -t lib/main_dev.dart \
  --dart-define=FLAVOR=dev \
  --dart-define=BASE_URL=https://staging.id.taler.tirol \
  --dart-define=AGENT_SHELL_AS_HOME=true
```

- [ ] **Step 11.6: Press Home — verify agent shell screen appears immediately**

- [ ] **Step 11.7: Commit**

```bash
git add android/app/src/main/AndroidManifest.xml android/app/build.gradle lib/core/router/app_router.dart
git commit -m "feat(agent-shell): make dev flavor eligible as Android home launcher"
```

---

## Task 12: Voice integration — register `agent_task` tool in OpenAI Realtime session (TDD-light)

**Files:**
- Create: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/assistant/services/agent_task_handler.dart`
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/assistant/presentation/screens/assistant_screen.dart` (touch only lines 630-639 for tool config and 1600-1650 for dispatch)
- Create: `/Users/dmitry/Downloads/taler_id_mobile/test/features/assistant/agent_task_handler_test.dart`

The integration with `assistant_screen.dart` is the trickiest part — it's 2,800 lines. We isolate logic into a small testable handler class and only touch two regions of the screen file.

- [ ] **Step 12.1: Write failing test for AgentTaskHandler**

```dart
// test/features/assistant/agent_task_handler_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/agent/agent_loop.dart';
import 'package:taler_id_mobile/features/assistant/services/agent_task_handler.dart';

class _MockAgentLoop extends Mock implements AgentLoop {}

void main() {
  late _MockAgentLoop loop;
  late AgentTaskHandler handler;

  setUp(() {
    loop = _MockAgentLoop();
    handler = AgentTaskHandler(loop: loop);
  });

  test('passes goal to AgentLoop and returns finalText', () async {
    when(() => loop.run(userGoal: 'do stuff'))
        .thenAnswer((_) async => AgentResult(
              finalText: 'done',
              toolCalls: const [],
              aborted: false,
            ));

    final out = await handler.run({'goal': 'do stuff'});
    expect(out, 'done');
  });

  test('returns error string when goal missing', () async {
    final out = await handler.run({});
    expect(out, contains('ERROR'));
  });

  test('returns aborted result with marker', () async {
    when(() => loop.run(userGoal: 'oops'))
        .thenAnswer((_) async => AgentResult(
              finalText: 'partial',
              toolCalls: const [],
              aborted: true,
            ));
    final out = await handler.run({'goal': 'oops'});
    expect(out, contains('aborted'));
    expect(out, contains('partial'));
  });
}
```

- [ ] **Step 12.2: Run failing test**

```bash
flutter test test/features/assistant/agent_task_handler_test.dart
```

Expected: FAIL — import not found.

- [ ] **Step 12.3: Implement AgentTaskHandler**

`lib/features/assistant/services/agent_task_handler.dart`:
```dart
import '../../../core/agent/agent_loop.dart';

class AgentTaskHandler {
  final AgentLoop loop;
  AgentTaskHandler({required this.loop});

  Future<String> run(Map<String, dynamic> input) async {
    final goal = input['goal'];
    if (goal is! String || goal.isEmpty) {
      return 'ERROR: missing required string parameter "goal"';
    }
    final result = await loop.run(userGoal: goal);
    if (result.aborted) {
      return 'aborted after ${result.toolCalls.length} tool calls; partial: ${result.finalText}';
    }
    return result.finalText;
  }
}
```

- [ ] **Step 12.4: Run test — verify passes**

```bash
flutter test test/features/assistant/agent_task_handler_test.dart
```

Expected: 3 tests pass.

- [ ] **Step 12.5: Register AgentTaskHandler in DI**

In `lib/core/di/service_locator.dart`, near the AgentLoop registration from Task 7:
```dart
sl.registerLazySingleton<AgentTaskHandler>(
  () => AgentTaskHandler(loop: sl<AgentLoop>()),
);
```
Add the import at top.

- [ ] **Step 12.6: Add `agent_task` tool to OpenAI Realtime session in assistant_screen.dart**

Open `assistant_screen.dart`, navigate to lines 630-639 (the session config `tools: [...]` array per recon). Append a new tool entry **at the end of the array, before the closing bracket**:
```dart
{
  'type': 'function',
  'name': 'agent_task',
  'description':
      'Delegate a complex multi-step task to an internal agent loop. Use ONLY when the task requires multiple steps, planning, or tools beyond the voice-layer ones. Returns the final natural-language result.',
  'parameters': {
    'type': 'object',
    'properties': {
      'goal': {
        'type': 'string',
        'description':
            'Plain-language statement of what the user wants done. Be specific and include any constraints from the user.',
      },
    },
    'required': ['goal'],
  },
},
```

- [ ] **Step 12.7: Wire `agent_task` dispatch in tool handler region (lines 1600-1650 per recon)**

Locate the `if (name == 'exit_translator_mode') { ... }` block. Add a sibling `else if` block:
```dart
else if (name == 'agent_task') {
  try {
    final args = jsonDecode(argsJson) as Map<String, dynamic>;
    final handler = GetIt.I<AgentTaskHandler>();
    final result = await handler.run(args);
    // Feed the result back to OpenAI Realtime as the tool's output:
    _sendFunctionCallOutput(callId, result);
  } catch (e) {
    _sendFunctionCallOutput(
      callId,
      'ERROR: agent_task threw: $e',
    );
  }
}
```

**Note:** Names like `_sendFunctionCallOutput` and `callId` are placeholders — when editing, use the **actual** helper / variable names already used by the other tool handlers immediately above (e.g. `exit_translator_mode`). Match the existing pattern verbatim — don't invent new ones.

Add the GetIt import at top of `assistant_screen.dart` if not already present:
```dart
import 'package:get_it/get_it.dart';
import '../../services/agent_task_handler.dart';
```

- [ ] **Step 12.8: Run app + voice smoke test on emulator**

```bash
flutter run -d emulator-5554 --flavor dev -t lib/main_dev.dart \
  --dart-define=FLAVOR=dev \
  --dart-define=BASE_URL=https://staging.id.taler.tirol \
  --dart-define=AGENT_SHELL_AS_HOME=true
```

Grant microphone permission. Open the existing Assistant screen (not the new agent_shell screen — the Realtime voice lives there). Say:

> "Run the agent task to echo back the word ping."

Watch Flutter logs. Expected:
1. OpenAI Realtime sends `function_call` for `agent_task` with `goal` containing the user's phrasing
2. `AgentTaskHandler.run` invoked, hits backend `/agent/claude`
3. Claude returns `tool_use` for `echo`
4. EchoTool runs locally, returns "ping"
5. Claude returns `end_turn` with text like "echoed: ping"
6. `_sendFunctionCallOutput` sends that back to Realtime
7. Realtime speaks "Echoed back: ping" or similar

**This is Phase 0's primary exit criterion.** If anything in this chain fails, debug there before moving on.

- [ ] **Step 12.9: Commit**

```bash
git add lib/features/assistant/services/agent_task_handler.dart \
  lib/features/assistant/presentation/screens/assistant_screen.dart \
  lib/core/di/service_locator.dart \
  test/features/assistant/agent_task_handler_test.dart
git commit -m "feat(assistant): add agent_task tool routing to Claude Agent Loop"
```

---

## Task 13: Daily-driver switchover + journaling setup

**Files:**
- Create: `/Users/dmitry/Downloads/taler_id_mobile/docs/agent-shell-journal.md` (gitignored or repo, your call)

This task is procedural — getting Дмитрий's actual Pixel device set up as daily driver and starting the friction journal that drives Phase 1 prioritization.

- [ ] **Step 13.1: Build the dev APK**

```bash
ssh dvolkov@138.124.61.221 \
  'cd ~/taler_id_mobile && git fetch origin && git checkout feature/agent-shell-phase-0 && git pull && \
   flutter build apk --flavor dev --release -t lib/main_dev.dart \
     --dart-define=FLAVOR=dev \
     --dart-define=BASE_URL=https://staging.id.taler.tirol \
     --dart-define=AGENT_SHELL_AS_HOME=true && \
   cp build/app/outputs/flutter-apk/app-dev-release.apk /var/www/downloads/taler-id-dev.apk'
```

Public URL: https://id.taler.tirol/download/taler-id-dev.apk

- [ ] **Step 13.2: Install on Pixel**

Open https://id.taler.tirol/download/taler-id-dev.apk on the Pixel, install, allow unknown sources, sign in.

- [ ] **Step 13.3: Set as default launcher**

Press Home → chooser appears → "Taler ID Dev" → "Always".

- [ ] **Step 13.4: Verify agent_shell screen on Home press**

Press Home button — should land on the agent shell chat screen. Type "ping" — should round-trip via Claude. Press Power → Power → Home — should also land here (full launcher experience).

- [ ] **Step 13.5: Create journal file in repo**

`/Users/dmitry/Downloads/taler_id_mobile/docs/agent-shell-journal.md`:
```markdown
# Agent Shell — Daily Driver Journal

Pain points, missing capabilities, surprising wins. Drives Phase 1 prioritization.

## 2026-05-XX (Day 1)

- [ ] Setup done, launcher swapped, first echo round-trip OK
- 
```

- [ ] **Step 13.6: Commit journal**

```bash
git add docs/agent-shell-journal.md
git commit -m "docs(agent-shell): start daily-driver journal"
```

- [ ] **Step 13.7: PUSH the mobile branch — do not merge yet**

```bash
git push -u origin feature/agent-shell-phase-0
```

Same for backend if not already pushed:
```bash
cd /Users/dmitry/Downloads/taler_id
git push -u origin feature/agent-shell-phase-0
```

**Do NOT merge to `dev` (mobile) or `main` (backend) until you've used this for at least 5 days and decided it's worth continuing.** Phase 1 work happens on top of this branch or merges in once green.

---

## Phase 0 Exit Criteria — Sign-off Checklist

Before declaring Phase 0 done and starting Phase 1 planning:

- [ ] Backend `/agent/claude` proxies a real Anthropic call successfully (curl test passes)
- [ ] All unit tests pass: `npm test` (backend), `flutter test` (mobile)
- [ ] Mobile app builds for dev flavor without warnings: `flutter build apk --flavor dev --release`
- [ ] Voice end-to-end: spoken "echo ping" via Assistant → `agent_task` → Claude → echo tool → spoken result
- [ ] Direct chat end-to-end on `/agent-shell` screen: typed message → Claude → reply
- [ ] Default launcher set on Pixel; Home button → agent shell chat screen
- [ ] Journal file initialized with at least 1 day of usage notes
- [ ] PROD untouched (still on `main`/`prod` branches, no merge done)
- [ ] No regressions in existing Taler ID tests: integration test suite (`npm test` in `~/Downloads/taler_id_tests`) passes
- [ ] Anthropic API key NOT present in any committed file (`git log -p | grep ANTHROPIC_API_KEY` returns nothing)

When all of these are checked, run `superpowers:writing-plans` again with the Phase 1 spec section to write the Phase 1 plan.

---

## Notes for the implementer

- **TDD discipline:** Each task here writes the test first, then implementation. Don't skip; don't bulk-write code and then write tests after. The plan order is the execution order.
- **Commits:** One commit per task. Don't squash; keep the spike's history granular so we can bisect later if Phase 1 work touches something fragile.
- **Existing patterns:** Read the existing Voice and Assistant modules before writing new code in those files. The codebase has established conventions — follow them, don't invent parallel ones.
- **Don't expand scope.** If you find yourself adding tools beyond `echo`, stop and ask. Phase 1 is when more tools come. Phase 0 only proves the plumbing works.
- **Anthropic blocking risk (R2 in spec).** If the AEZA DEV server can't reach `api.anthropic.com` directly, the recovery is documented in Task 4 Step 4.5. Do that fix only if needed — don't preemptively build the DO proxy.
- **Existing OpenAI Realtime integration.** Task 12 touches a 2,800-line file. Read the regions around lines 630-639 and 1600-1650 first so you understand the conventions before editing. Match the helper-method names verbatim.
