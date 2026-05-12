# Changelog

All notable changes to this project will be documented in this file.
Format: `vMAJOR.MINOR.PATCH.MICRO — YYYY-MM-DD — summary`

---

## v1.16.0.19 — 2026-05-12 — nightly refinement run — 22 guides extended (cycle 16/100)

### qa-refine (5 guides, +3,252 lines)
- playwright-patterns.md: +312 lines — click({steps}), connectOverCDP({isLocal}), locator.describe() patterns, 3 new gotchas
- k6-patterns.md: +727 lines — ramping-arrival-rate, SLO thresholds, TypeScript native, Grafana dashboards, regression detection
- cypress-patterns.md: +783 lines — @cypress/grep filtering, addQuery typed retry, CT providers, OAuth/MFA auth patterns
- detox-patterns.md: +877 lines — TypeScript-first scaffold, native module mocking strategies, performance optimization, screenshot-on-failure
- appium-wdio-patterns.md: +553 lines — .appiumrc.json reference, Sauce Labs CI integration, cross-platform selector table, multi-gesture

### qa-methodology-refine (12 guides, +5,518 lines)
- test-pyramid-guide.md: +685 lines — Vitest 5.0 migration, property-based integration testing, AI agent governance, module augmentation
- tdd-guide.md: +622 lines — streaming APIs (ReadableStream/SSE), edge/serverless TDD, OpenTelemetry instrumented code
- bdd-guide.md: +550 lines — MSW step-level mocking, vitest-cucumber, Rule keyword + Example Mapping walkthrough
- test-isolation-guide.md: +486 lines — Testcontainers PostgreSQL, MSW v2 isolation, Jest projects monorepo, EventEmitter leak detection
- test-data-guide.md: +467 lines — data-driven test.each/test.for, MSW WebSocketHandler.test(), community gotchas
- contract-testing-guide.md: +487 lines — multi-interaction executeTest, dateTime matchers, lean checklist, Bun runtime compat
- flakiness-guide.md: +503 lines — EventEmitter leak detection, jest.doMock() vs jest.mock(), unhandledRejection guard
- coverage-guide.md: +606 lines — ts-jest advanced config, nyc→Istanbul 2.x migration, Turborepo/Nx coverage merging
- ci-cd-testing-guide.md: +421 lines — timing-based test splitting, deployment gate patterns, GitHub Actions cache strategies
- accessibility-guide.md: +280 lines — Playwright a11y assertions, ARIA tabs/combobox patterns, testInfo.attach() CI
- shift-left-guide.md: +391 lines — local test speed optimization, IDE integration, ROI quantification template
- exploratory-guide.md: +476 lines — page.clock() oracles, Stagehand/browser-use, SBTM debrief anti-patterns

### lang-refine (5 guides, +2,990 lines)
- typescript-patterns.md: +650 lines — jest-mock-extended, branded types, satisfies operator, strict mode impact
- javascript-patterns.md: +599 lines — ESM module mocking, Vitest vs Jest decision guide, spy patterns, prototype mocking
- java-patterns.md: +550 lines — ArchUnit architecture testing, Mockito thenAnswer/Answer, JUnit 5 Extensions SPI
- python-patterns.md: +719 lines — conftest.py hierarchy, fixture factories, FastAPI TestClient, pytest-bdd
- csharp-patterns.md: +472 lines — xUnit ClassData/MemberData, Moq Protected/MockRepository, FluentAssertions extensions, Bogus/NSubstitute

**Total: ~12,216 lines added across 22 guides**

---

## v1.16.0.18 — 2026-05-12 — nightly refinement run — 22 guides extended (cycle 15/100)

### qa-refine (5 guides, 97-100/100)
- `playwright-patterns.md` — `connectOverCDP({ noDefaults: true })` (v1.60+) preserves colorScheme/reducedMotion/contrast; G49 default context media settings reset; ARIA snapshot `/children` matching modes (`contain`/`equal`/`deep-equal`) with global config (+133 lines, 100/100, iter 36)
- `cypress-patterns.md` — `--pass-with-no-tests` CLI flag (15.11+); React SSR `data-cy-bootstrap` hydration fix (15.11+); G123 `cy.prompt()` no offline fallback; G124 TS6 `const enum` in shared packages breaks `tsx` config parsing (+195 lines, 97/100, iter 44)
- `k6-patterns.md` — xk6-kafka v2 load testing (constant-arrival-rate producer, SASL-PLAIN, ~383k msgs/sec baseline); xk6-mqtt MQTT broker testing (QoS, round-trip Trend, TLS); G62 `k6/experimental/fs` shared file cursor silent EOF (+338 lines, 100/100, iter 35)
- `detox-patterns.md` — P62 `detox-copilot` AI natural-language test steps (Detox 20.50+, `AnthropicPromptHandler`); G97 Android 16 edge-to-edge breaks `scrollTo('bottom')` with soft keyboard; G98 iOS 26 home indicator swipe-up gesture preemption in safe area (+247 lines, 99/100, iter 54)
- `appium-wdio-patterns.md` — UIAutomator2 v7.0.0 `mobile:listApps` breaking format (string[]→Record); UIAutomator2 v7.1.0 `mobile:setStylusHandwriting`; XCUITest v11.3.0 `download-wda` CLI bypasses 4-min WDA build; WDIO v9.27.1 BiDi `networkGetData` response body capture (+260 lines, 100/100, iter 35)

