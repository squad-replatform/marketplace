---
name: docs-writer
description: >
  Metodologia completa do plugin docs-writer: 5 estrategias, pipeline obrigatorio de 3 fases
  (Extracao -> Sintese -> Consolidacao), politica de modelos, naming/slug/tema, numeracao de
  arquivos, encadeamento PRD->TDD->backlog->task, contrato de arquivos temporarios e regras
  hard-constrained de templates. Use ao executar /write-docs ou ao implementar qualquer fase
  do pipeline.
---

# Skill: docs-writer

Metodologia do plugin `docs-writer`. Todo agente que participar do pipeline DEVE ler esta skill.

## Estrategias

A estrategia define QUAIS docs serao gerados. Todas passam pelas 3 fases.

| # | Trigger | Docs gerados |
|---|---------|-------------|
| 1 | `kind=theme`, sem PRD no tema | PRD -> TDD(s) -> backlog |
| 2 | `kind=theme`, PRD existe, sem TDD | TDD(s) -> backlog |
| 3 | `kind=theme`, PRD + TDD(s) existem | backlog |
| 4 | `kind=adr` | 1 ADR (agrupado se `cod` presente, solto se ausente) |
| 5 | `kind=rfc` | 1 RFC (agrupado se `cod` presente, solto se ausente) |

`--from scratch|prd|prd-tdd` forca a estrategia ignorando a auto-deteccao.

## Parsing do comando `/write-docs`

```
/docs <kind> [<cod>] <assunto> [--from scratch|prd|prd-tdd]
```

- `kind` = 1o token; validos: `theme`, `adr`, `rfc`. Se invalido, listar validos e parar.
- `cod` = proximo token SE casar com `^[A-Za-z]+\d+$` (ex.: `E1`, `EP2`); normalizar para maiusculo.
- `assunto` = tokens restantes (exceto `--from <valor>`).
- `slug` = `assunto` em kebab-case ASCII minusculo (sem acentos, nao-alfanumerico -> hifen, hifens multiplos -> 1).
- `desc_snake` = descricao curta do tema em snake_case ASCII (para nomear a pasta).

## Resolucao de tema

- Varrer `.docs/<COD>-*`. Se encontrar, reusar (extrair `desc_snake` do nome da pasta).
- Se nao encontrar: perguntar descricao curta, derivar `desc_snake`, criar `.docs/<COD>-<desc_snake>/`.

## Convencao de paths em `.docs`

### Agrupado por tema (PRD, TDD, backlog, task; ADR/RFC com `cod`)

```
.docs/<COD>-<desc_snake>/<tipo>/<tipo><NN>-<slug>.md
```

- `<NN>` = 2 digitos sequencial POR TIPO DENTRO DO TEMA (varre `<tipo>*`, maior + 1, inicia em `01`).
- Exemplos:
  - `.docs/E1-split_cd/prd/prd01-split-de-cd-no-checkout.md`
  - `.docs/E1-split_cd/tdd/tdd01-split-de-cd-no-checkout.md`
  - `.docs/E1-split_cd/adr/adr01-escolha-do-banco-de-eventos.md`

#### Work items (task) dentro de um tema

Cada linha do backlog pode ser expandida em um arquivo individual:

```
.docs/<COD>-<desc_snake>/tasks/T<NN>-<slug>.md
```

- `<NN>` = 2 digitos que correspondem ao ID da linha no backlog (T01, T02, ...).
- `<slug>` = titulo da task em kebab-case ASCII.
- O arquivo `tasks<NN>-<slug>.md` (backlog) permanece como ponto de entrada do conjunto; os arquivos `T<NN>-...` sao os work items individuais.

### Solto (ADR/RFC sem `cod`)

```
.docs/adr/adr<NNNN>-<slug>.md
.docs/rfc/rfc<NNNN>-<slug>.md
```

- `<NNNN>` = 4 digitos sequencial GLOBAL dentro de `.docs/adr` (ou `.docs/rfc`), maior + 1, inicia em `0001`.

Criar diretorios faltantes. Se o arquivo ja existir, confirmar sobrescrita antes de gravar.

## Encadeamento (chain)

A cadeia PRD -> TDD -> backlog -> task vive DENTRO DO MESMO TEMA, ligada pelo `slug`.

- **TDD**: se existe `.docs/<tema>/prd/*-<slug>.md`, preencher `prd:` no frontmatter e secao "PRD relacionado" (link relativo `../prd/...`).
- **backlog**: linkar TDD(s) e PRD de mesmo slug no tema (secao "Contexto / docs de origem"). Cada celula Titulo na tabela de tarefas deve conter um link relativo para o `T<NN>-...md` correspondente quando o work item existir.
- **task**: preencher `relacionados` com links para o backlog, TDD(s) e PRD do tema. Secao "Notas tecnicas" deve referenciar dependencias de outras tasks.
- **PRD**: secao "Documentos derivados" lista TDD/backlog/tasks de mesmo slug se ja existirem, senao `pendente`.
- **RFC/ADR**: alheios a cadeia, mas tem secao "Referencias" para citar/ser citados. Agrupados no mesmo tema usam links relativos dentro de `.docs/<tema>/`.

## Contrato de arquivos temporarios

```
.docs/.work/<run-id>/
  request.json           # kind, estrategia, cod, tema, assunto, slug, alvos, paths resolvidos
  01-extract/
    jira.json
    confluence.json
    codebase.json
    evidence-index.json  # claim_id, statement, sources[], origin_date, freshness, corroboracao
  02-synth/
    synthesis.md
    index.json
```

`run-id` = `<COD>-<slug>-<timestamp>` (temas) ou `<kind>-<slug>-<timestamp>` (ADR/RFC soltos).

`.docs/.work/` persiste para rastreabilidade e pode ser gitignored.

