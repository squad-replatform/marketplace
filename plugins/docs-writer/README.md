# docs-writer

Plugin Cursor para geração de design docs em PT-BR via comando único `/write-docs`.

## O que faz

- Recebe um `kind` (`theme`, `adr`, `rfc`), um código de tema (`E1`, `EP2`, ...) e um assunto.
- Consulta automaticamente **Jira**, **Confluence** e o **codebase** como fontes de contexto.
- Executa um pipeline obrigatório de **3 fases** (Extração → Síntese → Consolidação), cada uma num subagent dedicado.
- Grava os docs finais em `.docs/` agrupados por tema, respeitando templates **hard-constrained** por tipo.

## Exemplos

```
/docs theme E1 split de CD no checkout
/docs theme E1 split de CD no checkout --from prd-tdd
/docs adr E1 escolha do banco de eventos
/docs rfc padronizar envelope de eventos
```

## Estratégias

| # | Trigger | Docs gerados |
|---|---------|-------------|
| 1 | `kind=theme`, sem PRD | PRD → TDD(s) → tasks |
| 2 | `kind=theme`, PRD existe, sem TDD | TDD(s) → tasks |
| 3 | `kind=theme`, PRD + TDD(s) existem | tasks |
| 4 | `kind=adr` | 1 ADR (agrupado no tema se `cod` presente, solto se ausente) |
| 5 | `kind=rfc` | 1 RFC (agrupado no tema se `cod` presente, solto se ausente) |

`--from scratch|prd|prd-tdd` força a estratégia ignorando a auto-detecção.

## Pipeline de 3 fases

```
/docs (orquestrador)
  └─ Fase 1: docs-extractor (sonnet)   — lança em paralelo:
       ├─ docs-src-jira       (sonnet, readonly)
       ├─ docs-src-confluence (sonnet, readonly)
       └─ docs-src-codebase   (sonnet, readonly)
             [saída: .docs/.work/<run-id>/01-extract/]
  └─ Fase 2: docs-synthesizer (opus)
             [saída: .docs/.work/<run-id>/02-synth/]
  └─ Fase 3: docs-consolidator (sonnet)
             [saída: .docs/<tema>/<tipo>/...]
```

- **Fase 1** extrai fatos estruturados de Jira, Confluence e codebase; valida frescor.
- **Fase 2** sintetiza em formato otimizado para IA (claims normalizados, glossário, lacunas).
- **Fase 3** escreve os docs finais usando os templates e a skill `doc-style` (único agente que grava em `.docs/`).

## Convenção de output em `.docs`

```
.docs/<COD>-<desc_snake>/<tipo>/<tipo><NN>-<slug>.md
```

Exemplos:
```
.docs/E1-split_cd/prd/prd01-split-de-cd-no-checkout.md
.docs/E1-split_cd/tdd/tdd01-split-de-cd-no-checkout.md
.docs/E1-split_cd/tasks/tasks01-split-de-cd-no-checkout.md
.docs/E1-split_cd/adr/adr01-escolha-do-banco-de-eventos.md
.docs/rfc/rfc0001-padronizar-envelope-de-eventos.md
```

Arquivos de trabalho temporários em `.docs/.work/` (pode ser gitignored).

## Modelos

| Agente | Modelo |
|--------|--------|
| `docs-extractor`, `docs-consolidator`, `docs-src-*` | `claude-4.6-sonnet-medium-thinking` |
| `docs-synthesizer` | `claude-opus-4-8-thinking-high` |

**Limitação conhecida:** o campo `model` em subagents de plugins de marketplace pode ser ignorado pelo Cursor (honrado em subagents locais `.cursor/agents/`). Os valores estão declarados para quando a limitação for resolvida. Workaround: copiar os agentes para `.cursor/agents/` no seu repo.

## Dependências

### Obrigatório

- Plugin **`atlassian-assistant`** instalado (skills `jira-assistant` + `confluence-assistant` + MCP `atlassian-gsp`).
- **`Environments.yaml`** na raiz do repo com bloco `atlassian`:

```yaml
atlassian:
  cloudId: "<seu-cloud-id>"
  jira:
    boards:
      - key: "<PROJECT-KEY>"
  confluence:
    spaces:
      - key: "<SPACE-KEY>"
```

### Recomendado

- Plugin **`gsp-guidelines`** instalado — usado como fonte primária de contexto de codebase (skills `gsp-*` + rule de discovery).

A skill `codenav` é própria do plugin (`skills/codenav/`) e não requer dependência externa; é acionada apenas quando `gsp-guidelines` não for suficiente. Fallback final ao `explore` nativo.

## Pré-requisitos

```bash
# Validar configuração
bash .marketplace/plugins/docs-writer/scripts/preflight.sh
```

Requer `python3` e `PyYAML` (`pip install pyyaml`).

## Componentes

| Componente | Caminho | Descrição |
|------------|---------|-----------|
| Skill | `skills/docs-writer/SKILL.md` | Metodologia completa (estratégias, pipeline, naming, templates) |
| Skill | `skills/doc-style/SKILL.md` | Padrão de escrita humana (fase 3) |
| Skill | `skills/codenav/SKILL.md` | Recon read-only de codebase (acionada quando gsp-guidelines não bastar) |
| Templates | `skills/docs-writer/templates/` | prd, tdd, rfc, adr, tasks — hard-constrained |
| Command | `commands/docs.md` | `/write-docs` — parsing, preflight, resolução, orquestração |
| Rule | `rules/docs-writer-entrypoint.mdc` | Avalia uso do plugin por intenção semântica |
| Agent | `agents/docs-extractor.md` | Fase 1 — lança fontes em paralelo, valida frescor |
| Agent | `agents/docs-synthesizer.md` | Fase 2 — síntese otimizada para IA |
| Agent | `agents/docs-consolidator.md` | Fase 3 — escreve docs finais |
| Agent | `agents/docs-src-jira.md` | Fonte Jira (readonly) |
| Agent | `agents/docs-src-confluence.md` | Fonte Confluence (readonly) |
| Agent | `agents/docs-src-codebase.md` | Fonte Codebase (readonly) |
| Script | `scripts/preflight.sh` | Valida dependências e configuração |
