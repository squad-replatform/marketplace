---
name: confluence-assistant
description: >
  Confluence skill for this workspace — loads Environments.yaml and runs all Confluence
  MCP ops (search, read, create, update pages and spaces). Use for Confluence pages,
  spaces, documentation, docs, wiki, or any Confluence content operation.
---

# Confluence Assistant

Skill focada em Confluence. Para operacoes em Jira, use `jira-assistant`.

## Every Request

1. Read `Environments.yaml` (raiz do repo) — ver [../_shared/config.md](../_shared/config.md)
2. Executar o workflow Confluence abaixo
3. Auth failure → `mcp_auth (atlassian-gsp)`, retry

---

## Configuration

Ver [../_shared/config.md](../_shared/config.md) para parsing completo do `Environments.yaml`, variaveis `{CLOUD_ID}` / `{SPACE_KEY}`, tratamento de falhas e preflight.

---

## Confluence

**Search:** `search(...)` primeiro — incluir nome/keywords do space da config.

**Read:** `fetch(ari)` | `getConfluencePage` | `getConfluenceSpaces(keys=["{SPACE_KEY}"])` | `getPagesInConfluenceSpace`

IDs: page ID (numerico) ≠ space key (string) ≠ space ID (numerico).

**Create:** `getConfluenceSpaces` → `createConfluencePage(spaceId, title, body)`

**Update:** `updateConfluencePage(pageId, title, body)`

Body: **Markdown only** — headings, lists, code blocks. Validar space antes de criar.

**Nao confundir:** page ID (numerico) vs space key (CAPS string) vs space ID (numerico). ARI: `ari:cloud:confluence:site-id:page/page-id`.

---

## Examples

**Buscar documentacao:**
load config → `search("GSP API documentation")` → `getConfluencePage`

**Atualizar pagina:**
search → `getConfluencePage` → merge content → `updateConfluencePage`

Ver exemplos detalhados em [reference.md](reference.md).

**Multi-resource (subagents):**
um subagent por page/query, cada um seguindo esta skill com `{CLOUD_ID}` e `{SPACE_KEY}` injetados. Retornar fatos estruturados — sem narrativa.

---

## Do not

- Pedir Cloud ID quando YAML resolver
- Usar HTML no body de paginas (Markdown only)
- Confundir page ID com space key ou space ID

## Related

- [reference.md](reference.md) — exemplos de create/update, estrutura de body
- [../_shared/config.md](../_shared/config.md) — configuracao via Environments.yaml
