# Learning Sources: QA Methodology
<!-- updated: 2026-05-06 | entries: 33 | skill-version: 1.12.0.0 -->

Used by: `qa-methodology-refine` (Phase 1a primary), `qa-audit`

---

## Official Documentation & Standards

| Source | URL | Type | Topic | Last Verified | Notes |
|--------|-----|------|-------|---------------|-------|
| BDD — Cucumber Docs | https://cucumber.io/docs/bdd/ | official-docs | bdd | 2026-05-03 | ⭐ BDD primer |
| Gherkin Reference | https://cucumber.io/docs/gherkin/reference/ | official-docs | bdd | 2026-05-03 | ⭐ |
| Pact Docs | https://docs.pact.io/ | official-docs | contract-testing | 2026-05-03 | ⭐ Consumer-driven contracts |
| Pact Consumer Guide | https://docs.pact.io/consumer | official-docs | contract-testing | 2026-05-03 | ⭐ |
| Pact Provider Guide | https://docs.pact.io/provider | official-docs | contract-testing | 2026-05-03 | ⭐ |
| W3C WAI WCAG 2.1 Quick Ref | https://www.w3.org/WAI/WCAG21/quickref/ | official-docs | accessibility | 2026-05-03 | ⭐ 📄 WCAG authority |
| W3C WAI ARIA Authoring | https://www.w3.org/WAI/ARIA/apg/ | official-docs | accessibility | 2026-05-03 | ⭐ ARIA patterns |
| OWASP DevSecOps Guideline | https://owasp.org/www-project-devsecops-guideline/ | official-docs | shift-left | 2026-05-03 | ⭐ Security shift-left |
| axe-core | https://www.deque.com/axe/axe-for-web/ | official-docs | accessibility | 2026-05-03 | ⭐ |
| axe-core GitHub | https://github.com/dequelabs/axe-core | github-repo | accessibility | 2026-05-03 | 🌟 |
| pact-foundation/pact-js | https://github.com/pact-foundation/pact-js | github-repo | contract-testing | 2026-05-03 | 🌟 Official JS Pact client |

---

## Blogs & Community Sources

| Source | URL | Type | Topic | Last Verified | Notes |
|--------|-----|------|-------|---------------|-------|
| Google Testing Blog | https://testing.googleblog.com/ | blog | all | 2026-05-03 | 🌟 Production testing experience |
| Martin Fowler — Testing | https://martinfowler.com/testing/ | blog | all | 2026-05-03 | 🌟 Foundational test strategy |
| Kent C. Dodds — Write Tests | https://kentcdodds.com/blog/write-tests | blog | test-pyramid | 2026-05-03 | 📰 Testing Trophy concept |
| Tracetest Docs | https://docs.tracetest.io/ | official-docs | ci-cd-testing | 2026-05-03 | Distributed trace-based testing |
| Trunk — Flaky Tests | https://trunk.io/flaky-tests | official-docs | flakiness | 2026-05-03 | Flaky test detection + quarantine SaaS |
| PactFlow Blog | https://pactflow.io/blog/ | blog | contract-testing | 2026-05-03 | Contract testing patterns + PactFlow AI beta |
| How They Test | https://abhivaikar.github.io/howtheytest/ | blog | all | 2026-05-04 | 📰 108 companies, 797 resources on real-world testing cultures |

---

## Research & Standards

| Source | URL | Type | Topic | Last Verified | Notes |
|--------|-----|------|-------|---------------|-------|
| ISTQB CTFL 4.0 Syllabus | https://www.istqb.org/certifications/certified-tester-foundation-level | research/standard | all | 2026-05-03 | 📄 Authoritative terminology |
| ISTQB Glossary | https://glossary.istqb.org/ | research/standard | all | 2026-05-03 | 📄 |
| Meta ACH: Mutation-Guided LLM Test Generation | https://arxiv.org/abs/2501.12862 | research/standard | coverage / tdd | 2026-05-03 | 📄 arXiv:2501.12862 — mutation-guided LLM test synthesis |

---

## GitHub Repositories

| Source | URL | Type | Topic | Last Verified | Notes |
|--------|-----|------|-------|---------------|-------|
| langwatch/scenario | https://github.com/langwatch/scenario | github-repo | AI testing / red-teaming | 2026-05-03 | 🌟 869 stars — AI agent red-teaming |
| Codium-ai/cover-agent | https://github.com/Codium-ai/cover-agent | github-repo | coverage | 2026-05-03 | Coverage gap filler via LLM |
| Intelligent-CAT-Lab/FlakyDoctor | https://github.com/Intelligent-CAT-Lab/FlakyDoctor | github-repo | flakiness | 2026-05-03 | Neurosymbolic flaky repair (ISSTA 2024) |
| kubeshop/tracetest | https://github.com/kubeshop/tracetest | github-repo | ci-cd-testing | 2026-05-03 | Trace-based test assertions |
| cucumber/cucumber-js | https://github.com/cucumber/cucumber-js | github-repo | bdd | 2026-05-04 | 🌟 5.3k stars — official JS Cucumber for Gherkin execution |
| pact-foundation/pact_broker | https://github.com/pact-foundation/pact_broker | github-repo | contract-testing | 2026-05-04 | 742 stars — OSS contract registry; share + verify pacts |
| pytest plugin writing | https://docs.pytest.org/en/stable/how-to/writing_plugins.html | official-docs | test-framework | 2026-05-04 | ⭐ conftest.py hooks, entry-point distribution, pytester |
| Pact Nirvana | https://docs.pact.io/pact_nirvana | official-docs | contract-testing | 2026-05-04 | ⭐ 7-level CI/CD maturity roadmap for consumer-driven contracts |
| Martin Fowler — Practical Test Pyramid | https://martinfowler.com/articles/practical-test-pyramid.html | blog | test-pyramid | 2026-05-06 | 🌟 Definitive long-form guide: unit→integration→E2E, redundancy avoidance |
| Pact University | https://docs.pact.io/university | official-docs | contract-testing | 2026-05-06 | ⭐ Free workshops: Pact fundamentals, Message Pact, plugin dev; MIT licensed |
| Pact Broker — Sharing Pacts | https://docs.pact.io/getting_started/sharing_pacts | official-docs | contract-testing | 2026-05-06 | ⭐ CI/CD decoupling pattern; webhooks, network graph, multi-language publish |
| Cucumber 10-Minute Tutorial | https://cucumber.io/docs/guides/10-minute-tutorial/ | official-docs | bdd | 2026-05-06 | ⭐ End-to-end BDD walkthrough: Gherkin→step defs→scenario outlines; Example Mapping |
