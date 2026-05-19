# Taler ID Agent Shell — Phase 0 Implementation Plan (v2, OAuth)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Validate end-to-end architecture (OpenAI Realtime → `agent_task` tool → backend `POST /agent/run` → Claude Agent SDK with OAuth → echo tool → spoken response) by building a thin spike: backend integrates `@anthropic-ai/claude-agent-sdk` using existing `claude` CLI OAuth credentials, exposes `/agent/run`, Flutter sends goals as plain REST, the existing OpenAI Realtime session gets a new `agent_task` tool that delegates to the backend. Plus AndroidManifest tweak so Taler ID is eligible as Android home launcher, and a basic chat screen for direct (non-voice) interaction. After Phase 0 Дмитрий switches his Pixel to Taler ID as default home and starts journaling pain points.

**Architecture (after 2026-05-19 pivot):** Backend NestJS gains a JWT-protected `POST /agent/run` endpoint backed by `@anthropic-ai/claude-agent-sdk`. The SDK authenticates via OAuth, reading credentials from `~/.claude/.credentials.json` on the DEV server (the same `claude login` Дмитрий already uses for `taler-monitor`). One custom `echo` tool is registered as TypeScript code on the backend — it just validates that tool_use round-trips through the SDK. Flutter gets a tiny `AgentClient` (Dio wrapper), `AgentBloc`, `AgentShellHomeScreen` — **no Dart agent loop, no tool registry on phone**. Phone-side tools come in Phase 1+ via WebSocket bridge.

**Tech Stack:**
- Backend: NestJS, `@anthropic-ai/claude-agent-sdk` (npm), Jest, JwtAuthGuard, `process.env`
- Flutter: `flutter_bloc`, `freezed`, `dio`, `mocktail`, `go_router`, `get_it`, `bloc_test`
- Claude model: `claude-sonnet-4-6` default (Opus 4.7 by flag for heavy tasks later)
- Auth: OAuth via `claude login` on DEV server

**Spec reference:** `docs/superpowers/specs/2026-05-18-taler-agent-shell-design.md` (revised 2026-05-19 — see Update Log)

**Branches:**
- Mobile: `feature/agent-shell-phase-0` off `dev` in `/Users/dmitry/Downloads/taler_id_mobile/` ✓ created in Task 1
- Backend: `feature/agent-shell-phase-0` off `main` in `/Users/dmitry/Downloads/taler_id/` ✓ created in Task 1

**Deploy target:** DEV only (`dvolkov@89.169.55.217`). PROD untouched. Per CLAUDE.md rule.

**Out of scope for Phase 0** (explicit, do NOT add):
- Any tools other than `echo` (no system.*, no call.*, no dev.* — those come in Phase 1+)
- Phone-side tool WebSocket bridge (Phase 1)
- Wake-word / Porcupine (Phase 6)
- Accessibility Service (Phase 5)
- Dynamic UI widgets beyond plain text bubbles
- iOS support
- Daily-driver hardening (foreground service, battery audit, etc.) — Phase 6
- Anthropic API-key auth — we use OAuth only

---

## Task 1: Create feature branches ✓ DONE

Already completed 2026-05-18. Both repos have `feature/agent-shell-phase-0` branches active.

---

## Task 2: Verify `claude` CLI on analyst box + SSH path from DEV → analyst

**Files:** No code changes. Operational verification.

The backend NestJS on DEV (89.169.55.217) will spawn SSH-subprocess to the analyst box (`dv@5.101.115.184`) and run `claude --print` there. This is the same pattern `taler-monitor` already uses. We need to confirm:
1. `claude` CLI works on analyst box (Дмитрий already uses it for `taler-monitor`).
2. Non-interactive SSH from DEV → analyst is configured (key-based, no password prompt).

- [ ] **Step 2.1: Verify `claude` CLI on analyst-box works directly**

```bash
ssh dv@5.101.115.184 'which claude && claude --version && ls -la ~/.claude/.credentials.json 2>&1'
```

Expected: claude path, version number, credentials file present with `600` permissions. If any of these fails — fix on analyst box first (re-install / `claude login`).

- [ ] **Step 2.2: Sanity-check `claude --print` non-interactive works**

```bash
ssh dv@5.101.115.184 'claude --print --output-format text -- "Reply with only the single word: pong"'
```

Expected: stdout = `pong` (possibly with trailing newline). If `claude` prints multi-line preamble or formatting that we don't want — try `--output-format text` (or `--output-format=text`) per `claude --help`. If `--print` is not the flag name on the installed version, run `claude --help` and use whatever non-interactive one-shot mode exists.

If the prompt syntax differs (e.g. claude expects `claude -p "..."` instead of `claude --print -- "..."`), note the actual invocation — Task 3 production code must match.

- [ ] **Step 2.3: Verify SSH from DEV → analyst is key-based (non-interactive)**

```bash
ssh dvolkov@89.169.55.217 'ssh -o BatchMode=yes dv@5.101.115.184 "echo SSH-OK"'
```

Expected: `SSH-OK` on stdout, no password prompt, no host-key prompt.

If "Permission denied (publickey)" — copy DEV's `~/.ssh/id_*.pub` to analyst's `~/.ssh/authorized_keys` for user `dv`:
```bash
ssh dvolkov@89.169.55.217 'cat ~/.ssh/id_ed25519.pub' | \
  ssh dv@5.101.115.184 'cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys'
```
(Adjust key filename if not ed25519.)

If "Host key verification failed" — first do `ssh dvolkov@89.169.55.217 'ssh-keyscan -t ed25519 5.101.115.184 >> ~/.ssh/known_hosts'`.

- [ ] **Step 2.4: Full chain test — DEV runs `claude` on analyst**

```bash
ssh dvolkov@89.169.55.217 \
  'ssh -o BatchMode=yes dv@5.101.115.184 "claude --print --output-format text -- \"Reply with only the single word: pong\""'
```

