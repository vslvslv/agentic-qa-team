# Learning Sources Catalog
<!-- updated: 2026-05-03 | version: 1.12.0.0 -->

Maintained by `/learning-sources-refinement`. Run that skill to search for new sources,
verify staleness, and update this catalog. All refine skills read from this catalog
before falling back to hardcoded URLs (catalog-first integration).

## Domains

| Domain | File | Entries | Last Updated |
|--------|------|---------|--------------|
| QA Tools | [qa-tools.md](qa-tools.md) | 30 | 2026-05-03 |
| QA Methodology | [qa-methodology.md](qa-methodology.md) | 22 | 2026-05-03 |
| Languages | [languages.md](languages.md) | 28 | 2026-05-03 |
| Security, A11y & AI Testing | [security-a11y-ai.md](security-a11y-ai.md) | 20 | 2026-05-03 |

## Usage by Refine Skills

| Skill | Reads | When |
|-------|-------|------|
| `lang-refine` | `languages.md` | Phase 1a — before hardcoded language fallbacks |
| `qa-refine` | `qa-tools.md` | Phase 1a — before hardcoded tool fallbacks |
| `qa-methodology-refine` | `qa-methodology.md` | Phase 1a — before hardcoded methodology fallbacks |
| `qa-security` | `security-a11y-ai.md` | Supplemental — new tool discovery |
| `qa-a11y` | `security-a11y-ai.md` | Supplemental — new tool discovery |

## Entry Format

All domain files use this table column format:

```
| Source | URL | Type | Topic/Language | Last Verified | Notes |
```

Types: `official-docs` · `github-repo` · `blog` · `research/standard`

Quality tiers (informational):
- ⭐ Official source (authoritative, vendor-maintained)
- 🌟 Community flagship (>10k GitHub stars or widely cited)
- 📰 Blog/article (practitioner experience)
- 📄 Research/standard (academic or standards body)
