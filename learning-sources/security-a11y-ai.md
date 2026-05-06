# Learning Sources: Security, Accessibility & AI/Agent Testing
<!-- updated: 2026-05-06 | entries: 53 | skill-version: 1.12.0.0 -->

Used by: `qa-security` (supplemental), `qa-a11y` (supplemental), all refine skills

---

## Security Testing

| Source | URL | Type | Topic | Last Verified | Notes |
|--------|-----|------|-------|---------------|-------|
| OWASP Top 10 | https://owasp.org/www-project-top-ten/ | research/standard | web security | 2026-05-03 | 📄 ⭐ Authority |
| OWASP API Security Top 10 | https://owasp.org/www-project-api-security/ | research/standard | API security | 2026-05-03 | 📄 ⭐ |
| OWASP Testing Guide | https://owasp.org/www-project-web-security-testing-guide/ | official-docs | security testing | 2026-05-03 | ⭐ |
| ZAP MCP Docs | https://www.zaproxy.org/blog/2025-04-16-zap-now-has-an-mcp-server/ | official-docs | DAST | 2026-05-03 | ⭐ April 2025 MCP add-on |
| ZAP GitHub | https://github.com/zaproxy/zaproxy | github-repo | DAST | 2026-05-03 | 🌟 28k+ stars |
| Nuclei Templates | https://github.com/projectdiscovery/nuclei | github-repo | vulnerability scanning | 2026-05-03 | 🌟 28k+ stars — 9000+ templates |
| Nuclei Docs | https://docs.projectdiscovery.io/tools/nuclei/overview | official-docs | vulnerability scanning | 2026-05-03 | ⭐ |
| BurpMCP | https://github.com/swgee/BurpMCP | github-repo | authenticated testing | 2026-05-03 | Burp Suite MCP extension |
| Aboudjem/sniff | https://github.com/Aboudjem/sniff | github-repo | network sniffing | 2026-05-03 | HTTP/S traffic capture for security analysis |
| CyberWardion/ai-pentest-agent | https://github.com/CyberWardion/ai-pentest-agent | github-repo | AI pentesting | 2026-05-03 | AI-driven penetration testing agent |
| trufflesecurity/trufflehog | https://github.com/trufflesecurity/trufflehog | github-repo | secrets scanning | 2026-05-04 | 🌟 26k stars — 800+ secret types, active credential verification |
| semgrep/semgrep | https://github.com/semgrep/semgrep | github-repo | static analysis / SAST | 2026-05-04 | 🌟 15k stars — fast multi-language SAST with 30+ languages |
| dependency-check/DependencyCheck | https://github.com/dependency-check/DependencyCheck | github-repo | SCA / CVE scanning | 2026-05-04 | 🌟 7.5k stars — OWASP SCA; detects known CVEs in dependencies |
| OWASP/wstg | https://github.com/OWASP/wstg | github-repo | security testing | 2026-05-04 | 🌟 9.2k stars — Web Security Testing Guide v5.0 in progress |
| juice-shop/juice-shop | https://github.com/juice-shop/juice-shop | github-repo | security training | 2026-05-04 | 🌟 13.1k stars — deliberately vulnerable app; 112 challenges |
| google/oss-fuzz | https://github.com/google/oss-fuzz | github-repo | fuzzing | 2026-05-04 | 🌟 12.2k stars — continuous fuzzing for OSS; 13k+ CVEs found |
| OWASP Mobile App Security | https://owasp.org/www-project-mobile-app-security/ | official-docs | mobile security | 2026-05-04 | ⭐ MASVS + MASTG + MASWE; mobile security standard |
| OWASP ASVS | https://owasp.org/www-project-application-security-verification-standard/ | official-docs | web app security | 2026-05-06 | ⭐ 📄 Flagship — v5.0 (May 2025); web app security verification requirements |
| OWASP LLM Verification Standard | https://owasp.org/www-project-llm-verification-standard/ | official-docs | AI/LLM security | 2026-05-06 | 📄 v0.1 — 7 objectives: LLM-specific design, training, ops, monitoring security |
| aquasecurity/trivy | https://github.com/aquasecurity/trivy | github-repo | container / SCA security | 2026-05-06 | 🌟 34.9k stars — CVEs, IaC misconfig, secrets, SBOM; containers, K8s, git repos |
| gitleaks/gitleaks | https://github.com/gitleaks/gitleaks | github-repo | secrets scanning | 2026-05-06 | 🌟 26.6k stars — regex+entropy detection; pre-commit hook, GH Action, SARIF output |

---

## Accessibility Testing

| Source | URL | Type | Topic | Last Verified | Notes |
|--------|-----|------|-------|---------------|-------|
| W3C WAI WCAG 2.1 | https://www.w3.org/WAI/WCAG21/quickref/ | research/standard | accessibility | 2026-05-03 | 📄 ⭐ WCAG authority |
| W3C WAI WCAG 2.2 | https://www.w3.org/WAI/WCAG22/quickref/ | research/standard | accessibility | 2026-05-04 | 📄 ⭐ Current WCAG standard — supersedes 2.1 |
| W3C WAI ARIA | https://www.w3.org/WAI/ARIA/apg/ | official-docs | accessibility | 2026-05-03 | ⭐ ARIA patterns |
| Deque axe-core | https://www.deque.com/axe/axe-for-web/ | official-docs | accessibility | 2026-05-03 | ⭐ |
| dequelabs/axe-core GitHub | https://github.com/dequelabs/axe-core | github-repo | accessibility | 2026-05-03 | 🌟 |
| navable-web-accessibility-mcp | https://github.com/web-DnA/navable-web-accessibility-mcp | github-repo | accessibility | 2026-05-03 | MCP-based a11y testing |
| Pa11y | https://pa11y.org/ | official-docs | accessibility | 2026-05-03 | Automated a11y scanning |
| architzero/Aura-accessibility-scanner | https://github.com/architzero/Aura-accessibility-scanner | github-repo | accessibility | 2026-05-03 | AI-generated alt text + axe violations |
| Farhod75/ai-a11y-testing | https://github.com/Farhod75/ai-a11y-testing | github-repo | accessibility | 2026-05-03 | AI-assisted accessibility testing patterns |
| microsoft/accessibility-insights-web | https://github.com/microsoft/accessibility-insights-web | github-repo | accessibility | 2026-05-04 | 899 stars — MS Chrome/Edge extension for WCAG 2.1 AA assessment |