Expected: `pong` on stdout. **This exact command (parameterized with the user's goal) is what AgentService will spawn in Task 3.** If this works end-to-end, Phase 0 architecture is validated at the operational level — Task 3 just wraps it in NestJS.

- [ ] **Step 2.5: Latency sample**

```bash
time ssh dvolkov@89.169.55.217 \
  'ssh -o BatchMode=yes dv@5.101.115.184 "claude --print --output-format text -- \"Reply with: ack\""'
```

Expected: 2-6 seconds (SSH-DEV + SSH-analyst + Claude API + return). Record this as the baseline — it's the floor for Phase 0 voice latency.

If significantly slower (>10s) — investigate SSH connection caching (`~/.ssh/config` with `ControlMaster auto`, `ControlPath`, `ControlPersist 10m` on DEV-side for the analyst host).

- [ ] **Step 2.6: Document tier + invocation pattern**

Save to a scratch note (we'll formalize in journal in Task 12):
- Claude CLI version on analyst
- Plan/tier of the OAuth account (Pro / Max / Team)
- The exact `claude` invocation that produced the expected output in Step 2.2 — Task 3 production code must mirror this verbatim
- Latency baseline from Step 2.5

- [ ] **Step 2.7: No commit** (operational only).

**Note:** Anthropic blocking is NOT a risk here — analyst box already reaches Anthropic successfully (taler-monitor confirms). DEV server itself does not call Anthropic; only SSH to analyst.

---

## Task 3: Backend — AgentModule with SSH-subprocess to analyst (TDD)

**Files:**
- Create: `/Users/dmitry/Downloads/taler_id/src/agent/agent.module.ts`
- Create: `/Users/dmitry/Downloads/taler_id/src/agent/agent.controller.ts`
- Create: `/Users/dmitry/Downloads/taler_id/src/agent/agent.service.ts`
- Create: `/Users/dmitry/Downloads/taler_id/src/agent/dto/run-agent-request.dto.ts`
- Create: `/Users/dmitry/Downloads/taler_id/src/agent/dto/run-agent-response.dto.ts`
- Create: `/Users/dmitry/Downloads/taler_id/src/agent/agent.service.spec.ts`
- Modify: `/Users/dmitry/Downloads/taler_id/src/app.module.ts` — register AgentModule

**No new npm packages.** We use Node's built-in `child_process.exec` to spawn an SSH command to the analyst box. No Claude SDK in this process — the `claude` CLI on the analyst box does all the work.

The backend's `AgentService.runAgent` will:
1. Take a `goal` string from the caller.
2. Spawn `ssh -o BatchMode=yes dv@5.101.115.184 'claude --print --output-format text -- "<escaped goal>"'`.
3. Capture stdout, return as `finalText`.
4. On non-zero exit or timeout, set `aborted: true` and put stderr/error in `finalText`.

**Verify in Task 2 first** what the exact non-interactive `claude` invocation is on the analyst box. The command shown above assumes `--print --output-format text -- "PROMPT"`. If your installed claude version uses `claude -p "..."` or different flags, adapt all instances in this task.

- [ ] **Step 3.1: Create DTO files**

`/Users/dmitry/Downloads/taler_id/src/agent/dto/run-agent-request.dto.ts`:
```typescript
import { IsString, IsOptional } from 'class-validator';

export class RunAgentRequestDto {
  @IsString()
  goal!: string;

  @IsOptional()
  @IsString()
  conversationId?: string;
}
```

(No `model` field for Phase 0 — claude CLI on analyst is invoked with its default model. Model selection comes in Phase 1+ if needed via `claude --model` flag.)

`/Users/dmitry/Downloads/taler_id/src/agent/dto/run-agent-response.dto.ts`:
```typescript
export interface AgentToolCall {
  name: string;
  input: Record<string, unknown>;
  output: string;
}

export interface RunAgentResponseDto {
  finalText: string;
  toolCalls: AgentToolCall[]; // empty in Phase 0 — claude CLI runs tools internally
  aborted: boolean;
  conversationId?: string;
  durationMs?: number;
}
```

- [ ] **Step 3.2: Write failing test for `AgentService`**

`/Users/dmitry/Downloads/taler_id/src/agent/agent.service.spec.ts`:
```typescript
import { Test, TestingModule } from '@nestjs/testing';
import { AgentService } from './agent.service';

const mockExec = jest.fn();
jest.mock('node:child_process', () => ({
  exec: (cmd: string, opts: any, cb: any) => mockExec(cmd, opts, cb),
}));

describe('AgentService', () => {
  let service: AgentService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [AgentService],
    }).compile();
    service = module.get<AgentService>(AgentService);
    mockExec.mockReset();
  });

  it('spawns SSH command targeting analyst host and returns claude stdout', async () => {
    mockExec.mockImplementation((_cmd: string, _opts: any, cb: any) => {
      cb(null, { stdout: 'pong\n', stderr: '' });
    });

    const result = await service.runAgent({
      goal: 'Reply with: pong',
      userId: 'user-123',
    });

    expect(result.finalText).toBe('pong');
    expect(result.aborted).toBe(false);
    expect(result.toolCalls).toEqual([]);

    // Verify the spawned command shape
    const [cmd] = mockExec.mock.calls[0];
    expect(cmd).toContain('ssh');
    expect(cmd).toContain('dv@5.101.115.184');
    expect(cmd).toContain('claude');
    expect(cmd).toContain('--print');
    expect(cmd).toContain('Reply with: pong');
  });

  it('escapes single quotes in the goal to prevent shell injection', async () => {
    mockExec.mockImplementation((_cmd: string, _opts: any, cb: any) => {
      cb(null, { stdout: 'ok', stderr: '' });
    });

    await service.runAgent({
      goal: "what's the time?",
      userId: 'u1',
    });

    const [cmd] = mockExec.mock.calls[0];
    // The single quote in "what's" must NOT close the outer shell string unsafely
    expect(cmd).not.toMatch(/'what's/);
    // It should be escaped — pattern depends on chosen escaping. Either:
    //  - '\\'' sequence (POSIX): 'what'\''s'
    //  - Or use a different quoting strategy entirely.
    // Either way the goal text must be reconstructible inside the inner shell.
    expect(cmd).toMatch(/what.{1,4}s the time\?/);
  });

  it('marks aborted on non-zero exit and surfaces stderr', async () => {
    mockExec.mockImplementation((_cmd: string, _opts: any, cb: any) => {
      const err: any = new Error('Command failed');
      err.code = 1;
      err.stdout = '';
      err.stderr = 'claude: rate limited';
      cb(err);
    });

    const result = await service.runAgent({
      goal: 'go',
      userId: 'u1',
    });

    expect(result.aborted).toBe(true);
    expect(result.finalText).toContain('rate limited');
  });

  it('marks aborted on timeout', async () => {
    mockExec.mockImplementation((_cmd: string, _opts: any, cb: any) => {
      const err: any = new Error('timeout');
      err.killed = true;
      err.signal = 'SIGTERM';
      err.stdout = '';
      err.stderr = '';
      cb(err);
    });

    const result = await service.runAgent({
      goal: 'long task',
      userId: 'u1',
    });

    expect(result.aborted).toBe(true);
    expect(result.finalText.toLowerCase()).toMatch(/timeout|killed|aborted/);
  });
});
```

- [ ] **Step 3.3: Run test — verify it fails**

```bash
cd /Users/dmitry/Downloads/taler_id
npm test -- src/agent/agent.service.spec.ts
```

Expected: FAIL with `Cannot find module './agent.service'`.

- [ ] **Step 3.4: Implement `AgentService`**

`/Users/dmitry/Downloads/taler_id/src/agent/agent.service.ts`:
```typescript
import { Injectable, Logger } from '@nestjs/common';
import { exec } from 'node:child_process';
import { promisify } from 'node:util';
import { RunAgentResponseDto } from './dto/run-agent-response.dto';

const execAsync = promisify(exec);

interface RunAgentInput {
  goal: string;
  userId: string;
  conversationId?: string;
}

@Injectable()
export class AgentService {
  private readonly logger = new Logger(AgentService.name);
  private readonly ANALYST_HOST = process.env.CLAUDE_ANALYST_HOST || 'dv@5.101.115.184';
  private readonly TIMEOUT_MS = 120_000; // 2 min for Phase 0; tune later
  private readonly MAX_BUFFER = 5 * 1024 * 1024; // 5 MB stdout cap

  async runAgent(input: RunAgentInput): Promise<RunAgentResponseDto> {
    this.logger.debug(
      `agent.run user=${input.userId} goal="${input.goal.slice(0, 80)}"`,
    );

    const cmd = this.buildSshCommand(input.goal);
    const start = Date.now();

    try {
      const { stdout, stderr } = await execAsync(cmd, {
        timeout: this.TIMEOUT_MS,
        maxBuffer: this.MAX_BUFFER,
      });

      if (stderr) {
        this.logger.warn(`claude stderr: ${stderr.slice(0, 500)}`);
      }

      return {
        finalText: stdout.trim(),
        toolCalls: [],
        aborted: false,
        conversationId: input.conversationId,
        durationMs: Date.now() - start,
      };
    } catch (err: any) {
      const durationMs = Date.now() - start;
      const reason =
        err.killed && err.signal === 'SIGTERM'
          ? `timeout after ${this.TIMEOUT_MS}ms`
          : err.code != null
          ? `exit ${err.code}`
          : 'unknown';
      const stderr = (err.stderr || '').toString().slice(0, 500);
      const stdout = (err.stdout || '').toString().slice(0, 500);

      this.logger.error(
        `agent.run failed user=${input.userId} reason="${reason}" stderr="${stderr}"`,
      );

      return {
        finalText: `(aborted: ${reason}) ${stderr || stdout}`.trim(),
        toolCalls: [],
        aborted: true,
        conversationId: input.conversationId,
        durationMs,
      };
    }
  }

  /**
   * Build the shell command:
   *   ssh -o BatchMode=yes dv@5.101.115.184 'claude --print --output-format text -- "<goal>"'
   *
   * Goal is escaped to be safe inside the OUTER single-quoted shell string
   * AND inside the INNER double-quoted claude argument. Strategy:
   *   1. Replace any double-quote with \" (escapes within inner double-quoted arg)
   *   2. Replace any single-quote with '\\'' (POSIX trick to close, escape, reopen
   *      the outer single-quoted string)
   */
  private buildSshCommand(goal: string): string {
    const innerEscaped = goal.replace(/"/g, '\\"'); // protect inner double-quotes
    const outerEscaped = innerEscaped.replace(/'/g, "'\\''"); // protect outer single-quotes
    return `ssh -o BatchMode=yes ${this.ANALYST_HOST} 'claude --print --output-format text -- "${outerEscaped}"'`;
  }
}
```

**Note:** If `claude --print` outputs extra preamble lines (e.g. session ID, model info) before the actual response, you may need to parse them out. Run Step 2.2 of Task 2 and observe the exact stdout shape — the assertion `.trim()` here assumes the actual response is the only content. If not, add filtering logic and a test for it.

- [ ] **Step 3.5: Run tests — verify pass**

```bash
cd /Users/dmitry/Downloads/taler_id
npm test -- src/agent/agent.service.spec.ts
```

Expected: 4 tests pass.

- [ ] **Step 3.6: Create `AgentController`**

`/Users/dmitry/Downloads/taler_id/src/agent/agent.controller.ts`:
```typescript
import { Body, Controller, Logger, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { AgentService } from './agent.service';
import { RunAgentRequestDto } from './dto/run-agent-request.dto';
import { RunAgentResponseDto } from './dto/run-agent-response.dto';

@Controller('agent')
export class AgentController {
  private readonly logger = new Logger(AgentController.name);
  constructor(private readonly agent: AgentService) {}

  @UseGuards(JwtAuthGuard)
  @Post('run')
  async run(
    @CurrentUser() user: any,
    @Body() body: RunAgentRequestDto,
  ): Promise<RunAgentResponseDto> {
    return this.agent.runAgent({
      goal: body.goal,
      userId: user?.sub,
      conversationId: body.conversationId,
    });
  }
}
```

**Verify** import paths: `CurrentUser` decorator location may differ. Grep:
```bash
grep -rn "export.*CurrentUser" /Users/dmitry/Downloads/taler_id/src/
```
and adjust the import accordingly.

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

Open `/Users/dmitry/Downloads/taler_id/src/app.module.ts`. Find the `imports: [...]` array. Add `AgentModule`; add the import at the top:
```typescript
import { AgentModule } from './agent/agent.module';
```

- [ ] **Step 3.9: Build**

```bash
cd /Users/dmitry/Downloads/taler_id && npm run build
```

Expected: clean build.

- [ ] **Step 3.10: Commit**

```bash
git add src/agent/ src/app.module.ts
git commit -m "feat(agent): /agent/run endpoint via SSH-subprocess to claude on analyst box"
```

Note: no `package.json` / `package-lock.json` in the commit — we didn't add any dependencies.

---

## Task 4: Deploy backend to DEV and verify endpoint live

**Files:** No new code. Operational verification.

- [ ] **Step 4.1: Push branch**

```bash
cd /Users/dmitry/Downloads/taler_id
git push -u origin feature/agent-shell-phase-0
```

- [ ] **Step 4.2: Pull on DEV server**

```bash
ssh dvolkov@89.169.55.217 'cd ~/taler-id && git fetch origin && git checkout feature/agent-shell-phase-0 && git pull'
```

No `npm install` step — Task 3 added no dependencies.

- [ ] **Step 4.3: Build + restart**

```bash
ssh dvolkov@89.169.55.217 'cd ~/taler-id && npm run build && pm2 restart taler-id-dev && pm2 logs taler-id-dev --lines 30 --nostream'
```

Look for `[AgentService]` log lines confirming the module loaded.

- [ ] **Step 4.4: Get JWT for test account**

```bash
curl -sX POST https://staging.id.taler.tirol/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"integration_test@taler-test.com","password":"IntegrationTest123!"}' \
  | jq -r '.access_token' > /tmp/jwt.txt && head -c 30 /tmp/jwt.txt && echo "..."
```

- [ ] **Step 4.5: Test endpoint**

```bash
curl -sX POST https://staging.id.taler.tirol/agent/run \
  -H "Authorization: Bearer $(cat /tmp/jwt.txt)" \
  -H 'Content-Type: application/json' \
  -d '{"goal":"Reply with only the single word: pong"}' \
  | jq
```

Expected: `finalText` equals "pong" (or contains it), `toolCalls: []`, `aborted: false`, `durationMs` ~2000-6000.

If 401 — JWT expired. If 500 with stderr mentioning SSH — DEV → analyst SSH key setup issue (revisit Task 2 Step 2.3). If 500 with stderr from claude — analyst-box OAuth issue (run `claude login` again on the analyst). If `aborted: true` with `(aborted: timeout...)` — the 120s timeout was hit, which means claude or SSH is hanging — check claude version and try non-interactive directly per Task 2 Step 2.2.

- [ ] **Step 4.6: Latency observation**

```bash
time curl -sX POST https://staging.id.taler.tirol/agent/run \
  -H "Authorization: Bearer $(cat /tmp/jwt.txt)" \
  -H 'Content-Type: application/json' \
  -d '{"goal":"Reply with just the word: ack"}' \
  > /dev/null
```

Expected: 2-6 sec for a simple turn. Note observation.

---

## Task 5: Flutter — Define `AgentRunResult` Freezed type

**Files:**
- Create: `/Users/dmitry/Downloads/taler_id_mobile/lib/core/agent/models/agent_run_result.dart`

Only one Freezed file needed on Flutter side (no `AgentMessage`, no `AgentTool`, no `AgentResponse` — those were for the obsolete Dart agent loop).

- [ ] **Step 5.1: Verify Freezed in pubspec**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile && grep -E "(freezed|json_serializable|json_annotation)" pubspec.yaml
```

Expected: lines present (used by other features in this app).

- [ ] **Step 5.2: Create model**

`lib/core/agent/models/agent_run_result.dart`:
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'agent_run_result.freezed.dart';
part 'agent_run_result.g.dart';

@freezed
class AgentToolCall with _$AgentToolCall {
  const factory AgentToolCall({
    required String name,
    required Map<String, dynamic> input,
    required String output,
  }) = _AgentToolCall;

  factory AgentToolCall.fromJson(Map<String, dynamic> json) =>
      _$AgentToolCallFromJson(json);
}

@freezed
class AgentRunResult with _$AgentRunResult {
  const factory AgentRunResult({
    required String finalText,
    required List<AgentToolCall> toolCalls,
    required bool aborted,
    String? conversationId,
  }) = _AgentRunResult;

  factory AgentRunResult.fromJson(Map<String, dynamic> json) =>
      _$AgentRunResultFromJson(json);
}
```

- [ ] **Step 5.3: Run build_runner**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile
dart run build_runner build --delete-conflicting-outputs
```

Expected: success, generates `.freezed.dart` and `.g.dart`.

- [ ] **Step 5.4: Commit**

```bash
git add lib/core/agent/models/
git commit -m "feat(agent): add AgentRunResult Freezed type"
```

---

## Task 6: Flutter — `AgentClient` (Dio wrapper) + tests (TDD)

**Files:**
- Create: `/Users/dmitry/Downloads/taler_id_mobile/lib/core/agent/agent_client.dart`
- Create: `/Users/dmitry/Downloads/taler_id_mobile/test/core/agent/agent_client_test.dart`

Single-method client. No agent loop, no tools — that all lives on backend now.

- [ ] **Step 6.1: Write failing test**

`test/core/agent/agent_client_test.dart`:
```dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/agent/agent_client.dart';

class _MockDio extends Mock implements Dio {}

class _FakeRequestOptions extends Fake implements RequestOptions {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeRequestOptions());
  });

  late _MockDio dio;
  late AgentClient client;

  setUp(() {
    dio = _MockDio();
    client = AgentClient(dio);
  });

  test('POSTs /agent/run with goal and parses response', () async {
    when(() => dio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
        )).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/agent/run'),
        statusCode: 200,
        data: {
          'finalText': 'echoed: ping',
          'toolCalls': [
            {
              'name': 'echo',
              'input': {'text': 'ping'},
              'output': 'ping',
            },
          ],
          'aborted': false,
          'conversationId': 'conv-1',
        },
      ),
    );

    final result = await client.runAgent(goal: 'echo ping');

    expect(result.finalText, 'echoed: ping');
    expect(result.toolCalls.length, 1);
    expect(result.toolCalls.first.name, 'echo');
    expect(result.toolCalls.first.output, 'ping');
    expect(result.aborted, isFalse);
    expect(result.conversationId, 'conv-1');

    verify(() => dio.post<Map<String, dynamic>>(
          '/agent/run',
          data: {'goal': 'echo ping'},
        )).called(1);
  });

  test('includes conversationId and model when provided', () async {
    when(() => dio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
        )).thenAnswer(
      (_) async => Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/agent/run'),
        statusCode: 200,
        data: {
          'finalText': 'ok',
          'toolCalls': [],
          'aborted': false,
        },
      ),
    );

    await client.runAgent(
      goal: 'go',
      conversationId: 'c-9',
      model: 'claude-opus-4-7',
    );

    verify(() => dio.post<Map<String, dynamic>>(
          '/agent/run',
          data: {
            'goal': 'go',
            'conversationId': 'c-9',
            'model': 'claude-opus-4-7',
          },
        )).called(1);
  });
}
```

- [ ] **Step 6.2: Run failing test**

```bash
cd /Users/dmitry/Downloads/taler_id_mobile
flutter test test/core/agent/agent_client_test.dart
```

Expected: FAIL.

- [ ] **Step 6.3: Implement**

`lib/core/agent/agent_client.dart`:
```dart
import 'package:dio/dio.dart';
import 'models/agent_run_result.dart';

