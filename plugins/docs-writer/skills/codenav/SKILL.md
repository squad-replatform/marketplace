---
name: codenav
description: >
  Recon read-only de codebase para extracao de fatos estruturados. Acionada pelo docs-src-codebase
  SOMENTE quando o plugin gsp-guidelines nao for suficiente para responder a pergunta. Retorna
  claims com proveniencia obrigatoria (file:Lx-Ly + data) consumiveis pelo evidence-index.json.
  Nunca edita, nunca executa comandos de mutacao, nunca narra — apenas extrai e estrutura.
---

# Skill: codenav

Skill de reconhecimento read-only de codebase. Uso exclusivo do agente `docs-src-codebase`
quando o plugin `gsp-guidelines` (skills `gsp-*`) nao for suficiente para responder a pergunta.

## Restricoes absolutas

- **Read-only por contrato**: apenas navega e le arquivos; nunca edita, cria, move ou deleta.
- **Nunca executa comandos de mutacao**: sem `git commit`, `npm install`, `docker run`, etc.
- **Sem narrativa**: a saida e um array de claims estruturados — nao um relatorio em prosa.
- **Sem alucinacao**: se a informacao nao esta no codigo, declare `confidence: low` e registre a lacuna.

## Quando acionar

Acionar `codenav` SOMENTE quando:

1. O `gsp-guidelines` nao cobre o alvo (ex.: projeto fora das skills `gsp-*`, novo repositorio, path especifico nao documentado).
2. Ha uma lacuna explicita que requer traca de fluxo no codigo-fonte.
3. O extractor precisa de ponteiros `file:Lx-Ly` para alimentar o `evidence-index.json`.

Nao acionar para perguntas que o `gsp-guidelines` ja responde (arquitetura de torres, archetypes, stack, convencoes globais do GSP).

## Ciclo de trabalho

### 1. Briefing

Receber do `docs-extractor`:
- `query`: o que se quer saber (ex.: "como o checkout dispara o evento ORDER_PLACED?")
- `scope`: repositorio(s) ou diretorio(s) alvo (ex.: `gsp-checkout-api/src/`)
- `max_claims`: limite de claims a retornar (default 10)

### 2. Recon dirigido

Estrategia de busca (em ordem de prioridade, parar quando tiver `max_claims` claims confiaveis):

1. **Consultar `.notebook/INDEX.md`** se existir na raiz do repo — pode mapear modulos, fluxos e arquivos chave. Read-only; nao escrever nele.
2. **Busca por simbolo/pattern** via `rg`/`grep` nos diretorios de escopo (ex.: nome do evento, nome do handler, nome da funcao).
3. **Leitura dirigida**: ler apenas os arquivos identificados na busca — assinaturas de funcoes e blocos relevantes, NAO o arquivo inteiro.
4. **Navegacao por imports/references**: seguir imports apenas 1 nivel abaixo do ponto de entrada identificado; nao explorar recursivamente toda a arvore.
5. **Data do arquivo/commit**: extrair com `git log -1 --format="%ai" -- <arquivo>` (readonly).

Disciplina de tokens:
- Ler assinaturas e trechos relevantes, nao arquivos completos.
- Preferir busca dirigida a leitura sequencial.
- Parar quando tiver claims suficientes (ou `max_claims` atingido).

### 3. Saida estruturada

Retornar um objeto JSON com o array `claims`:

```json
{
  "query": "<query recebida>",
  "scope": "<scope recebido>",
  "claims": [
    {
      "claim_id": "codebase-001",
      "statement": "O handler OrderPlacedHandler dispara o evento ORDER_PLACED apos salvar o pedido.",
      "pointer": "gsp-checkout-api/src/handlers/order-placed.handler.ts:L34-L58",
      "origin_date": "2025-03-12",
      "confidence": "high",
      "note": ""
    }
  ],
  "gaps": [
    "Nao foi possivel identificar o mecanismo de retry para falhas no SNS."
  ]
}
```

Campos de cada claim:
- `claim_id`: string unica no formato `codebase-NNN`.
- `statement`: fato concreto em 1-2 frases; sem especulacao.
- `pointer`: `<arquivo>:L<inicio>-L<fim>` — nunca colar o bloco de codigo, so o ponteiro.
- `origin_date`: data do ultimo commit do arquivo (`YYYY-MM-DD`); se nao disponivel, `""`.
- `confidence`: `high` (lido diretamente no codigo) | `medium` (inferido de assinaturas) | `low` (incerto/nao encontrado).
- `note`: contexto adicional ou ressalva sobre o claim (pode ser vazio).

`gaps`: lista de perguntas que nao puderam ser respondidas com confianca.

## Anti-padroes a evitar

- Nao colar blocos de codigo na saida — apenas ponteiros `file:Lx-Ly`.
- Nao inventar nomes de funcoes, eventos ou paths que nao foram lidos.
- Nao explorar toda a arvore de arquivos sem uma query dirigida.
- Nao declarar `confidence: high` quando o achado e uma inferencia.
- Nao escrever em `.notebook/INDEX.md` nem em qualquer outro arquivo.