---

## AI / Agent Testing

| Source | URL | Type | Topic | Last Verified | Notes |
|--------|-----|------|-------|---------------|-------|
| langwatch/scenario | https://github.com/langwatch/scenario | github-repo | AI agent red-teaming | 2026-05-03 | 🌟 869 stars — adversarial AI probing |
| ctrf-io/ctrf | https://github.com/ctrf-io/ctrf | github-repo | test reporting standard | 2026-05-03 | 🌟 Universal test result format |
| ctrf-io/ai-test-reporter | https://github.com/ctrf-io/ai-test-reporter | github-repo | AI test reporting | 2026-05-03 | Claude/GPT failure summarizer |
| NihadMemmedli/quorvex_ai | https://github.com/NihadMemmedli/quorvex_ai | github-repo | AI test generation | 2026-05-03 | 4-stage Plan/Generate/Validate/Heal |
| modal-labs/devlooper | https://github.com/modal-labs/devlooper | github-repo | AI code loop | 2026-05-03 | 🌟 468 stars — diagnose-then-fix loop |
| proffesor-for-testing/agentic-qe | https://github.com/proffesor-for-testing/agentic-qe | github-repo | agentic QA | 2026-05-03 | 60+ agents, pattern memory, risk-weighted gaps |
| testsigmahq/testsigma | https://github.com/testsigmahq/testsigma | github-repo | AI QA platform | 2026-05-03 | 1.2k stars — GenAI QA with Generator/Runner/Healer agents |
| final-run/finalrun-agent | https://github.com/final-run/finalrun-agent | github-repo | Mobile QA AI | 2026-05-03 | 253 stars — YAML-driven mobile QA agent |
| Agent-Field/SWE-AF | https://github.com/Agent-Field/SWE-AF | github-repo | SWE agent fleet | 2026-05-03 | 742 stars — hardness-aware agent routing |
| bug0inc/passmark | https://github.com/bug0inc/passmark | github-repo | Visual AI consensus | 2026-05-03 | 690 stars — multi-model visual test consensus |
| mnotgod96/AppAgent | https://github.com/mnotgod96/AppAgent | github-repo | Mobile AI agent | 2026-05-03 | 🌟 6.7k stars — multimodal mobile test agent |
| X-PLUG/MobileAgent | https://github.com/X-PLUG/MobileAgent | github-repo | Mobile AI agent | 2026-05-03 | 🌟 8.6k stars — multi-agent with Reflector for flaky recovery |
| bytedance/UI-TARS | https://github.com/bytedance/UI-TARS | github-repo | Vision UI agent | 2026-05-03 | 🌟 10.2k stars — vision-native UI interaction model |
| microsoft/OmniParser | https://github.com/microsoft/OmniParser | github-repo | UI parsing | 2026-05-03 | 🌟 24.7k stars — CV-based UI element detection |
| neu-se/testpilot2 | https://github.com/neu-se/testpilot2 | github-repo | LLM test generation | 2026-05-03 | LLM-driven test suite generation research |
| robusta-dev/holmesgpt | https://github.com/robusta-dev/holmesgpt | github-repo | AI RCA | 2026-05-03 | 🌟 2.3k stars — CNCF Sandbox AI root-cause analysis |
| EsraaKamel11/Autonomous-QA-Agent-Framework | https://github.com/EsraaKamel11/Autonomous-QA-Agent-Framework | github-repo | Autonomous QA | 2026-05-03 | Confidence-gated repair pipeline (auto-commit / review / issue) |
| test-zeus-ai/testzeus-hercules | https://github.com/test-zeus-ai/testzeus-hercules | github-repo | Gherkin execution | 2026-05-03 | 997 stars — Gherkin + DOM distillation, no hardcoded selectors |
| confident-ai/deepeval | https://github.com/confident-ai/deepeval | github-repo | LLM evaluation | 2026-05-04 | 🌟 15.1k stars — pytest-like LLM eval: RAG, agents, multimodal |
| promptfoo/promptfoo | https://github.com/promptfoo/promptfoo | github-repo | LLM red-teaming | 2026-05-04 | 🌟 20.8k stars — LLM eval + automated red-teaming CLI |
| openai/evals | https://github.com/openai/evals | github-repo | LLM benchmarks | 2026-05-04 | 🌟 18.4k stars — open-source LLM benchmark registry |
| agentops-ai/agentops | https://github.com/agentops-ai/agentops | github-repo | AI agent monitoring | 2026-05-06 | 🌟 5.5k stars — observability for AI agents: session replay, LLM cost tracking, multi-agent graphs |