class AgentClient {
  final Dio _dio;

  AgentClient(this._dio);

  Future<AgentRunResult> runAgent({
    required String goal,
    String? conversationId,
    String? model,
  }) async {
    final body = <String, dynamic>{
      'goal': goal,
      if (conversationId != null) 'conversationId': conversationId,
      if (model != null) 'model': model,
    };

    final resp = await _dio.post<Map<String, dynamic>>(
      '/agent/run',
      data: body,
    );

    return AgentRunResult.fromJson(resp.data ?? const {});
  }
}
```

- [ ] **Step 6.4: Verify pass**

```bash
flutter test test/core/agent/agent_client_test.dart
```

Expected: 2 tests pass.

- [ ] **Step 6.5: Commit**

```bash
git add lib/core/agent/agent_client.dart test/core/agent/agent_client_test.dart
git commit -m "feat(agent): add AgentClient Dio wrapper with tests"
```

---

## Task 7: Flutter — `AgentShellBloc` + `AgentShellHomeScreen` + tests

**Files:**
- Create: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/agent_shell/presentation/bloc/agent_shell_event.dart`
- Create: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/agent_shell/presentation/bloc/agent_shell_state.dart`
- Create: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/agent_shell/presentation/bloc/agent_shell_bloc.dart`
- Create: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/agent_shell/presentation/screens/agent_shell_home_screen.dart`
- Create: `/Users/dmitry/Downloads/taler_id_mobile/test/features/agent_shell/agent_shell_bloc_test.dart`

- [ ] **Step 7.1: Write failing bloc test**

`test/features/agent_shell/agent_shell_bloc_test.dart`:
```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/agent/agent_client.dart';
import 'package:taler_id_mobile/core/agent/models/agent_run_result.dart';
import 'package:taler_id_mobile/features/agent_shell/presentation/bloc/agent_shell_bloc.dart';