So a fase 3 (`docs-consolidator`) escreve fora de `.work/`.

## Pipeline obrigatorio de 3 fases

```
/docs (orquestrador)
  └─ Fase 1: docs-extractor (sonnet)
       ├─ docs-src-jira       (sonnet, readonly)
       ├─ docs-src-confluence (sonnet, readonly)
       └─ docs-src-codebase   (sonnet, readonly)
         [saida: 01-extract/]
  └─ Fase 2: docs-synthesizer (opus)
       [leitura: 01-extract/ | saida: 02-synth/]
  └─ Fase 3: docs-consolidator (sonnet)
       [leitura: 02-synth/ + templates/ + skill doc-style | saida: .docs/...]
```

### Fase 1 — Extracao (`docs-extractor`, sonnet)

- Lanca em paralelo `docs-src-jira`, `docs-src-confluence`, `docs-src-codebase`.
- Cada fonte retorna fatos estruturados com `claim_id`, `statement`, `sources[]`, `origin_date`.
- Regra de frescor: claim com `origin_date` > `STALE_MONTHS` (default 12) nao pode ser `atual`;
  exige corroboracao em >= 2 fontes independentes (ou fonte recente autoritativa) para `confirmado`.
- Conflitos entre fontes sao registrados explicitamente no `evidence-index.json`.
- Grava `01-extract/` em `.work/<run-id>/`.

Mapeamento de fontes:
- **Jira** -> plugin `atlassian-assistant`, skill `jira-assistant`.
- **Confluence** -> plugin `atlassian-assistant`, skill `confluence-assistant`.
- **Codebase** -> prioridade: (1) plugin `gsp-guidelines` (skills `gsp-*`); (2) skill propria `codenav` quando `gsp-guidelines` nao bastar; (3) `explore` nativo como fallback.

### Fase 2 — Sintese (`docs-synthesizer`, opus)

- Le `01-extract/`, indexa, referencia, sintetiza e contextualiza.
- Output otimizado para IA: claims normalizados com IDs, glossario, log de decisoes,
  mapa de cross-referencia claim->secao/doc, lacunas explicitas. Denso, pouca prosa.
- Grava `02-synth/synthesis.md` e `02-synth/index.json`.

### Fase 3 — Consolidacao (`docs-consolidator`, sonnet)

- Le `02-synth/`, carrega templates e skill `doc-style`.
- Escreve docs finais otimizados para HUMANO (coesos, bem estruturados), respeitando o contrato hard-constrained.
- UNICA fase que grava em `.docs` nos paths finais.
- Lacunas viram `> [!QUESTAO] ...` nas secoes de questoes em aberto.

## Politica de modelos

| Agente | Model |
|--------|-------|
| `docs-extractor`, `docs-consolidator`, fontes (`docs-src-*`) | `claude-4.6-sonnet-medium-thinking` |
| `docs-synthesizer` | `claude-opus-4-8-thinking-high` |

Fallback: o Cursor faz fallback automatico para modelo compativel quando o configurado nao esta disponivel.

Limitacao conhecida: o campo `model` de subagents vindos de plugin de marketplace pode ser ignorado
pelo Cursor (honrado em subagents locais `.cursor/agents/`). O `model` e declarado mesmo assim para
quando a limitacao for resolvida.

## Regras hard-constrained de templates

Cada template tem secoes de nivel 1 FIXAS, em ordem fixa. O consolidador NAO pode adicionar,
remover ou reordenar secoes. Toda secao e preenchida ou contem `N/A - <motivo>`.

Estrutura por tipo (ver `templates/` para o template completo):

- **PRD** (`templates/prd.md`): 1 Resumo — 2 Contexto e problema — 3 Objetivos e metricas (KPIs) — 4 Nao-objetivos — 5 Personas/usuarios — 6 Requisitos funcionais — 7 Requisitos nao-funcionais — 8 User stories — 9 Riscos e dependencias — 10 Questoes em aberto — 11 Documentos derivados
- **TDD** (`templates/tdd.md`): 1 Resumo tecnico — 2 PRD relacionado/contexto — 3 Objetivos tecnicos e escopo — 4 Arquitetura proposta (Mermaid obrigatorio) — 5 Modelo de dados — 6 APIs/contratos/eventos — 7 Alternativas consideradas — 8 Impactos — 9 Plano de testes — 10 Rollout/rollback — 11 Riscos tecnicos — 12 Tarefas derivadas
- **RFC** (`templates/rfc.md`): 1 Resumo — 2 Motivacao — 3 Proposta detalhada — 4 Alternativas consideradas — 5 Impacto e compatibilidade — 6 Plano de adocao — 7 Questoes em aberto — 8 Referencias
- **ADR** (`templates/adr.md`): 1 Contexto e problema — 2 Drivers da decisao — 3 Opcoes consideradas — 4 Decisao — 5 Consequencias — 6 Referencias
- **backlog** (`templates/backlog.md`): 1 Contexto/docs de origem — 2 Resumo do escopo — 3 Lista de tarefas — 4 Sequenciamento/marcos — 5 Riscos e bloqueios — 6 Definition of Done global
- **task** (`templates/task.md`): 1 Metadados — 2 Contexto — 3 Objetivo — 4 Requisitos e criterios de aceite — 5 Especificacao tecnica — 6 Como executar — 7 Dependencias e referencias — 8 Definition of Done

Frontmatter YAML obrigatorio em cada doc: `tipo`, `titulo`, `slug|numero`, `status`, `autor`, `data`, `tema`, `relacionados`.

Frontmatter adicional para `task`: `id` (T-NN), `jira` (JGR-xxx ou pendente), `tipo_item` (feat/fix/chore/test/doc), `story_points`, `depende_de`.
