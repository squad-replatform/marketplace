---
name: code-review
description: >
  Reviews a GitHub Pull Request given a URL, repo+number, or Jira work item key.
  Fetches PR diff via gh CLI, extracts Jira key, retrieves acceptance criteria via
  atlassian-assistant, and emits severity-tagged findings with a merge verdict.
  Use when the user invokes /review, asks to review a PR, or provides a Jira key
  to review linked open PRs.
---

# Code Review Skill

Review de Pull Request com contexto Jira. Audiência: o autor da PR.

## Inputs aceitos

O `/review` aceita 3 formas. Owner default = `naturacode`.

| Forma | Exemplo | Comportamento |
|-------|---------|---------------|
| URL da PR | `https://github.com/naturacode/gsp-cart-api/pull/393` | 1 PR; owner extraído da URL |
| Repo + número | `gsp-cart-api #393` ou `gsp-cart-api/393` | 1 PR; owner = `naturacode` |
| Work item Jira | `JGR-960` | Descobrir PRs abertas (incl. draft) via `discover-prs.sh`; revisar cada uma |

## Classificação do input

```
URL   → regex: github\.com/([^/]+)/([^/]+)/pull/(\d+)   → owner/repo/number
repo  → regex: ([\w.-]+)\s*[#/]\s*(\d+)                 → owner=naturacode, repo, number
Jira  → regex: [A-Z]+-\d+                                → modo descoberta
```

Se o input não casar com nenhuma forma, pedir esclarecimento.

## Fluxo — PR avulsa (URL ou repo+número)

```
1. fetch-pr.sh <owner> <repo> <number>   → metadata JSON + diff
2. Extrair Jira key do título/branch/body  (regex [A-Z]+-\d+)
3. Se encontrou key → jira-assistant.getJiraIssue → summary + criterios de aceite
4. Revisar diff vs criterios + checklist
5. Emitir findings + veredito
```

## Fluxo — Work item Jira

```
1. discover-prs.sh <JIRA-KEY>   → lista de PRs abertas (open + draft)
2. Se vazio → fallback: gh search prs "<KEY>" --owner naturacode --state open --match body
3. Se ainda vazio → reportar "nenhuma PR encontrada" e parar
4. jira-assistant.getJiraIssue <KEY> → contexto uma vez, reaproveitar entre PRs
5. Para cada PR: disparar subagent code-reviewer (em paralelo quando >1)
6. Consolidar síntese final (tabela de PRs)
```

## Comandos gh

```bash
# Exportar token (necessário antes de qualquer chamada gh)
export GH_TOKEN="$(python3 -c "import yaml; print(yaml.safe_load(open('Environments.yaml'))['github']['token'])")"

# Metadata da PR
gh pr view <number> --repo <owner>/<repo> \
  --json title,body,headRefName,baseRefName,isDraft,url,state

# Diff da PR
gh pr diff <number> --repo <owner>/<repo>

# Busca por Jira key (título)
gh search prs "<KEY>" --owner naturacode --state open --match title \
  --json repository,number,title,isDraft,url

# Busca por Jira key (corpo — fallback)
gh search prs "<KEY>" --owner naturacode --state open --match body \
  --json repository,number,title,isDraft,url
```

## Extração da Jira key

Regex: `[A-Z]+-\d+` — buscar em:
1. Título da PR
2. Nome do branch (`headRefName`)
3. Corpo da PR (`body`)

Usar a primeira key encontrada. Se mais de uma key distinta for encontrada, usar a do título (ou a que foi passada como input).

## Contexto Jira via atlassian-assistant

```
jira-assistant.getJiraIssue(cloudId, issueKey)
  → campos relevantes: summary, description, customfield_11700
```

Criterios de aceite: campo `customfield_11700` (Acceptance Criteria) se disponível; caso contrário, `description`. Não inventar critérios ausentes — se não houver, revisar apenas com o checklist de qualidade e avisar.

## Checklist de revisão

Avaliar **sempre** todos os itens abaixo no diff:

| # | Categoria | O que verificar |
|---|-----------|-----------------|
| 1 | Correção | Lógica implementa o comportamento esperado (criterios de aceite / Jira) |
| 2 | Segurança | Validação de entrada, exposição de segredos, injeção, IDOR |
| 3 | Performance | N+1 queries, loops desnecessários, falta de cache/índice |
| 4 | Error handling | Exceções capturadas/propagadas corretamente; fallbacks adequados |
| 5 | Testes | Casos cobertos; edge cases faltando; asserções superficiais |
| 6 | Aderência aos critérios | Todos os critérios de aceite do Jira cobertos pelo diff |

## Taxonomia de severidade

| Prefixo | Significado | Prioridade |
|---------|-------------|------------|
| `🔴 bug:` | Comportamento quebrado, risco de incidente | 1 — corrigir antes do merge |
| `🟡 risk:` | Funciona mas frágil (race, null, erro engolido) | 2 — corrigir ou aceitar conscientemente |
| `❓ q:` | Dúvida genuína, não sugestão | 3 — responder no PR |
| `🔵 nit:` | Estilo, naming, micro-otimização | 4 — opcional |

**Regras:**
- Todo finding **deve** ter exatamente um prefixo.
- Ordenar findings por prioridade: 🔴 → 🟡 → ❓ → 🔵.
- `Top issue` na tabela de PRs = finding de maior severidade.

## Formato dos findings

```
<file>:L<line>: <prefixo> <problema>. <fix>.
```

Exemplos:
```
src/cart/CartService.java:L47: 🔴 bug: `applyDiscount` não valida `amount < 0`; pode gerar subtotal negativo. Adicionar guard `if (amount < 0) throw new IllegalArgumentException(...)`.
src/cart/CartMapper.java:L12: 🟡 risk: `ObjectMapper` criado por chamada — custo de inicialização a cada request. Injetar como bean singleton.
src/cart/CartController.java:L88: 🔵 nit: nome `data` é genérico; renomear para `cartResponse`.
```

## Contrato de saída

### PR avulsa

```markdown
## {owner}/{repo} #{number} — 🔴 {n} · 🟡 {n} · ❓ {n} · 🔵 {n}

**Título:** {title}  
**Branch:** {head} → {base}  
**Jira:** {KEY} — {summary}  (omitir se não houver key)

### Findings
1. `{file}:L{line}: 🔴 bug: ...`
2. `{file}:L{line}: 🟡 risk: ...`
… (max 8 findings, ordenados por severidade)

### Criterios de aceite não cobertos
- {criterio ausente, se houver}  (omitir seção se todos cobertos)

### Resumo
{1–2 frases: o que a PR entrega + veredito `merge` / `fix-first` / `block`}
```

**Veredito:**
- `merge` — nenhum 🔴
- `fix-first` — há 🔴
- `block` — 🔴 cross-cutting ou impede deploy

### Múltiplas PRs (modo Jira key)

```markdown
# {KEY} — PR review

**Jira:** {summary} · **PRs abertas:** {N}  
**Findings:** 🔴 {N} · 🟡 {N} · ❓ {N} · 🔵 {N}

## Gate
{merge-all | fix-first | block} — {uma frase}

## PRs
| PR | Verdict | Severity | Top issue |
|----|---------|----------|-----------|
| {repo} #{n} | merge \| fix-first \| block | 🔴{n} 🟡{n} | {finding principal} |

## Per-PR findings
### {repo} #{n} — 🔴 {n} · 🟡 {n} · ❓ {n} · 🔵 {n}
1. `{file}:L{line}: 🔴 bug: ...`
…

## Actions
1. 🔴 {ação no bug de maior prioridade}
2. 🟡 {próximo risco}
…
```

## Linguagem da review

- Usar o Jira key (`JGR-960`) e termos do **código/comportamento** (`hasSplit`, `distributionCenterId`).
- **Não** citar IDs de design docs (P1, US*, FR-*, RN-*, T##) na saída — o autor da PR não os reconhece.
- Se citar pattern letter, flag, header ou sigla de lib no **Resumo**, explicar entre parênteses na primeira menção.

## Do not

- Editar código, aprovar ou reprovar no GitHub
- Usar PR fechada/merged como base do review
- Rodar reviews sequencialmente quando paralelo for possível
- Inventar critérios de aceite ausentes
- Citar P1/P2, US*, FR-*, T## na saída final
- Pular o checklist por falta de Jira key (revisar qualidade mesmo sem key)
