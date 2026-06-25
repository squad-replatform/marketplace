# code-review

Plugin Cursor para review de Pull Requests com contexto do card Jira.

## O que faz

- Recebe uma **URL de PR**, **repo + número**, ou **work item Jira** como input.
- Busca o diff via `gh` CLI e extrai a Jira key do título/branch/body.
- Obtém summary e critérios de aceite do card via plugin `atlassian-assistant`.
- Retorna findings com prefixo de severidade (`🔴 bug` / `🟡 risk` / `❓ q` / `🔵 nit`) e veredito (`merge` / `fix-first` / `block`).
- No modo Jira key: descobre todas as PRs abertas (incluindo drafts) vinculadas ao work item e revisa cada uma em paralelo.

## Exemplos

```
/review https://github.com/naturacode/gsp-cart-api/pull/393
/review gsp-shipping-api #42
/review gsp-cart-api/101
/review JGR-960
```

## Owner default

Owner = `naturacode` (quando não especificado na URL).

## Dependências

### Obrigatório

- **`gh` CLI** instalado e acessível no PATH.
- **`Environments.yaml`** na raiz do repo com `github.token`:

```yaml
github:
  token: "<seu-github-personal-access-token>"
```

### Para contexto Jira (recomendado)

- Plugin **`atlassian-assistant`** instalado (skill `jira-assistant` + MCP `atlassian-gsp`).
- Bloco `atlassian` no `Environments.yaml` — ver [`Environments-template.yaml`](../../Environments-template.yaml).

Sem o atlassian-assistant, o plugin ainda funciona, mas revisa apenas qualidade de código (sem comparar com critérios de aceite).

## Pré-requisitos

```bash
# Validar configuração
bash .marketplace/plugins/code-review/scripts/preflight.sh

# Com validação Atlassian também
CHECK_ATLASSIAN=1 bash .marketplace/plugins/code-review/scripts/preflight.sh
```

Requer `python3` e `PyYAML` (`pip install pyyaml`).

## Componentes

| Componente | Caminho | Descrição |
|------------|---------|-----------|
| Skill | `skills/code-review/SKILL.md` | Metodologia completa de review |
| Subagent | `agents/code-reviewer.md` | Revisa 1 PR (read-only, sem subagents aninhados) |
| Command | `commands/review.md` | `/review` — classifica input, descobre PRs, consolida |
| Script | `scripts/fetch-pr.sh` | Busca metadata + diff de 1 PR |
| Script | `scripts/discover-prs.sh` | Descobre PRs abertas por Jira key |
| Script | `scripts/preflight.sh` | Valida dependências e configuração |
