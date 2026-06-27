---
name: write-docs
description: >
  Gera design docs (PRD, TDD, RFC, ADR, tasks) em PT-BR a partir de Jira, Confluence e codebase.
  Uso: /write-docs <kind> [<cod>] <assunto> [--from scratch|prd|prd-tdd]. Orquestra o pipeline
  obrigatorio de 3 fases (Extracao -> Sintese -> Consolidacao) e agrupa output em .docs/.
---

# /write-docs

Gera design docs via pipeline obrigatorio de 3 fases. Leia e siga a skill `docs-writer` para a metodologia completa.

## Uso

```
/write-docs <kind> [<cod>] <assunto> [--from scratch|prd|prd-tdd]
```

Exemplos:
```
/write-docs theme E1 split de CD no checkout
/write-docs theme E1 split de CD no checkout --from prd-tdd
/write-docs adr E1 escolha do banco de eventos
/write-docs rfc padronizar envelope de eventos
```

## Passo 1 — Preflight

Executar `scripts/preflight.sh`. Se falhar, exibir a mensagem de erro e **parar**.

## Passo 2 — Parsing

### kind

1o token. Validos: `theme`, `adr`, `rfc`. Se invalido:

> Nao reconheci o kind `<valor>`. Use: `theme`, `adr` ou `rfc`.

### cod (opcional)

Proximo token SE casar com `^[A-Za-z]+\d+$` (ex.: `E1`, `EP2`, `e1`). Normalizar para maiusculo.

- `kind=theme`: **OBRIGATORIO**. Se ausente: pedir ao usuario e parar.
- `kind=adr` ou `kind=rfc`: opcional. Com `cod` -> agrupado no tema; sem `cod` -> solto.

### assunto e slug

Tokens restantes (excluir `--from <valor>`). Derivar `slug` em kebab-case ASCII minusculo
(remover acentos, trocar nao-alfanumerico por hifen, colapsar hifens multiplos em 1).

### --from

Se presente: `scratch` -> estrategia 1; `prd` -> estrategia 2; `prd-tdd` -> estrategia 3.
Forca a estrategia (ignora auto-deteccao).

## Passo 3 — Selecao de estrategia

### kind=theme

Auto-detectar varrendo `.docs/<COD>-*/`:

| Estado da pasta `.docs/<COD>-*/` | Estrategia |
|----------------------------------|-----------|
| Nao existe ou sem arquivos `prd*` | 1 (do zero) |
| Existe `prd*`, nenhum `tdd*` | 2 (a partir de PRD) |
| Existe `prd*` e pelo menos 1 `tdd*` | 3 (a partir de PRD + TDDs) |

`--from` sobrescreve a auto-deteccao.

### kind=adr -> estrategia 4 | kind=rfc -> estrategia 5

## Passo 4 — Resolucao de tema

Para `kind=theme` e ADR/RFC com `cod`:

1. Varrer `.docs/<COD>-*/`. Se encontrar, reusar (extrair `desc_snake` do nome da pasta).
2. Se nao encontrar:
   - Perguntar: "Qual e a descricao curta do tema `<COD>`?"
   - Derivar `desc_snake` em snake_case ASCII da resposta.
   - O diretorio `.docs/<COD>-<desc_snake>/` sera criado pela fase 3.

Para ADR/RFC sem `cod`: usar `.docs/adr/` ou `.docs/rfc/` (criados pela fase 3 se ausentes).

## Passo 5 — Resolucao de paths e numeracao

Calcular os paths finais dos docs a serem gerados:

### Agrupado (tema)

```
.docs/<COD>-<desc_snake>/<tipo>/<tipo><NN>-<slug>.md
```

`<NN>`: varrer `.docs/<COD>-<desc_snake>/<tipo>/<tipo>*.md`, pegar o maior numero + 1; iniciar em `01`.

### Solto (ADR/RFC sem cod)

```
.docs/adr/adr<NNNN>-<slug>.md
.docs/rfc/rfc<NNNN>-<slug>.md
```

`<NNNN>`: varrer `.docs/adr/*.md` (ou `.docs/rfc/`), pegar maior numero + 1; iniciar em `0001`.

## Passo 6 — Gravar request.json

Criar `.docs/.work/<run-id>/request.json` com:

```json
{
  "run_id": "<run-id>",
  "kind": "<theme|adr|rfc>",
  "strategy": <1-5>,
  "cod": "<COD ou null>",
  "tema": "<COD>-<desc_snake> ou null",
  "assunto": "<assunto original>",
  "slug": "<slug>",
  "targets": ["<tipos a gerar>"],
  "output_paths": {
    "<tipo>": "<path-final>"
  }
}
```

`run-id` = `<COD>-<slug>-<timestamp>` (temas/agrupados) ou `<kind>-<slug>-<timestamp>` (soltos).

## Passo 7 — Fase 1: Extracao

Disparar subagent `docs-extractor` foreground com:

```
run_id, work_dir: .docs/.work/<run-id>, request: <conteudo de request.json>
```

Aguardar conclusao. Se falhar: exibir erro e parar.

## Passo 8 — Fase 2: Sintese

Disparar subagent `docs-synthesizer` foreground com:

```
run_id, work_dir: .docs/.work/<run-id>, request: <conteudo de request.json>
```

Aguardar conclusao. Se falhar: exibir erro e parar.

## Passo 9 — Fase 3: Consolidacao

Disparar subagent `docs-consolidator` foreground com:

```
run_id, work_dir: .docs/.work/<run-id>, request: <conteudo de request.json>,
output_paths: <mapa de paths do request.json>
```

Aguardar conclusao. Se falhar: exibir erro e parar.

## Passo 10 — Sumario final

Exibir ao usuario:

```
Docs gerados com sucesso:
- .docs/E1-split_cd/prd/prd01-split-de-cd-no-checkout.md
- .docs/E1-split_cd/tdd/tdd01-split-de-cd-no-checkout.md
- .docs/E1-split_cd/tasks/tasks01-split-de-cd-no-checkout.md

Arquivos de trabalho em: .docs/.work/<run-id>/
```

Se houver questoes em aberto registradas pelo consolidador, listar brevemente.

## Erros comuns

| Situacao | Mensagem |
|----------|---------|
| Preflight falhou | Exibir saida do preflight.sh e parar |
| `kind` invalido | "Nao reconheci o kind `<valor>`. Use: `theme`, `adr` ou `rfc`." |
| `cod` ausente para `kind=theme` | "Para `kind=theme` o codigo do tema e obrigatorio. Ex.: `/write-docs theme E1 <assunto>`." |
| Fase 1/2/3 falhou | Exibir erro do subagent e parar |
