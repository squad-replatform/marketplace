---
name: jira-assistant
description: >
  Jira skill for this workspace — loads Environments.yaml and runs all Jira MCP ops
  (search, create, update, transition, comments). Use for Jira issues, tickets,
  sprints, JQL queries, transitions, or any Jira work item operation.
---

# Jira Assistant

Skill focada em Jira. Para operacoes em Confluence, use `confluence-assistant`.

## Every Request

1. Read `Environments.yaml` (raiz do repo) — ver [../_shared/config.md](../_shared/config.md)
2. Executar o workflow Jira abaixo
3. Auth failure → `mcp_auth (atlassian-gsp)`, retry

---

## Configuration

Ver [../_shared/config.md](../_shared/config.md) para parsing completo do `Environments.yaml`, variaveis `{CLOUD_ID}` / `{PROJECT_KEY}`, tratamento de falhas e preflight.

---

## Jira

**Search:** `search(...)` primeiro (linguagem natural). **Filtro:** `searchJiraIssuesUsingJql` — **sempre** `project = {PROJECT_KEY}` no JQL.

**Read:** `fetch(ari)` ou `getJiraIssue(cloudId, issueKey)` — chave `{PROJECT_KEY}-123`, ID numerico.

**Create:** `getJiraProjectIssueTypesMetadata` → `getJiraIssueTypeMetaWithFields` → `createJiraIssue`

Tipos: Task (padrao), Epic, Subtask (`parent` obrigatorio). No create, ler [reference.md](reference.md) para o template de descricao.

**Update:** `editJiraIssue` (fields, assignee, description)

**Transition:** `getTransitionsForJiraIssue` → `transitionJiraIssue`

**Comment:** `addCommentToJiraIssue`

Todos os calls: `cloudId="{CLOUD_ID}"`, `projectKey="{PROJECT_KEY}"`. Para JQL, ver [reference.md](reference.md).

---

## Examples

**Minhas tarefas em progresso:**
load config → `searchJiraIssuesUsingJql(jql="project = {PROJECT_KEY} AND assignee = currentUser() AND status = 'In Progress'")`

**Criar task:**
load config → ler [reference.md](reference.md) → `createJiraIssue(...)`

**Subtask:**
`createJiraIssue(..., issueTypeName="Subtask", parent="{PROJECT_KEY}-789")`

**Mover para Done:**
`getTransitionsForJiraIssue` → `transitionJiraIssue`

**Multi-resource (subagents):**
um subagent por issue/query, cada um seguindo esta skill com `{CLOUD_ID}` e `{PROJECT_KEY}` injetados. Retornar fatos estruturados — sem narrativa.

---

## Do not

- Pedir Cloud ID quando YAML resolver
- Omitir `project = {PROJECT_KEY}` no JQL
- Incluir file paths em descricoes Jira
- Usar HTML em campos de texto

## Related

- [reference.md](reference.md) — template de task, JQL snippets
- [../_shared/config.md](../_shared/config.md) — configuracao via Environments.yaml