class _MockAgentClient extends Mock implements AgentClient {}

void main() {
  late _MockAgentClient agent;

  setUp(() {
    agent = _MockAgentClient();
  });

  blocTest<AgentShellBloc, AgentShellState>(
    'appends user + agent messages on submit',
    build: () {
      when(() => agent.runAgent(
            goal: any(named: 'goal'),
            conversationId: any(named: 'conversationId'),
            model: any(named: 'model'),
          )).thenAnswer(
        (_) async => const AgentRunResult(
          finalText: 'echoed: hi',
          toolCalls: [],
          aborted: false,
        ),
      );
      return AgentShellBloc(client: agent);
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

  blocTest<AgentShellBloc, AgentShellState>(
    'emits error state when AgentClient throws',
    build: () {
      when(() => agent.runAgent(
            goal: any(named: 'goal'),
            conversationId: any(named: 'conversationId'),
            model: any(named: 'model'),
          )).thenThrow(Exception('boom'));
      return AgentShellBloc(client: agent);
    },
    act: (bloc) => bloc.add(const AgentShellSubmit('hi')),
    expect: () => [
      isA<AgentShellState>().having((s) => s.busy, 'busy', true),
      isA<AgentShellState>()
          .having((s) => s.busy, 'busy', false)
          .having((s) => s.error, 'error', contains('boom')),
    ],
  );
}
```

Verify `bloc_test` is in dev_dependencies; if not, add `bloc_test: ^9.1.7`.

- [ ] **Step 7.2: Run failing test**

```bash
flutter test test/features/agent_shell/agent_shell_bloc_test.dart
```

Expected: FAIL.

- [ ] **Step 7.3: Create event + state**

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
  final String? conversationId;
  const AgentShellState({
    required this.messages,
    required this.busy,
    this.error,
    this.conversationId,
  });
  factory AgentShellState.initial() =>
      const AgentShellState(messages: [], busy: false);
  AgentShellState copyWith({
    List<AgentShellMessage>? messages,
    bool? busy,
    String? error,
    String? conversationId,
  }) =>
      AgentShellState(
        messages: messages ?? this.messages,
        busy: busy ?? this.busy,
        error: error,
        conversationId: conversationId ?? this.conversationId,
      );
  @override
  List<Object?> get props => [messages, busy, error, conversationId];
}
```

- [ ] **Step 7.4: Create bloc**

`lib/features/agent_shell/presentation/bloc/agent_shell_bloc.dart`:
```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/agent/agent_client.dart';
import 'agent_shell_event.dart';
import 'agent_shell_state.dart';

export 'agent_shell_event.dart';
export 'agent_shell_state.dart';

class AgentShellBloc extends Bloc<AgentShellEvent, AgentShellState> {
  final AgentClient client;
  AgentShellBloc({required this.client}) : super(AgentShellState.initial()) {
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
      final result = await client.runAgent(
        goal: event.text,
        conversationId: state.conversationId,
      );
      final agentMsg = AgentShellMessage(
        role: 'agent',
        text: result.finalText.isEmpty ? '(empty response)' : result.finalText,
        ts: DateTime.now(),
      );
      emit(state.copyWith(
        messages: [...state.messages, agentMsg],
        busy: false,
        conversationId: result.conversationId,
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

- [ ] **Step 7.5: Verify test pass**

```bash
flutter test test/features/agent_shell/agent_shell_bloc_test.dart
```

Expected: 2 tests pass.

- [ ] **Step 7.6: Create screen widget**

`lib/features/agent_shell/presentation/screens/agent_shell_home_screen.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../bloc/agent_shell_bloc.dart';
import '../../../../core/agent/agent_client.dart';

class AgentShellHomeScreen extends StatelessWidget {
  const AgentShellHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AgentShellBloc(client: GetIt.I<AgentClient>()),
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
      appBar: AppBar(title: const Text('Taler ID Agent (Phase 0 spike)')),
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

- [ ] **Step 7.7: Analyzer**

```bash
flutter analyze lib/features/agent_shell/
```

Expected: no errors.

- [ ] **Step 7.8: Commit**

```bash
git add lib/features/agent_shell/ test/features/agent_shell/
git commit -m "feat(agent-shell): AgentShellBloc + home screen with tests"
```

---

## Task 8: Flutter — Register `AgentClient` in DI + `/agent-shell` route

**Files:**
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/lib/core/di/service_locator.dart`
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/lib/core/router/app_router.dart`
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/lib/core/router/route_constants.dart` (or equivalent — find via grep)

- [ ] **Step 8.1: Add DI registration**

Open `lib/core/di/service_locator.dart`. Near where `DioClient` is registered (~line 242 per recon), add:

```dart
// === Agent Shell (Phase 0) ===
sl.registerLazySingleton<AgentClient>(
  () => AgentClient(sl<DioClient>().dio),
);
```

Add import at top:
```dart
import '../agent/agent_client.dart';
```

**Note:** Verify `DioClient.dio` accessor name. If different (e.g. `instance`, `client`), use that.

- [ ] **Step 8.2: Find `RouteConstants`**

```bash
grep -rn "class RouteConstants" /Users/dmitry/Downloads/taler_id_mobile/lib/
```

Open the matched file. Add inside the class:
```dart
static const String agentShell = '/agent-shell';
```

- [ ] **Step 8.3: Register route + env-driven `initialLocation`**

Open `lib/core/router/app_router.dart`. Find the GoRouter routes array. Add:
```dart
GoRoute(
  path: RouteConstants.agentShell,
  builder: (_, __) => const AgentShellHomeScreen(),
),
```

Add import at top:
```dart
import '../../features/agent_shell/presentation/screens/agent_shell_home_screen.dart';
```

Then find `initialLocation: RouteConstants.splash` (or similar). Wrap as:
```dart
final initial = const String.fromEnvironment(
  'AGENT_SHELL_AS_HOME',
  defaultValue: 'false',
) == 'true'
    ? RouteConstants.agentShell
    : RouteConstants.splash;

return GoRouter(
  initialLocation: initial,
  // ... rest of existing config
);
```

- [ ] **Step 8.4: Compile check**

```bash
flutter analyze lib/core/
```

Expected: no errors.

- [ ] **Step 8.5: Commit**

```bash
git add lib/core/di/ lib/core/router/
git commit -m "feat(agent-shell): register AgentClient in DI + /agent-shell route"
```

---

## Task 9: Manual UI smoke test on emulator

**Files:** No code changes; manual verification.

- [ ] **Step 9.1: Launch emulator + run**

```bash
flutter emulators --launch Pixel_XL_API_33
# wait ~20 sec
~/Library/Android/sdk/platform-tools/adb devices

cd /Users/dmitry/Downloads/taler_id_mobile
flutter run -d emulator-5554 --flavor dev -t lib/main_dev.dart \
  --dart-define=FLAVOR=dev \
  --dart-define=BASE_URL=https://staging.id.taler.tirol \
  --dart-define=AGENT_SHELL_AS_HOME=true
```

- [ ] **Step 9.2: Login**

`integration_test@taler-test.com` / `IntegrationTest123!`. Should land on agent shell chat screen.

- [ ] **Step 9.3: Type "echo back the word 'pong'"**

Tap send. Expected: user bubble → "Думаю…" → agent bubble with "pong" or "echoed: pong" (2-5 sec).

Check Flutter logs for `POST /agent/run` returning 200.

If 401 — JWT issue. If 500 — read DEV server logs (`ssh dvolkov@89.169.55.217 'pm2 logs taler-id-dev --lines 50 --nostream --err'`).

- [ ] **Step 9.4: Second round-trip**

Type "echo the word 'pang'". Should reply "pang".

- [ ] **Step 9.5: Note observations (latency, friction) for later journal**

No commit yet — observations get added in Task 12.

---

## Task 10: Android — Make Taler ID Dev eligible as home launcher

**Files:**
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/android/app/src/main/AndroidManifest.xml`
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/android/app/build.gradle`

- [ ] **Step 10.1: `build.gradle` manifestPlaceholders**

Find `productFlavors { ... dev { ... } prod { ... } }`. Inside `dev`:
```gradle
manifestPlaceholders = [
    appLauncherCategories: '<category android:name="android.intent.category.HOME" /><category android:name="android.intent.category.DEFAULT" />'
]
```

Inside `prod`:
```gradle
manifestPlaceholders = [
    appLauncherCategories: ''
]
```

If `manifestPlaceholders` already exists in either block, merge entries.

- [ ] **Step 10.2: Update `AndroidManifest.xml`**

Per prior recon, the MAIN/LAUNCHER intent filter is around lines 61-64. Immediately AFTER it, add:
```xml
<intent-filter>
  <action android:name="android.intent.action.MAIN" />
  ${appLauncherCategories}
</intent-filter>
```

- [ ] **Step 10.3: Re-run on emulator**

```bash
flutter run -d emulator-5554 --flavor dev -t lib/main_dev.dart \
  --dart-define=FLAVOR=dev \
  --dart-define=BASE_URL=https://staging.id.taler.tirol \
  --dart-define=AGENT_SHELL_AS_HOME=true
```

Press Home button on the emulator. Expected: Android shows a chooser asking which launcher to use. If Taler ID Dev not in list — inspect merged manifest at `build/app/intermediates/merged_manifests/devDebug/AndroidManifest.xml`.

- [ ] **Step 10.4: Pick Taler ID Dev → "Always"**

Press Home again. Should land on agent shell screen.

- [ ] **Step 10.5: Commit**

```bash
git add android/app/src/main/AndroidManifest.xml android/app/build.gradle
git commit -m "feat(agent-shell): make dev flavor eligible as Android home launcher"
```

---

## Task 11: Voice integration — `agent_task` tool in OpenAI Realtime session

**Files:**
- Create: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/assistant/services/agent_task_handler.dart`
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/lib/features/assistant/presentation/screens/assistant_screen.dart` (touch only lines ~630-639 for tool config and ~1600-1650 for dispatch — per prior recon)
- Modify: `/Users/dmitry/Downloads/taler_id_mobile/lib/core/di/service_locator.dart`
- Create: `/Users/dmitry/Downloads/taler_id_mobile/test/features/assistant/agent_task_handler_test.dart`

Isolate the dispatch logic into a small testable handler. Touch `assistant_screen.dart` (2,800 lines) only in two narrow regions.

- [ ] **Step 11.1: Write failing test**

```dart
// test/features/assistant/agent_task_handler_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taler_id_mobile/core/agent/agent_client.dart';
import 'package:taler_id_mobile/core/agent/models/agent_run_result.dart';
import 'package:taler_id_mobile/features/assistant/services/agent_task_handler.dart';

class _MockAgentClient extends Mock implements AgentClient {}

void main() {
  late _MockAgentClient client;
  late AgentTaskHandler handler;

  setUp(() {
    client = _MockAgentClient();
    handler = AgentTaskHandler(client: client);
  });

  test('passes goal to AgentClient and returns finalText', () async {
    when(() => client.runAgent(
          goal: 'do stuff',
          conversationId: any(named: 'conversationId'),
          model: any(named: 'model'),
        )).thenAnswer((_) async => const AgentRunResult(
          finalText: 'done',
          toolCalls: [],
          aborted: false,
        ));

    final out = await handler.run({'goal': 'do stuff'});
    expect(out, 'done');
  });

  test('returns error string when goal missing or wrong type', () async {
    expect(await handler.run({}), contains('ERROR'));
    expect(await handler.run({'goal': 42}), contains('ERROR'));
  });

  test('returns aborted result with marker', () async {
    when(() => client.runAgent(
          goal: 'oops',
          conversationId: any(named: 'conversationId'),
          model: any(named: 'model'),
        )).thenAnswer((_) async => const AgentRunResult(
          finalText: 'partial',
          toolCalls: [],
          aborted: true,
        ));

    final out = await handler.run({'goal': 'oops'});
    expect(out, contains('aborted'));
    expect(out, contains('partial'));
  });
}
```

- [ ] **Step 11.2: Run failing test**

```bash
flutter test test/features/assistant/agent_task_handler_test.dart
```

Expected: FAIL.

- [ ] **Step 11.3: Implement `AgentTaskHandler`**

`lib/features/assistant/services/agent_task_handler.dart`:
```dart
import '../../../core/agent/agent_client.dart';

class AgentTaskHandler {
  final AgentClient client;
  AgentTaskHandler({required this.client});

  Future<String> run(Map<String, dynamic> input) async {
    final goal = input['goal'];
    if (goal is! String || goal.isEmpty) {
      return 'ERROR: missing required string parameter "goal"';
    }
    final result = await client.runAgent(goal: goal);
    if (result.aborted) {
      return 'aborted after ${result.toolCalls.length} tool calls; partial: ${result.finalText}';
    }
    return result.finalText;
  }
}
```

- [ ] **Step 11.4: Run test — pass**

```bash
flutter test test/features/assistant/agent_task_handler_test.dart
```

Expected: 3 tests pass.

- [ ] **Step 11.5: Register `AgentTaskHandler` in DI**

In `lib/core/di/service_locator.dart`, near AgentClient (from Task 8):
```dart
sl.registerLazySingleton<AgentTaskHandler>(
  () => AgentTaskHandler(client: sl<AgentClient>()),
);
```
Add import at top:
```dart
import '../../features/assistant/services/agent_task_handler.dart';
```

- [ ] **Step 11.6: Add `agent_task` tool to OpenAI Realtime session config**

Open `assistant_screen.dart`. Per recon, the tool config is around lines 630-639 — the `'tools': [...]` array. Append:
```dart
{
  'type': 'function',
  'name': 'agent_task',
  'description':
      'Delegate a complex multi-step task to an internal agent. Use ONLY when the task requires planning, multiple tools, or backend operations beyond the voice-layer tools. Returns the final natural-language result.',
  'parameters': {
    'type': 'object',
    'properties': {
      'goal': {
        'type': 'string',
        'description':
            'Plain-language statement of what the user wants done. Be specific and include constraints.',
      },
    },
    'required': ['goal'],
  },
},
```

- [ ] **Step 11.7: Wire `agent_task` dispatch**

Per recon, the tool dispatch handler is around lines 1600-1650. Find the existing `if (name == 'exit_translator_mode') { ... }` block. Add a sibling `else if`:
```dart
else if (name == 'agent_task') {
  try {
    final args = jsonDecode(argsJson) as Map<String, dynamic>;
    final handler = GetIt.I<AgentTaskHandler>();
    final result = await handler.run(args);
    _sendFunctionCallOutput(callId, result);
  } catch (e) {
    _sendFunctionCallOutput(callId, 'ERROR: agent_task threw: $e');
  }
}
```

**Important:** `_sendFunctionCallOutput` and `callId` are PLACEHOLDER NAMES used as illustration. The actual helper / variable names in `assistant_screen.dart` may differ. **Read the existing dispatch block for `exit_translator_mode` (and any other tools nearby) and use the EXACT names already used by other handlers.** Do not invent new helpers — match the existing pattern verbatim.

Add imports at top of `assistant_screen.dart`:
```dart
import 'package:get_it/get_it.dart';
import '../../services/agent_task_handler.dart';
```

- [ ] **Step 11.8: Voice end-to-end smoke test**

```bash
flutter run -d emulator-5554 --flavor dev -t lib/main_dev.dart \
  --dart-define=FLAVOR=dev \
  --dart-define=BASE_URL=https://staging.id.taler.tirol \
  --dart-define=AGENT_SHELL_AS_HOME=true
```

Grant mic permission. Open the existing Assistant screen (NOT the new agent shell — Realtime lives there). Say:

> "Run the agent task to echo back the word ping."

Expected sequence in logs:
1. OpenAI Realtime → `function_call` for `agent_task` with `goal`
2. `AgentTaskHandler.run` → POST `/agent/run`
3. Backend SDK runs agent loop → calls `echo` tool → finalizes
4. Backend returns `{finalText: "ping" or "echoed: ping"}`
5. Result sent back to Realtime via the `_sendFunctionCallOutput` (or actual) helper
6. Realtime speaks the result aloud

**This is Phase 0's primary exit criterion.** Debug if any step fails.

- [ ] **Step 11.9: Commit**

```bash
git add lib/features/assistant/services/agent_task_handler.dart \
  lib/features/assistant/presentation/screens/assistant_screen.dart \
  lib/core/di/service_locator.dart \
  test/features/assistant/agent_task_handler_test.dart
git commit -m "feat(assistant): add agent_task tool routing to backend Claude Agent SDK"
```

---

## Task 12: Daily-driver switchover + journal

**Files:**
- Create: `/Users/dmitry/Downloads/taler_id_mobile/docs/agent-shell-journal.md`

- [ ] **Step 12.1: Build dev APK on PROD build server**

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

- [ ] **Step 12.2: Install on Pixel**

Browse to the URL, install, allow unknown sources, sign in.

- [ ] **Step 12.3: Set as default launcher**

Press Home → chooser → "Taler ID Dev" → "Always". (Or via Settings → Apps → Default apps → Home app.)

- [ ] **Step 12.4: Verify**

Press Home — should land on agent shell. Type "ping" — should round-trip via backend.

- [ ] **Step 12.5: Create journal**

`/Users/dmitry/Downloads/taler_id_mobile/docs/agent-shell-journal.md`:
```markdown
# Agent Shell — Daily Driver Journal

Pain points, missing capabilities, surprising wins.
Drives Phase 1 prioritization.

## 2026-05-XX (Day 1)

- [ ] Setup done, launcher swapped, first echo round-trip OK
- 

## Friction recurring across days

(Add patterns here as they emerge.)
```

- [ ] **Step 12.6: Commit journal**

```bash
git add docs/agent-shell-journal.md
git commit -m "docs(agent-shell): start daily-driver journal"
```

- [ ] **Step 12.7: Push mobile branch (don't merge yet)**

```bash
git push -u origin feature/agent-shell-phase-0
```

**Do NOT merge to `dev` (mobile) or `main` (backend) until you've used this for at least 5 days and decided it's worth continuing.**

---

## Phase 0 Exit Criteria — Sign-off Checklist

- [ ] `claude` CLI on analyst-box (`dv@5.101.115.184`) works: `claude --print --output-format text -- "ping"` returns expected output
- [ ] SSH from DEV (`dvolkov@89.169.55.217`) → analyst is non-interactive (`BatchMode=yes` succeeds)
- [ ] Backend `POST /agent/run` returns 200 with valid JWT + a sensible `finalText`
- [ ] All unit tests pass: `npm test` (backend), `flutter test` (mobile)
- [ ] Mobile app builds for dev flavor without errors: `flutter build apk --flavor dev --release`
- [ ] Voice end-to-end: spoken request via Assistant → `agent_task` → backend → SSH → claude on analyst → spoken result
- [ ] Direct chat end-to-end on `/agent-shell` screen: typed → backend → reply
- [ ] Default launcher set on Pixel; Home → agent shell
- [ ] Journal initialized with at least 1 day of usage notes
- [ ] PROD untouched (no merge done to main / prod branches)
- [ ] Existing integration tests pass: `cd ~/Downloads/taler_id_tests && npm test`
- [ ] No Anthropic API key anywhere in committed files: `git -C /Users/dmitry/Downloads/taler_id grep -n "ANTHROPIC_API_KEY" -- . ':!node_modules' ':!*.example'` returns nothing
- [ ] No `@anthropic-ai/claude-agent-sdk` in `package.json`: `grep claude-agent-sdk /Users/dmitry/Downloads/taler_id/package.json` returns nothing

When all checked: write Phase 1 plan via `superpowers:writing-plans` with the Phase 1 section of the spec.

---

## Notes for the implementer

- **TDD discipline:** Each task writes the test first, then implementation. Don't skip.
- **One commit per task.** Granular history for bisecting.
- **No Claude SDK in this Phase.** We deliberately do NOT add `@anthropic-ai/claude-agent-sdk` or any Anthropic Node library. The backend just shells out to `claude` CLI on the analyst box via SSH. This mirrors the `taler-monitor` pattern Дмитрий already uses.
- **Exact `claude` invocation** — Task 2 Step 2.2 establishes the real CLI flags. Task 3 production code (`buildSshCommand`) must use the exact same flags. If `--print --output-format text` doesn't exist in the installed claude version, Task 2 will surface that and Task 3 must adapt.
- **Shell escaping is security-critical.** The `buildSshCommand` method must NOT allow goal text to break out of either the inner double-quoted claude argument or the outer single-quoted SSH command string. The test in Step 3.2 includes a single-quote injection check; if you add more sanitization, add more tests.
- **`assistant_screen.dart` is 2,800 lines.** Task 11 touches it minimally — read existing tool registration + dispatch patterns FIRST, match them. Don't invent helpers.
- **Existing infrastructure (Realtime WebRTC, voice billing, transcripts) — don't touch.** Only one new tool + dispatch arm. Everything else reuse.
- **Don't expand scope.** No custom tools, no MCP servers, no system tools in Phase 0. Phase 1 adds those.

---

## What changed across the 2026-05-19 pivots

Three revisions of Phase 0 happened on the same day as Дмитрий refined the architecture:

**v1 (initial):** API-key auth, Dart `AnthropicClient` + 400-line Agent Loop on phone, `/agent/claude` raw Messages proxy.

**v2 (morning):** OAuth via Claude Code SDK on DEV backend, `@anthropic-ai/claude-agent-sdk` library in NestJS, `/agent/run` endpoint. Drops Dart agent loop entirely.

**v3 (afternoon, current):** OAuth lives on analyst-box `dv@5.101.115.184` (not DEV — that's where `taler-monitor`'s `claude login` is). Backend spawns SSH-subprocess to analyst. **Drops the SDK as well** — just uses claude CLI via shell. ~30 lines of subprocess code instead of ~100 lines of SDK integration.

Net result vs original v1: Phase 0 is ~50% smaller, no npm deps added, matches existing taler-monitor pattern exactly. Trade-off: custom tools (echo, system, etc.) deferred to Phase 1 as MCP servers on the analyst box. Phase 0 only validates the end-to-end voice → backend → SSH → claude → text → spoken loop.