### qa-methodology-refine (12 guides, all 97-100/100)
- `test-pyramid-guide.md` — Vitest 5.0 beta.1 `createReport` API + `getAriaTree`/`matchAriaTree`; Bun 1.2 `--rerun-each` + `bunfig.toml` pyramid config; G51 Bun `mock.module()` declaration-order vs Vitest hoisting; G52 `test.failing.each` permanent quarantine debt (+293 lines, 98/100, iter 46)
- `tdd-guide.md` — Stryker VS Code extension inline mutation feedback (MSP, 5–15s per file); Stryker `--incremental` 120s→8s per-PR; Vitest 5.0 TDD breaking changes (`.vitest/` dir, `sequential` removal, G50); LLM as Red-phase collaborator (prompt template, 70–80% mutation score improvement) (+432 lines, 97/100, iter 27)
- `bdd-guide.md` — TS 5.5+ `noUncheckedIndexedAccess`/`isolatedDeclarations` BDD step definition impacts; AI-generated Gherkin quality evaluation checklist + `bdd-quality-check.ts` CLI (7-criterion, 0-100 score); Cucumber.js `externalise: true` v12.8.0 step inventory extraction (+428 lines, 100/100, iter 36)
- `test-isolation-guide.md` — P42 Node.js 24 `AsyncLocalStorage` `defaultValue` null-safe context stores; P43 Vitest `aroundEach`+`AsyncLocalStorage.run()` scoped context propagation; G103 Node.js 24 subtest completion teardown ordering; G104 `--test-global-setup` same-process singleton sharing (+306 lines, 100/100, iter 25)
- `test-data-guide.md` — MSW v2.13.5 generator state auto-reset on `resetHandlers()`; faker v10.4 food module (`dish`/`ethnicCategory`) + Finnish locale; Playwright 1.60 `browser.on('context')` seed injection observer; MSW v2.14.2 typed `SetupServerApi`/`NetworkApi` container; G34 generator handler position leaks across tests (+588 lines, 100/100, iter 46)
- `contract-testing-guide.md` — `filterConsumerNames`/`filterProviderStates` formal VerifierV3 scoping with CI sharding; Apollo Federation GraphQL supergraph `_entities` contract testing; lessons #66-67 (+305 lines, 100/100, iter 31)
- `coverage-guide.md` — G58 Jest 30.4 multi-project `collectCoverageFrom` accuracy fix (PR #16140); G59 `coverage.changed`+`thresholds.perFile` untested-new-file gap + audit script; P33 `coverage.reporter` default array CI overhead; G60 Jest 30.4 upgrade silent coverage debt (+338 lines, 100/100, iter 45)
- `ci-cd-testing-guide.md` — Stryker.js mutation testing as CI gate (incremental, GitHub Actions YAML, TypeScript mutation-gate helper); `workflow_run` cross-workflow fork PR gate pattern; TypeScript 6 strict-by-default CI impact audit; AI test quality gate mutation score enforcement (+510 lines, 100/100, iter 38)
- `accessibility-guide.md` — `@axe-core/mcp` Claude Desktop config + TypeScript `scanUrlForA11yViolations()` via Anthropic SDK; G89 WCAG 3.0 March 2026 terminology pivot; G90 axe-core 4.11.3 `position:fixed` exclusion logic change; G91 EU EAA sector-phased enforcement with microenterprise exemption (+97 lines, 98/100, iter 45)
- `shift-left-guide.md` — `@zod/mini` tree-shakable Zod for edge functions + esbuild bundle size gate; Zod v4 `z.globalRegistry` schema metadata registry + CI completeness gate; GitHub Copilot PR Review GA 2025 with `.github/copilot-instructions.md`; Biome v2 CSS+GraphQL coverage + `noRedundantCssDeclarations` (+480 lines, 100/100, iter 35)
- `flakiness-guide.md` — P100 Playwright `testResult.annotations` per-retry root-cause in custom reporters (v1.52+); P101 Vitest 3.2 `context.annotate()` structured metadata across reporters; G49 `dorny/test-reporter@v1` inline PR flakiness annotations; AP49 `getSeed()` returns `undefined` inside test bodies (+419 lines, 100/100, iter 59)
- `exploratory-guide.md` — Playwright `init-agents` seed.spec.ts workflow + charter-scoped preconditions; `browser.on('context')` multi-context lifecycle v1.60 + `MultiContextLifecycleHarness`; `browserContext.setStorageState()` mid-session auth rotation v1.59; `locator.normalize()` WCAG 4.1.2 oracle v1.59; lessons #135-137 (+364 lines, 100/100, iter 49)

### lang-refine (5 guides updated)
- `typescript-patterns.md` — Type-level testing `expectTypeOf`/`assertType` (Vitest built-in + `tsd`/`expect-type` alternatives); TS 6.0 Temporal API patterns (core types, immutable arithmetic, timezone-safe comparison); constrained `infer` with `extends` bounds (TS 4.7+); `satisfies`+`as const` nested discriminated union config pattern (+393 lines, iter 40)
- `javascript-patterns.md` — `node:test` `t.assert.snapshot()` stable (Node.js 24); `fetch()` priority hints (`high`/`low`/`auto`) + `keepalive` beacon replacement; `structuredClone` with Transferables (zero-copy ArrayBuffer); Temporal API in testing — dependency injection + monkey-patching patterns (+315 lines, iter 55)
- `java-patterns.md` — Mockito 5.19 `ReturnsEmptyValues` for SequencedCollection/Set/Map; AssertJ 4.0.0-M1 Java 17+ baseline + native `isSealed()`/`isRecord()`; Spring Boot 4.0.6 POM fix + `@Ssl @ServiceConnection` on `@Bean` methods; Spring Boot 4.1 RC1 `@GrpcAdvice` + OpenTelemetry SDK auto-config (+201 lines, 99/100, iter 36)
- `python-patterns.md` — Python 3.15 `lazy import` keyword (PEP 810, `sys.set_lazy_imports()`); `frozendict` (PEP 814) + `sentinel` (PEP 661) immutable test fixtures; `threading.synchronized_iterator()`/`concurrent_tee()` thread-safe iteration; `asyncio.TaskGroup.cancel()` structured early-exit; G59-60 (+365 lines, 100/100, iter 52)
- `csharp-patterns.md` — .NET 10 MTP native support via `global.json` `"runner"` key; xUnit v3 `TestContext` static diagnostic API (`SendDiagnosticMessage`, `CancellationToken`); TUnit `[Timeout]` + `[Retry]` per-test cancellation; C# 14 `extension` blocks as test builder helpers with `field` keyword (+246 lines, iter 40)

---

## v1.16.0.17 — 2026-05-12 — nightly refinement run — 22 guides extended (cycle 14/100)

### qa-refine (5 guides, 97-100/100)
- `playwright-patterns.md` — `--fail-on-flaky-tests` CLI flag (v1.45+) added to CLI Flags table with `STRICT_FLAKE_MODE` env var gate; `page.clock.runFor()`/`page.clock.tick()` typed TypeScript examples added to Clock section; G48 `fastForward()` vs `runFor()`/`tick()` behavioral difference (intermediate callback skipping) (+51 lines, 100/100, iter 35)
- `cypress-patterns.md` — Pattern 132: `Cypress.require()` in `cy.origin()` callbacks (SSO login, custom commands, `experimentalOriginDependencies: true`); Pattern 133: `experimentalCspAllowList` (3 config modes, directive table, hash-based `script-src` runner breakage); Pattern 134: `detect-flake-but-always-fail` retry strategy + `stopIfAnyPassed` comparison table; G120-122 (+244 lines, 97/100, iter 43)
- `k6-patterns.md` — `file` secret source key=value plaintext format + Docker volume-mount pattern; `url` secret source 9-option table (`urlTemplate`/`method`/`headers`/`responsePath`/`timeout`/rate-limit options) with 4 provider examples (Vault KV v2, AWS Secrets Manager, multi-source); G61 URL-encoded slash in Vault paths returns 404 (+192 lines, 100/100, iter 34)
- `detox-patterns.md` — P61 `idleAwareWaitFor` custom condition loop; G94 `resetAppState()` + runtime permissions silently broken on Android (separate `revokePermissions()` call required); G95 DEP0190 Node.js path.join deprecation in configs; G96 no public `appStatus()` API (+226 lines, 99/100, iter 53)
- `appium-wdio-patterns.md` — `appium:chromedriverForwardBiDi` (UIAutomator2 v7+ BiDi WebSocket in Android WebView); `currentDisplayId` settings API (foldable device display targeting); Appium 3.1 Device Posture WebDriver endpoints; XCUITest v11 `appium:appTimeZone`/`simulatorLogLevel`/`appLaunchStateTimeoutSec` capabilities (+359 lines, 100/100, iter 34)

### qa-methodology-refine (12 guides, all 97-100/100)
- `test-pyramid-guide.md` — `@fast-check/vitest` `test.prop()` API (named Vitest test cases, TypeScript typing); RTL v16 + React 19 auto-`act()` deprecation + `onCaughtError`; G50 fast-check v4.x ESM-only `ERR_REQUIRE_ESM` (+300 lines, 98/100, iter 45)
- `tdd-guide.md` — Vitest 4.1 `test.extend()` builder chaining (auto-inferred fixture types); `context.annotate()` (structured diagnostics, JUnit XML/HTML integration); `sequence.groupOrder` multi-project ordered CI pipeline; G48-49 (+294 lines, 97/100, iter 26)
- `bdd-guide.md` — `TestStepInfo.titlePath` (v1.55+) collision-free artifact filenames; Playwright Test Agents `npx playwright init-agents` (v1.56+, planner/generator/healer loop); `page.pickLocator()` (v1.59+) locator strategy selector (+171 lines, 100/100, iter 35)
- `test-isolation-guide.md` — Pattern 40: Vitest `test.signal` AbortSignal cancellation; Pattern 41: `page.clearConsoleMessages()`/`clearPageErrors()` (v1.59+) multi-phase isolation; G101-102 (+251 lines, 100/100, iter 24)
- `test-data-guide.md` — Vitest 3.2 `scope: 'file'` fixture; `test.signal` AbortSignal for factory teardown; `using vi.spyOn()` auto-restoration; Vitest 4.1 `mockThrow()`/`mockThrowOnce()`; Chai-style mock assertions (`calledBefore`/`calledAfter`) (+442 lines, 100/100, iter 45)
- `contract-testing-guide.md` — pact-js v16.3.0 DELETE body regression in jsdom; PactFlow AI Test Templates; lessons #64-65 (+104 lines, 100/100, iter 30)
- `coverage-guide.md` — G56 `coverage.skipFull`; G57 `aroundEach`/`aroundAll` rollback paths undetected by V8 branch coverage (+149 lines, 100/100, iter 44)
- `ci-cd-testing-guide.md` — TS 5.9 `import defer` lazy module init (8s→2s CI cold-start, `module: preserve`); `noUncheckedSideEffectImports` CI hygiene gate; G65-66 (+160 lines, 100/100, iter 37)
- `accessibility-guide.md` — `testInfoError.errorContext` (Playwright 1.60) aria snapshot in failure output; `cypress-axe v1.7.0` Cypress 15 support + `retries`/`interval` options; G86-88 (+194 lines, 98/100, iter 44)
- `shift-left-guide.md` — Playwright `toMatchAriaSnapshot()` (v1.49) YAML-based a11y shift-left; `--only-changed` (v1.46) PR fast-feedback GitHub Actions; Vitest pool types `forks`/`threads`/`vmThreads`; ESLint v9 flat config migration (+261 lines, 100/100, iter 34)
- `flakiness-guide.md` — P97 `page.clock` deterministic time control; P98 `page.addLocatorHandler()` overlay dismiss; P99 Vitest 4.0 `getSeed()`; AP48 (+461 lines, 100/100, iter 58)
- `exploratory-guide.md` — `test.step()` timeout phase inheritance; `toHaveAccessibleErrorMessage()` live region oracle; `locator.filter({ visible: true })`; `partitionKey` cookie isolation; `page.consoleMessages()`/`pageErrors()`/`requests()` async diagnostic APIs; lessons #132-134 (+534 lines, 100/100, iter 48)

### lang-refine (3 guides updated)
- `java-testing-guide.md` — Spring Boot 4.0 `@MockBean`→`@MockitoBean` migration + `RestTestClient`; JUnit 6.1 `assertInstanceOf` cause attachment, stack trace pruning, `@TempDir(cleanup=CleanupMode)`, `WorkerThreadPoolHierarchicalTestExecutorService`; JUnit 6.0.3 deadlock fix; G49-50 (+447 lines, 99/100, iter 35)
- `python-testing-guide.md` — Python 3.15 `TypeForm`/`TypedDict(closed=True)`/`re.prefixmatch()`; pytest 9.0 breaking changes; G57-58 (+341 lines, iter 51)
- `typescript-testing-guide.md` — TS 5.5 JSDoc `@import` tag; TS 5.7 composite project ownership; `Object.groupBy()` `Partial<Record>` gotcha (+135 lines, iter 39)

### Other guides
- `javascript-testing-guide.md` — ESLint 9 flat config migration; G76-78 (+148 lines, iter 54)

---

## v1.16.0.16 — 2026-05-12 — nightly refinement run — 22 guides extended (cycle 13/100)

### qa-refine (5 guides, 97-100/100)
- `playwright-patterns.md` — `page.on('weberror')` covers both uncaught exceptions AND unhandled rejections (v1.60+, distinct from `pageerror`); `webError.location()` returns `{url, lineNumber, columnNumber}`; `globalTimeout` (1hr CI hard stop) and `reportSlowTests` added to baseline config (+4 lines, 100/100, iter 34)
- `cypress-patterns.md` — Fixed stale `result.code` → `result.exitCode` (Cypress 15 breaking change); G117 Chrome autofill popup intercepts `.type()` on address/payment fields (fixed 15.6.0); G118 `cy.wait(['@alias1', '@alias2'])` + page navigation deadlock (fixed 15.12.0); G119 `cy.intercept()` delay ≥ 2³¹ silently discarded via V8 integer overflow (fixed 15.13.1); Pattern 131 safe multi-intercept patterns (+91 lines, 97/100)
- `k6-patterns.md` — `locator.locator()` hierarchical scoping pattern (v1.3+ fundamental API for container-scoped searches on tables/lists/cards); fixed `k6chaijs` version 4.3.4.3→4.5.0.1; fixed `K6_CLOUD_STACK` → `K6_CLOUD_STACK_ID` env var (silent failure); G60 stale `~/.config/k6/credentials.json` from `cloud login` on shared CI agents (+112 lines, 100/100, iter 33)
- `detox-patterns.md` — G89: ADB command failure when device serial contains `()` from mDNS/Wi-Fi (shell subshell interpretation, pin adbName workaround); G90: iOS DetoxSync `null` description log spam causing `waitFor` timeout confusion; G91: Android WebView LavaMoat injection silently broken before PR #4943 (merged May 2026, `ignoreUnexpectedMessages: 'warn'` interim fix); G92: `withAncestor()` returns null on Fabric/New Architecture (unique testID workaround); G93: `toHaveText()` has no RegExp overload (`getAttributes()` + `jestExpect` pattern) (+203 lines, 99/100, iter 52)
- `appium-wdio-patterns.md` — `mobile:startXCTestScreenRecording`/`stop`/`info` (Xcode 15+/iOS 17+ native XCTest recording, ghost-recording detection, real-device `xctest_screen_record` security flag, 3 gotchas); `appium:adbListenAllNetwork` UIAutomator2 v6.7.0 for distributed CI (Appium and ADB on separate hosts, `allowInsecure` requirement, 3 gotchas including 0.0.0.0 security exposure) (+138 lines, 100/100, iter 33)

### qa-methodology-refine (12 guides, all 97-100/100)
- `test-pyramid-guide.md` — G49: TS 5.9 new `tsc --init` defaults that break test code: `noUncheckedIndexedAccess` (`results[0]` → `T | undefined`), `exactOptionalPropertyTypes` (factory objects setting optional → `undefined`), `noUncheckedSideEffectImports` (bare `import './setup'` breaks NestJS/Vitest setups); Bun 1.3.x additions: `--randomize`/`--seed` for order-dependency detection, `test.concurrent`/`test.serial` per-pyramid-level concurrency, AI agent mode env vars (`CLAUDECODE=1`/`REPL_ID=1`/`AGENT=1`) (+154 lines, 100/100, iter 44)
- `tdd-guide.md` — TS 6.0 Temporal API clock injection: `Clock` interface + `FakeClock` with built-in `Temporal` types, `SubscriptionService` TDD walkthrough, `vi.spyOn(Temporal.Now)` anti-pattern; Vitest 3.2 `ctx.signal` per-test AbortSignal for cancellation TDD (async iterator stream cancellation, `AbortController` comparison); G46 `ts5to6` codemod doesn't update `"types"` arrays; G47 `ctx.signal` fires on timeout only, not normal completion (+261 lines, 97/100, iter 25)
- `bdd-guide.md` — `page.screencast()` step-level action annotations: `Before`/`BeforeStep`/`After` hooks with `annotate()` per BDD keyword, conditional failure attachment (60-80% triage time reduction); `toHaveCSS({ pseudo: '::after'/'::before' })` typed BDD step definitions for pseudo-element UI patterns (required-field asterisk, nav accent, error border) (+167 lines, 100/100, iter 34)
- `test-isolation-guide.md` — Pattern 38: `page.routeWebSocket()`/`browserContext.routeWebSocket()` (v1.48) WebSocket connection isolation without real server; Pattern 39: `mergeTests()`/`mergeExpects()` compositional fixture isolation; G97 worker-scope `page` route handler accumulation; G98 `mergeTests()` name collision silent last-wins; G99 `test.abort()` vs `test.fail()` distinction (fail-fast invariant vs expected failure inversion); G100 `tracing.startHar()` disposable requires `await using` or `finally` (+308 lines, 100/100, iter 23)
- `test-data-guide.md` — Playwright 1.57 `testConfig.webServer.wait` regex named capture groups for dynamic port injection into test fixtures; Playwright 1.60 `locator.drop()` file-drop/clipboard data factory with `dropFile` fixture; Playwright 1.60 `webSocketRoute.protocols()` subprotocol-aware WS mock factories; G32 `locator.drop()` silent empty `file.type` without `mimeType` (type-gated dropzone rejection) (+350 lines, 100/100, iter 44)
- `contract-testing-guide.md` — pact-js v16.0.2 state handler error surfacing (exceptions now logged at ERROR level with stack trace instead of silent HTTP 500, PR #1585); v16.0.4 mixed HTTP + async message provider verification fix (single `verifyProvider()` call now works, PR #1634); Community lessons #62 (pre-16.0.2 hides exceptions) and #63 (pre-16.0.4 silently skips async message pacts with "0 interactions") (+185 lines, 100/100, iter 29)
- `coverage-guide.md` — G54: Jest 30.3+ `defineConfig`/`mergeConfig` type-safe config helpers + `.mts`/`.cts` config file support (deep merge vs spread behavior); G55: Jest 30.4+ `global` threshold key now applies only to files unmatched by named patterns (behavioral change, comparison table vs Vitest) + Babel coverage now instruments `.mts`/`.cts` (+177 lines, 100/100, iter 43)
- `ci-cd-testing-guide.md` — TS 5.9 features: `--module node20` frozen Node 20 semantics, 11% type-check speedup for Zod/Prisma codebases, `types:[]` default in `tsc --init`; Playwright `browserContext.setStorageState()` auth swap fixture (50ms vs 3-5s, `{}`  is no-op gotcha); Vitest 4.1 tag shared config options (`timeout`/`retry`/`concurrent` per tag, `@db`/`@slow`/`@flaky` CI YAML); pillars 58-60, gotchas #61-64 (+430 lines, 100/100, iter 36)
- `accessibility-guide.md` — Jest v30 + jest-axe v10.0.0 incompatibility (issue #293, `jest-matcher-utils` version mismatch, `overrides` workaround, TypeScript smoke test); Playwright v1.53 `locator.describe(label)` Trace Viewer annotation for accessibility locators; G84 jest-axe/Jest 30 runtime failure diagnostic; G85 `locator.describe()` naming confusion with `aria-describedby` (+189 lines, 98/100, iter 43)
- `shift-left-guide.md` — Playwright v1.44+ native accessibility assertions (`toHaveAccessibleName()`/`toHaveAccessibleDescription()`/`toHaveRole()`) as first-class shift-left ARIA contract matchers vs axe-core injection (3-5× faster setup); `testConfig.tsconfig` pin (v1.45+) for consistent strict-mode type checking; TypeScript version mismatch gotcha with Playwright's bundled esbuild (+100 lines, 100/100, iter 33)
- `flakiness-guide.md` — Pattern 94: `page.routeWebSocket()` (v1.48) deterministic WS mocking (no real server, no port binding, no lifecycle races); Pattern 95: `storageState({ indexedDB: true })` (v1.51) eliminates 40-60% of Firebase/Supabase auth failures (with `waitForFunction` guard); Pattern 96: `jest.onGenerateMock()` centralized auto-mock configuration; AP47 `onGenerateMock` + `__mocks__/` silent no-op; G48 `WebSocketRoute.onMessage()` drops forwarding silently (+513 lines, 100/100, iter 57)
- `exploratory-guide.md` — `page.routeWebSocket()`/`WebSocketRoute` `WebSocketRouteHarness` (mock + intercept + frame injection modes, comparison vs native WS harness); `page.requestGC()` + `WeakRef` memory leak oracle (double-GC pattern, component/DOM leak detection); `storageState({ indexedDB: true })` multi-role auth exploration + security probes; `toContainClass()` `CssStateOracleHarness`; `failOnFlakyTests` harness reliability guard; community lessons #129-131 (+679 lines, 100/100, iter 47)

### lang-refine (5 guides, all 97-100/100)
- `typescript-patterns.md` — TS 5.8: computed property names preserved in `.d.ts` (no longer collapsed to index signatures; `isolatedDeclarations` still errors; TS ≤5.7 consumer break); TS 5.6: `--build` continue-on-error default + `--stopOnBuildErrors` opt-out; region-prioritized diagnostics (143ms vs 3,330ms); `autoImportSpecifierExcludeRegexes` (does NOT enforce imports — needs ESLint alongside); 3 anti-pattern rows (+147 lines, 97/100, iter 38)
- `javascript-patterns.md` — `node:sqlite` built-in: `DatabaseSync`/`StatementSync`/`SQLTagStore` tagged-template API (Node.js 24.9+), sync-only design decision table, 3 gotchas (event loop blocking, integer overflow without `readBigInts`, BigInt requirement); native TypeScript type stripping: supported/unsupported comparison, tooling table (`node --strip-types` vs `tsx` vs `ts-node` vs `tsc`); G72-75 (+209 lines, 100/100, iter 53)
- `java-patterns.md` — JUnit 5.14 migration bridge (Sept 2025): `ResourceSupport`, `OutputDirectoryCreator`, `MediaType`/`ParameterInfo` package moves, `@EnabledOnJre` JRE.OTHER fix (5.14.3), `@ResourceLock` on `@ParameterizedClass` fix (5.14.2); Mockito 5.20 generic type construction mocking with `context.getGenericTypeArguments()`; Mockito 5.21 `ReturnsEmptyValues` returns `CompletableFuture.completedFuture(null)` for unstubbed async; Spring Boot 3.5 `spring.test.print-condition-evaluation-report` (300-500 line CI noise elimination) (+208 lines, 99/100, iter 34)
- `python-patterns.md` — `syrupy` (file-based snapshots, custom serializers, partial matching with `Is()`) + `inline-snapshot` (in-place inline testing); `pytest-benchmark` micro-benchmarks (`benchmark.pedantic()`, `compare-fail` CI regression detection, warmup gotcha); `mutmut` mutation testing (≥70% score target, `pragma: no mutate`, equivalent mutation triage); `pytest-timeout` + `pytest-randomly` (signal vs thread, seed pinning); G53-56 (syrupy overwrites all baselines, benchmark cold-start warmup, equivalent mutants, pytest-asyncio event_loop deprecated ≥0.23) (+545 lines, 100/100, iter 50)
- `csharp-patterns.md` — Testcontainers.NET: `MsSqlContainer`/`PostgreSqlContainer` with `IAsyncLifetime` + Respawn data reset, container reuse via `IClassFixture`, 30+ module ecosystem; HttpClient mocking: `RichardSzalay.MockHttp` (`When/Respond`, `VerifyNoOutstandingExpectation`) vs `WireMock.Net` (loopback, `InScenario` stateful retry); xUnit `ITestOutputHelper` with `ILogger<T>` routing; NetArchTest architecture enforcement (layering, namespace residency, naming conventions); 4 gotchas (Docker socket CI, MockHttp BaseAddress mismatch, WireMock port collision, NetArchTest startup cost); 6 anti-pattern rows (+580 lines, 98/100, iter 38)

---



### qa-refine (5 guides, 97-100/100)
- `playwright-patterns.md` — no new additions; guide already fully current through v1.61 at 100/100 (8,845 lines, 0 lines added)
- `cypress-patterns.md` — no new additions; guide already fully current through 15.14.2 at 97/100 (0 lines added)
- `k6-patterns.md` — no new additions; guide already fully current through v2.0.0 at 100/100 (9,611 lines, 59 gotchas, 0 lines added)
- `detox-patterns.md` — Gotcha 85: iOS 26+ biometric flags deprecated (`--matchFace`/`--matchFinger` removed by Apple from applesimutils; Detox 20.51 switches to `--biometricMatch`/`--biometricNonmatch` silently); Gotcha 86: Android `<Modal>` silent tap failure (renders in separate Window, Espresso taps discarded, `toBeVisible()` passes but `tap()` no-ops — no upstream fix in 20.51.1); Pattern 60: 4 Android Modal workarounds; Gotcha 87: RN 0.85 requires Detox 20.51+ (Metro WS handshake change causes launchApp hang); Gotcha 88: `atIndex(N).getAttributes()` iOS bug fixed in 20.51 (atIndex was silently ignored pre-20.51) (+256 lines, 99/100)
- `appium-wdio-patterns.md` — XCUITest v11 migration corrections: `appium:waitForQuiescence` and `appium:simpleIsVisibleCheck` were removed in v11.0.0 (prominent no-op callout added); `appium:ignoredWebviewBundleIds` filter system WebViews from getContexts(); `appium:iosSyslogFile` CI syslog artifact pattern; `snapshotMaxChildren`/`enforceCustomSnapshots` large list tuning; `pageLoadStrategy` Safari/WebView SPA modes; `sendKeyStrategy` React-controlled WebView inputs; `placeholderValue` iOS 18+ XML attribute; `mobile:pressButton` tvOS D-pad extensions (v10.25); Appium 3.4 `getGlobalPrivacyControl`/`setGlobalPrivacyControl` W3C GPC endpoints (+477 lines, 100/100)

### qa-methodology-refine (12 guides, all 97-100/100)
- `test-pyramid-guide.md` — Bun 1.3.x test runner: `--parallel`/`--shard`/`--only-failures`, `Symbol.dispose` for automatic mock cleanup (`using` keyword parity with Vitest 3.2), critical gotcha: `mock.module()` is NOT hoisted in Bun unlike Vitest's `vi.mock()`; MSW v2.14+ WebSocket: `ws.onUpgrade` auth/protocol interception, `finalize` API (resolves Vitest 4.1 `--detect-async-leaks` false positives), `NetworkApi` TypeScript type export; Pact-JS v16.x: `PactV4`/`MatchersV3` → `Pact`/`Matchers` export rename, GraphQL `withGraphQLRequest`, v16.4 external interaction references, Gotcha #48 DSL version mixing (+299 lines, 100/100)
- `tdd-guide.md` — Vitest 3.2 unified `Matchers<T>` type replaces per-context `Assertion<R>` pattern; native `using vi.spyOn()` Disposable support (no wrapper needed in Vitest 3.2+); scoped fixtures pattern (`scope: 'file'`/`scope: 'worker'`) with comparison table; Gotchas #43-45: old Assertion<R> migration silent break, worker-scoped fixture ordering dependence, double-restoration with `using` + `afterEach(vi.restoreAllMocks)` (+146 lines, 97/100)
- `bdd-guide.md` — `await using` disposable pattern (Playwright v1.59, TypeScript 5.2+) for automatic resource cleanup in BDD hooks/fixtures; `page.ariaSnapshot()` on full pages for landmark/structure assertions; `--debug=cli` interactive debugger for headless/CI step development; HAR recording via `tracing.startHar()`/`tracing.stopHar()` per BDD scenario; `locator.drop()` for drag-and-drop scenarios (vs `setInputFiles()`); `getByRole()` with `description` option for identical-name disambiguation; Quick Reference Card updated with 6 new v1.59-v1.60 entries (+375 lines, 99/100)
- `test-isolation-guide.md` — `node:test` `TestContext.mock` auto-restoration (built-in equivalent of `restoreMocks: true`, zero-dependency); `node:test` `mock.module()` ESM module isolation stable in Node.js 24 (file-scoped not test-scoped); Node.js 24 `AsyncLocalStorage` `AsyncContextFrame` default: deterministic context propagation across `setImmediate`/`process.nextTick`; Playwright v1.59 `browserContext.setStorageState()` in-test user switching (~5ms vs ~200ms context recreation); Playwright v1.51 `storageState({ indexedDB: true })` for Firebase/Supabase auth (+390 lines, 100/100)
- `test-data-guide.md` — MSW `defineNetwork()` RFC #2488: unified network mock API separating sources from handler resolution (v2.14.x experimental); Playwright 1.53 `locator.describe()` factory locator annotation for Trace Viewer; Playwright 1.56 `page.requests()` post-interaction history for N+1 detection; Playwright 1.56 LLM Test Agents planner/generator/healer relation to factory scaffolding; Gotcha #31 `failOnFlakyTests` as factory isolation quality signal (+348 lines, 100/100)
- `contract-testing-guide.md` — `matchingBranch` consumer version selector: three-tier selector pattern + `providerVersionBranch` requirement; full 12-property `ConsumerVersionSelector` TypeScript reference (all selector properties with examples and comparison table); PactFlow AI Code Review (August 2025 beta): detects over-specified matchers/duplicate descriptions/missing error interactions/provider-rule coupling; pact-protobuf-plugin v0.7.0 (October 2025): 30-60% speedup via proto descriptor caching + nested message lookup fix; Community lessons 58–61 (+262 lines, 100/100)
- `coverage-guide.md` — V8 branch-selective `if`/`else` ignore directives (`/* v8 ignore if -- @preserve */`/`/* v8 ignore else -- @preserve */`) — suppress one side of conditional only, unlike Istanbul which suppresses both; Gotcha G53: `coverage.htmlDir` for custom output path + `html-spa` reporter for single-file CI artifact uploads with V8-vs-Istanbul comparison; `ast-v8-to-istanbul` resource (+123 lines, 100/100, iter 42)
- `ci-cd-testing-guide.md` — TS 5.8 CI pillar 57: `--erasableSyntaxOnly` gate (Node.js type-stripping compatibility) with `tsconfig.ci.json` advisory→required rollout pattern; Gotcha #60: mass CI failure on first enable (audit sprint approach); `--libReplacement false` 8-15% `tsc --noEmit` speedup; `--module node18` vs `nodenext` decision guide; granular branch return type checking (+114 lines, 97/100, iter 35)
- `accessibility-guide.md` — `<selectedcontent>` element: ARIA-in-HTML W3C Recommendation April 15, 2026 — `role=none` (do not add ARIA), jest-axe unit test + Playwright ARIA snapshot + keyboard navigation test; Gotcha 81: `<selectedcontent>` `aria-allowed-role` trap; Gotcha 82: `<label>` `role`/`aria-*` now permitted when unassociated (axe guardrail may disappear — add explicit ESLint rule); Gotcha 83: `image` role synonym for `img` causes Playwright ARIA snapshot inconsistency (+144 lines, 98/100, iter 42)
- `shift-left-guide.md` — Zod v4 migration: `z.check()` typed cross-field validation replaces `.superRefine()`, `z.meta()` OpenAPI-compatible metadata for docs-as-code, `z.fromJSONSchema()` CI drift gate; v4 error message breakage gotcha (assert on `.code` not `.message`); v3→v4 performance table (14× faster string parsing, 57% smaller core); 6-step monorepo migration checklist; 5 community gotchas covering peer version pinning and `exactOptionalPropertyTypes` interaction (+220 lines, 100/100, iter 32)
- `flakiness-guide.md` — Jest 30 Pattern 92: `retryTimes` with `waitBeforeRetry` (eventual-consistency delays) and `retryImmediately` (false-positive from intervening-test state) options; Pattern 93: `advanceTimersToNextFrame()` for rAF/animation flakiness (eliminates frame-rate assumption bug + infinite `requestAnimationFrame` loop risk); Anti-Pattern 46: `globalsCleanup: 'on'` not enabled (cross-test-file global state leaks); Quick Reference 3 new rows (+405 lines, 100/100, iter 56)
- `exploratory-guide.md` — Playwright v1.57 `locator.description()` getter: `SessionLocatorRegistry` TypeScript harness for human-readable locator index; v1.57 Service Worker network routing: `PwaExploratorySession` harness intercepting page + SW-originated requests + YAML charter for PWA cache-invalidation exploration; `testConfig.webServer.wait` dynamic-port readiness with named capture group promotion; OWASP Top 10 for Agentic Applications 2026: risk-to-charter mapping table + `evaluateAgentSession` TypeScript oracle + LLM Top 10 vs Agentic Top 10 vs MCP comparison; Community lessons #126-128 (+552 lines, 100/100, iter 46)

### lang-refine (5 guides, all 97-100/100)
- `typescript-patterns.md` — TS 5.7: never-initialized variable detection (closure-captured use-before-assignment), ES2024 target + `TypedArray<ArrayBuffer>` generic breaking change (3 fix options), validated JSON imports require `with { type: "json" }` under `nodenext`, V8 compile caching transparent on Node.js 22 (2.5× startup speedup); TS 5.6: `--strictBuiltinIteratorReturn` (not in `strict` umbrella — common pitfall), arbitrary module identifiers for WASM + CJS compat gotcha; 6 new anti-pattern rows (+242 lines, 97/100)
- `javascript-patterns.md` — Vitest 3 inline workspace: multi-project `vitest.config.ts` (unit + integration + browser), per-project `fileParallelism`/`execArgv`; V8 coverage `coverage.include` requirement (AST-based, files never imported silently dropped); `vi.mock()` ESM hoisting: `ReferenceError` from module-scope variables, `vi.hoisted()` fix, `vi.resetModules()` isolation; Playwright `page.clock()`: fixed-date rendering, session expiry, debounce testing (install before `page.goto()` gotcha); accessibility assertions; soft assertions; 5 new gotchas #67-71 (+351 lines, 100/100)
- `java-patterns.md` — JUnit 5.13: `@SentenceFragment` per-class/method display tokens, `AutoCloseable` in `ExtensionContext.Store` (no `CloseableResource` needed), session/request-scoped stores, Kotlin `Sequence` in `@MethodSource`/`@FieldSource`/`@TestFactory`; JUnit 6.1 preview (RC1 April 2026): `@DefaultLocale`/`@DefaultTimeZone`, `@EnabledOnJre`/`@DisabledOnJre` with `int`/`int[]`, `@EmptySource` with `Iterable`/`Iterator`/`ListIterator`, `@CsvSource commentCharacter`; Mockito 5.23: `@Nullable` on `when()` parameters, Android dexmaker migration; AssertJ 3.27.7 CVE-2026-24400 XXE fix in `isXmlEqualTo()`, `XmlStringPrettyFormatter` deprecation (+350 lines, 99/100)
- `python-patterns.md` — `unittest.mock.patch.dict`/`patch.multiple`; `pytest-mock` plugin: `mocker` fixture, `mocker.spy()`, `mocker.patch.object()`, `mocker.stopall()`; `freezegun`/`time-machine`: datetime freezing, `tick=True`, comparison table; `responses` HTTP mocking; `pytest-httpx`/`aioresponses` async HTTP mocks; `st.register_type_strategy()` Hypothesis custom types; `pytest-xdist` parallel testing with `xdist_group`, worker-ID fixture; `pytest-cov` `pyproject.toml` config with branch coverage + `fail_under`; Gotchas #50-52: xdist session-fixture per-worker confusion, freezegun C-extension bypass, `responses` library mismatch (+817 lines, 100/100)
- `csharp-patterns.md` — MSTest SDK: `MSTest.Sdk/4.x` project file, `TestingExtensionsProfile`, `EnableAspireTesting`/`EnablePlaywright`, `global.json` pinning, redundant `<PackageReference>` migration gotcha; MTP Retry/HotReload extensions: `--retry-failed-tests` safety valves, `TESTINGPLATFORM_HOTRELOAD_ENABLED`, restricted license callout; NUnit 4.x `[FixtureLifeCycle]`: `InstancePerTestCase` vs `SingleInstance` + Moq + parallel safety matrix; xUnit v3 `Assert.Equivalent` `strict:false/true` modes, collection order behavior vs FluentAssertions `BeEquivalentTo`; FluentAssertions v8.9 collection aliases + type-based property exclusion; 3 gotchas + 6 anti-pattern rows (+389 lines, 97/100)

---



### qa-refine (5 guides, all 95-100/100)
- `playwright-patterns.md` — Playwright v1.60 `WebError.location()` returns `{url, lineNumber, columnNumber}` for uncaught JS errors (vs `pageerror` which misses unhandled rejections), `webErrors` fixture for zero-error assertions, `retain-on-failure-and-retries` trace mode added to reference table (100/100)
- `cypress-patterns.md` — no new additions; guide already fully covers Cypress 15.0–15.14.2 (0 lines added, 95/100)
- `k6-patterns.md` — `page.waitForResponse()` three usage forms + race condition fix (`Promise.all` pattern), `locator.boundingBox()` returns null for hidden/detached elements (null-check before destructuring), `locator.contentFrame()` vs `page.frameLocator()` disambiguation (+220 lines, 100/100)
- `detox-patterns.md` — fixed phantom iteration (metadata claimed iter 49 but content was missing — patterns 56-59 and gotchas 79-84 were never written): `by.semanticType()` 20.47+ semantic role vocabulary + platform mapping table, `device.resetAppState()` 4-way comparison + Android permission re-grant fix, `ignoreUnexpectedMessages` hybrid WebView/native overlay config, iOS 26 `arch` config for Rosetta x86_64 + Xcode 26 split runtimes, iOS 26 liquidGlass nav bar requires Detox 20.51.1+ for correct screenshots (+498 lines, 100/100)
- `appium-wdio-patterns.md` — `appium:waitForQuiescence` XCUITest idle-resource control for React Native animations, `appium:includeSafariInWebviews` OAuth/SSO Safari redirect flows, `appium:nativeWebTap` canvas/WebGL WebView clicks, `appium:appWaitActivity` Android launch stabilization, `ignoreUnimportantViews` 70% element-lookup speedup, Capacitor/Ionic hybrid WebView patterns, Appium 3 canonical app lifecycle (`mobile:openApp`/`activateApp`/`terminateApp`/`queryAppState`), `appium:reduceMotion` iOS accessibility + CI, Flutter Integration Testing via `appium-flutter-driver` Semantics tree locator (+674 lines, 100/100)

### qa-methodology-refine (12 guides, all 97-100/100)
- `test-pyramid-guide.md` — Node.js 25.9.0 `mock.module()` API consolidation: `namedExports`/`defaultExport` silently ignored → consolidated `exports` object (Gotcha #47, official codemod provided), Node.js 24.15.0 worker ID exposure for parallel integration resource partitioning, `require(esm)` stability, fake timer isolation fix for concurrent `node:test` runs (+114 lines, 100/100)
- `tdd-guide.md` — corrected `noUncheckedSideEffectImports` default-on in TS 6.0 (was erroneously described as opt-in), TS 6.0 `baseUrl`-relative `paths` entries break silently after upgrade (Gotcha #41), `#/` subpath imports for `viteModuleRunner:false` Node-native testing, TS 6.0 `--moduleResolution bundler` + `--module commonjs` combo unlocked, Vitest 4.1 coverage ignore comments require `@preserve` annotation or esbuild strips them → phantom coverage gaps (Gotcha #42) (+166 lines, 97/100)
- `bdd-guide.md` — Playwright v1.51-v1.60 BDD-relevant APIs: `TestStepInfo` for step-level decisions, IndexedDB `storageState` for SPA auth, `toContainClass`, `locator.describe()`, `page.consoleMessages()`/`pageErrors()`/`requests()` test-scoped helpers, `testConfig.tag`, `test.abort()` for unrecoverable fixture state; Cucumber.js version matrix updated with granular v12.6.0/v12.8.1 rows; Quick Reference Card extended with 5 new API rows (+260 lines, 99/100)
- `test-isolation-guide.md` — Jest 30 `SERIALIZABLE_PROPERTIES` symbol for pinning class fields in snapshot diffs (phantom drift prevention), `toEqual` non-enumerable exclusion breaking change (silent for `Object.defineProperty`/`#private` fields), `defineConfig`/`mergeConfig` type-safe Jest 30 config helpers replacing `import type { Config }`, Vitest 5.0 `vi.spyOn` on TypeScript `#private` methods without `as any` cast (+351 lines, 100/100)
- `test-data-guide.md` — MSW v2.14.0 `ws.onUpgrade` HTTP-Upgrade WebSocket interception in Node.js: comparison table vs `ws.link()` (layer/scope/browser availability), auth-header inspection + rejection/acceptance patterns, per-session factory context seeding, global-scope trap + browser unavailability gotcha (#30) (+248 lines, 100/100)
- `contract-testing-guide.md` — factual error corrected: `addInteractionReference(InteractionObject)` was a fabricated API — actual API is `.reference(group, name, value)` (traceability annotation linking Jira/PRs to Broker UI, not interaction reuse); all 3 occurrences in body corrected with accurate TypeScript examples and "What it does NOT do" callout (+5 net lines, 100/100)
- `flakiness-guide.md` — Playwright v1.60 `tracing.startHar()`/`stopHar()` as first-class tracing API with `await using` pattern + `urlFilter`/`mode` options, `toHaveCSS({pseudo: 'before'|'after'})` replaces screenshot snapshots for pseudo-element styling, `browser.on('context')` lifecycle listener registration-order race condition + fixture pre-registration fix, Vitest 4.1 `FixtureAccessError` (named error instead of silent `undefined` when accessing test-scoped fixture from `beforeAll`/`afterAll`) (+515 lines, 100/100)
- `coverage-guide.md` — `@fast-check/vitest` dedicated Vitest integration (v4.x, 2025) with `test.prop()` patterns, Node.js 24 `test()`/`t.test()` no longer return Promises (breaking change affects awaiting patterns), global setup/teardown hooks, `--experimental-strip-types` RC status clarification (+167 lines, 100/100)
- `ci-cd-testing-guide.md` — Node.js 24 LTS native test runner: `--test-global-setup` flag zero-framework global setup/teardown, stable `t.assert.snapshot()` (no flags needed), programmatic coverage thresholds in `node:test run()`, npm 11 CI changes (`--ignore-scripts` suppresses `prepare`/TypeScript compile silently, bulk audit endpoint removed, Node `^20.17.0||>=22.9.0` requirement), type stripping progression table (+159 lines, 100/100)
- `accessibility-guide.md` — WebAIM 2025 actual data: 55.3 avg errors/page (down from 56.8), EU EAA enforcement did not significantly move aggregate numbers; Playwright 1.50 `locator.normalize()` accessibility-first locator conversion + audit script for CSS-only selectors; axe-core 4.11.4 ancestry selector escaping fix (baseline regeneration required — `node.target` selectors with custom element names now correctly escaped); Gotchas 77-80 including `normalize()` unchanged output = missing semantics signal (+218 lines, 99/100)
- `shift-left-guide.md` — TS 6.0 new defaults that break shift-left gates (`module:esnext`, `target:es2025`, `rootDir:.` — only `strict:true` and `types:[]` were previously documented), TS 6.0 ES2025 library additions: `RegExp.escape()` eliminates regex injection anti-pattern, `Map.getOrInsert()`/`getOrInsertComputed()` for memoization, Temporal built-in types, TS 7.0 `--stableTypeOrdering` CI preview gate, Vitest 5.0 `vitest list` static discovery gate + `worker_threads` coverage gap fix (+422 lines, 100/100)
- `exploratory-guide.md` — Playwright v1.60 `tracing.startHar()` `HarOracleOracle` TypeScript harness for API-layer defect handoff, `locator.drop()` `UploadZoneExplorer` with MIME-type spoofing + OWASP ASVS V12/LLM Top 10 mapping, `getByRole({description})` `auditFormDescriptions` oracle, `test.abort()` `SentinelGuard` for unrecoverable state detection (reduces false-positive defects ~60%), `browser.bind()` multi-client session sharing for AI co-pilot pair exploration (+527 lines, 100/100)

### lang-refine (5 guides, all 97-100/100)
- `typescript-patterns.md` — TS 5.5 RegExp syntax checking (4 validation types; `new RegExp(string)` NOT validated gotcha), TS 5.5 constant indexed access narrowing + reassignment scope loss, TS 5.6 always-truthy/always-nullish detection catches `if (mockFn)` and `if (/regex/)` testing anti-patterns, TS 5.5 `${configDir}` limited to `paths`/`baseUrl` only (not `rootDir`/`outDir`/`include`/`exclude`) (+308 lines, 97/100)
- `javascript-patterns.md` — `assert.partialDeepStrictEqual()` Node.js 24 stable (partial deep equality for API response testing, replaces `toMatchObject` workaround), `AsyncLocalStorage` `defaultValue` constructor option (Node.js 24, eliminates null-checks in tests running outside `run()` context), `import.meta.dirname`/`import.meta.filename` stable Node.js 22+ (decision table vs legacy `fileURLToPath`) (+234 lines, 100/100)
- `java-patterns.md` — Testcontainers 2.0 migration: module artifact ID renames (`postgresql`→`testcontainers-postgresql`), JUnit 4 removal, default constructor removal; AssertJ 3.27 `actual()` escape hatch + `extracting(Function...)` type-narrowing breaking change + CompletableFuture assertions; JUnit 6.0 Java 17 baseline + FastCSV strictness + Kotlin `suspend` test support + migration checklist; Mockito 5.22 `mockSingleton()` for Kotlin `object` + `ReturnsEmptyValues` change; Spring Boot 3.5 `@PostgreSqlSslBundle` SSL Testcontainers; AssertJ 3.27.1 record/sealed class introspection (+380 lines, 98/100)
- `python-patterns.md` — Hypothesis stateful testing (`RuleBasedStateMachine`, `@rule`, `@initialize`, `@invariant`, `Bundle`, `multiple()`/`consumes()`, differential testing), `pytest.raises(check=...)` 8.4+ predicate shorthand, `capteesys` fixture captures AND passes through, `collect_imported_tests=false` 8.4+, `console_output_style='times'`, `--xfail-tb`/`--no-fold-skipped` 8.3+, `strict_parametrization_ids` 9.0+, Gotcha #48 sync-test async fixture hard error 8.4+, Gotcha #49 non-None return hard error 8.4+ (+411 lines, 98/100)
- `csharp-patterns.md` — NUnit 4.x Classic API (`Assert.AreEqual` etc.) → `NUnit.Framework.Legacy` shim migration table + `Assert.Multiple` soft assertions + NUnit4TestAdapter; MSTest v4 `Assert.That(() => lambda)` + `CallerArgumentExpression` diagnostics + `Microsoft.Testing.Platform` v2; FluentAssertions v8 Xceed Community License (decision table: pin v6 vs Shouldly vs Xceed commercial), `Span<T>`/`Memory<T>` assertions v8.9, `BeNaN`/`BeRelativelyCloseTo`; xUnit v3 `CancellationToken` injection + `Assert.Multiple`; TUnit framework complete section (source-generator discovery, parallel-by-default, built-in DI, `[DependsOn]`/`[NotInParallel]`/`[ParallelLimit<T>]`, async-first assertions, framework comparison table); 4 new gotchas + 6 anti-pattern rows (+532 lines, 97/100)

---

## v1.16.0.13 — 2026-05-12 — nightly refinement run — 22 guides extended (cycle 10/100)

### qa-refine (5 guides extended, all 97-100/100)
- `playwright-patterns.md` — ESLint v9 flat config (`eslint.config.js`) support for `eslint-plugin-playwright`: `flat/recommended` preset import, `@1.6.0+` version compatibility gotcha, migration path from legacy `.eslintrc.*` for TypeScript projects scaffolded after early 2025 (+47 lines, 100/100)
- `cypress-patterns.md` — restored missing `### 68. Pure API Test Suite with cy.request()` section heading (was orphaned prose with no navigation anchor); confirmed full Cypress 15.0–15.14.2 changelog coverage — no uncovered APIs found (+4 net lines, 97/100)
- `k6-patterns.md` — CVE-2026-33186 `grafana/k6:1.7.0` gRPC RCE advisory (pin to 1.7.1, Dependabot snippet, grep audit command), `k6 cloud project list` dynamic CI project-ID resolution via `jq`, xk6 extension author v2.0.0 migration (easyjson→stdlib `encoding/json`, `k6 archive` metadata `dependencies` SBOM field, OCI container labels) (+223 lines, 97/100)
- `detox-patterns.md` — no new additions (guide already at 100/100 ceiling, 9120 lines)
- `appium-wdio-patterns.md` — `appium-uiautomator2-server` v10 ESM-only `ERR_REQUIRE_ESM` gotcha for custom scripts/plugins (standard test code unaffected), Appium 3.3.0 exact dependency pinning `ERESOLVE` on plugin upgrades, Node.js v20.19.0 exact minimum requirement (not just any v20.x, `setup-node` resolution gotcha), UIAutomator2 v7.2.0 + XCUITest v11.2.0 Bluebird removal (`.reflect()` removed → `p-map` replacement) (+172 lines, 100/100)

### qa-methodology-refine (12 guides extended, all 97-100/100)
- `test-pyramid-guide.md` — TypeScript 5.9 new `tsc --init` prescriptive defaults and test pipeline impact table, `--module node20` stable semantics, `import defer` lazy test setup, Gotcha #45: `Buffer` no longer assignable to `ArrayBuffer` in TS 5.9 (integration test helpers break), Gotcha #46: `verbatimModuleSyntax:true` as TS 5.9 default silently passes in Vitest (esbuild ignores flag) but fails `tsc --noEmit` CI (+166 lines, 97/100)
- `tdd-guide.md` — Vitest 4.1 Browser Mode ARIA Snapshot TDD (`toMatchAriaSnapshot`/`toMatchAriaInlineSnapshot`) for accessibility contracts, Type-Level TDD with `expectTypeOf`+`*.test-d.ts` Red/Green/Refactor cycle, Gotcha #38: `--update-snapshots` silently accepts accessibility regressions, Gotcha #39: `vitest typecheck --watch` stale cache produces false Greens (+318 lines, 100/100)
- `bdd-guide.md` — Playwright `Clock` API (`page.clock.setFixedTime()`/`fastForward()`) for time-dependent BDD scenarios (password reset expiry, session timeout), `WebSocketRoute` (`context.routeWebSocket()`) mock server for real-time BDD without backend, `toMatchAriaSnapshot()` v1.49+ ARIA tree assertions for structural accessibility BDD, `toHaveAccessibleErrorMessage()` v1.50+ for `aria-errormessage` associations, Cucumber 2025 community ownership pinning guidance (+369 lines, 98/100)
- `test-isolation-guide.md` — Jest 30 `expect.arrayOf()`/`expect.not.arrayOf()` asymmetric matcher (empty-array pass-through gotcha), `jest.clearMocksOnScope()` targeted clearing, `workerGracefulExitTimeout` prevents false-positive `--detectOpenHandles` warnings masking real leaks, Vitest 5.0-beta.2 `test.sequential` fully removed (not deprecated) + `@vitest/expect` inlined (breaking import paths), Jest 30.4 `Temporal.Duration` in `advanceTimersByTime()` (+341 lines, 100/100)
- `test-data-guide.md` — Playwright 1.48 `page.routeWebSocket()` E2E mock+`connectToServer()` passthrough, 1.49 composable `globalSetup` via project `dependencies`+`teardown`, 1.50 `test.step.skip()` data-dependent step guarding, 1.60 `test.abort()` fixture precondition enforcement, MSW v2.14 `finalize()` WebSocket handler cleanup, faker v10.4 `nb_NO`/`ja` locale expansions, WebSocket route linger gotcha on worker-scoped pages (`page.unrouteAll()` fix) (+791 lines, 100/100)
- `contract-testing-guide.md` — multipart/file upload contract testing (`multipartBody()` simple + `binaryFile()`+`matchingRules` complex), `SpecificationVersion` enum reference (V2/V3/V4) with silent-disable gotcha, EADDRINUSE lifecycle bug (#1568 from missing `provider.finalize()`), Jest `--watch` non-fatal tracing warning (#1438), multipart over-specification anti-pattern, `SpecificationVersion.V4` silent feature disable TypeScript gap (+241 lines, 100/100)
- `flakiness-guide.md` — Vitest 5.0-beta `sequential` option removal → `concurrent: false`/`describe.serial` migration with table, Playwright v1.60 `locator.drop()` drag-and-drop upload zone (replaces flaky `DragEvent`/`dispatchEvent`), Vitest 5.0 attachment directory path change `.vitest-attachments/`→`.vitest/attachments/` with config-pinning fix, AP44 anti-pattern for hardcoded attachment path in CI (+338 lines, 100/100)
- `coverage-guide.md` — G51: Vitest 4.0 silently ignores `coverage.all: true` without warning (zero-coverage modules disappear from reports), explicit `coverage.include` replacement, 4 other options removed in Vitest 4 (`coverage.extensions`, `coverage.ignoreEmptyLines`, `coverage.experimentalAstAwareRemapping`), 5-step upgrade checklist, G40: `coverage.ignoreClassMethods` now works with V8 provider in Vitest 4+ (+94 lines, 100/100)
- `ci-cd-testing-guide.md` — Jest 30 release date corrected (June 4 2025, not January 2025), Jest 30 new APIs: `expect.arrayOf`, `jest.advanceTimersToNextFrame()` rAF fake-timer support, `jest.onGenerateMock()` global interceptor, `using` spy auto-cleanup (TS 5.2+), `test.each %$` title numbering; Vitest 4.1: `mockThrow()`/`mockThrowOnce()`, Chai-style mock assertions, `vi.defineHelper()` stack hygiene, Vite 8 peer dep consolidation, `page.mark()` trace annotations, Vitest Agent Reporter for AI coding contexts; GitHub Actions Copilot Minutes billing impact June 2026 (+451 lines, 100/100)
- `accessibility-guide.md` — WCAG 2.4.12 Focus Not Obscured dedicated section (CSS `scroll-padding-top` fix, dynamic `useStickyHeaderOffset` React hook, Playwright tab-order bounding-box test walking all sticky/fixed overlays, axe-core 4.11.4 still does NOT test 2.4.12/2.4.13), EU EAA post-June 2025 enforcement status (complaint-driven, member-state variation, micro-enterprise exemptions), `@axe-core/mcp` Deque official MCP server (scan_url/scan_html/get_rule tools, Claude Code settings.json integration, TypeScript type defs), WebAIM 2019-2024 5-year trend (61.1→56.8 errors/page, 7% improvement), 5 new gotchas (scroll-padding anchor blind spot, EAA enforcement reality, scan_html JS limitation, `toMatchAriaSnapshot` live region race, `scroll-behavior:smooth`+`scroll-padding` interaction) (+532 lines, 97/100)
- `shift-left-guide.md` — Vitest 4.1 `viteModuleRunner:false` integration test mode (catches ESM circular deps and CJS/ESM interop bugs invisible in Vite sandbox, requires Node 22.15+), Chai-style `expect(fn).to.have.been.called` + `mockThrow()` for migrating teams, Vitest 4.1 `agent` reporter for AI coding environments (Claude Code/Cursor/Copilot Workspace — suppresses passing-test noise to preserve LLM context) (+255 lines, 100/100)
- `exploratory-guide.md` — `toMatchAriaSnapshot()` YAML `AriaStructuralOracle` TypeScript class (record/compare modes, `boxes` option for AI analysis), Playwright Test Agents v1.56 planner/generator/healer integration + SBTM guidance + anti-pattern (Generator output ≠ complete test suite), Screencast API v1.59 `runAnnotatedExploratorySession()` harness with chapter markers + Screencast vs Trace Viewer decision table, `page.pickLocator()`+`locator.describe()` chaining, `await using` async disposables, community lessons #120-122 (+569 lines, 100/100)

### lang-refine (5 guides extended, all 97/100)
- `typescript-patterns.md` — `using` declaration test resource cleanup (scope pitfall: disposes at end of `beforeEach` not end of test), type-safe `expect.extend` custom matchers for Jest (`MatcherFunction<[]>`) and Vitest 2.x (`CustomMatcherResult`) with module augmentation + `export {}` script-vs-module pitfall, Vitest 2.x `vi.fn<(arg: T) => R>()` breaking generic change (old `vi.fn<[Args], Return>()` silently produces `Mock<unknown>`), `satisfies` exhaustive fixture type-checking (gotcha: `satisfies ApiEvent[]` does NOT enforce union variant coverage) (+300 lines, 97/100)
- `javascript-patterns.md` — `String.isWellFormed()`/`toWellFormed()` ES2024 lone-surrogate sanitization before `encodeURI`/`TextEncoder`/fetch, RegExp `v` flag (ES2024) unicodeSets mode with set intersection/subtraction/string Unicode properties + `u`/`v` mutual exclusion, resizable `ArrayBuffer` ES2024 with `maxByteLength`/`resize()`/`SharedArrayBuffer.grow()`, Node.js 24 test runner auto-awaiting subtests (version-compat gotcha for Node 22 LTS), global `before`/`after` hooks, per-test `{timeout}` option, JSON module mocking with `t.mock.module()` (+357 lines, 100/100)
- `java-patterns.md` — JUnit 5.11 `@FieldSource` (field-backed parameterized args), `@AutoClose` (automatic field teardown), repeatable `@Source`+`argumentSet()` named rows; JUnit 5.12 `@EnumSource` `from`/`to` range; JUnit 5.13 `@ParameterizedClass` (entire class parameterization, May 2025); Spring Boot `@ServiceConnection` replaces `@DynamicPropertySource` for Testcontainers (`replace=NONE` gotcha with `@DataJpaTest`); Spring 6.2 `@MockitoBean`/`@MockitoSpyBean` replaces `@MockBean` with strategy control; `MockMvcTester` AssertJ-native wrapper (Spring Boot 3.4); Mockito 5.x STRICT_STUBS + final class inline mock gotcha (+504 lines, 99/100)
- `python-patterns.md` — Major gap filled: pytest+Hypothesis testing section added. pytest: fixture scopes (5 scopes + yield teardown + conftest.py + autouse), `@pytest.mark.parametrize` + `pytest.HIDDEN_PARAM` (8.4+), subtests (9.0+), built-in fixtures (`tmp_path`/`monkeypatch`/`caplog`/`capsys`), `pytest.raises`/`warns`/`approx` + `pytest.RaisesGroup` (8.4+), marks + pyproject.toml registration, native TOML config (9.0+), pytest-asyncio `asyncio_mode`. Hypothesis: `@given/@settings/@example`, all key strategies + `@composite`, `assume()/note()/target()`, database reproducibility. Gotchas: fixture scope leakage, monkeypatch vs patch namespace, Hypothesis filter rejection kill ratio (+928 lines, 97/100)
- `csharp-patterns.md` — Full testing patterns section: Moq (`MockBehavior.Strict/Loose`, `It.*`, `SetupSequence`, `Verify/Times.*`, async `ReturnsAsync`/`ThrowsAsync`), NSubstitute comparison table (when to pick each), FluentAssertions (`BeEquivalentTo` with `Excluding`/`WithStrictOrdering`/custom comparators, FA v7 commercial license note), xUnit v3 (`IAsyncLifetime`, `TheoryData<T>`, `IAssemblyFixture`, fixture scoping table), NUnit (`[TestCase]`/`[TestCaseSource]`/`[Values]` combinatorial), MSTest v3 async lifecycle + `[Parallelize]`, `CustomWebApplicationFactory<T>` integration testing, Bogus seeded faker + AutoFixture `[AutoData]`, Respawn DB reset, Verify snapshot testing, 14-row anti-patterns table + 5 community gotchas (+748 lines, 97/100)

---

## v1.16.0.12 — 2026-05-12 — nightly refinement run — 22 guides extended (cycle 9/100)

### qa-refine (5 guides extended, all 100/100)
- `playwright-patterns.md` — `response.httpVersion()` HTTP/2 assertion (v1.59), `request.existingResponse()` returns null in `page.route()` handler (route-vs-intercept distinction), Planner→Generator→Healer agentic testing workflow, `page.screencast()` Chromium-only restriction callout, Playwright Agents healer anti-pattern `waitForTimeout()` introduced by AI healing (+3 patterns, +3 gotchas)
- `cypress-patterns.md` — `cy.press()` modifier key limitations (single-key only; `cy.type()` required for Ctrl/Shift/Alt/Meta chords + full `Cypress.Keyboard.Keys` reference), Studio AI assertion suggestions workflow (Cypress 15.13+, DOM diff → AI-generated `.should()` calls), `cy.prompt()` restrictions (E2E-only/Chromium-only with guards), `experimentalFastVisibility` point-sampling speedup + shadow DOM false-negative, Cypress 15 tsx replaces ts-node config (top-level await, `import.meta.dirname`), Brotli proxy decompression (Cypress 15.11+ transparent `Content-Encoding: br`); gotchas: `cy.press()` modifier chord silent no-op, `experimentalFastVisibility` shadow DOM false-negative, `cy.prompt()` CT-mode throw, ts-loader 9.5.2→9.5.7 pin conflict on 15.14.2 upgrade, Brotli binary `res.body` pre-15.11 (+525 lines, +6 gotchas)
- `k6-patterns.md` — Prometheus Native Histograms require Prometheus ≥2.40 + `--enable-feature=native-histograms` flag, `K6_WEB_DASHBOARD` CI hang fix (`PORT=-1` disables), `k6/experimental/websockets` deprecated (migrate to `k6/x/websockets`), `--execution-segment` distributed testing pattern (+4 patterns, +4 gotchas)
- `detox-patterns.md` — React Navigation v7 static config + centralized `SCREENS` testID map, `device.reverseTcp()` vs `reversePorts` decision table for Android network routing, custom Jest reporter writing Markdown to `$GITHUB_STEP_SUMMARY`; RN 0.80+ Package Exports breaks Metro resolver (fix: `unstable_enablePackageExports: false`), iOS 18.2+ Settings restructure invalidates `by.system()` location navigation (fix: `App-Prefs:Privacy` deep link), Android AGP 8.4+ deprecated flags + unsigned APK path change, `device.setLocation()` Android API 35 pre-launch requirement, `device.reloadReactNative()` inside `it()` resets `withTimeout` clock causing 20s+ hang, `jest-junit` v17+ template change breaks shard XML merge, `element.tap()` on disabled `Pressable` fires via Espresso bypass, `waitFor.not.toBeVisible()` resolves mid-animation on slow CI GPUs (+3 patterns, +8 gotchas)
- `appium-wdio-patterns.md` — XCUITest v11 migration guide (breaking: `appium:launchWithIDB` removed, `mobile:startPcap`/`stopPcap` removed; `mobile:startScreenRecording`/`stopScreenRecording` dedicated wrappers v11.1.0, `download-wda` CLI v11.3.0), UIAutomator2 v7 new commands (`mobile:listWindows`, `mobile:listDisplays`, `mobile:resetAccessibilityCache`, `mobile:pressKey source`, `mobile:setStylusHandwriting`, `mobile:listApps` breaking field rename `name`→`packageName`), `browser.background()` comprehensive semantics guide, `mobile:simctl` iOS privacy/push/deep-link control, `toHaveLocalStorageItem` matcher (expect-webdriverio v5.6.5); gotchas: UIAutomator2 v7 `mobile:listApps` TypeScript silent `undefined` on field rename, `background(-1)` newCommandTimeout session expiry, `mobile:setStylusHandwriting` requires `--allow-insecure`, XCUITest v11 `mobile:startScreenRecording` silently discards previous clip if called while recording, `mobile:simctl privacy` iOS 17+ re-grant dialog breaks `beforeEach` (+394 lines, +5 gotchas)

### qa-methodology-refine (12 guides extended, all 100/100)
- `test-pyramid-guide.md` — Node.js 26.0.0 removes `--experimental-transform-types` (force-upgrade before bumping), Temporal API requires clock injection (no test double intercepts native Temporal), `--test-randomize`/`--test-random-seed` Node 26.1.0 test order randomization (+3 patterns, +2 gotchas)
- `tdd-guide.md` — `viteModuleRunner:false` with `vi.mock()` requires Node 22.15+ (not just Node 22), `onCleanup()` co-located fixture teardown (single-registration limitation: subsequent calls silently dropped), Chai-style mock assertions vs Jest `toHaveBeenCalled()` mixing TypeError, TS 6.0 `this`-less parameter inference (+4 patterns, +3 gotchas)
- `bdd-guide.md` — `Plugin<T>` generic API for `pickles:filter/order`, `FormatterPlugin<T>` + `@cucumber/query` 4-hop trace correlation, `satisfies Partial<IConfiguration>` for native TypeScript config, playwright-bdd v8.4.0 fixture determinism improvement (+4 patterns)
- `test-isolation-guide.md` — Jest 30.3 `setTimerTickMode({mode:'nextAsync'})` object param format (was string), Jest 30.4 `Temporal.Now.timeZoneId()` not faked by fake timers (UTC CI failures), Vitest 5.0 `test.sequential` deprecated → `{concurrent: false}` (+3 gotchas)
- `test-data-guide.md` — faker v10 `book` module (replaces `commerce.productName` for literary data), `faker.word` `strategy:'fail'` as new default breaking change (previous: `'any-length'`), Playwright CT `router` fixture for component-level network mocking (+3 patterns, +2 gotchas)
- `contract-testing-guide.md` — "Bug Catcher Rule" decision checklist (when to skip provider state vs require it), V4 `statusCode('serverError'/'clientError'/'success')` semantic matchers, mTLS mutual authentication workaround, `fallbackBranch` TypeScript type gap (accepts string but ignores non-default-branch values) (+4 patterns)
- `coverage-guide.md` — Vitest per-glob thresholds double-evaluate path against both include AND configured globs (Jest migration trap), Stryker v9.6.1 confirmed current, Vitest 4.1.6 no coverage API changes (+2 gotchas, corrections)
- `ci-cd-testing-guide.md` — Jest 30 37% faster execution +77% lower memory footprint, `babel-plugin-transform-barrels` 2–100× import resolve speedup, `globalsCleanup:'soft'` Jest 30 migration risk (partial cleanup causes ordering sensitivity), GitHub Actions 50-rerun cap April 2026 (+4 patterns, +2 gotchas)
- `accessibility-guide.md` — IBM Equal Access v4.0.17 `aChecker.getCompliance()` TypeScript API, `page.ariaSnapshot({boxes:true})` silently breaks `toMatchAriaSnapshot()` (incompatible output format), WCAG 3.0 March 2026 Bronze/Silver/Gold model ratified (+3 patterns, +2 gotchas)
- `shift-left-guide.md` — Node.js 26.0.0 removal of `--experimental-transform-types` confirmed, Node.js 22.18.0 unflagged TS execution date corrected, `erasableSyntaxOnly:true` as LTS insurance pattern (+3 patterns, corrections)
- `flakiness-guide.md` — `testCase.outcome()==='flaky'` reporter API bug (`TestResult.status` has no `'flaky'` value — use `TestResult.retry`), `updateSnapshots:'changed'+'3way'` interactive merge mode, `updateSnapshots:'all'` in CI silently overwrites broken baselines (AP43 anti-pattern) (+3 patterns, +2 gotchas)
- `exploratory-guide.md` — `OTelExploratoryOracle` TypeScript class polling Jaeger REST API for test-scoped trace validation, tool call cascade defect pattern (AI chaining tools → cumulative side effects invisible to per-call validation), correlation ID discipline as prerequisite for agentic exploratory testing (+3 patterns)

### lang-refine (5 guides extended, all 100/100)
- `typescript-patterns.md` — TS 6.0 `rootDir` inference removal (extra `src/` nesting level silently added), `types:["*"]` glob costs 20–50% build penalty (explicit enumeration required), `PartialExcept<T,K>` utility type pattern, `tsc --init` opinionated defaults audit checklist (+4 patterns, +2 gotchas)
- `javascript-patterns.md` — Closure entire-scope variable retention memory leak (closure retains ALL vars in enclosing scope not just referenced ones), ESM named import alias captures value not live binding (re-export loses reactivity) (+2 gotchas)
- `java-patterns.md` — `StructuredTaskScope.Joiner` Java 25 JEP 505 structured concurrency GA, Spring `@Async` self-invocation AOP bypass (call from same bean skips proxy), HikariCP `maxLifetime` must be < `wait_timeout`/`interactive_timeout` (silent connection drops), Hibernate 2LC invalidation storms on high-write workloads (+4 patterns, +3 gotchas)
- `python-patterns.md` — T-string PEP 750 `template.strings` N+1 elements rule (strings array always one longer than interpolations), free-threaded CPython shared-iterator race condition (GIL was masking), `Executor.map()` unbounded backpressure (collect to list first), `ProcessPoolExecutor.terminate_workers()`/`kill_workers()` Python 3.14 new methods (+4 patterns, +2 gotchas)
- `csharp-patterns.md` — Polly `AddStandardResilienceHandler` POST idempotency gap (retries non-idempotent POSTs → silent duplicate inserts; fix: `ShouldHandle` predicate), `TimeoutRejectedException` vs `System.TimeoutException` distinction (outer pipeline catches wrong type), stacking multiple resilience handlers multiplies retry count 3×N (+3 gotchas, +2 patterns)

---

## v1.16.0.11 — 2026-05-12 — nightly refinement run — 22 guides extended (cycle 8/100)

### qa-refine (5 guides extended, all 100/100)
- `playwright-patterns.md` — `tracing.startHar()/stopHar()` as `await using` async disposable (v1.60), `locator.drop({files/data})` for drag-and-drop upload zones (does NOT fire `<input type=file>` change event), `browser.on('context')` + `context.on('pageclose/pageload/frameattached/framenavigated')` lifecycle events (must register before context creation), `getByRole({description})`, `locator.highlight({style})`, `page.hideHighlight()`; gotchas: `toMatchAriaSnapshot()` locale drift, HAR embed buffers all bodies (use `urlFilter`), `locator.drop` no-op on file inputs (+354 lines, +3 gotchas)
- `cypress-patterns.md` — Next.js 16 CT (Turbopack silently falls back to Webpack; CSS Modules/path aliases break), `cy.prompt()` self-healing badge semantics ("Self-healed via AI" = CI rate-limit diagnostic), `hideHttpRequests` toggle Cy 15.4+; gotchas: `cy.press()` yields `null` (vacuous `have.focus` passes), `cy.press()` fires on `document.body` with no focused element (CI-only failures), `cy.prompt()` beforeunload navigation hang (+249 lines, +5 gotchas)
- `k6-patterns.md` — WebSocket `onclose` `.code/.reason` tracking (v1.5.0) + close code reference table, CSV `asObjects:true`/`skipFirstLine:true` streaming patterns, `-e` vs `K6_` env var precedence + resolution chain, extension ecosystem (xk6-faker seeded, xk6-sql DB validation in teardown, xk6-dns DNS pinning); gotchas: `csv.parse()` in `default()` memory explosion, `browser` scenarios fail without `type:"chromium"`, `K6_CLOUD_STACK_ID` wrong org silent, xk6-disruptor `cluster-admin` RBAC timeout no-hint, `-e K6_ITERATIONS=50` does NOT configure options (most common CI misconfiguration) (+580 lines, +5 gotchas)
- `detox-patterns.md` — `device.setStatusBar()/resetStatusBar()` comprehensive field reference (time/batteryLevel/batteryState/networkType/wifiBars/cellularBars), Allure reporting integration with `step()/attachScreenshot()`, network interception via `launchArgs` + `http.createServer({port:0})` (parallel-safe), `toHaveText()/toHaveLabel()/toHaveValue()/toHaveToggleValue()` disambiguation table; gotchas: `batteryLevel` float clamped 2 decimal places, `DETOX_SERVER_PORT` collision in monorepo CI (silent failure), `longPress(0)` behaves as tap on Android (800ms min), RN 0.79+ Metro lazy bundling raises cold-start timeout, `jest-circus afterAll` nested describe deadlock (+763 lines, +7 gotchas)
- `appium-wdio-patterns.md` — `isStable()` animation-aware stability check (always `true` in native context — silent false positive), `start-appium-inspector` CLI, Appium 3.1 W3C `printPage` PDF generation, Appium 3.2 `click()` silent WebView regression (stricter W3C interactable checks) + `robustClick()` JS-fallback + 2.17→3.2 migration checklist, `browser.swipe({from,to})` pixel-coordinate pattern (iOS logical vs physical pixels); gotchas: `--allow-cors` security risk, Chrome vs WebKit PDF rendering differences, 3.2 click resolves without error while doing nothing (+315 lines, +15 gotchas)

### qa-methodology-refine (12 guides extended, all 100/100)
- `test-pyramid-guide.md` — Node.js 24.14.0 LTS `expectFailure:true` in `node:test` (xfail semantics — governance risk as permanent quarantine anti-pattern), `env` option on programmatic `run()` for per-invocation env injection without mutating `process.env`
- `tdd-guide.md` — Vitest 4.1 experimental `runner:'node'` sub-50ms TDD feedback (erasable TS only, Node 23.6+), Google TotT "The Way of TDD" March 2026 (absence of Refactor-only commits diagnoses test-first vs true TDD), `page.mark()` Playwright trace annotations for TDD cycle visibility; gotchas: `const enum` native strip, unawaited `expect.element()` silent false greens in Browser Mode (+285 lines, +3 gotchas)
- `bdd-guide.md` — Gherkin DocString backtick `` ``` `` delimiter officially supported since Gherkin 6 (renders syntax-highlighted in GitHub PR reviews), `prettier-plugin-gherkin` `docStringDelimiter` option, Cucumber.js v12.8.3 + playwright-bdd v8.5.0 confirmed current
- `test-isolation-guide.md` — `vi.mock(import('./path'), factory)` module promise syntax for type-safe factories (compile error on shape drift), `onCleanup` single-call limitation (subsequent registrations silently dropped → resource leaks), `vi.resetModules()` clears module cache only (mock registry requires separate `vi.unmock()`), "Construct with Collaborators, Call with Work" Google TotT May 2026, Chai `.to.have.been.called` property access vs Jest `toHaveBeenCalled()` mixing TypeError (+5 gotchas, +1 pattern)
- `test-data-guide.md` — Playwright `{option:true}` fixture for per-project factory config (staging-minimal vs staging-full profiles in `playwright.config.ts`), Playwright 1.51 `browserContext.setStorageState()` atomic IndexedDB reset for Firebase Auth/Supabase sessions, Vitest 5.0 default-concurrent mode breaks module-level mutable factory state (counters, connection pool singletons) (+200 lines, +1 gotcha)
- `contract-testing-guide.md` — `constrainedArrayLike(min, max, shape)` + `atMostLike()` for bounded paginated API contracts, `InterfaceToTemplate<T>` silently relaxes field-completeness (use `Record<keyof T, unknown>` instead), `executeTest()` session model — multiple `addInteraction()` before one `executeTest()` is correct pattern; pact-js v16.4.0 confirmed current (+3 patterns, +3 community lessons)
- `flakiness-guide.md` — `vi.setTimerTickMode('nextTimerAsync')` drop-in for brittle `runAllTimersAsync()` cascade, `tracing.start({live:true})` real-time trace (survives test timeout), `trace:'retain-on-failure-and-retries'` cross-retry trace comparison (v1.58), Vitest 4.1 `beforeAll/afterAll/aroundAll` Suite arg silently removed (now `{file,worker}`) (+404 lines, +4 patterns, +1 anti-pattern)
- `coverage-guide.md` — TS 6.0 defaults (`module:"esnext"`, `types:[]`, `rootDir:"."`) silently instrument 0 files with ts-jest/Istanbul, `--outFile` + `--moduleResolution classic` fully removed, `ignoreDeprecations:"6.0"` migration bridge (+74 lines, +1 gotcha)
- `ci-cd-testing-guide.md` — Vitest 4.1 `github-actions` reporter silently self-disables when any custom `reporters` array defined, GitHub Actions OIDC repository custom properties GA March 2026 (`repo_property_*` claims — must pair `sub` org scoping), `viteModuleRunner:false` 30–50% faster CI + exposes CJS/ESM interop bugs Vite masks (+307 lines, +2 gotchas, +5 anti-patterns)
- `accessibility-guide.md` — `@axe-core/playwright` 4.11.1 TypeScript export reorder fix (TS2305 on `moduleResolution:bundler`), deferred/lazy iframes silently skipped (check `results.incomplete` for `id==='frame-tested'`), pin all `@axe-core/*` to same monorepo version (v4.11.3) (+4 gotchas, +2 patterns)
- `shift-left-guide.md` — GitHub Actions `${{ github.event.* }}` workflow injection in `run:` steps (fix: `env:` isolation + `actionlint` pre-commit gate), GitHub agentic detection platform Q2 2026 (CodeQL `actions` language + AI cross-file IaC/Dockerfile/Terraform scanning), Copilot Autofix 2025: 460k+ alerts, 0.66h vs 1.29h manual remediation (+2 patterns, +2 gotchas)
- `exploratory-guide.md` — MCP Server Exploratory Testing Pattern with YAML charter template + `MCPExploratoryHarness` TypeScript class (AJV JSON Schema validation), "tool call cascade defect" (AI chaining tools → cumulative side effects), Cascade Charter technique, when NOT to use harness (+130-line TypeScript class, +3 community lessons)

### lang-refine (5 guides extended, all 100/100)
- `typescript-patterns.md` — Generic parameter defaults replace overload sprawl (defaults only fire when inference has no candidate — `f(123)` gives `T=123` not string default), `--stableTypeOrdering` diagnostic-only flag (25% overhead, use separate `tsconfig.check-7.0.json`), variance `in/out` annotations don't affect structural type behavior (misconception: does not enforce read-only) (+198 lines)
- `javascript-patterns.md` — `await` on non-Promise creates microtask overhead + subtle ordering shifts, module-level floating code breaks test isolation + serverless cold-start, `Promise.try` vs `Promise.resolve().then()` same-tick vs deferred scheduling distinction (+3 gotchas)
- `java-patterns.md` — `Object.wait()` pinning in Java 21–23 (fixed Java 24 JEP 491, missed alongside `synchronized`), `List.copyOf()` NPE on null elements (unlike `unmodifiableList`), `new Locale("en-US")` silent wrong locale (use `Locale.of()`), `String.chars()` returns `IntStream` not `Stream<Character>`, `Collectors.teeing()` dual aggregation, `Path.of()/Files` modern idioms, `Map.ofEntries()` (+4 gotchas, +3 idioms)
- `python-patterns.md` — `Unpack[TypedDict]` for `**kwargs` dedicated section (PEP 692, optional/required variants), `super()` pickling in Python 3.14 (unblocks proxy/delegation in task queues), `pow()` three-arg `__rpow__` fallback (Python 3.14), `NamedTuple` keyword-argument syntax removed Python 3.15 (+239 lines, +1 gotcha)
- `csharp-patterns.md` — `Channel<T>` fan-out/fan-in + `BoundedChannelFullMode` drop modes + `itemDropped` callback (concurrent writers with `SingleWriter:true` silently corrupts), sync-over-async bridge pattern (deadlock triangle: SyncContext + no `ConfigureAwait(false)` + blocking), `ToArray()` vs `ToList()` for async LINQ (`Task.WhenAll(items.Select(...))` without `ToArray()` runs tasks serially) (+255 lines)

---

## v1.16.0.10 — 2026-05-12 — nightly refinement run — 22 guides extended (cycle 7/100)

### qa-refine (5 guides extended, all 100/100)
- `playwright-patterns.md` — `npx playwright init-agents --loop=<vscode|claude|opencode>` AI agent project bootstrap (v1.56+), `worker.on('console')` service worker log capture + parallel-CI URL filter, `page.emulateMedia({contrast})` prefers-contrast testing (WebKit no-op noted), `expect(fn).toPass({intervals})` custom retry back-off arrays, `expect(page).toHaveURL(predicate)` function-based URL assertion, page-level `toMatchAriaSnapshot()` v1.60 enhancement, HTML reporter `noSnippets:true` large-suite size optimization, `page.close({reason})` diagnostic messages in Trace Viewer; gotchas: `toMatchAriaSnapshot()` locale drift, `toPass()` no state reset between retries, contrast emulation no-op WebKit, `init-agents` overwrites on re-run (+481 lines, +5 gotchas)
- `cypress-patterns.md` — `cy.intercept()` Middleware Routing (`middleware:true`) for global auth header injection without per-test duplication, `cy.press()` Focus Trap Testing for WCAG 2.1 SC 2.1.2 (why `cy.type('{tab}')` is ineffective), Cypress Cloud UI Coverage AI test suggestions (interaction vs code coverage), `cy.session()` Parallel CI Cache Scope (`cacheAcrossSpecs:true` is per-worker not per-run); gotchas: `cacheAcrossSpecs` false-sharing, `resourceType` deprecated Cypress 14, `validate()` fires before `setup()` on first warmup, Cloud Coverage throttles 50 elements/batch, `cy.press()` silent no-op on F1-F12 (+346 lines, +5 gotchas)
- `k6-patterns.md` — Browser Module Locator Composition (`locator.filter()`, `locator.all()`, `locator.nth()`), Browser Advanced Page APIs v1.4-1.6 (`page.waitForRequest/Event()`, `page.on('requestfailed')`, `frameLocator()`, `locator.evaluate()`), `locator.pressSequentially()` character-by-character typing (v1.5+), `k6 deps` CLI dependency analysis (v1.6+), `--new-machine-readable-summary` threshold-aware JSON (v1.5+), mcp-k6 AI integration Playwright-to-k6 conversion (v1.6+), OpenTelemetry stable graduation (from `--out experimental-opentelemetry`), PBKDF2 WebCrypto key derivation (v1.6+); gotchas: `require()` removed v1.4 (CommonJS dead), Chromium orphan leak + CI cleanup recipe, `--vus` silently ignored with `scenarios`, StatsD tag special-char silent drop (+987 lines, +5 gotchas)
- `detox-patterns.md` — `element.swipe()` `startNormalizedX/Y` precision control (pull-to-refresh/carousel patterns), Test tagging `[smoke]/[regression]` with `--testNamePattern` three-tier CI; iOS 18 "Precise Location" two-step permission breaks `by.system()` (fix: `preciselocation:'YES'`), `device.setStatusBar()` overrides persist across files (must call `resetStatusBar()` in `afterAll`), `element.longPress(0)` behaves as `tap()` on Android (800ms minimum), Expo SDK 53 requires Detox 20.9+, `--loglevel verbose` overflows GitHub Actions 50MB log buffer, `waitFor().whileElement().scroll('up')` skips SectionList sticky headers, `device.setOrientation()` no-op Android API 34+ ANGLE (fix: `swiftshader_indirect`) (+717 lines, +7 gotchas)
- `appium-wdio-patterns.md` — `isDisplayed()` CSS Visibility Option Flags v9.18.4 (`contentVisibilityAuto`, `opacityProperty`, `visibilityProperty`) for virtual-scroll detection, WebDriver BiDi Low-Level Network Commands v9.27.1 (`networkAddIntercept`, `networkContinueRequest`, `networkFailRequest`, `networkSetCacheBehavior`), `create-wdio` Interactive Project Scaffolding v9.17 wizard flow; gotchas: BiDi driver guard (`browser.isBidi`), stalled page if intercept unresolved (use try/finally), `networkSetCacheBehavior` does not clear existing cache, `urlPatterns` type distinction (+288 lines, +7 gotchas)

### qa-methodology-refine (12 guides extended, all 100/100)
- `test-pyramid-guide.md` — Node.js v22.18.0 (LTS) bare `node file.ts` works by default (decorator-heavy NestJS/Angular cannot use this path), Node.js 24 breaks `await t.test()` ordering (no longer returns Promise), Vitest 4.1 strict browser locators surface hidden multi-match defects on upgrade, Vitest 4.1 GitHub Actions Job Summary flaky-test permalink, Vitest 5.0 beta CI pipeline changes; gotchas: transitive `ERR_UNSUPPORTED_TYPESCRIPT_SYNTAX` from enum in helper file (+5 gotchas)
- `tdd-guide.md` — Vitest 4.1 `detectLeaks` per-test resource attribution, `vi.defineHelper()` removes helper frames from stack traces, `aroundEach/aroundAll` generator hooks for DB transaction TDD rollback (+344 lines)
- `bdd-guide.md` — Cucumber Expression advanced syntax (optional parts, alternation, custom parameter types), playwright-bdd v8.4.1 TypeScript strict mode types, DataTable cell escape rules, Background tags silently ignored pitfall (+395 lines)
- `test-isolation-guide.md` — `vi.setTimerTickMode('nextTimerAsync')` prevents `setInterval` live-lock in async tests, `vi.mockObject({spy:true})` auto-spy without manual `vi.fn()` per method, `test.override()` replaces deprecated `test.scoped`, `FixtureAccessError` diagnostics, `vi.doMock()` as AsyncDisposable (+535 lines)
- `test-data-guide.md` — Playwright 1.59 async disposables for fixture teardown, `routeFromHAR()` HAR drift detection pattern, `testProject.workers` per-project parallelism for data-heavy suites
- `contract-testing-guide.md` — tRPC CDC consumer pattern, Prisma/Drizzle state handler implementations, Vitest 2.x `singleThread` removal migration, dynamic `uuid()` in interactions triggers 200 unnecessary webhook builds/day
- `flakiness-guide.md` — Vitest 4.1 `retry({count, delay, condition})` infrastructure-only retry (condition as RegExp or function), Playwright `TestStepInfo.skip(condition?, description?)` step-level quarantine (v1.53), `testInfoError.errorContext` ARIA snapshot at failure time for lightweight diagnosis (v1.60) (+601 lines)
- `coverage-guide.md` — `coverage.reportOnFailure:false` silently loses data on first failure (use `:true`), Stryker `disableTypeChecks` v7.0 behavior change (+271 lines)
- `ci-cd-testing-guide.md` — Playwright v1.60 HAR-based request tracing for CI network capture, Vitest v5 breaking changes in CI pipelines (+303 lines)
- `accessibility-guide.md` — WCAG 2.2 ratified as ISO/IEC 40500:2025 enabling ISO procurement mandates, ACT Rules Format 1.1 W3C standard for auditable custom axe-core rules, Playwright 1.56 renders `<input>` placeholder in ariaSnapshot (snapshot mismatches + WCAG 3.3.2 detection), WCAG-EM 2.0 evaluation methodology scripted sampling; gotchas: CI sharding for axe scans (CPU-bound not I/O) (+4 gotchas, +4 sections)
- `shift-left-guide.md` — Vitest 4.1 `vi.defineHelper()` custom assertion stack trace precision, Vitest 4.1 fixture type inference builder pattern, Biome v2 test nursery rules (`useTestHooksInOrder`, `useTestHooksOnTop`, `noIdenticalTestTitle`, `useConsistentTestIt` — 50× faster than `@typescript-eslint`), `@typescript-eslint` v8.58 TypeScript 6 support (upgrade required before TS6 migration), Privacy by Design branded PII types (`RedactedString`) as GDPR/CCPA compile-time gate (+451 lines)
- `exploratory-guide.md` — Feature-flag two-state exploration pattern, `FeatureFlagOracleHarness` TypeScript class, AI co-pilot pairing for exploratory session debriefs (+470 lines)

### lang-refine (5 guides extended, all 100/100)
- `typescript-patterns.md` — TS 6.0 `noUncheckedSideEffectImports` now `true` by default (breaks CSS/polyfill side-effect imports silently), `libReplacement` default flipped, `Promise.allKeyed` Stage 2.7 proposal awareness
- `javascript-patterns.md` — `Promise.allKeyed` Stage 2.7, `Iterator.chunks()/windows()` Stage 2.7 lazy sliding window (+181 lines)
- `java-patterns.md` — Hexagonal Architecture port/adapter test structure, JPMS split package gotcha in multi-module testing, `instanceof` pattern chain vs sealed class + switch expression (+219 lines)
- `python-patterns.md` — `asyncio.CancelledError` swallowing anti-pattern in test teardown, `configparser.InvalidWriteError` (3.14), `operator.is_none()` / `is_not_none()` (3.14) (+202 lines)
- `csharp-patterns.md` — .NET 10 JIT struct promotion + stack allocation escape analysis, lambda `static` modifier for zero-allocation closures in test hot paths, `ActivitySourceOptions` for structured test telemetry (+553 lines)

---

## v1.16.0.9 — 2026-05-12 — nightly refinement run — 22 guides extended (cycle 6/100)

### qa-refine (5 guides extended, all 100/100)
- `playwright-patterns.md` — updateSourceMethod:'patch'/'overwrite'/'3-way' for CI snapshot review-first diffs (v1.50+), dialog handler must call accept()/dismiss() or page hangs, page.evaluateHandle() multi-handle destructuring, HiDPI/Retina deviceScaleFactor emulation, testResult.annotations per-retry (v1.52+); outer scope variables undefined in page.evaluate() gotcha (+341 lines, +2 gotchas)
- `cypress-patterns.md` — cy.prompt() BDD Gherkin loop caching (one AI call per N iterations), Module API expose+posixExitCodes orchestrator, cy.env() multi-key + log:false masked values; .invoke() throws on Promise-returning functions (Cypress 15 breaking change), cy.wait([aliases]) routeId crash (15.14.2 fixed 15.14.3), Chrome 137 --load-extension removed, cy.prompt() self-healing exhausts Cloud rate limits, experimentalStudio:true config error (flag removed 15.4+), injectDocumentDomain silent removal (+349 lines, +7 gotchas)
- `k6-patterns.md` — k6 Studio section (Record→Generate→Validate GUI, undocumented in file), K6_WEB_DASHBOARD CI hang (fix: K6_WEB_DASHBOARD_PORT=-1), WebSocket binaryType defaults to blob (k6 has no Blob, fix: arraybuffer), --stack mandatory for all cloud commands, --upload-only removed in v2.0 (+314 lines, +4 gotchas)
- `detox-patterns.md` — by.system() full dialog workflow (permissions/UIAlertController/UIActivityViewController), device.openURL() deep link warm+cold start, parallel worker sharding GitHub Actions matrix YAML, by.traits() iOS accessibility traits (15 constants), element.getAttributes() extended inspection (12 properties), device.shake() shake gesture; by.system() locale-sensitive labels, deep link cold-start race, parallel workers shared fixtures, getAttributes().value is string not boolean, getAttributes() null for off-screen, device.shake() no-op on physical devices (+921 lines, +6 gotchas)
- `appium-wdio-patterns.md` — browser.deepLink()/restartApp() native commands (v9.10, replaces execute patterns), maskingPatterns config-level redaction (v9.15), browser.emulate('onLine') navigator.onLine only (not network traffic), defineConfig() thin TypeScript wrapper, native DOM toMatchSnapshot() silent no-op on Appium native elements, @wdio/xvfb must precede @wdio/appium-service in services array (+8 sections, +25 gotchas)

### qa-methodology-refine (12 guides extended, all 100/100)
- `test-pyramid-guide.md` — Playwright Agents healer generates waitForTimeout() sleep anti-patterns (governance YAML added), TS 6.0 esModuleInterop always-true breaks import * as X (only surfaces in CI tsc), coverage.changed file-rename blind spot (pair with nightly full-coverage gate), Playwright v1.56–v1.60 series content: page.mark(), locator.mark(), browser.on('context'), toHaveCSS pseudo-element, WebSocket subprotocol, vi.defineHelper() stack traces
- `tdd-guide.md` — Zod v4 z.input<T>/z.output<T> test fixture TDD coverage gap (factory typed against output never exercises coercion path), using/await using scope-bound spy teardown (Symbol.dispose typed, TypeScript catches missing teardown at compile time), Neon DB per-test branching as AsyncDisposable (real Postgres isolation), Promise.try for sync-to-async TDD wrappers (+3 community gotchas)
- `bdd-guide.md` — Cucumber.js v13 SummaryFormatter/ProgressFormatter fully removed from public API (must implement Formatter interface directly), playwright-bdd strict arity checks fire at registration time not execution, @cucumber/messages 27→32 breaks custom report processors, Cucumber.js + playwright-bdd version matrix 2024-2026 (+312 lines)
- `test-isolation-guide.md` — vi.mockThrow()/mockThrowOnce() declarative error injection (Vitest 4.1), mock.withImplementation() block-scoped override auto-restored, Jest workerIdleMemoryLimit worker recycling prevents heap contamination, Jest resetModules:true global registry reset config, showSeed:true + randomize:true must be paired together, jest-util protectProperties() exempts globals from globalsCleanup sweep (+7 gotchas, +2 patterns)
- `test-data-guide.md` — Vitest 4.0 expect.schemaMatching inline factory output validation (catches z.email/z.uuid violations TypeScript misses), getSeed() aligns faker seed with Vitest run seed, experimental.viteModuleRunner:false surfaces __dirname injection bugs, Google "Construct with Collaborators, Call with Work" applied to factory design (+493 lines)
- `contract-testing-guide.md` — stateHandlers + requestFilter combination bug (silent 30s timeout, undocumented /_pactSetup workaround), Content-Length mismatch on empty {} body causes Express hang (delete req.headers['content-length']), duplicate uponReceiving silently overwrites earlier interactions, real credentials/PII in pact files security risk (+4 community lessons)
- `flakiness-guide.md` — Playwright MCP server (@playwright/mcp v1.59) for AI-assisted flakiness diagnosis, Vitest experimental.viteModuleRunner:false module singleton detection, mockThrow on async functions sync throw escapes async boundary, Trunk AI failure fingerprinting detects variant flakiness (30-50% more flaky tests surface) (+4 patterns)
- `coverage-guide.md` — Vitest 5.0 coverage.include bare directory names silent empty coverage (must use explicit globs), Stryker.NET 4.13 MTP runner keep-alive architecture, Qodo Cover (cover-agent) archived June 2025 + replacement strategy with surviving-mutant LLM prompts (+3 findings)
- `ci-cd-testing-guide.md` — Playwright v1.59 page.screencast first-class per-test video with chapter markers + await using disposable, act v0.2.79 --validate/--strict GitHub Actions workflow pre-flight checks (+280 lines, +2 patterns)
- `accessibility-guide.md` — aria-braille-equivalent rule (axe-core 4.11.0), @axe-core/playwright multi-selector array silently drops all but first selector, @axe-core/react silently fails in React 18+ with no error/warning (+395 lines, +3 gotchas)
- `shift-left-guide.md` — Vitest 4.1 aroundEach/aroundAll DB transaction rollback (parallel-test race condition fix), --detect-async-leaks deterministic CI failures (5-10% overhead, enable only in CI), v8 coverage @preserve suffix required (esbuild strips prefix form during TS transpilation)
- `exploratory-guide.md` — contract-aware API exploration pattern with SchemaOracleValidator TypeScript class (classifies missing-required/wrong-type/undocumented-field violations as HICCUPPS Claims oracle violations), undocumented API fields as unintentionally leaked internal data (~40% of cases)

### lang-refine (5 guides extended, all 100/100)
- `typescript-patterns.md` — TS 6.0 Removed vs Deprecated precision: "target":"es5" hard removed (ignoreDeprecations doesn't help), import assert hard removed (no escape hatch), esModuleInterop:false hard removed (always-enabled interop); ignoreDeprecations:"6.0" is 6-month migration window not permanent fix
- `javascript-patterns.md` — URLPattern Node.js 24 global (no polyfill), AsyncLocalStorage run() vs withScope() vs enterWith() comparison (enterWith() contaminates siblings), import attributes with {type:'json'} (assert removed), Node.js 24 dirent.path removal + Error.isError(), AsyncContextFrame performance; gotchas #46-50 (+307 lines)
- `java-patterns.md` — WireMock stateful scenario stubs (429→retry→200), Awaitility untilAsserted/ignoreExceptions (never mix with Thread.sleep), Spring @WebMvcTest (5-10x faster than @SpringBootTest) + @DataJpaTest Replace.NONE + Testcontainers (H2 dialect false passes on JSON/window functions), Stable Values JEP 502 Java 25 preview (+408 lines)
- `python-patterns.md` — pathlib.copy()/copy_into()/move()/move_into() (3.14), HTTPSServer (3.14), os.readinto() zero-copy fd reads (3.14), date.strptime()/time.strptime() (3.14), contextvars.Token context manager (3.14), Python 3.14 CLI -X importtime=2; multiprocessing forkserver Linux default breaks fork-inherited state, int() no longer delegates __trunc__(), NotImplemented boolean TypeError (+367 lines)
- `csharp-patterns.md` — C# 14 extension blocks (instance properties/static/operators/generic), field-backed properties INotifyPropertyChanged+lazy init+struct readonly, null-conditional LHS assignment with compound ops, first-class Span implicit conversions (covariance+betterness rules); Reverse() returns void in C# 14 (most widely reported migration break), xUnit Assert.Equal ambiguity, covariant array crash, expression tree LINQ provider surprise, field shadows class member (+474 lines, +7 gotchas)

---

## v1.16.0.8 — 2026-05-12 — nightly refinement run — 22 guides extended (cycle 5/100)

### qa-refine (5 guides extended, all 100/100)
- `playwright-patterns.md` — page.requestGC() WeakRef memory leak detection (v1.48+), tracing.group()/groupEnd() Trace Viewer action grouping (v1.49+), ControlOrMeta cross-platform keyboard modifier (v1.45+), webServer.gracefulShutdown (v1.50+), multiple globalSetup/globalTeardown array syntax (v1.49+), screenshot:'on-first-failure' (v1.49+); page.clock.install() must precede page.goto() gotcha, webSocketRoute.onMessage() disables auto-forwarding, page.requestGC() Chromium-only (+384 lines, +3 gotchas)
- `cypress-patterns.md` — cy.url()/cy.location() use CDP/BiDi in Cypress 15 (works in cy.origin()), cy.fixture() cache invalidation fix (Cypress 15 — was silently stale in 14), defaultBrowser config (v13.16+) aligns local dev with CI Chrome, cy.wrap() circular reference hang (fixed 15.7.0), synchronous XHR + cy.intercept() deadlock (fixed 15.8.0) (+82 lines, +4 gotchas)
- `k6-patterns.md` — CSRF token extraction with k6/html parseHTML(), http.asyncRequest + Promise.all concurrent HTTP, coordinated omission gotcha (constant-vus masks SUT degradation — use constant-arrival-rate), AWS SigV4 for Amazon Managed Prometheus (+237 lines)
- `detox-patterns.md` — WebView by.web() matchers (9 selector types, full web element API), visual regression baseline helper, JUnit XML CI reporting with jest-junit shard-specific outputName, device.resetContentAndSettings() deep factory reset, per-configuration network blacklist; Android 15 predictive back gesture assertion change, RN 0.78+ StrictMode double-render, Hermes debugger port 8083 CI shard conflict (+5 patterns, +7 gotchas)
- `appium-wdio-patterns.md` — Appium 3 full 37-command rename table (appium prefix) + WDIO v9.26 wrapper, screen recording API iOS+Android with failure-only hook, browser.on() event monitoring table, addInitScript()+emit() BiDi DOM event streaming, TypeScript 7 erasableSyntaxOnly migration guide, disableElementImplicitWait v9.27.1 fix, Allure historyId multi-platform fix (+485 lines, +20 gotchas)

### qa-methodology-refine (12 guides extended, all 100/100)
- `test-pyramid-guide.md` — Vitest 3.2 sequence.groupOrder fail-fast (replaces &&-chained commands), using vi.spyOn() auto-restore (TS 5.2 Symbol.dispose), TS 5.8 --module node18 + import with breakage (+126 lines, +2 gotchas)
- `tdd-guide.md` — Feature flags FakeFlagReader disabled-state testing (Google TotT Mar 2026), one-lookup Map pattern vs double Map.has()+get()! smell (Google TotT Apr 2026), TCR strict mode with tsc --noEmit compile gate (+3 community gotchas)
- `bdd-guide.md` — playwright-bdd next: junit-modern alias deprecated, tinyglobby replaces fast-glob, bddgen worker concurrency capped at CPU/2 (OOM fix for GitHub Actions), @cucumber/messages 27→32 bump, Cucumber JSON reporter skips attachments by default (180MB→3MB), Gherkin "1922" technology-agnostic heuristic, vivid character names recommendation (+286 lines)
- `test-isolation-guide.md` — Vitest 4.1 aroundEach DB transaction rollback with Prisma, detectAsyncLeaks per-test resource attribution, onCleanup builder pattern, viteModuleRunner: false native Node mode tradeoffs, jest.onGenerateMock() file-scope accumulation gotcha, jest.retryTimes retryImmediately:true breaks ordering, aroundAll breaking change (receives fixture context not Suite) (+7 gotchas, +2 patterns)
- `test-data-guide.md` — Vitest 4.1 TestRunner.matchesTags() conditional DB seeding (pre-commit 45s→8s), coverage.changed modified-file-only reports, coverage ignore block comments (start/stop for both providers), --detectAsyncLeaks for factory module-scope Pool leaks (+4 patterns)
- `contract-testing-guide.md` — pact-js v16.3.0 race condition under parallel Vitest (mockServerMatchedSuccessfully() false intermittently, workaround: singleThread:true), no built-in provider interaction filter (by-description/by-state not supported) (+2 community lessons)
- `flakiness-guide.md` — Playwright v1.59 CLI trace subcommands (actions/action/snapshot --grep, 15min→4min triage), --last-failed targeted rerun, Vitest 3.2 using vi.spyOn() auto-restore (Symbol.dispose), Vitest 3.2 context.signal AbortSignal cleanup on timeout (+367 lines, +4 patterns)
- `coverage-guide.md` — Correction: /* istanbul ignore next -- @preserve */ (suffix) is canonical Vitest format (prefix still works), multi-line start/stop block suppression directives, Stryker VS Code plugin (v9.3.0+ MSP, gutter annotations, incremental:true required) (+3 findings)
- `ci-cd-testing-guide.md` — Fixed deprecated Vitest 4.0 poolOptions.threads.maxThreads→maxWorkers in 2 live code examples (was silently ignored causing integration test parallelization), trace:'retain-on-failure-and-retries' (v1.54), test.abort() CI guard-rail fixtures (exit code 1 vs test.skip() silent green), Vitest 4.0 pool migration section (+3 new sections)
- `accessibility-guide.md` — Correction: page.accessibility.snapshot() fully removed in Playwright 1.57 (not just deprecated — breaking change), ariaSnapshot({ depth }) limits brittleness, ariaSnapshot({ mode:'ai' }) for LLM consumption, ariaSnapshot({ boxes:true }) layout coordinates, global toMatchAriaSnapshot playwright.config.ts (+2 gotchas)
- `shift-left-guide.md` — TS 5.9 noUncheckedSideEffectImports as new tsc --init default, ArrayBuffer/Buffer breaking change (Buffer no longer assignable to ArrayBuffer), import defer syntax, ~11% tsc --noEmit perf improvement (Zod/tRPC codebases) (+193 lines)
- `exploratory-guide.md` — OWASP LLM Top 10 2025 full charter mapping table (LLM01-LLM10), TypeScript generateLLMSecurityCharter() utility, LLM-as-judge oracle pattern (judge must differ from agent under test), synthetic monitoring gaps as exploration scheduling signal (+358 lines, +3 community lessons)

### lang-refine (5 guides extended, all 100/100)
- `typescript-patterns.md` — Zod v4 migration (z.toJSONSchema, z.registry, z.file, z.prefault, z.interface; stricter URL/base64; tuple default materialization), TS 5.9 MDN DOM API summary descriptions with deprecation markers, WeakMap.getOrInsert/getOrInsertComputed (ES2025), fork-ts-checker vs --noCheck CI pitfall
- `javascript-patterns.md` — Node.js 22 require(ESM) + module-sync exports condition, fs.glob/globSync built-in (no npm), path.matchGlob (v23+), v8.queryObjects() memory leak detection, SuppressedError from using blocks, node --run limitations, url.parse() removed in Node 24; gotchas #42-45 (+267 lines)
- `java-patterns.md` — StampedLock idiom (optimistic read pattern, virtual thread caveats), SequencedMap (Java 21 firstEntry/lastEntry/reversed/putFirst), CopyOnWriteArrayList O(n²) in write-heavy loops gotcha, WeakHashMap interned-key never-evicts gotcha (+151 lines)
- `python-patterns.md` — annotationlib deep-dive (Format enum, ForwardRef deferred, get_type_hints() migration), t-string custom processors (HTML escaping, SQL parameterization, shell quoting), concurrent.interpreters/InterpreterPoolExecutor with data-sharing rules; gotcha #34 (t-string naive concat identical to f-string), #35 (InterpreterPoolExecutor pickle constraints) (+473 lines)
- `csharp-patterns.md` — ASP.NET Core 10 OpenAPI 3.1 YAML output + nullable schema breaking change (nullable:true→["T","null"]), Cookie Auth 401/403 direct response (no more login redirect for API endpoints), IMemoryPoolFactory<T> DI-registered pools, X509Certificate2Collection SHA-256/SHA-3, Blazor JS GetValueAsync/SetValueAsync/InvokeConstructorAsync (+278 lines)

---

## v1.16.0.7 — 2026-05-12 — nightly refinement run — 22 guides extended (cycle 4/100)

### qa-refine (5 guides extended, all 100/100)
- `playwright-patterns.md` — toHaveAccessibleName/toHaveRole/toHaveAccessibleDescription (v1.44, were undocumented 2+ years), --test-list/--test-list-invert (v1.56) for enterprise TMS, page.route() misses first popup request (use context.route()), toMatchAriaSnapshot placeholder gotcha (--update-snapshots=changed not all) (+10 patterns)
- `cypress-patterns.md` — React SSR hydration bootstrapScript for Next.js/Remix CT, Cypress.ElementSelector.defaults() selectorPriority, cy.intercept() delay integer overflow (fixed 15.13.1), base target="_top" iframe break (fixed 15.14.2), allowCypressEnv:false blocks @cypress/grep + cypress-axe (+4 patterns, +4 gotchas)
- `k6-patterns.md` — browser devices object emulation (v0.54+), Locator auto-retries in v2.0 (selectors wait 30s not fail instantly — reduce defaultActionTimeout), http.get() extra-arg warning exposes silent v1.x scripting errors (+2 gotchas)
- `detox-patterns.md` — waitFor chaining silently replaces not combines, Android 14 permission dialog label changes (API 34+ breaks by.system().label()), RN 0.77+ Hermes-canary crash, device.installApp() doesn't grant permissions, missing Hermes source maps (+8 patterns, +5 gotchas)
- `appium-wdio-patterns.md` — expect.soft() soft assertions (WDIO v9+), Appium 3 Node 20+ migration, multiRemoteBrowser rename (silent undefined), pre-built WDA CI cache, browser.throttleCPU() WebView-only, toggleNetworkSpeed() real-device caveat (+9 sections, ~25 gotchas, 196+ total sections)

### qa-methodology-refine (12 guides extended, all 100/100)
- `test-pyramid-guide.md` — TS 6.0 types:[] breaks test tsconfig (runtime not compile error), Vitest 5.0.0-beta.2 breaking changes (pin to ^4.1), Playwright tracing.startHar() HAR-based CI replay
- `tdd-guide.md` — Correction: noUncheckedSideEffectImports is TS 5.6 (not 5.9) and OFF by default; TS 6.0 release (May 11 2026) breaks Vitest/Jest globals; Google Testing Blog "Construct with Collaborators, Call with Work" principle
- `bdd-guide.md` — Cucumber.js upcoming SummaryFormatter/ProgressFormatter deprecation, printAttachments→includeAttachments rename, playwright-bdd next $step.docStringType, v8.4.2 multiple step decorators (zero-downtime Gherkin migration)
- `test-isolation-guide.md` — Vitest 4.0 vi.restoreAllMocks() no longer resets call history (add clearMocks:true), singleFork/singleThread removal + isolate:false silent module isolation disable, test.extend() fixture hooks stronger teardown guarantee
- `test-data-guide.md` — Vitest 4.1 builder pattern for test.extend() (return-based, onCleanup()), aroundEach transaction-per-test isolation, test.override() per-suite fixture substitution, vi.defineHelper() call-site stack traces, coverage.all removal (factory files silently excluded)
- `contract-testing-guide.md` — GIGO anti-pattern for POST/PUT (echo sent fields in response), over-specified validation rules anti-pattern, pact-js v16.3.1 Content-Type extraction fix
- `flakiness-guide.md` — Vitest 4.1 aroundEach/aroundAll transaction rollback (eliminates afterEach crash gap), Playwright HAR recording tracing.startHar() for HTTP waterfall, --detect-async-leaks catches AsyncLocalStorage leaks, setStorageState() auth reset saves 30-60s per test
- `coverage-guide.md` — Vitest 5.0.0-beta.2 V8 tracks node:worker_threads (coverage drops on upgrade — accurate), blob reporter path change (.vitest-tmp/→.vitest/blob/), coverage.instrumenter misuse risk
- `ci-cd-testing-guide.md` — webServer.wait named capture groups (v1.57+), --last-failed retry (25→3-4 min), aroundEach/aroundAll, --detect-async-leaks, test tags + --tags-filter, coverage.changed, Vitest 4.x defineWorkspace→silent "0 tests", Playwright HTML Speedboard, GitHub Actions custom runner images (March 2026 GA)
- `accessibility-guide.md` — toMatchAriaSnapshot() (v1.49+) supersedes legacy JSON API, toHaveAccessibleErrorMessage() computed text vs HTML attribute, getByRole({description}) (v1.60+), React 19 form actions auto-reset timing risk
- `shift-left-guide.md` — OWASP Top 10:2025 A03 Supply Chain (Bybit $1.5B + Shai-Hulud npm worm), A10 Exceptional Conditions (useUnknownInCatchVariables), Vitest 4.0 migration table, eslint-plugin-security v4 (recommended-legacy removed)
- `exploratory-guide.md` — inverted test pyramid for AI features (50-70% exploratory budget), context drift requires full multi-turn oracle harness, Crescendo red-team technique (constraint erosion after 8-15 adversarial turns)

### lang-refine (5 guides extended, all 100/100)
- `typescript-patterns.md` — TS 5.9 inference tightening (may surface new errors), --moduleResolution bundler + --module commonjs TS 6.0 migration path, isolatedModules vs isolatedDeclarations distinction, tsconfig glob changes invalidate incremental cache
- `javascript-patterns.md` — RegExp inline modifiers (?i:) ES2025, duplicate named capture groups ES2025, Map.getOrInsert/getOrInsertComputed ES2026, JSON.parse context.source (64-bit integer precision), node: protocol prefix (npm shadowing prevention)
- `java-patterns.md` — FFM API (JEP 454 Java 22, replaces JNI), Class-File API (JEP 484 Java 24, replaces ASM), Java Testing Patterns section (JUnit 5, Mockito STRICT_STUBS, AssertJ, Testcontainers), Spring @Transactional self-invocation gotcha, finalize() removal Java 18 → Cleaner
- `python-patterns.md` — asyncio.timeout()/timeout_at() (3.11+, dynamic rescheduling), eager task execution eager_start=True (3.12+), os.reload_environ() (3.14), fire-and-forget create_task() GC gotcha
- `csharp-patterns.md` — EF Core 10 LeftJoin/RightJoin (replaces GroupJoin+SelectMany), EF1002 analyzer (compile-time SQL injection warning), JsonSerializerOptions.Strict (.NET 10, replaces 4 manual options)

---

## v1.16.0.6 — 2026-05-12 — nightly refinement run — 22 guides extended (cycle 3/100)

### qa-refine (5 guides extended, all 100/100)
- `playwright-patterns.md` — component.update()/unmount() CT lifecycle, testStepInfo.titlePath (v1.55+), sessionStorage storageState limitation + addInitScript workaround, APIRequestContext disposal race guard, vi.mock CT isolation (runs in Node not browser) (+250 lines)
- `cypress-patterns.md` — cy.prompt() AI test authoring (15.13+), Cypress.stop() fail-fast, Firefox WebDriver BiDi CDP guard, justInTimeCompile default (14+), experimentalRunAllSpecs CT (15.9+), --posix-exit-codes/--pass-with-no-tests CLI flags (+8 patterns, +8 gotchas)
- `k6-patterns.md` — corrected false claim: k6/net/grpc supports bidirectional streaming since v0.49.0; gRPC client-side/bidi streaming, reflection (no .proto), health check setup() gate, BrowserContext auth state sharing (not serializable across VUs) (+250 lines)
- `detox-patterns.md` — Android GitHub Actions CI (AVD API 31 + swiftshader_indirect mandatory), MSW 2.x for RN network interception, RN 0.76+ New Architecture selector name changes, 10.0.2.2 vs localhost + reversePorts (+3 gotchas)
- `appium-wdio-patterns.md` — @wdio/mcp MCP server (Feb 2026, XML page source 2 vs 600+ calls), getPerformanceData() jagged array return type correction, toggleAirplaneMode v9 explicit boolean, network toggles rejected on cloud farms (+13 sections, +28 gotchas, 358 total)

### qa-methodology-refine (12 guides extended, all 100/100)
- `test-pyramid-guide.md` — Vitest 3.x→4.x correction, expect.schemaMatching (Zod inline), --detect-async-leaks (fixes 20–40% false flakiness from NestJS/TypeORM handle leaks), Playwright v1.60 test.abort() + await using
- `tdd-guide.md` — TS 5.9 noUncheckedSideEffectImports (silent false-green imports), isolatedModules: true default, Vitest 4.0 verbose sequential-everywhere, typed test.extend() fixture context
- `bdd-guide.md` — Cucumber.js v12.7.0 env var fix in parallel workers (secrets undefined on v12.0–12.6 — upgrade immediately), playwright-bdd v8.0 missingSteps: 'pending', v12.8.0 externalise for S3 attachments; fixed truncated file (Additional Resources was missing)
- `test-isolation-guide.md` — jest.replaceProperty() for typed property isolation, jest.isolateModulesAsync() ESM requirement, Vitest forks vs threads pool isolation tradeoff
- `test-data-guide.md` — Playwright mergeTests() modular fixture composition, {box:true}/{box:'self'} fixture hiding, Vitest 4.x singleThread removal + VITEST_MAX_WORKERS env var rename
- `contract-testing-guide.md` — pact-js v16 addGraphQLInteraction() V4 DSL (replaces brittle regex), PactFlow MCP Server, AI over-specification gotcha (40% use exact instead of like())
- `flakiness-guide.md` — Vitest 4.1 tags with per-tag retry (replaces manual quarantine), Playwright testProject.workers: 1 for flaky suite isolation, webServer.wait regex (v1.57) DB migration race fix
- `coverage-guide.md` — Vitest 4.1 coverage.changed (diff coverage), autoUpdate CI footgun, excludeAfterRemap (phantom tslib in NestJS), Stryker 9.6.1 hitcount fix for Vitest 4.1 (perTest scores were wrong)
- `ci-cd-testing-guide.md` — --fail-on-flaky-tests strict gate (nightly-first rollout), captureGitInfo + fetch-depth:0 requirement, per-project workers (v1.52 OOM fix), testConfig.tsconfig (path-alias fix), Vitest v3.2 workspace→projects rename
- `accessibility-guide.md` — axe-core 4.11.0 RGAA tags (French public-sector beyond WCAG), 4.11.1 open shadow DOM (Shoelace/Lit violations surface), oklch/oklab contrast change, WCAG 3.0 confirmed 2028+ timeline
- `shift-left-guide.md` — Node.js 23.6.0 stable --strip-types (CI examples corrected from --experimental-), Vitest 3.x line-number filtering (vitest spec.ts:42)
- `exploratory-guide.md` — Playwright UI Mode/Trace Viewer as exploratory tools (60%→90% reproducibility), LLM oracle statistical failure-rate model, behavior-envelope charter framing for AI features

### lang-refine (5 guides extended, all 100/100)
- `typescript-patterns.md` — --explainFiles/--traceResolution diagnostics, disableReferencedProjectLoad monorepo memory, TS 6.0 module→namespace hard error, --ignoreConfig file-level tsc, ts5to6 migration tool, selective annotation strategy
- `javascript-patterns.md` — Iterator.zip/zipKeyed Stage 3 ("strict" mode gotcha), Atomics.pause Stage 3 spinlock, import source Wasm phase imports, Symbol.metadata (replaces reflect-metadata, mixing causes double-registration)
- `java-patterns.md` — Java 24 JEP 491 lifts synchronized pinning restriction (major correction), BigDecimal.equals() scale gotcha, double/float money trap, Record Wither Pattern, Java 25 unnamed classes (JEP 477)
- `python-patterns.md` — compression.zstd stdlib (3.14), heapq max-heap functions (3.14), multiprocessing fork+thread deadlock gotcha
- `csharp-patterns.md` — C# 14 file-based apps (#!/#: + inline NuGet), ASP.NET Core 10 AddValidation/[ValidatableType] source-gen, TypedResults.ServerSentEvents, Blazor [PersistentState], WebSocketStream (.NET 10), field keyword naming conflict

---

## v1.16.0.5 — 2026-05-12 — nightly refinement run — 22 guides extended (cycle 2/100)

### qa-refine (5 guides extended, all ≥ 99/100)
- `playwright-patterns.md` — locator.highlight leak in headed mode, ariaSnapshot assertion boxes for AI-based selector healing (+321 lines)
- `cypress-patterns.md` — Svelte 5 runes CT silent-failure, glibc 2.31 requirement for Cypress 14 on Ubuntu 18/20, `origin` route-target correction (99→100/100)
- `k6-patterns.md` — k6 v2.0.0 final: HTTP API server opt-in (`--address` required), cloud secrets auto-injection risk with `--local-execution`, Readable Streams API section (+203 lines)
- `detox-patterns.md` — Detox 20 `withTimeout` default 6000ms note, `clearText` caveat on secureTextEntry, multi-app waitForBackgroundOrSuspended (+248 lines)
- `appium-wdio-patterns.md` — enhanced context switching deep-dive, `touchId` Simulator-only caveat, clipboard read base64-wrapped binary, WDIO v9 `browser.url()` await enforcement (+474 lines, 10,794 total)

### qa-methodology-refine (12 guides extended, all 100/100)
- `accessibility-guide.md` — WCAG 2.5.7 Dragging Movements SC, TS 6.0 jest-axe `types: []` break, axe-core 4.12 `preload` option (+994 lines)
- `flakiness-guide.md` — `page.consoleMessages()` v1.56 API, Playwright `captureGitInfo` for CI trace attribution, flaky-test GitHub Actions matrix retry pattern (+538 lines)
- `shift-left-guide.md` — langwatch/scenario AI agent adversarial testing, TS 6.0 migration gate in pre-commit, Semgrep 1.90+ YAML syntax breaking change (+416 lines)
- `coverage-guide.md` — Stryker default bug fix: `prioritizePerformanceOverAccuracy` is `true` by default (not false as previously documented)
- `contract-testing-guide.md` — pact-js v16.4 `addInteractionReference`, corrected webhook event type (`contract_published` not `contract_created`)
- `test-data-guide.md` — Vitest 4.0 `poolOptions` deprecation: `forks`/`threads` deprecated → `pool` API migration guide
- `ci-cd-testing-guide.md`, `tdd-guide.md`, `bdd-guide.md`, `test-isolation-guide.md`, `test-pyramid-guide.md`, `exploratory-guide.md` — incremental improvements, refreshed community signal

### lang-refine (5 guides extended, all 100/100)
- `csharp-patterns.md` — `FrozenDictionary`/`FrozenSet`, `SearchValues<T>` SIMD, `TimeProvider` for test-clock, `SseParser` SSE streaming (+375 lines)
- `java-patterns.md` — Java 24: Module Imports JEP 476, Flexible Constructor Bodies JEP 492, primitive-type patterns preview
- `typescript-patterns.md`, `javascript-patterns.md`, `python-patterns.md` — incremental improvements, refreshed community signal

---

## v1.16.0.4 — 2026-05-12 — nightly refinement run — 22 guides extended (cycle 1/100), learning-sources +36 new sources

### learning-sources catalog (+36 sources, 327 → 363 entries)
- QA tools +12: Playwright assertions/debug/frames/downloads/pages, Vitest config/API, k6 HTTP/2, cypress-realworld-app, httpbin, Step CI, tRPC testing
- QA methodology +7: pytest parametrize, Cucumber anti-patterns, 4× Martin Fowler bliki entries, nektos/act
- Languages +8: TypeScript template literals/utility types, C# patterns/LINQ, Go effective/testing flags, Java Streams, Rust Clippy
- Security/A11y/AI +9: OWASP Cheat Sheet Series, OWASP AI Security, OWASP SAMM, NIST SSDF, Snyk, Semgrep, TruffleHog, axe-core API, DeepEval

### qa-refine (3 guides extended, all 100/100)
- `playwright-patterns.md` — v1.60 APIs: `locator.drop()`, `test.abort()`, `tracing.startHar()`, `getByRole description`, `toHaveCSS pseudo`, BrowserContext lifecycle events (+332 lines)
- `cypress-patterns.md` — Cypress 14/15: `cy.press()` native keyboard, `cy.env()` secure vars, `exitCode` rename, Firefox CDP removed, Angular 21 zoneless CT (+550 lines)
- `k6-patterns.md` — HTTP/2 protocol: ALPN negotiation, `r.proto` assertion, VU sizing math, GOAWAY `error_code=1610` (+157 lines)
- `detox-patterns.md` — iOS PickerView `scrollPickerViewToRowIndex`, `jestExpect` alias gotcha, Android slider no-op (+226 lines)
- `appium-wdio-patterns.md` — `browser.emulate()`, WDIO v9 migration, `trackSelectorPerformance`, `scrollIntoView` native options, Allure v3 `ALLURE_TESTPLAN_PATH` (+580 lines, 10,320 total)

### qa-methodology-refine (12 guides extended, all 100/100)
- `ci-cd-testing-guide.md` — Testcontainers Cloud Turbo mode, file-mount limitation
- `tdd-guide.md` — Beck/DHH/Fowler Investment Framework, 2026 Google TotT
- `bdd-guide.md` — Feature-coupled steps anti-pattern, conjunction steps, Discovery→Formulation→Automation
- `test-isolation-guide.md` — Jest 30 `globalsCleanup`, `using spy` TypeScript 5.2 auto-restore, Vitest `vi.stubEnv`/`vi.stubGlobal`
- `test-data-guide.md` — faker v10 ESM-only migration, UUID v7 `faker.string.uuid({version:7})`, Self-Initializing Fake (MSW v2)
- `contract-testing-guide.md` — pact-js v16: Node ≥20, export renames, wrapper library co-upgrade
- `flakiness-guide.md` — `failOnFlakyTests: !!process.env.CI` (v1.52), `retain-on-failure-and-retries` trace (v1.59), Vitest 4 screenshot OS-baseline
- `coverage-guide.md` — Stryker 9.5.1 `testFiles`, Vitest 4 `enableCoverage` API, AI-agent `json-summary` gotcha
- `accessibility-guide.md` — jest-axe v10, axe-core 4.11.4 fixes, Next.js App Router route announcer, RSC ARIA boundaries
- `shift-left-guide.md` — IAST runtime taint tracking, `nektos/act` local CI
- `test-pyramid-guide.md` — Fowler 5-layer microservice strategy, Neon DB branch-per-CI-run, Vitest `defineProject` type-safe config
- `exploratory-guide.md` — WCAG 2.2 charter design, defect prediction model, charter dependency graph (+644 lines)

### lang-refine (5 guides extended, all 100/100)
- `typescript-patterns.md` — Template literal types deep-dive, complete 22-row utility types reference (95→100/100)
- `javascript-patterns.md` — ES2026: `Math.sumPrecise()`, `Uint8Array.toBase64()`/`.toHex()`, Stage 3 Decorators warning
- `java-patterns.md` — Virtual thread + `synchronized` pinning (Java 21), ORM N+1 lazy loading
- `python-patterns.md` — `Concatenate`+`ParamSpec`, TypeVar bound vs constraint, Python 3.14 `map(strict=True)`
- `csharp-patterns.md` — `Task.WhenAny` double-await pitfall, C# 14 compound assignment operators

---

## v1.16.0.3 — 2026-05-08 — deep refine run (30-iter cap) — 25 reference guides written/updated

### qa-refine (17 guides, all ≥ 95/100)

**New guides (14):**
- `playwright-advanced.md` — retries, annotations, config, emulation, timeouts, parameterize, CI (96/100)
- `vitest-advanced.md` — coverage, mocking, snapshots, workspace, browser mode, type testing, CLI (96/100)
- `k6-websockets.md` — k6/websockets + k6/ws, concurrent connections, density testing (96/100)
- `gatling-patterns.md` — JS/TS SDK, simulation, injection profiles, assertions (95/100)
- `wiremock-patterns.md` — request matching, templating, scenarios, fault injection (95/100)
- `msw-patterns.md` — REST/GraphQL/WebSocket, browser/Node.js, per-test overrides (96/100)
- `allure-patterns.md` — steps/labels/links/attachments/parameters/history/CI (95/100)
- `stagehand-patterns.md` — act/extract/agent, hybrid Playwright integration (95/100)
- `selenium-patterns.md` — TypeScript, POM, explicit waits, Actions API (95/100)
- `webdriverio-appium-patterns.md` — WebDriverIO v9 + Appium iOS/Android, gestures, contexts (95/100)
- `detox-patterns.md` — matchers, lifecycle, auto-sync, dark mode, artifacts (95/100)
- `maestro-patterns.md` — YAML flow structure, sub-flows, CI, environment vars (95/100)
- `jmeter-patterns.md` — Thread Groups, HTTP, CSV, extractors, non-GUI CI (95/100)
- `locust-patterns.md` — HttpUser, FastHttpUser, TaskSets, distributed, CI (95/100)

**Upgraded guides (3):**
- `playwright-aria-visual-snapshots.md` — 88 → 96/100 (+CI golden file workflow)
- `k6-advanced-studio-api-disruptor-experimental-secrets.md` — 85 → 96/100 (+install, RBAC, gotchas)
- `cypress-network-requests-github-actions.md` — 86 → 96/100 (+WebSocket interception, Smart Orchestration)

### qa-methodology-refine (3 guides updated)

- `test-framework-guide.md` — 88 → 97/100: +Spring Boot test slices, Testcontainers Cloud, AssertJ deep-dive, Pact JUnit 5 extension, CI pyramid enforcement, JUnit 5→6 migration checklist
- `flakiness-guide.md` — 100/100: +pytest cross-language section (xfail quarantine, rerunfailures, randomly)
- `test-data-guide.md` — 100/100: +Neon DB branch-per-test pattern, Testcontainers Cloud singleton + Turbo mode

### lang-refine (5 guides updated, all 10 at 100/100)

- `typescript-patterns.md` — +Mapped Types deep-dive (modifiers, key remapping, template literals, utility impls)
- `csharp-patterns.md` — +Nullable Value Types deep-dive (T?/Nullable<T>, lifted operators, boxing behavior)
- `javascript-patterns.md` — +Faker.js realistic test data (seeding, locales, factory pattern)
- `python-patterns.md` — +factory_boy test factories (DjangoModelFactory, SQLAlchemy, traits, associations)
- `java-patterns.md` — +REST Assured API testing DSL (given/when/then, GPath, auth, Spring MockMvc)

---

## v1.16.0.2 — 2026-05-08 — nightly refinement run — 45 new catalog sources (313 → 327 + 14 via CloakBrowser test)

### Catalog updates (learning-sources/)

- **qa-tools.md** — +9 sources: Playwright projects/emulation/CI/timeouts/parameterize/TypeScript, k6 WebSockets protocol, Vitest CLI + reporters
- **qa-methodology.md** — +2 sources: pytest flaky test guide, Testcontainers getting-started guides
- **languages.md** — +2 sources: TypeScript mapped types, C# nullable value types
- **security-a11y-ai.md** — +1 source: NIST AI Risk Management Framework (airc.nist.gov)

### CloakBrowser integration verified

`bin/cloak-fetch.sh` confirmed working: auto-installs `cloakbrowser` via pip, fetches page
text via stealth Chromium, exits 1 on unreachable URLs. Batched URL verification (single
Bash call for all candidates) eliminates per-URL permission prompts in nightly runs.

---

## v1.16.0.1 — 2026-05-07 — nightly refinement run — 24 new catalog sources, 8 reference guides updated

### Catalog updates (learning-sources/)

- **qa-tools.md** — +10 sources: Playwright aria snapshots, visual comparisons, v1.59 release notes; k6 Studio, JS API, xk6-disruptor, experimental modules, secrets module; Cypress network requests + GitHub Actions CI guide
- **qa-methodology.md** — +2 sources: Pact Plugin Framework (gRPC/Protobuf/WebSocket contracts); JUnit 5/6 User Guide
- **languages.md** — +7 sources: TypeScript 5.8/5.9/6.0 release notes; Python 3.13/3.14 what's new; Kotlin 2.0/2.1.20 what's new
- **security-a11y-ai.md** — +5 sources: OWASP LLM Top 10 2025 + GenAI guide; Microsoft PyRIT; pa11y-ci; IBM Equal Access

### Reference guides written/updated

- `qa-refine/references/playwright-aria-visual-snapshots.md` — ARIA snapshot testing, visual golden files, v1.59 Screencast API (score: 88/100)
- `qa-refine/references/k6-advanced-studio-api-disruptor-experimental-secrets.md` — k6 Studio HAR workflow, full JS API, fault injection, experimental/secrets modules (score: 85/100)
- `qa-refine/references/cypress-network-requests-github-actions.md` — cy.intercept() stubs, GraphQL helpers, GitHub Actions matrix parallelization (score: 86/100)
- `qa-methodology/references/contract-testing-guide.md` — +Pact Plugin Framework section: gRPC/Protobuf consumer+provider patterns, matching rules, CI gotchas (score: 89/100)
- `qa-methodology/references/test-framework-guide.md` — new: JUnit 5/6 full annotation reference, TDD mapping, test pyramid placement, migration from JUnit 4 (score: 91/100)
- `lang-refine/references/typescript-patterns.md` — +TS 5.8/5.9/6.0: erasableSyntaxOnly, import defer, new compiler defaults, Temporal API, RegExp.escape (score: 100/100)
- `lang-refine/references/python-patterns.md` — +Python 3.13/3.14: TypeIs, TypeVar defaults, t-strings, deferred annotations, InterpreterPoolExecutor (score: 100/100)
- `lang-refine/references/kotlin-patterns.md` — +Kotlin 2.0/2.1.20: K2 smart casts, AtomicInt/Long, kotlin.time.Clock, UUID, Gradle Isolated Projects (score: 100/100)

---

## v1.16.0.0 — 2026-05-06 — 17 new skills + 2 enhancements (BL-067..BL-107)

### New skills

- **qa-secrets** (BL-067) — TruffleHog git history + staged diff secrets scanner; verified secrets = FAIL; unverified = warn; regex fallback when trufflehog absent
- **qa-sca** (BL-106) — Syft SBOM (CycloneDX) + Grype CVE scan + license compliance; delta vs previous SBOM to surface only new findings
- **qa-slsa** (BL-098) — SLSA provenance attestation verification via `gh attestation verify` + `slsa-verifier`; tampered artifacts = hard FAIL
- **qa-env-parity** (BL-099) — Env var drift detection across dev/staging/prod .env files; LLM classifies required-missing / expected-drift / stale-orphaned
- **qa-test-lint** (BL-103) — Static test smell scanner: sleep(), assertion-free, permanent skips, empty describes, console.log, magic numbers, duplicate bodies
- **qa-test-order** (BL-104) — Randomized test order runner (jest --randomize, pytest-randomly, go test -shuffle) to detect order-dependent state leakage
- **qa-test-docs** (BL-105) — LLM reads test files grouped by domain → human-readable Markdown docs with business rules, edge cases, and coverage gaps
- **qa-coverage-gate** (BL-069) — Per-file coverage delta gate vs base branch; LLM stub suggestions for uncovered lines on files below threshold
- **qa-report** (BL-070) — Aggregates all CTRF files → unified sprint/PR dashboard with LLM top-3 risk narrative and flaky registry enrichment
- **qa-cost** (BL-071) — Token cost tracking across QA runs using CTRF metadata; optional CI budget gate (`QA_COST_BUDGET`)
- **qa-eval-gate** (BL-101) — CI gate: discovers evals/ dir, runs promptfoo/deepeval/custom evals, blocks if pass-rate < `EVAL_PASS_THRESHOLD` (default 0.8)
- **qa-intent-assert** (BL-102) — NL code property assertions via `*.intent.yaml` files; LLM judge evaluates each assertion against target code
- **qa-geo** (BL-100) — Playwright timezone + geolocation simulation matrix (4 timezones × N pages); catches date/locale formatting bugs and geo-gated regressions
- **qa-deeplinks** (BL-107) — Deep link / universal link validator; parses AASA, assetlinks.json, AndroidManifest; tests cold-start + in-app via xcrun/adb/Playwright
- **qa-deps** (BL-088) — Docker Compose service dependency smoke test; type-aware health checks (pg_isready, redis-cli ping, kafka topics, HTTP /health); teardown on exit
- **qa-ci-trace** (BL-072) — OTel/Honeycomb build trace analysis → ranked CI optimization recommendations (slowest steps, parallelism gaps, cache misses)
- **qa-spec-to-test** (BL-073) — Markdown PRD/spec → YAML test plan → optional Playwright skeleton .spec.ts files; tags scenarios P1/P2/P3 by priority language

### Enhancements

- **qa-a11y** (BL-068) — Added `A11Y_BASELINE_MODE` (full|diff, default diff): saves per-branch baseline JSON; diff mode suppresses existing violations, surfacing only new regressions
- **qa-explore** (BL-074) — Added `CONSENSUS_MODE`: when `GEMINI_API_KEY` set, functional assertion findings are validated by Claude + Gemini with a third-Claude arbitration; only majority-FAIL findings count

### Infrastructure

- `qa-team/SKILL.md.tmpl`: added qa-secrets, qa-sca, qa-geo, qa-deps to auto-dispatch; qa-deeplinks added as opt-in (`QA_DEEPLINKS=1`)
- `bin/setup`: added 17 new `/qa-*` command descriptions to available commands footer
- `.claude/agents/`: 17 new agent files created

---

## v1.15.0.1 — 2026-05-06 — nightly learning-sources catalog update

### learning-sources
- +28 new sources: 13 QA tools (Playwright clock/mock/network/locators/actions/nav/screenshots/videos, k6 extensions/env vars, k6-operator, Karate, Jest), 6 languages (PEP 484, pytest good practices, TC39 proposals, Biome, Oxc, Jest), 4 methodology (Fowler Practical Test Pyramid, Pact University, Pact Broker sharing, Cucumber tutorial), 5 security/a11y/AI (OWASP ASVS v5, OWASP LLM VS, Trivy, Gitleaks, AgentOps)
- 0 stale entries flagged — all 258 catalog entries current

---

## v1.15.0.0 — 2026-05-04 — qa-meta-eval + qa-manager (BL-011, BL-050, BL-051)

### qa-meta-eval (new skill — BL-011)
- Adversarial red-teaming of QA skills: 8 scenarios × UserSimulatorAgent + JudgeAgent
- Scenarios cover: no-test-files (qa-web), no-OpenAPI-spec (qa-api), broken-selector (qa-heal),
  hollow-tests (qa-audit), zero-a11y-elements (qa-mobile), server-unreachable (qa-perf),
  high-complexity routing (qa-web), timing-flakiness classification (qa-heal)
- Phase 4 report: per-skill pass rate table; flags skills below 80% with anti-pattern breakdown
- CTRF output; `QA_META_TARGET=<skill>` env var scopes run to one target skill
- Scenarios defined in `qa-refine-workspace/meta-evals/scenarios.json` (versioned)

### qa-manager (new skill — BL-050 + BL-051)
- Mode A (Epic → Playwright, BL-050): JIRA Epic → Features → User Stories → Test Plan →
  Playwright spec skeletons with `// TC-{id}` + `// Story: {key}` traceability comments;
  versioned JSON artifacts at every stage (`test-specs/01_epic_*.confirmed.v1.json`, etc.);
  AskUserQuestion confirmation gates; final traceability matrix JSON
- Mode B (Figma → Test Cases, BL-051): parses Figma URLs from JIRA sprint ticket bodies;
  fetches frame PNGs via Figma API (`/v1/images/{fileKey}`); Claude vision analysis → structured
  test cases (Title, Preconditions, Steps, Expected Result, Priority); pushes to TestRail or
  Xray TCMS; markdown fallback when TCMS not configured
- Env vars: `JIRA_URL`, `JIRA_TOKEN`, `FIGMA_TOKEN`, `TESTRAIL_URL`/`XRAY_URL`, `JIRA_EPIC_ID`
- Both modes degrade gracefully when integrations are unavailable (manual-input fallback)

---

## v1.14.0.0 — 2026-05-04 — [M] batch: observability RCA, contract testing, chaos, VLM mobile, DOM metrics, offline CI

### qa-observability (new skill — BL-057)
- New skill + agent: HolmesGPT-style failure RCA loop — fetches OTel traces (Jaeger/Tempo), queries Loki logs (±30s window), synthesizes root cause with HIGH/MEDIUM/LOW confidence
- Auto-discovers local observability endpoints (localhost:16686 Jaeger, :3200 Tempo, :3100 Loki)
- Output: `FAILURE_REASON` block appended to failing skill's report; CTRF JSON emitted

### qa-api (BL-010 + BL-025 + BL-031 + BL-032 + BL-056 + BL-064)
- Phase 0.75: OpenAPI contract testing via Dredd — validates running API against spec, flags schema drift before test generation
- Phase 3: Tracetest span assertions — generates `tracetest/*.yaml` alongside HTTP tests; asserts DB span latency, auth gRPC status
- Phase 4d: Pact consumer contract verification — auto-runs when `*.pact.json` / `pacts/*.json` found
- Phase 4e: RESTler stateful REST fuzzing — opt-in via `QA_DEEP_FUZZ=1`; Docker-based; reports bug buckets by category
- Phase 4f: Keploy eBPF traffic re-recording — record mode (`QA_KEPLOY_RECORD=1`) + replay mode when fixtures exist
- Phase 4g: aimock offline record/replay — record mode + replay proxy for deterministic CI
- Preamble: aimock, Keploy, Pact file, Tracetest detections added

### qa-visual (BL-009 + BL-043)
- Phase 4.5: DOM metric extraction — `page.evaluate()` captures bounding boxes, colors, font sizes; only escalates to full screenshot when metrics diverge; `.visual-spec/` file support
- Phase 5.5: Multi-model consensus (Layer 2b) — second judge call + arbiter when models disagree; verdict caching by diff-file SHA

### qa-mobile (BL-045 + BL-046 + BL-047)
- Phase 4.5: Midscene VLM fallback — `aiAction()` when selectors break; Maestro `.midscene.yaml` parallel flows
- Phase 4.5: OmniParser perception layer — triggered when accessibility tree yields 0 elements; Docker service at localhost:8000
- Phase 4.5: Mobile-Agent Reflector — `withReflection()` wrapper; up to 2 retries per step; reflection rate tracking → flakiness candidates

### qa-perf (BL-039 + BL-040 + BL-041)
- Phase 3.5: LitmusChaos concurrent resilience — `QA_CHAOS=1`; ChaosEngine YAML auto-generated from k6 thresholds; concurrent chaos + load run
- Phase 3.5: GoReplay production traffic replay — `QA_REPLAY_MODE=1`; capture + replay modes; per-endpoint p99 regression analysis
- Phase 4.6: Bencher continuous benchmarking — pushes k6 summary to Bencher trend store; Claude writes 1-paragraph regression narrative

### qa-web (BL-005 + BL-025 + BL-066)
- Phase 2: aimock record/replay integration — fixture-based offline CI mode
- Phase 2: TestZeus Hercules — Gherkin `.feature` file detection; Hercules execution when available; fallback to Playwright spec generation from Gherkin steps
- BL-005 marked implemented (NL mode covered by BL-049)

### qa-team (BL-024 + BL-025)
- Phase 1.5: Container isolation — Testcontainers provisioning from `test-env.yml`; per-agent `DB_URL`/`REDIS_URL` injection; teardown after Phase 2
- Phase 1.5: aimock pre-spawn proxy — starts replay proxy before spawning sub-agents; stops after Phase 2

### qa-heal (BL-064)
- Phase 3: Keploy eBPF re-recording — triggered on `api-schema-change` failure type; schema delta analysis; auto-commit when ≤5 files changed

---

## v1.13.0.0 — 2026-05-03 — [S] quick-wins: AndroidWorld templates, NL tests, OTel tracing, Honeycomb CI, Lost Pixel, test impact scoping

### qa-mobile
- Phase 2.5: AndroidWorld template matching (BL-048) — maps discovered screens to 20 task categories (Clock, Calendar, Contacts, File Manager, Settings, Browser, Messaging, Email, Maps, Camera, Notes, Tasks, Shopping, Media, Health, Finance, Auth, Search, Notifications, Forms); generates framework-appropriate tests per category

### qa-web
- Phase 2 NL mode (BL-049): Shortest natural-language test generation — `<feature>.shortest.ts` pattern when `_SHORTEST_AVAILABLE=1`; reads `tests.nl.md` if present
- Preamble: `_SHORTEST_AVAILABLE` + `_NL_TESTS_EXIST` detection
- Phase 2 OTel tracing (BL-055): injects W3C `traceparent` header into all test-driven HTTP requests via `page.route()`; annotates failures with `traceId` for backend correlation

### qa-api
- Phase 3 OTel header (BL-055): injects `traceparent` into `APIRequestContext` when `_OTEL_AVAILABLE=1`; annotates CTRF failure messages with trace IDs
- Preamble: `_OTEL_AVAILABLE` detection (`OTEL_EXPORTER_OTLP_ENDPOINT` presence)

### qa-visual
- Phase 4 Lost Pixel fallback (BL-061): when neither `APPLITOOLS_API_KEY` nor `CHROMATIC_PROJECT_TOKEN` is set, auto-generates `lostpixel.config.ts` with Tailwind-derived breakpoints `[375, 768, 1280, 1920]`; coexists with Playwright `toHaveScreenshot`

### qa-heal
- Phase 0.5 test impact scoping (BL-063): `git diff --name-only origin/main` → stem-based co-located test mapping; scopes heal run to impacted tests when `_IMPACTED_COUNT > 0`; falls back to full suite when no mapping found

### CI (.github/workflows/qa-report.yml)
- Honeycomb opt-in step (BL-058): emits one OTel event per QA domain to Honeycomb Events API; activated by `HONEYCOMB_API_KEY` secret; dataset configurable via `HONEYCOMB_DATASET` var

### learning-sources (catalog expansion)
- `qa-tools.md`: expanded from 30 → 74 entries (BACKLOG sources: Storybook, fast-check, Litmus, Pyroscope, Stryker, BackstopJS, Playwright MCP, Midscene, shortest, Artillery MCP, GoReplay, 35+ repos)
- `qa-methodology.md`: expanded from 22 → 24 entries (Trunk flaky-tests blog, PactFlow blog, Meta ACH mutation testing research)
- `security-a11y-ai.md`: expanded from 20 → 36 entries (sniff, ai-pentest-agent, Aura, testsigma, AppAgent, MobileAgent, UI-TARS, OmniParser, HolmesGPT, TestZeus, TestPilot2, Autonomous-QA-Agent, FinalRun, SWE-AF, Passmark)
- `INDEX.md`: updated entry counts to 74/24/28/36

---

## v1.12.0.0 — 2026-05-03 — learning-sources-refinement skill + catalog-first integration

### learning-sources-refinement (new skill)
- Maintains shared knowledge base in `learning-sources/` across 4 domains:
  QA tools, QA methodology, programming languages, security/a11y/AI testing
- Phase 1: catalog review — stale detection (>6 months), gap analysis (<5 entries per section)
- Phase 2: domain search — WebSearch + WebFetch for new official docs, GitHub repos, blogs
- Phase 3: catalog update — appends new entries, flags stale inline, updates INDEX.md
- Phase 4: discovery report with per-skill source recommendations

### learning-sources/ (new catalog — 5 files, pre-seeded)
- `INDEX.md` — master index with domain pointers and usage mapping
- `qa-tools.md` — 30 entries: Playwright, Cypress, Selenium, k6, Detox, Appium + community repos
- `qa-methodology.md` — 22 entries: BDD/contract testing/accessibility/flakiness/ISTQB standards
- `languages.md` — 28 entries: TypeScript, Python, Java, C#, Kotlin, Ruby, Bash + GoF patterns
- `security-a11y-ai.md` — 20 entries: OWASP, ZAP, Nuclei, WCAG, axe-core, AI agent testing

### lang-refine / qa-refine / qa-methodology-refine
- Added catalog detection step — `_LS_AVAILABLE` detection runs before Phase 1a
- Phase 1a: catalog-first instruction — reads `learning-sources/*.md` before hardcoded fallbacks

---

## v1.11.0.0 — 2026-05-03 — BurpMCP authenticated testing, OFFAT security fuzzing, chaos mode wiring

### qa-security
- Phase 3.5: BurpMCP Authenticated Session Security Testing — retrieve captured Burp traffic, Claude identifies BOLA/IDOR/mass-assignment/SQLi/XSS/SSRF injection points, replays payloads with session tokens; Burp Collaborator support for out-of-band blind probes; `ATTACK_SUCCEEDED` = security finding (BL-021)
- Preamble: added `_BURP_AVAILABLE` detection (burp.jar scan + port 1337 health check)

### qa-api
- Phase 4c: OWASP OFFAT OpenAPI Security Fuzzing — opt-in (`QA_SECURITY=1`); OWASP API Top 10 attack classes (BOLA, mass assignment, SQLi, XSS, method bypass); high-severity findings block; OFFAT install hint when not found (BL-033)
- Preamble: added `_SEED_MODE` detection; chaos-mode warning in Phase 5 report when `QA_SEED_MODE=chaos` (BL-023)

### qa-web
- Preamble: added `_SEED_MODE` detection; chaos-mode warning in report when `QA_SEED_MODE=chaos` (BL-023)

---

## v1.10.0.0 — 2026-05-03 — Hardness routing, risk-weighted gaps, two-tier mutation, MutaHunter

### qa-team
- Phase 0.8: Hardness-Aware Routing — 0–7 complexity score (routes, auth, domains, LOC); simple (<3) → single qa-web smoke-only fast-path; complex (3–5) → full parallel fleet; very-complex (≥6) → full fleet + mandatory qa-audit + qa-explore (BL-012)
- Preamble: added `_ROUTE_COUNT`, `_HAS_AUTH`, `_DOMAIN_COUNT`, `_LOC` detection variables
- Phase 4 report: new "Routing" block — complexity tier, score breakdown, agent fleet used

### qa-audit
- Preamble: added `_STRYKER_AVAILABLE`, `_PITEST_AVAILABLE`, `_MUTMUT_AVAILABLE`, `_MUTAHUNTER_AVAILABLE`, `_DIFF_FILES`, `_DIFF_COUNT`, `_TEST_CMD`
- Phase 2.7: Risk-Weighted Coverage Gap Scoring — git log surfaces recently changed (+3) and fix-commit (+2) files; auth/payment path heuristic (+3); complexity heuristic (+2); covered discount (−5); Top 5 risk-ranked table drives Phase 3.5 fill order (BL-013)
- Phase 3.8: Two-Tier Mutation Testing — Tier 1 tool-based incremental (Stryker/Pitest/mutmut) scoped to diff files; Tier 2 Claude classifies survived mutants EQUIVALENT vs. GENUINE-GAP + generates killing assertions; warn <60%, BLOCK <40% adjusted score; skip via `QA_SKIP_MUTATION=1` (BL-034)
- Phase 3.9: MutaHunter LLM-native mutant generation — opt-in (`QA_MUTAHUNTER=1`); Haiku model; 50-mutant cap; scientific 3-turn debugging loop; few-shot from real bug commits (BL-035)

---

## v1.9.0.0 — 2026-05-03 — Five new skills: explore, security, seed, simulate, component

### qa-explore (new)
- Swarm exploratory testing: N parallel browser agents autonomously find 404s, JS errors, broken links (BL-008)
- Configurable via `QA_EXPLORE_AGENTS` (default: 3), `QA_EXPLORE_MAX_PAGES` (default: 20)
- Auto-detects seed routes from `pages/` and `app/` directories; sitemap.xml fallback

### qa-security (new)
- Mode A: OWASP ZAP DAST — spider + active scan + Claude OWASP/CWE triage (BL-020)
- Mode B: Lightweight curl probes — security headers, exposed files, CORS, JWT checks (always available)
- Nuclei template-based scanning as second pass when installed; stack-aware tag selection

### qa-seed (new)
- Schema-aware synthetic data: Prisma, SQL migrations, TypeORM, Django ORM, Drizzle (BL-022)
- FK-constraint-aware topological seeding; realistic distributions per column type
- Chaos mode (`QA_SEED_MODE=chaos`): null injection, boundary values, unicode edge cases, duplicate rows

### qa-simulate (new)
- UserSimulator generates multi-turn user journeys from feature descriptions (BL-026)
- RedTeam mode (`QA_REDTEAM=1`): adversarial inputs — SQL injection, XSS, auth bypass, race conditions
- Judge agent evaluates scenario correctness 0–1; scenarios cached as JSON for deterministic CI replay

### qa-component (new)
- Storybook test execution: interaction tests + a11y checks + Chromatic visual snapshots (BL-052)
- Prop boundary testing via fast-check: ts-morph extracts interfaces → Claude generates `fc.record()` arbitraries, 200 iterations (BL-053)
- Stryker mutation quality gate on changed components: surviving mutants classified EQUIVALENT/GENUINE-GAP; killing assertions generated for GENUINE-GAP (BL-054)

### qa-team
- Added qa-explore, qa-security, qa-seed, qa-component, qa-simulate to dispatch table
- Updated auto-detection rules for 5 new domains
- Updated aggregate loop: `for domain in web api mobile perf visual audit a11y heal explore security seed component simulate`

---

## v1.8.0.0 — 2026-05-03 — Multi-browser, API fuzzing, visual AI diff, perf Artillery, snapshot healing

### qa-web
- Multi-browser default: chromium + firefox + webkit in generated playwright.config.ts (BL-059)
- `QA_BROWSERS` env var to opt out of specific browsers (BL-062)
- Phase 2.6: Cross-browser locator audit — detect fragile CSS/XPath selectors, suggest getByRole/getByLabel/getByTestId rewrites (BL-060)
- Browser Matrix table in Phase 4 report
- Removed hardcoded `--project=chromium` from Phase 3 execution; config drives browser selection

### qa-api
- Phase 0.5: Spectral OpenAPI lint pre-flight — blocks on errors, surfaces warnings (BL-028)
- Phase 1.5: GraphQL schema diff via `@graphql-inspector/cli` — BREAKING/DANGEROUS/NON_BREAKING classification (BL-029)
- gRPC detection in Preamble + Phase 2b gRPC smoke tests via `grpcurl` (BL-030)
- Phase 4b: Schemathesis property-based fuzzing — 25 examples, all checks, stateful links (BL-027)

### qa-perf
- Artillery detection added to Preamble tool selection (BL-036)
- Phase 2.5: Artillery adaptive phase sequencing — smoke → baseline → soak with threshold gates (BL-036, BL-037)
- Phase 4.5: Pyroscope flamegraph diff → 3-bullet CPU hotspot insight when `PYROSCOPE_URL` set (BL-037)
- SLO Compliance table in Phase 4 report: parse k6 thresholds → Sloth YAML + error budget burn rate (BL-038)

### qa-visual
- Phase 1.5: BackstopJS config generation from Tailwind breakpoints + route discovery (BL-044)
- Phase 5.5: Three-layer AI diff pipeline — pixelmatch auto-pass (<0.1%) / auto-fail (>20%) + Claude Vision COSMETIC/FUNCTIONAL/CONTENT classification for 0.1–20% range (BL-042)

### qa-heal
- 7th failure classification: `snapshot-drift` — `pytest --inline-snapshot=fix` / `jest --updateSnapshot` repair (BL-065)
- Confidence score: +0.10 for snapshot-drift with ≤3 spec files changed (low-risk mechanical fix)

---

## v1.7.0.0 — 2026-05-03 — New skills: qa-heal + qa-a11y; CTRF output; coverage gap loop; flaky classifier

### New Skills
- `qa-heal` — Self-healing test repair: 6-type failure classification (broken-selector,
  stale-element, moved-element, assertion-drift, navigation-change, timing-issue),
  confidence-gated auto-commit/PR/issue routing (BL-004)
- `qa-a11y` — Accessibility audit: axe-core scan + POUR grouping + AI alt text generation (BL-018/019)
- Both skills added to `qa-team` auto-dispatch and `.claude/agents/`

### CI/CD Integration
- CTRF universal JSON output added to all 6 runner skills + qa-heal + qa-a11y + qa-team aggregation (BL-014)
- GitHub PR comment via `npx github-test-reporter` in qa-team (optional, requires gh CLI) (BL-015)
- `.github/workflows/qa-report.yml` for CI-native CTRF artifact reporting (BL-015)
- Persistent `qa-flaky-registry.json` updated after every qa-team run; flaky tests annotated (BL-016)
- Test impact analysis in qa-team Phase 0.5: diff-scoped fast-path when ≤5 test files affected (BL-017)

### qa-audit Enhancements
- Phase 2.5: Flaky test OD/ID classification via isolation run + registry lookup (BL-007)
- Phase 3.5: Coverage gap fill loop — run coverage, generate targeted tests, repeat ×3 (BL-006)

---

## v1.6.0.0 — 2026-05-03 — Architecture upgrade: subagents, hooks, DRY version check, memory

### Subagent definitions (`.claude/agents/`)
- Created `.claude/agents/qa-web.md`, `qa-api.md`, `qa-mobile.md`, `qa-perf.md`, `qa-visual.md`, `qa-audit.md`
- Each agent: `model: sonnet`, `memory: project`, `effort: high` (medium for `qa-visual`), inline safety hooks
- `bin/setup` updated to symlink agents to `~/.claude/agents/`

### Skill frontmatter additions (6 runner skills)
- `disable-model-invocation: true` — prevents accidental auto-triggering
- `model: sonnet` — makes model selection explicit
- `effort: high` (`medium` for `qa-visual`) — controls reasoning depth
- `hooks.PreToolUse` — blocks broad `rm -rf` commands via `bin/hooks/qa-pre-bash-safety.sh`
- `hooks.PostToolUse` — async `tsc --noEmit` after spec writes via `bin/hooks/qa-post-write-typecheck.sh`
- Added `disable-model-invocation: true` to `qa-team` frontmatter

### DRY version check
- Created `bin/qa-version-check-inline.sh`
- Replaced 45-line version check block in all 9 `.tmpl` files with 4-line `!bash` injection
- Saves ~405 lines of duplicate code across the repo

### Agent memory instructions
- All 6 runner skills now include `## Agent Memory` section
- Instructions to maintain `.claude/agent-memory/<domain>/MEMORY.md` across runs
- Accumulates: framework version, auth patterns, known flaky scenarios, base URL, infrastructure quirks

### New files
- `bin/hooks/qa-pre-bash-safety.sh` — blocks destructive `rm -rf` in QA agent context
- `bin/hooks/qa-post-write-typecheck.sh` — async TypeScript type-check after spec writes
- `bin/qa-version-check-inline.sh` — DRY version check helper for `!bash` injection
- `.claude/agents/qa-{web,api,mobile,perf,visual,audit}.md` — isolated subagent definitions
- `CLAUDE.md` — project contributor guide (architecture, build, version bumping, adding skills)

---

## v1.5.11.0 — 2026-05-03 — BL-001 CI grounding · BL-002 anti-sycophancy gate · BL-003 diagnose-then-fix (qa-web, qa-api, qa-mobile, qa-perf)

### BL-001 — CI Grounding (`qa-web`, `qa-api`)

Before generating new tests, run the existing test suite and capture its output. The generation phase uses this baseline to:
- Skip endpoints/pages that already have passing coverage
- Target failing tests with understanding of why they fail
- Tag pre-existing failures so Phase 5 diagnosis can distinguish regressions from known issues

- **`qa-web` Phase 1.5**: new `CI Grounding` phase — runs `playwright test`, `dotnet test`, or `cypress run` (branched on `_WEB_TOOL`); saves output to `$_TMP/qa-web-ci-ground.txt`; emits filtered pass/fail lines for generation context
- **`qa-api` Phase 2.5**: new `CI Grounding` phase — runs appropriate runner for `_API_TOOL` (playwright/java/python/csharp/ruby); saves output to `$_TMP/qa-api-ci-ground.txt`; skips gracefully when no existing specs found

### BL-002 — Anti-Sycophancy Quality Gate (`qa-web`, `qa-api`, `qa-mobile`)

After generating tests and before executing them, all generated test blocks must pass a 3-criteria quality gate. Tests that fail are rewritten (not skipped). The gate prevents hollow tests that assert nothing meaningful, duplicate passing tests, or copy-paste templates with wrong URLs.

- **`qa-web` Phase 2.5**: gate criteria: non-trivial assertion · real interaction coverage · failure sensitivity; bad/good TypeScript examples included
- **`qa-api` Phase 3.5**: gate criteria: non-trivial body assertion · correct method+path · auth coverage (authenticated + 401 unauthenticated variant)
- **`qa-mobile` Phase 3.5**: gate criteria: non-trivial assertion · real interaction (tap/input/swipe) · failure sensitivity; Detox/Maestro examples

### BL-003 — Diagnose-Then-Fix (`qa-web`, `qa-api`, `qa-mobile`, `qa-perf`)

When tests fail, the report requires a structured **Diagnosis** table before listing individual failures. The table forces the agent to articulate: what broke, what was expected, what happened, likely root cause, and whether the failure is pre-existing (cross-referenced against the CI grounding output) or a new regression.

- **`qa-web` Phase 4 report**: mandatory `## Diagnosis` table when `EXIT_CODE != 0`; cross-references `$_TMP/qa-web-ci-ground.txt`
- **`qa-api` Phase 5 report**: mandatory `## Diagnosis` table when `EXIT_CODE != 0`; cross-references `$_TMP/qa-api-ci-ground.txt`
- **`qa-mobile` Phase 5 report**: mandatory `## Diagnosis` table when `EXIT_CODE != 0`
- **`qa-perf` Phase 4 report**: mandatory `## Diagnosis` table when any threshold is violated; placed before `## Threshold Violations`

---

## v1.5.10.1 — 2026-04-28 — qa-api: add RestSharp as C# HTTP client option

- **`qa-api` preamble**: added `_CS_RESTSHARP` detection — greps `.csproj` files for RestSharp package reference; emits `CS_RESTSHARP: 1` when found, `CS_RESTSHARP: 0` otherwise
- **`qa-api` Phase 3 — C# reference pointer**: updated description from "HttpClient" to "RestSharp or HttpClient"; added routing rule — use RestSharp section when `CS_RESTSHARP=1`, HttpClient section otherwise; updated note to cross-reference both `CS_TEST_FW` and `CS_RESTSHARP`
- **`api-patterns-csharp.md`**: restructured file into two top-level sections (`## RestSharp Section` and `## HttpClient Section`); added full RestSharp v107+ `ApiClient` with typed generics (`GetAsync<T>` / `PostAsync<T>`) and untyped overloads; added RestSharp NUnit / MSTest / xUnit sub-sections with identical test coverage (happy path, 401, 404, 400, lifecycle DELETE); renamed existing HttpClient test sub-sections to `### HttpClient — NUnit/MSTest/xUnit`; header comment updated to include `http-clients: RestSharp, HttpClient`
- **`qa-refine` reference table**: updated C# API testing entry to "C# (RestSharp or HttpClient)"

---

## v1.5.10.0 — 2026-04-28 — multi-repo support (QA_EXTRA_PATHS) + ISTQB CTFL 4.0 terminology

### Multi-repo support (`QA_EXTRA_PATHS`) — all scanning skills

- **qa-audit, qa-web, qa-api, qa-mobile, qa-perf, qa-team**: added `QA_EXTRA_PATHS` multi-repo block to each skill's preamble — when the env var is set (space-separated absolute paths), the preamble counts test files in each extra repo and emits `EXTRA_REPO <name>: N files — <path>` lines
- **Post-preamble notes**: added "If `MULTI_REPO_PATHS` output appeared" instruction to all 6 skills — directs agents to include extra-repo files when sampling during subsequent phases; notes that language detection uses CWD and that sub-agents inherit `QA_EXTRA_PATHS` automatically via the environment
- **qa-team**: notes that sub-agents inherit the variable automatically so no manual forwarding is needed

### Language consistency — qa-audit

- **`_TARGET_LANG` detection**: added to preamble so recommendation code examples use the project's detected language (TypeScript, Java, Python, C#)
- **C# test file patterns**: `*Tests.cs`, `*Test.cs`, `*Spec.cs` added to `_ALL_TESTS` find patterns with `! -path "*/obj/*"` exclusion
- **C# framework detection**: added bash block to detect xUnit, NUnit, MSTest in `.csproj` files and emit `CS_TEST_FW: <framework>`
- **Recommendation template**: added `(use the project's detected TARGET_LANG for all code examples)` note

### ISTQB CTFL 4.0 terminology — qa-methodology-refine

- **Phase 1b base community sources**: added `WebSearch: '"ISTQB CTFL 4.0" "<TARGET_TOPIC>" terminology 2026'` to the base source list with explanatory note (ISTQB defines authoritative terms: "test case" vs "test", "test level" vs "test layer", etc.)
- **Phase 2 document structure**: added ISTQB CTFL 4.0 standardized terminology note listing key term mappings ("test case" not "test", "test level" not "test layer", "test basis" not "test source", "test suite", "test object", "test condition", "defect" not "bug") so generated guides stay consistent with industry certifications

---

## v1.5.9.9 — 2026-04-28 — lang-refine: update WebSearch queries from 2025 to 2026

- **lang-refine WebSearch queries**: all 11 occurrences of `2025` updated to `2026`

---

## v1.5.9.8 — 2026-04-28 — qa-methodology-refine: WebSearch-first sources, existing guide check, 2026 queries

- **Step 0 language detection**: TypeScript detection strengthened — now checks `tsconfig.json`, `@types/node`, `.ts`/`.tsx` files in addition to `typescript`/`ts-jest` in `package.json`
- **Phase 1a — check existing guide first**: added `ls qa-methodology/references/` step + instruction to read the existing `<TARGET_TOPIC>-guide.md` before fetching, so research extends prior work rather than duplicating it
- **Phase 1a — sources table**: replaced all old blog post URLs (martinfowler.com pre-2018, testing.googleblog.com/2016, satisfice.com PDF download, developsense.com/2009, xunitpatterns.com, ibm.com) with WebSearch queries; these URLs are unreliable and their content is already captured in the generated guide files; WebSearch naturally returns current, high-quality coverage of the same concepts
- **Phase 1a — active official docs preserved**: `cucumber.io/docs/bdd/`, `cucumber.io/docs/gherkin/reference/` (BDD), `docs.pact.io/` + consumer + provider (contract-testing), `www.deque.com/axe/axe-for-web/` + W3C WCAG quickref + axe-core GitHub (accessibility), `owasp.org/www-project-devsecops-guideline/` (shift-left) — these are actively maintained and worth fetching
- **Phase 1a — explanatory note**: added paragraph explaining the WebSearch-first rationale (old content already in guide files; WebSearch finds current articles vs fixed stale URL)
- **Phase 1b lang-refine fetch**: removed "For non-JS/TS languages" qualifier; applies to all languages
- **WebSearch queries**: all `2025` occurrences updated to `2026` (Phase 1a WebSearch table, Phase 1b base + per-topic queries, Phase 4b refinement gap table — 25 total occurrences)

---

## v1.5.9.7 — 2026-04-28 — qa-refine: full reference index, Selenium URL dedupe, 2026 queries, no JS bias

- **Step 0 language detection**: TypeScript detection strengthened — now checks for `tsconfig.json`, `@types/node`, and `.ts`/`.tsx` files in `src/` in addition to `typescript`/`ts-jest` in `package.json`
- **Step 0 exceptions**: k6 and Detox updated from "always JavaScript" to "always **JavaScript/TypeScript**" (TS supported via bundler; official docs use JS examples)
- **Phase 1a — Existing reference files table**: added comprehensive table listing all 22 reference files currently in the repo (Playwright TS + baseline + C#, Cypress, Selenium TS, k6 + baseline, JMeter, Locust, NBomber, Detox + baseline, Appium WDIO/Java/Python/C#, Maestro, API patterns TS/Java/Python/C#/Ruby); instructs agent to read the relevant file before fetching to extend prior work rather than duplicate it
- **Phase 1a — Playwright "See also"**: simplified to a short pointer; detail moved to reference files table
- **Phase 1a — Selenium URLs**: refactored from per-language table (which repeated the same 4 selenium.dev URLs for every language) to a shared "language-independent" block + a small language-specific additions table; TS/JS/C# now noted as needing no additional source beyond selenium.dev; added `See also` pointer to `selenium-patterns.md`
- **Phase 1b — lang-refine fetch**: removed "For non-JS/TS languages" qualifier; now applies to all languages; lists all 7 available lang-refine reference files explicitly
- **Phase 2 — target paths**: removed "TypeScript/JavaScript (the default)" framing; replaced with neutral note that base-name files are the TypeScript references and all other languages use a suffix
- **Phase 2 — target paths table**: added NBomber → `qa-perf/references/nbomber-patterns.md`
- **WebSearch queries**: all 15 occurrences of `2025` updated to `2026`

---

## v1.5.9.6 — 2026-04-28 — qa-audit: 4 new methodology checks + scoring/report updates

- **qa-audit preamble**: expanded `_RETRY_COUNT` grep to capture `.only`, `xdescribe`, `@Ignore`, `[Ignore]`, `[Skip]`, `pytest.mark.xfail`, `jest.retryTimes`, `retries: N`
- **Check 7 (CI test integration)**: added bash block to detect artifact-on-failure signals (`upload-artifact`, `store_artifacts`, `junit`, `screenshot`, `video`, `allure`); added "Artifacts on failure" checklist item; removed "Parallel test execution" bullet (moved to dedicated Check 11)
- **new Check 8 — Assertion quality**: greps for presence-only assertions (`notBeNull`, `assertNotNull`, `toBeDefined()`, `ShouldNotBeNull`, `assertIsNotNone`, etc.); flags tests that confirm an object exists but do not verify its content or behaviour
- **new Check 9 — Positive/negative test balance**: counts test names matching positive-path keywords vs negative-path keywords; flags suites where `_NEG_TESTS = 0` (only happy-path coverage) or extreme imbalance
- **new Check 10 — Retry / ignore / skip markers**: greps for `.skip`, `.only`, `xtest`, `@Ignore`, `[Ignore]`, `pytest.mark.skip/xfail`, `retries: N`, `flaky`; explains risk of each marker type; flags any committed `.only` as a definite bug
- **new Check 11 — Parallelization safety**: greps for hardcoded shared ports/DB names and for `--runInBand` / `maxWorkers=1` / `singleThread` config flags that suppress parallelism instead of fixing root causes; explicitly distinguished from Check 7's CI parallel-execution check
- **Phase 4 scoring table**: renamed "Naming Quality" → "Assertion & Naming Quality" (Checks 1 & 8); renamed "CI / Coverage" → "CI / Coverage & Reliability" (Checks 4, 6, 7 & 10); updated "Pyramid Balance" signal to include Check 9; updated "Test Isolation" signal to include Check 11
- **Phase 5 report template**: updated dimension score rows to surface new signals; renamed "Flakiness Risk Summary" → "Flakiness & Reliability Summary"; added weak assertion count and missing-negative-path verdict rows
- **skill description**: updated to enumerate all 11 checks

---

## v1.5.9.5 — 2026-04-28 — qa-perf: NBomber support, C# detection, blockquote reference format

- **qa-perf preamble**: added `_TARGET_LANG` detection; .NET base URL from `launchSettings.json`; `_NBOMBER` detection via `find . -name "*.csproj" | xargs grep -il "NBomber"`; C# existing perf file patterns (`*LoadTest*.cs`, `*PerfTest*.cs`); C# Controller route detection
- **qa-perf Tool Selection Gate**: `NBOMBER_PRESENT` counted alongside k6/JMeter/Locust; NBomber listed as option 2 in zero-detected case with recommendation note for `_TARGET_LANG=csharp`
- **qa-perf Phase 2**: converted from bullet/inline list to blockquote format (matching qa-web/qa-api/qa-mobile pattern); NBomber entry added with reference link and key patterns summary
- **new files** — `qa-perf/tools/`:
  - `nbomber.md` — load simulation types table, full auth+scenario script template, thresholds, DataFeed, execute block, result parsing, CI notes
- **new files** — `qa-perf/references/`:
  - `nbomber-patterns.md` — core principles (open vs closed model, one `HttpClient`, auth before scenario); all `LoadSimulation` variants; full multi-scenario script with auth + thresholds + report formats; `DataFeed` parameterised data; NUnit `[Explicit]` integration; cleanup-after-writes with `ConcurrentBag`; default SLA profiles table

---

## v1.5.9.4 — 2026-04-28 — Consistent blockquote reference format; qa-mobile multi-language Appium

- **qa-web Phase 2**: reference section converted from flat bullet list to blockquote format matching qa-mobile Phase 3 — each tool now has a bold heading, `> Reference: [title](path)` link, and `> Key patterns: a · b · c` summary
- **qa-api Phase 3**: "Load language patterns file" section converted to same blockquote format — one entry per language with link + key patterns summary; `CS_TEST_FW` focus note retained for C#
- **qa-mobile preamble**: added `_TARGET_LANG` detection (`typescript`, `java`, `python`, `csharp`, `ruby`) after Maestro detection block
- **qa-mobile Phase 3 Appium section**: split into per-language blockquote entries (TypeScript/WDIO, Java, Python, C#); TS example code retained; other languages redirect to new reference files
- **new files** — `qa-mobile/references/`:
  - `appium-patterns-java.md` — `AppiumTestBase` with JUnit 5, `AppiumBy.ACCESSIBILITY_ID` selectors, `WebDriverWait`, `@BeforeAll`/`@AfterAll` lifecycle
  - `appium-patterns-python.md` — pytest session-fixture driver, `AppiumBy.ACCESSIBILITY_ID`, `WebDriverWait`/`expected_conditions`, `autouse` app-reset fixture
  - `appium-patterns-csharp.md` — `AppiumTestBase` with `IOSDriver`/`AndroidDriver`, NUnit/MSTest/xUnit sections, `MobileBy.AccessibilityId`, `WebDriverWait`, `dotnet test` execute block

---

## v1.5.9.3 — 2026-04-28 — qa-api: C# support, ApiClient pattern, reference files, DELETE/cleanup rules

- **qa-api preamble**: `_CS_TEST_FW` detection (nunit/mstest/xunit); .NET base URL from `launchSettings.json` + `appsettings*.json`; `Controllers/*.cs` added to route file scan; all C# `find` calls exclude `*/obj/*`
- **qa-api Phase 1**: added C# Controller attribute grep (`[HttpGet]`, `[HttpPost]`, `[Route]` etc.) as Strategy 2b
- **qa-api Phase 3**: removed all inline language templates; Phase 3 now reads `qa-api/references/api-patterns-<_API_TOOL>.md`; prominent DELETE policy and cleanup obligations added before test generation
- **qa-api Important Rules**: replaced vague "idempotent tests" with explicit "shared ApiClient", "no bare DELETE tests", and "cleanup everything you create" rules
- **new files** — `qa-api/references/`:
  - `api-patterns-typescript.md` — `ApiClient` wrapping Playwright request context, cleanup via `afterAll`
  - `api-patterns-java.md` — `ApiClient` wrapping REST Assured, cleanup in `@AfterAll`
  - `api-patterns-python.md` — `ApiClient` wrapping `requests.Session`, cleanup via session-scoped `autouse` fixture
  - `api-patterns-csharp.md` — `ApiClient` wrapping `HttpClient` (single instance, `Anonymous()` helper); NUnit / MSTest / xUnit sections; `_created` list + teardown cleanup; lifecycle DELETE pattern
  - `api-patterns-ruby.md` — `ApiClient` wrapping Faraday, cleanup in `after(:all)`

---

## v1.5.9.2 — 2026-04-28 — C# support in qa-web (preamble, base URL, patterns)

- **qa-web preamble**: added `_PW_DOTNET` / `_SE_DOTNET` detection (grep `.csproj` for `Microsoft.Playwright` / `Selenium.WebDriver`); `_TARGET_LANG` variable (`typescript`, `csharp`, `java`, `python`); `_CS_TEST_FW` detection (`nunit`, `mstest`, `xunit`)
- **qa-web base URL**: extended detection chain — `launchSettings.json` (`applicationUrl`, semicolon-safe), then `appsettings.json`/`appsettings.Development.json` `BaseUrl` key, then JS/TS configs, then fallback `http://localhost:3000`
- **qa-web spec scan**: added `*Tests.cs`, `*Test.cs`, `*Spec.cs`; all C# `find` calls exclude `*/obj/*`
- **qa-web routes**: added `Controllers/*.cs`, `Pages/*.cs`, `Views/*.cs` + `.cshtml` to Phase 1 route discovery
- **qa-web Tool Gate**: treats `PLAYWRIGHT_DOTNET` / `SELENIUM_DOTNET` as Playwright/Selenium signals; documents that `_TARGET_LANG=csharp` drives Phase 2 pattern file selection and Phase 3 execute command
- **qa-web Phase 2**: patterns file selection now branches on `_TARGET_LANG` — C# projects read `playwright-patterns-csharp.md` and focus on `CS_TEST_FW` section
- **qa-web Phase 3**: added `dotnet test` execute block for `_TARGET_LANG=csharp`
- **new file**: `qa-web/references/playwright-patterns-csharp.md` — C# Playwright patterns covering NUnit / MSTest / xUnit base classes, POM with `IPage`/`ILocator`, `StorageStateAsync` auth, selector strategy, `Expect()` assertions, network mocking, `.runsettings` config, CI notes


---

## v1.5.9.1 — 2026-04-28 — C# support in qa-team project/web-tool detection

- **qa-team preamble**: detect `*.csproj`, `*.sln`, `global.json`, `Directory.Build.props`, `nuget.config` as project signals
- **qa-team web E2E detection**: grep `.csproj` files for `Microsoft.Playwright` → `playwright-dotnet` and `Selenium.WebDriver` → `selenium-dotnet`
- **qa-team test file scan**: add `*Tests.cs`, `*Test.cs`, `*Spec.cs` patterns; exclude `*/obj/*` from all C# `find` calls
- **qa-team Phase 0**: auto-detection rule for **qa-web** now mentions `.csproj` Playwright/Selenium signals
- **qa-team Phase 1**: added C# entry-point discovery (`*.csproj`, `Controllers/`, `Pages/`, `Views/`)

---

## v1.5.9.0 — 2026-04-28 — Extract version-check + history persistence (Impact 9 complete)

Closes the two **deferred** Impact 9 sub-tasks from PR #5. With this release, every
piece of "this code repeats across N skills" duplication identified in the original
audit is now collapsed into shared `bin/` scripts.

### Added — `bin/qa-team-precheck`

Centralizes the ~12-line version-check + prompt-cooldown logic that was previously
duplicated verbatim in all 10 `SKILL.md` files. Prints two stdout markers the agent
reads (`VERSION_STATUS` and `SKIP_UPDATE_PROMPT`); cooldown management is internal.
Exits 0 always — never blocks the wrapping skill.

Each `SKILL.md` version-check block went from 13 lines to 5:

```bash
_TMP="${TEMP:-${TMP:-/tmp}}"
_QA_ROOT=$(dirname "$(readlink ~/.claude/skills/<skill> 2>/dev/null)" 2>/dev/null) || true
[ ! -f "${_QA_ROOT:-x}/VERSION" ] && \
  _QA_ROOT="$(readlink ~/.claude/skills/qa-agentic-team 2>/dev/null)" || true
bash "$_QA_ROOT/bin/qa-team-precheck"
```

The 4 surviving lines are the per-skill bootstrap (`$_TMP` and `$_QA_ROOT`) — those
remain inline because subsequent bash blocks in the same SKILL.md need them.

Prose updated: agents now read `SKIP_UPDATE_PROMPT` from stdout (was `_QA_SKIP_ASK`,
a shell variable) and write the cooldown to `$_TMP/.qa-update-asked` directly (was
`$_QA_ASK_COOLDOWN`, also a shell variable). Same observable behaviour.

### Added — `bin/qa-team-persist-history <skill-name>`

Centralizes the ~10-line "copy `$TMP/<skill>-{score.json,report.md}` to
`<repo>/.qa-team/<skill>-<commit>-<ts>.{json,md}` + update `<skill>-latest.json`
symlink" block that was duplicated as Phase Xc across the 6 sub-skills with sidecars
(`qa-audit`, `qa-api`, `qa-web`, `qa-visual`, `qa-perf`, `qa-mobile`).

The helper also handles the **delta-mode skip**: if `delta_mode.enabled == true` in
the sidecar JSON, it skips persistence entirely (delta runs are transient by design).
Previously this was inline in `qa-audit` only; centralizing means any sub-skill that
adopts delta mode in the future gets the correct behaviour for free.

Each Phase Xc block went from 11 lines to 1:

```bash
bash "$_QA_ROOT/bin/qa-team-persist-history" "<skill-name>"
```

### Net effect

- **2 new bin scripts**, ~120 LOC total
- **10 SKILL.md files** simplified (version-check)
- **6 SKILL.md files** further simplified (Phase Xc)
- **~8 lines saved per skill on the version-check** × 10 skills = ~80 lines
- **~10 lines saved per skill on Phase Xc** × 6 skills = ~60 lines
- **Single source of truth** for version-check, cooldown management, and history
  persistence (including delta-mode skip rules)

### Status of original 10-item audit plan

All 10 items are now fully shipped (PR #1 through #6):

| Impact | PR |
|--------|----|
| 1, 2, 3, 5, 7, 4, 8 | merged in #1 – #4 |
| 6 — Cost telemetry | merged in #5 |
| 9 — Extract test-file pattern | merged in #5 |
| 9 — Extract version-check | **#6** |
| 9 — Extract history persistence | **#6** |

---

## v1.5.8.0 — 2026-04-28 — Extract test-file pattern + cost telemetry

Closes the **Impact 9** test-file-pattern duplication directly responsible for
three Copilot review rounds on PR #4, and ships the **Impact 6** cost telemetry
that was the last open item from the original audit.

### Added (`bin/qa-team-test-files`) — single source of truth

Multi-mode helper that owns the canonical "what is a test file?" definition.
Five modes:

- `--regex` — print the canonical `grep -E` pattern
- `--globs` — print the canonical `find -name` glob list (one per line)
- `--list` — list all test files in the cwd via `find`
- `--has-tests` — exit 0 if any test file found, 1 otherwise
- `--since=<git-ref>` — print test files changed since `<ref>` (validates ref,
  rejects unreachable refs with exit 3)

Canonical pattern: `\.(test|spec)\.[jt]sx?$|_test\.py$|(^|/)test_.*\.py$|Tests?\.cs$|_spec\.rb$|_test\.go$|Test\.java$|Tests\.java$`
plus the corresponding 16 find globs. Bash 3.2 compatible. No external deps
beyond git + grep + find.

### Changed — five drift sites collapsed to one

The same test-file pattern previously lived in five places:
- `qa-audit/SKILL.md` Preamble (delta regex)
- `qa-audit/SKILL.md` non-delta `_ALL_TESTS` find globs
- `qa-team/SKILL.md` Preamble `_HAS_TESTS` find globs
- `qa-team/SKILL.md` Phase 5 verify-loop regex
- `bin/qa-team-suggest-rerun` regex

All five now call `bin/qa-team-test-files` instead. Net deletion of inline
regex/globs in the SKILL.md files. The cross-reference comments added in
PR #4's fixups are gone — the helper is now the documentation. Future
extensions (e.g. Kotlin tests, Rust tests) only need to update the helper.

### Added (`bin/qa-team-cost-log` + `bin/qa-team-cost`) — cost observability

- **`bin/qa-team-cost-log <skill> <status> [duration_seconds]`** — appends one
  JSONL line per skill run to `<repo>/.qa-team/runs.jsonl`. Schema:
  `{timestamp, skill, status, branch, commit, duration_seconds}`. Silent on
  bad args, outside-of-git, and write failures (telemetry never blocks the
  wrapping skill). Always exits 0.

- **`bin/qa-team-cost`** — aggregator that reads `runs.jsonl` and prints a
  per-skill summary table:

  ```
    SKILL                    RUNS   PASS   WARN   FAIL  OTHER     WALL(s)  LAST
    ----------------------------------------------------------------------------
    qa-audit                    4      2      0      1      1          99  2026-04-28T08:38:29
    qa-api                      1      0      1      0      0          13  2026-04-28T08:38:29
    qa-team                     1      1      0      0      0         180  2026-04-28T08:38:29
  ```

  Flags: `--since=<N>h|<N>d` (time-window filter), `--skill=<name>` (single-
  skill filter), `--json` (raw aggregate for hooks/CI). Bash 3.2 compatible.
  Requires `jq` (errors with exit 2 if missing).

### Added (all 10 skill telemetry tails)

Every skill now invokes `bin/qa-team-cost-log` after its existing
`gstack-timeline-log` call. Three skills already had a `## Telemetry` section
(`qa-team`, `qa-audit`, `qa-methodology-refine`) — extended in place. The
other seven (`qa-api`, `qa-web`, `qa-visual`, `qa-perf`, `qa-mobile`,
`qa-refine`, `lang-refine`) had no telemetry tail before; one was added.

The cost-log call uses `2>/dev/null || true` so a misconfigured environment
never breaks a successful skill run.

### Notes

- **Deferred to a future PR (still under Impact 9):** version-check extraction
  (10 SKILL.md files repeat the same ~12-line block), JSON sidecar persistence
  extraction (6 sub-skills repeat the same ~10-line `cp + ln -sf` block).
  These are real duplication but lower drift risk than the test-file pattern,
  and touching all 10 SKILL.md files for a mechanical extraction is heavy
  review surface for marginal benefit. Tracked for a follow-up PR.
- **Schema for cost JSONL is informal** — it's a private telemetry stream
  consumed only by `bin/qa-team-cost`. If we eventually expose it as a
  public contract (e.g. CI dashboards), we should add a `schema_version`
  field at that point.

---

## v1.5.7.0 — 2026-04-28 — Delta mode + sticky scope

Closes **Impact 4** (`--since=<ref>` delta mode) and **Impact 8** (sticky scope) from the
original audit. Together they cut the cost of repeat runs and remove the friction of
re-confirming identical scope on every invocation.

### Added (`qa-audit`) — `--since=<git-ref>` delta mode

- New optional argument: `/qa-audit --since=<commit | branch | tag>`. When set,
  qa-audit scores **only the test files changed since `<ref>`** instead of the entire
  test tree. Designed for per-PR audits: `/qa-audit --since=main` in a feature branch
  scopes to the PR's test diff.
- Preamble validates the ref via `git rev-parse` and `git merge-base --is-ancestor`,
  aborting with a clear error if the ref is unknown or not reachable from `HEAD`.
- Phase 1 (Test Inventory) sampling switches from `find` globs to iterating the
  `_CHANGED_TEST_FILES` list. Existing layer-classification heuristics still apply.
- The markdown report prepends a "Delta scope" banner so readers know the score covers
  a subset, not the whole suite.
- The JSON sidecar gains a `delta_mode` object: `{ enabled, since_ref, base_sha,
  changed_files_count }`. Schema stays at `1.0` (additive field).
- **Delta runs are transient** — Phase 5c skips persistence to `.qa-team/` entirely
  when `_DELTA_MODE=1`. Full audits remain the canonical history; mixing in delta
  scores would corrupt trend rendering and the regression detection in qa-team Phase 5.
- `Important Rules` gain a new entry codifying the transient-by-design rule.

### Added (`qa-team`) — propagation + sticky scope + Phase 5 wiring

- **`--since=<ref>` propagation:** qa-team accepts the same arg, validates it once in
  the Preamble (before Phase 0), and threads it through to `qa-audit` in Phase 2's
  sub-agent template. Sub-agents that don't support delta mode (`qa-api`, `qa-web`,
  `qa-visual`, `qa-perf`, `qa-mobile`) ignore the flag harmlessly — their scoring is
  already incremental.
- **Sticky scope (Impact 8):** Phase 0 reads `<repo>/.qa-team/last-scope` if present
  and offers it as the **first** option in `AskUserQuestion` ("Re-run last scope
  (Recommended)"). Confirmed scope is persisted back to the same file at the end of
  Phase 0 so subsequent runs benefit. Eliminates re-clicking the same domain mix on
  every invocation in an established project.
- **Phase 5 verify loop now suggests `--since=`:** when the user has changed test
  files since the last full audit, the re-run prompt's first option is now
  `Yes — re-run /qa-audit --since=$_PRIOR_COMMIT (cheap, Recommended)`. This is the
  intended workflow — verify-after-fixes runs are exactly the case delta mode was
  designed for.
- Score-delta hint is now mode-aware: full re-runs render `Audit score: 76 → 84
  (+8 since 0939d0b)`; delta re-runs render `Delta-scope audit (12 changed test files
  since 0939d0b): 88/100`. Two different shapes because the numbers measure different
  things.
- `Important Rules` gain two new entries codifying delta-mode-is-for-verification and
  sticky-scope-is-a-default-not-a-lock.

### Notes
- No change to `bin/qa-team-history` or `bin/setup` — delta mode is invoked through
  the skill, not via CLI tools. `bin/qa-team-suggest-rerun` is touched only to fix a
  pre-existing test-file regex bug (subdir Python tests) and add a sync-comment
  cross-referencing the SKILL.md duplicates — no behavioural change to the hook.
- `schema_version` stays at `1.0`. The `delta_mode` field is additive; consumers that
  pin to 1.0 will see it as an unknown extra field and must tolerate it (per JSON
  contract conventions).

---

## v1.5.6.0 — 2026-04-28 — Default Stop-hook for re-run nudges

Closes Impact 7 from the original audit: skill discovery and re-run had been pull-only.
With this release, every Claude Code session now ends with an automatic check that
detects whether test files have changed since the last `/qa-*` run, and surfaces a
passive nudge to re-run the affected skill.

### Added (`bin/qa-team-suggest-rerun`)
- New shell script (bash 3.2 compatible, jq-optional) designed to run as a Claude Code
  Stop hook. On every Stop:
  1. Reads `.qa-team/qa-*-latest.json` from the active git repo (silently exits if
     none exists, the cwd is not a git repo, or `git` is missing).
  2. For each skill's recorded commit, compares against `HEAD`.
  3. If the prior commit is reachable from `HEAD` AND test files changed in between
     (matched against patterns for JS/TS, Python, C#, Java, Ruby, Go), prints a
     one-line nudge per skill to **stderr** (visible to the user, not consumed by
     the agent's stdout pipeline).
  4. Always exits 0 — this hook never blocks a Stop event.
- Performance budget: <200ms (no network, no LLM, no Docker).
- Five-case smoke-test covers: not-in-repo, no-history, no-changes-since,
  test-file-changed, and multi-skill deltas.

### Changed (`bin/setup`)
- New flags: `--with-hook` (skip prompt — install Stop hook unattended), `--no-hook`
  (skip the hook entirely), `--hook-only` (don't touch symlinks; install/update hook
  only). Default behaviour unchanged: prompt before installing.
- Default install now offers a Y/n prompt to wire `bin/qa-team-suggest-rerun` into
  `~/.claude/settings.json` under `.hooks.Stop`. Non-interactive stdin defaults to
  yes. Pre-existing hooks and other settings keys are preserved (verified end-to-end).
- Hook installation is **idempotent**: re-running setup detects an existing entry by
  command-string match and skips. Works with `jq` (preferred); without `jq`, prints a
  manual install snippet for the user to paste.
- Atomic merge: writes to a tempfile and `mv`s into place — no partial-write risk.
- Two new env-var overrides for testing: `CLAUDE_SETTINGS_FILE` and
  `CLAUDE_SKILLS_DIR` (pre-existing).

### Notes
- The hook is **passive** — it never auto-runs `/qa-*`. It only prints a nudge. The
  user (or agent) decides whether to re-run, preserving the same decision boundary
  the verify-after-fixes loop in v1.5.4.0 introduced.
- The hook references the absolute path of `qa-team-suggest-rerun`. If the repo is
  moved or symlinks are recreated under a different name, re-run `bash bin/setup
  --hook-only` to refresh the reference.
- Why a `Stop` hook and not `PostToolUse`: nudging on every edit would be noisy (the
  user is mid-flow). Stop fires once per session — exactly when the user is about to
  step away and ask "did I leave something undone?".

---

## v1.5.5.0 — 2026-04-28 — Extend JSON sidecar pattern to all sub-skills

### Added (sub-skills)
Every sub-skill now emits a parseable score file alongside its existing markdown report,
sharing the `schema_version: "1.0"` envelope (skill, branch, commit, timestamp, status,
report_md_path) introduced for `qa-audit` in v1.5.4.0:

- **qa-api:** Phase 5b/5c — `qa-api-score.json` with `tool`, `auth`, `counts{passed,
  failed, skipped, total}`, `endpoints{discovered, tested, missing}`, `schema_gaps_count`.
  History persisted to `<repo>/.qa-team/qa-api-*.{json,md}`.
- **qa-web:** Phase 4b/4c — `qa-web-score.json` with `tool`, `base_url`, `counts`,
  `pages{discovered, tested, missing}`, `failure_count`. Same history pattern.
- **qa-visual:** Phase 6b/6c — `qa-visual-score.json` with `tool`, `counts`,
  `screenshots{baselines, viewports_count}`, `regressions_count`,
  `baseline_update_required_count`. Same history pattern.
- **qa-perf:** Phase 4b/4c — `qa-perf-score.json` with `tool`, `target_url`,
  `thresholds_met`, `threshold_violations_count`, `scenarios{total, passed, failed}`,
  `metrics{p50_ms, p95_ms, p99_ms, rps, error_rate_pct}` (null = not measured).
  Same history pattern.
- **qa-mobile:** Phase 5b/5c — `qa-mobile-score.json` with `tool`, `platform`, `device`,
  `counts`, `screens{discovered, tested, missing}`, `failure_count`. Same history pattern.

Each skill's "Important Rules" gained a load-bearing entry: the JSON contract is consumed
by `qa-team` Phase 5 and `bin/qa-team-history`, so renames or removals require bumping
`schema_version` and updating consumers.

### Added (cross-link footers — Impact 5 from the original audit)
Every sub-skill's report now ends with an "After this run" block pointing at the next
relevant skill:
- `qa-audit` → `/qa-methodology-refine` for unfamiliar methodology, `/qa-refine` for
  language-specific patterns, re-run for delta
- `qa-api` → `/qa-audit` for methodology, `/qa-refine` for tooling, re-run for delta
- `qa-web` → `/qa-visual` for visual regression, `/qa-refine` for selectors, `/qa-audit`
- `qa-visual` → `/qa-web` for functional, `/qa-refine` for masking, `--update-snapshots`
  + re-run after intentional changes
- `qa-perf` → `/qa-api` for correctness, `/qa-refine` for tool patterns
- `qa-mobile` → `/qa-refine` for framework patterns, `/qa-audit` for methodology

This addresses the original audit's #5 finding: skill discovery has been pull-only;
inline cross-links make follow-ups self-evident in the report itself.

### Changed (bin/qa-team-history)
- New `--skill=<name>` flag. Recognised: `qa-audit`, `qa-api`, `qa-web`, `qa-visual`,
  `qa-perf`, `qa-mobile`, or `all`. Default unchanged: shows `qa-audit` history.
- New `--skill=all` mode renders one section per skill, with a placeholder when a skill
  has no history yet.
- Per-skill table shape:
  - `qa-audit`: `COMMIT · TIMESTAMP · OVERALL · DELTA · RATING` (existing)
  - others: `COMMIT · TIMESTAMP · STATUS · COUNTS · TOOL` (new, since these skills
    report `status` + `counts` rather than a 0–100 `overall`)
- Bash 3.2 portability fixes (`set -u` array-empty guard, `case` → `if` inside
  process-substitution loops). Smoke-tested with synthetic multi-skill history.
- New exit code `3` for unknown `--skill` argument.

### Notes
- The verify-after-fixes loop in `qa-team` (added in v1.5.4.0) now applies to every
  domain, not only audit. Any sub-skill whose JSON sits in `.qa-team/` can be diffed
  by commit and rendered in the trend table.
- Sub-skills that previously emitted only markdown continue to do so — the JSON is
  strictly additive. No existing consumer breaks.

---

## v1.5.4.0 — 2026-04-28 — Machine-readable score sidecar and verify-after-fixes loop

### Added (qa-audit)
- **Phase 5b — JSON sidecar:** writes `$TEMP/qa-audit-score.json` alongside the existing
  markdown report. Stable contract under `schema_version: "1.0"`: `overall`, `rating`,
  `dimensions{pyramid, isolation, test_data, naming, ci_coverage}`,
  `counts{unit, integration, e2e, unclassified, total}`,
  `flakiness{sleep_calls, retry_marks, risk}`, `critical_count`, `commit`, `branch`,
  `timestamp`, `report_md_path`. Validated as parseable JSON before continuing.
- **Phase 5c — History persistence:** copies the JSON sidecar and markdown report into
  `<repo>/.qa-team/qa-audit-<sha>-<ts>.{json,md}` with a `qa-audit-latest.json` symlink.
  Skipped silently outside a git repo. Enables score-trend analysis and per-commit
  comparisons across runs.
- **Important Rules:** new entry documenting the JSON contract is load-bearing —
  consumers (`qa-team` Phase 5, `bin/qa-team-history`, user-defined CI hooks) depend on
  it. Field renames or removals require bumping `schema_version`.

### Added (qa-team)
- **Phase 5 — Verify after fixes:** reads `.qa-team/qa-audit-latest.json`, computes which
  test files changed since the recorded commit, and uses `AskUserQuestion` to offer
  narrowed re-runs of affected sub-agents. Surfaces score delta in the Executive Summary
  on re-run ("76 → 84 (+8 since 0939d0b)"). Skipped silently when no history exists or
  HEAD already matches the recorded commit. Closes the loop between triage and
  measurement — turns the harness from one-shot report into a measurement instrument.
- **Important Rules:** new entry making Phase 5 the default expectation, not an
  optional nicety.

### Added (bin)
- **`bin/qa-team-history`:** new portable script (bash 3.2 compatible, jq-only
  dependency) that renders a score-trend table from `.qa-team/`. Modes: default table
  with delta column, `--limit=N`, `--json` (raw array for hooks/CI), `--delta` (skips
  the first row). Designed to be cheap enough to call from `Stop` hooks and CI gates.
  Smoke-tested with synthetic history.

### Notes
- Existing markdown reports are unchanged — this release is strictly additive.
- Sub-skills `qa-api`, `qa-web`, `qa-visual`, `qa-perf`, `qa-mobile` continue to emit
  markdown only. Adding JSON sidecars to them is a planned follow-up once the qa-audit
  shape is validated in practice.

---

## v1.5.3.0 — 2026-04-28 — Nightly refinement: all 22 guides reach 100/100

### Changed (reference guides + SKILL.md templates)
- **qa-methodology (12 guides):** All at 100/100. Language correction pass: tdd, test-isolation,
  coverage, ci-cd-testing, shift-left, contract-testing, test-pyramid rewrote code examples from
  TypeScript to JavaScript (project has no TypeScript dependency). New patterns added to flakiness
  (randomness seeding, React `act()`, Vitest concurrent isolation), accessibility (WCAG 2.2 SC 2.5.8
  target-size test, SPA focus management), bdd (`playwright-bdd`, step health tooling, CI sharding),
  exploratory (Whittaker tours, thread-based charters, AI-assisted debrief)
- **qa-web/references/playwright-patterns.md:** Added 15+ Playwright v1.49–v1.59 APIs: aria snapshots,
  `locator.describe()`, `toContainClass`, `setStorageState()`, CHIPS partitioned cookies,
  `--only-changed`, `failOnFlakyTests`, per-project workers, `page.pickLocator()`, Component Testing
  (experimental CT) with MSW router fixture; 10 iterations
- **qa-web/references/cypress-patterns.md:** Fixed `Cypress.Commands.addQuery()` (Cypress 12+) as
  correct retrying-selector API; `experimentalOriginDependencies` flag for `cy.origin()` custom
  commands; Cypress Module API; Vue 3 Component Testing; 3 iterations
- **qa-perf/references/k6-patterns.md:** Fixed deprecated `k6/experimental/websockets` →
  `k6/websockets` (stable); added k6 v0.57+ native TypeScript support via esbuild; CSV
  parameterisation with papaparse + SharedArray; OpenTelemetry stable output; 4 iterations
- **qa-mobile/references/detox-patterns.md:** Added `getAttributes()`, biometrics simulation
  (`matchFace`/`unmatchFace`), `by.traits()`, Expo/EAS integration, React Navigation ghost screen
  strategy, `device.setOrientation()`, flakiness root-cause decision tree; 10 iterations
- **qa-mobile/references/appium-wdio-patterns.md:** Added visual regression (`@wdio/visual-service`),
  device farm integration (BrowserStack/Sauce Labs), accessibility validation, test tagging
  (`WDIO_GREP`), environment/secrets management, quick-reference checklist; 10 iterations
- **lang-refine (5 guides):** All at 100/100. JavaScript: added CJS/ESM interop section, ES2023/2024
  features (`Object.groupBy`, `Promise.withResolvers`, `toSorted`), Symbol.iterator, Map/Set idioms.
  Python: added structural pattern matching (`match`/`case`). TypeScript: added `using`/`await using`
  (TS 5.2), assertion functions, typed decorators (TS 5.0), const type parameters
- **SKILL.md templates updated:** `qa-mobile`, `qa-perf`, `qa-refine`, `qa-web` regenerated from
  agent-updated `.tmpl` files

---

## v1.5.2.0 — 2026-04-26 — Auto-update check on every skill invocation

### Changed (all 10 skills)
- Added `## Version check` section to every `SKILL.md.tmpl` — runs before the Preamble on
  every skill invocation
- Calls `bin/qa-team-update-check` (existing script) to compare local vs remote VERSION
- If `UPGRADE_AVAILABLE`, uses `AskUserQuestion`: "Update before running?" with
  "Yes — update now (recommended)" / "No — run with current version" options
- If user selects "Yes": runs `git -C "$_QA_ROOT" pull && bash "$_QA_ROOT/bin/setup"`
- 10-minute cooldown flag (`$_TMP/.qa-update-asked`) prevents repeated prompts when
  qa-team spawns multiple sub-agents in parallel within the same run
- Repo root resolved via `readlink ~/.claude/skills/<skill-name>` (short-names install)
  with fallback to `readlink ~/.claude/skills/qa-agentic-team` (namespaced/dev install)
- Applies to: `qa-team`, `qa-web`, `qa-api`, `qa-mobile`, `qa-perf`, `qa-visual`,
  `qa-audit`, `qa-refine`, `qa-methodology-refine`, `lang-refine`

---

## v1.5.1.0 — 2026-04-26 — Bash fetch fallback for WebFetch-restricted environments

### Changed (`/qa-refine`, `/qa-methodology-refine`)
- Added `_fetch_text` bash helper to Phase 1a of both research skills
- Helper tries Node 18+ built-in `fetch()` first (repo requires Node ≥ 18), falls back
  to Python3 `urllib.request`, strips HTML tags + entities + whitespace, truncates to 6000 chars
- Parallel fetch supported via `{ _fetch_text URL1 & _fetch_text URL2 & wait; }`
- Updated "if blocked" note at end of Phase 1a and Phase 1b to reference the helper
- Fixes research agents running as background subagents where WebFetch tool permission
  is restricted but outbound HTTP via Bash is still available

---

## v1.5.0.0 — 2026-04-26 — QA methodology layer: /qa-methodology-refine + /qa-audit

### Added (`/qa-methodology-refine`)
- New `/qa-methodology-refine` skill: runs the same autoresearch loop as `/qa-refine`
  but for QA methodology topics rather than tool-specific patterns
- Covers 12 methodology topics: `test-pyramid`, `tdd`, `bdd`, `test-isolation`,
  `test-data`, `contract-testing`, `flakiness`, `coverage`, `ci-cd-testing`,
  `accessibility`, `shift-left`, `exploratory`
- Step 0 topic detection: matches trigger phrases to topic key; prompts if unclear
- Step 0 language detection: same as `/qa-refine` — project signals → TARGET_LANG
- Phase 1a official sources per topic: martinfowler.com, cucumber.io, docs.pact.io,
  xunitpatterns.com, deque axe, WCAG quickref, Google Testing Blog, IBM shift-left
- Phase 1b community sources: Google Testing Blog, martinfowler.com/testing/,
  WebSearch per topic (production experience, anti-patterns, 2025)
- Quality rubric: Principle Coverage (topic checklist) · Code Examples (TARGET_LANG)
  · Tradeoffs & Context · Community Signal — same 0–100 scale as /qa-refine
- Per-topic concept checklist (drives Principle Coverage score): pyramid ratios,
  red-green-refactor, Feature file structure, FIRST principles, Object Mother, Pact
  workflow, flakiness root causes taxonomy, mutation testing tools, fail-fast CI
  ordering, WCAG 2.1 AA, cost-of-defects curve, SBTM charter format
- Output: `qa-methodology/references/<topic>-guide.md` (consumed by /qa-audit)

### Added (`/qa-audit`)
- New `/qa-audit` skill: static analysis of a project's test suite against methodology
  best practices, producing a scored report (0–100) with ranked recommendations
- 5-dimension scoring × 20 pts each: Pyramid Balance · Test Isolation · Test Data
  Strategy · Naming Quality · CI/Coverage Configuration
- Phase 1 test inventory: auto-classifies test files into unit / integration / e2e /
  unclassified using path patterns + import heuristics; computes pyramid ratios
- Phase 2 static checks: test naming quality (grep for vague names), AAA/GWT structure
  markers, shared mutable state detection, sleep/timing dependency count + locations,
  hardcoded test data vs factory/fixture ratio, coverage config & threshold presence,
  CI integration signals
- Phase 3 guide loading: reads `qa-methodology/references/` guides if present; maps
  each finding type to the relevant guide for enriched, sourced recommendations;
  graceful fallback to built-in knowledge when guides not yet generated
- Phase 5 audit report: per-dimension score table, test inventory table, up to 5
  ranked recommendations each with before/after code example and guide reference,
  flakiness risk summary, BDD signals, list of available methodology guides
- Works standalone or as qa-team sub-agent (writes to `$_TMP/qa-audit-report.md`)

### Changed (`/qa-team`)
- Preamble now detects test files (`*.spec.*`, `*.test.*`, `*_test.*`, `*Test.java`)
  and sets `_HAS_TESTS=1` flag
- Phase 0 auto-detection: any project with test files → include **qa-audit** domain
- Phase 0 `SELECTED_DOMAINS` and `DETECTED` echo updated to include `audit` and
  `AUDIT=${_HAS_TESTS}`
- Phase 2 sub-agent list: added `/qa-audit` → `$_TMP/qa-audit-report.md`
- Phase 3 aggregate loop: `for domain in web api mobile perf visual audit`
- Phase 4 report: added "Methodology Audit" section after Visual; updated "Domains
  Tested" line to include `audit`

### Changed (`bin/setup`)
- Echo section updated: reflects all 10 available skills with multi-tool descriptions;
  added `/qa-audit`, `/qa-methodology-refine`, `/qa-refine`, `/lang-refine` entries

---

## v1.4.0.0 — 2026-04-26 — Multi-tool support per QA category

### Added
- **`qa-web/tools/playwright.md`** — Auth (storageState), POM fixture pattern, selector
  ranking (getByRole > getByLabel > getByTestId), `page.route()` mocking, CI shard flags
- **`qa-web/tools/cypress.md`** — `cy.session()` auth, `cy.intercept()` mocking, data-cy
  selectors, Testing Library integration, headless CI flags, JSON reporter dispatch
- **`qa-web/tools/selenium.md`** — `BaseTest` pattern, `By.*` selector hierarchy,
  `WebDriverWait` explicit waits, Java/TS/Python examples, ChromeDriver pinning, headless mode
- **`qa-perf/tools/k6.md`** — Executor selection table, scenario/threshold script template,
  `SharedArray` parameterization, Web Vitals Playwright supplement, CI exit code 99 behavior
- **`qa-perf/tools/jmeter.md`** — Thread Group config, minimal JMX template, JSON token
  extractor, non-GUI `-n` mode, `-J` property overrides, JTL CSV parsing
- **`qa-perf/tools/locust.md`** — `HttpUser` + `@task(weight)` template, multi-class pattern,
  headless flags, `--csv` output, `--exit-code-on-error 1`, CSV stats parsing
- **`qa-web/references/cypress-patterns.md`** — qa-refine-generated Cypress best practices
- **`qa-web/references/selenium-patterns.md`** — qa-refine-generated Selenium best practices
- **`qa-perf/references/jmeter-patterns.md`** — qa-refine-generated JMeter best practices
- **`qa-perf/references/locust-patterns.md`** — qa-refine-generated Locust best practices
- **`qa-mobile/references/maestro-patterns.md`** — qa-refine-generated Maestro best practices

### Changed (`/qa-web`)
- Preamble now detects all three frameworks: Playwright (`playwright.config.*`), Cypress
  (`cypress.config.*`, `cypress/` dir, `"cypress"` in package.json), Selenium
  (`"selenium-webdriver"` in package.json; `selenium` in pom.xml/requirements.txt)
- Tool Selection Gate: exactly one → auto-select; zero or multiple → `AskUserQuestion`
  with recommendations based on project stack
- Phase 2 reads `qa-web/tools/<_WEB_TOOL>.md` sub-file after tool selection
- Phase 3 execute dispatches to the correct runner per `_WEB_TOOL`

### Changed (`/qa-perf`)
- Preamble now detects k6 (scripts/CLI), JMeter (`.jmx` files/CLI), and Locust
  (`locustfile.py`/CLI) with `_K6`, `_JMETER`, `_LOCUST` flags + JMX file count
- Tool Selection Gate: same 3-state pattern as qa-web
- Phase 2 reads `qa-perf/tools/<_PERF_TOOL>.md` sub-file
- Phase 3 execute dispatches per `_PERF_TOOL`

### Changed (`/qa-mobile`)
- Added Maestro detection: `.maestro/` directory, `which maestro`, YAML with Maestro
  commands (`appId:`, `tapOn:`, `assertVisible:`)
- Tool Selection Gate updated for three tools: Detox / Appium / Maestro
- Phase 3 adds inline Maestro YAML flow templates (login, invalid-login, suite runner)
  with Maestro tips (tapOn matching, runFlow reuse, envFile secrets, scrollUntilVisible)
- Phase 4 adds Maestro execute block (`maestro test --format junit --output`)
- Phase 5 report updated: Framework now lists "Detox / Appium+WebDriverIO / Maestro"

### Changed (`/qa-api`)
- Preamble adds language detection setting `_API_TOOL`: pom.xml/build.gradle → `java`;
  requirements.txt/conftest.py/pytest.ini/pyproject.toml → `python`; *.csproj/*.sln → `csharp`;
  Gemfile → `ruby`; package.json (default) → `playwright`
- Phase 3 replaced with 5 language-specific templates:
  TypeScript/JS (Playwright request context), Java (REST Assured + JUnit 5),
  Python (pytest + requests), C# (HttpClient + NUnit), Ruby (RSpec + Faraday)
- Phase 4 execute dispatches to mvn/gradle (Java), pytest (Python), dotnet (C#),
  rspec (Ruby), or npx playwright (JS/TS)
- "Portable by default" rule updated to "Language-native by default"

### Changed (`/qa-team`)
- Preamble now detects Cypress, Selenium, JMeter, Maestro signals alongside existing ones
- Adds `_WEB_TOOL`, `_PERF_TOOL`, `_MOB_TOOL` composite variables for orchestrator routing
- Phase 0 auto-detection rules updated: Cypress/Selenium → qa-web, JMeter → qa-perf,
  Maestro → qa-mobile
- Phase 2 sub-agent prompt template now passes `Detected tool:` field so sub-agents
  skip their tool selection gate when the orchestrator already knows the tool
- Phase 4 report headers now show dynamic tool names per domain

### Changed (`/qa-refine`)
- Tool→skill mapping expanded from 4 to 9 rows: added Cypress, Selenium, JMeter,
  Locust, Maestro — each with full pattern checklists and Phase 1a/1b source URLs
- Tool-language exceptions updated: Cypress (always TS/JS), Locust (always Python),
  Maestro (always YAML — skip TARGET_LANG detection, write flow files)
- Phase 2 reference file paths table updated with 5 new output paths

---

## v1.3.0.0 — 2026-04-26 — Multi-language qa-refine + new lang-refine skill

### Added (`/lang-refine`)
- New `/lang-refine` skill: researches programming language best practices using the same
  autoresearch loop as `/qa-refine` — official docs + community sources → score against a
  4-dimension rubric (Principle Coverage, Code Examples, Language Idioms, Community Signal)
  → iterative refinement until score ≥ 80 or 3 iterations
- Covers 10 language categories: `general` (SOLID, GoF, DRY/KISS/YAGNI, Law of Demeter,
  Composition over Inheritance), `typescript`, `javascript`, `java`, `python`, `csharp`,
  `kotlin`, `ruby`, `bash`, `functional`
- Per-language principle checklists in the rubric (e.g. Python: PEP 8, comprehensions,
  generators, context managers, type hints, dataclasses, EAFP vs LBYL)
- Phase 1a official sources per language (refactoring.guru, typescriptlang.org, peps.python.org,
  kotlinlang.org/docs/idioms, google styleguides, shellcheck.net, etc.)
- Phase 1b community sources per language (iluwatar/java-design-patterns 90k★,
  goldbergyoni/nodebestpractices 91k★, vinta/awesome-python, KotlinBy/awesome-kotlin, etc.)
- Output: `lang-refine/references/<language>-patterns.md` — standalone reference guides
  consumed by `/qa-refine` when a language idiom mismatch is identified

### Changed (`/qa-refine`)
- Added Step 0 — language detection: scans project signals (pom.xml → Java,
  conftest.py/requirements.txt → Python, *.csproj → C#, Gemfile → Ruby,
  package.json → JS/TS); k6, Detox, and WebDriverIO remain JS-only
- Added `TARGET_LANG` variable propagated through all phases
- Phase 1a Playwright URLs now language-specific (playwright.dev/java/docs/,
  playwright.dev/python/docs/, playwright.dev/dotnet/docs/)
- Phase 1a Appium client docs now language-specific (appium/java-client,
  appium/python-client, appium/dotnet-client, appium/ruby_lib)
- Phase 1b WebSearch queries now interpolate `{TARGET_LANG}` for targeted community research
- Phase 2 reference files now language-suffixed for non-TS languages
  (playwright-patterns-java.md, playwright-patterns-python.md) to coexist without overwriting
- Code example rule strengthened: must use actual TARGET_LANG API names, never TypeScript
  syntax in Java/Python examples
- Phase 4 gap→source table now includes "Language idiom mismatch →
  lang-refine/references/<TARGET_LANG>-patterns.md" for cross-skill knowledge transfer
- Phase 6 report now shows Language and Sources used fields

---

## v1.2.0.0 — 2026-04-26 — Expand qa-refine to community sources

### Changed (`/qa-refine`)
- Added Phase 1b: parallel community research alongside official docs — fetches
  awesome lists (mxschmitt/awesome-playwright, grafana/awesome-k6,
  webdriverio/awesome-webdriverio, saikrishna321/awesome-appium), official example
  repos (grafana/k6/examples, wix/Detox/examples, microsoft/playwright-examples,
  checkly/playwright-examples), and targeted WebSearch queries per tool
- Replaced Anti-Pattern rubric dimension with Community Signal (0–25): rewards
  production gotchas sourced from community blogs, GitHub Discussions, and awesome
  lists — patterns the official docs don't document
- Added `[community]` source tags to reference guide entries so readers know which
  patterns are doc-blessed vs. battle-tested in production
- Added "Real-World Gotchas" section to reference guide template (community-only)
- Added gap→source-type lookup table in Phase 4 so each gap is filled from the
  most appropriate source type
- Updated final report to list sources used and annotate top findings by source
- Updated k6 official doc URLs to grafana.com/docs/k6/latest (new canonical location)

---

## v1.1.0.0 — 2026-04-26 — Add qa-refine skill

### Added
- `/qa-refine` — Iterative research skill: fetches official docs for Playwright, k6, Detox,
  Appium/WebDriverIO, scores the result against a 4-dimension quality rubric (0–100), and
  runs an autoresearch-style loop (score → find gaps → targeted fetch → rewrite → re-score →
  keep/revert) until score ≥ 80 or 3 iterations. Also makes surgical updates to the
  corresponding skill's SKILL.md.tmpl. Includes scoring honesty enforcement to prevent
  premature loop exit.

---

## v1.0.0.0 — 2026-04-24 — Initial release

### Added
- `/qa-team` — Orchestrator: auto-detects project type, spawns specialized agents in parallel, aggregates results into a unified quality report
- `/qa-web` — Web E2E agent: discovers pages/routes, writes Playwright specs, executes, reports coverage
- `/qa-api` — API contract agent: reads OpenAPI/routes, generates HTTP tests (status codes, schema, auth enforcement), executes via Playwright request context
- `/qa-mobile` — Mobile agent: detects React Native/Expo (Detox) or native iOS/Android (Appium + WebDriverIO), generates screen tests, runs on simulator/emulator
- `/qa-perf` — Performance agent: writes k6 load scripts + Playwright Web Vitals tests, runs with ramp-up profiles, reports p50/p95/p99
- `/qa-visual` — Visual regression agent: captures Playwright screenshots, diffs against baselines, masks dynamic content, reports pixel regressions
- `bin/setup` — Symlink-based multi-platform installer
- `bin/dev-setup` / `bin/dev-teardown` — Developer mode: live-edits via single namespace symlink
- `bin/qa-team-update-check` — Periodic version check against GitHub main branch
- `bin/qa-team-next-version` — 4-part semver bump calculator
- `scripts/gen-skill-docs.sh` — Regenerates `SKILL.md` from `SKILL.md.tmpl` sources
- `scripts/check-skill-docs.sh` — CI freshness gate: fails if generated docs are stale
- GitHub Actions: `version-gate.yml`, `skill-docs.yml`
