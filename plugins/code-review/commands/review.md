---
name: review
description: >
  Revisa uma Pull Request a partir de URL, repo+número, ou work item Jira.
  Busca o diff via gh CLI, extrai contexto do card Jira via atlassian-assistant,
  e retorna findings com severidade e veredito de merge.
---

# /review

Revisa Pull Request(s) com contexto Jira. Leia e siga a skill `code-review` para o fluxo completo.

## Uso

```
/review <input>
```

onde `<input>` é uma das 3 formas:

```
/review https://github.com/naturacode/gsp-cart-api/pull/393
/review gsp-cart-api #393
/review JGR-960
```

## Parsing do input

### 1. URL da PR

Regex: `github\.com/([^/]+)/([^/]+)/pull/(\d+)`

```
owner  = captura 1
repo   = captura 2
number = captura 3
→ modo: 1 PR
```

### 2. Repo + número

Regex: `([\w.\-]+)\s*[#/]\s*(\d+)`

```
owner  = naturacode
repo   = captura 1
number = captura 2
→ modo: 1 PR
```

### 3. Work item Jira

Regex: `^[A-Z]+-\d+$`

```
jira_key = input
→ modo: descoberta de PRs
```

Se o input não casar com nenhum padrão, responder:
> Não reconheci o formato. Use: URL da PR, `repo #número`, ou uma Jira key (ex.: `JGR-960`).

## Comportamento por modo

### Modo: 1 PR (URL ou repo+número)

1. Rodar `preflight.sh` — interromper se falhar.
2. Disparar subagent `code-reviewer` com `{owner, repo, number, jira_key: null}`.
3. Retornar o output do subagent diretamente.

### Modo: descoberta (Jira key)

1. Rodar `preflight.sh` — interromper se falhar.
2. Executar `discover-prs.sh <KEY>` para listar PRs abertas (open + draft) no título.
3. Se vazio → repetir com `gh search prs "<KEY>" --owner naturacode --state open --match body`.
4. Se ainda vazio → responder "nenhuma PR aberta encontrada para `<KEY>`" e parar.
5. Resolver contexto Jira **uma vez** via `jira-assistant.getJiraIssue` (reaproveitado por todas as PRs).
6. Disparar **1 subagent `code-reviewer` por PR em paralelo** (quando >1), passando `{owner, repo, number, jira_key: KEY}`.
7. Aguardar todos os subagents.
8. Consolidar síntese final (tabela + per-PR findings + actions) conforme contrato da skill `code-review`.

## Pré-requisitos

- `Environments.yaml` na raiz do repo com `github.token`.
- `gh` CLI instalado e acessível no PATH.
- Para contexto Jira: plugin `atlassian-assistant` instalado e `atlassian.cloudId` em `Environments.yaml`.

## Exemplos

```
/review https://github.com/naturacode/gsp-cart-api/pull/393
/review gsp-shipping-api #42
/review gsp-orders-api/101
/review JGR-960
/review JGR-189
```

## Erros comuns

- **Token ausente:** `preflight.sh` falha com mensagem clara → preencher `github.token` em `Environments.yaml`.
- **gh não instalado:** `preflight.sh` falha → instalar `gh` CLI.
- **Nenhuma PR encontrada:** modo descoberta retorna vazio → verificar se há PRs abertas com a key no título/body.
- **MCP Atlassian indisponível:** `code-reviewer` avisa e revisa sem contexto Jira.
