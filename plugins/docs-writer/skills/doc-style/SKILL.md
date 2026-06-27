---
name: doc-style
description: >
  Padrao de escrita humana para design docs em PT-BR. Usado pela fase 3 (docs-consolidator)
  para produzir documentos coesos, bem estruturados e agradaveis de ler. Cobre tom, voz,
  estrutura, concisao, uso de tabelas e diagramas.
---

# Skill: doc-style

Guia de escrita para a fase 3 do pipeline docs-writer. Toda consolidacao de doc final DEVE seguir este guia.

## Tom e voz

- Escreva em **voz ativa** e **primeira pessoa do plural** ("definimos", "optamos", "o sistema processa").
- Seja **direto**: diga o que e, nao o que "poderia ser" ou "talvez seja".
- Prefira **PT-BR formal, sem jargoes desnecessarios**. Termos tecnicos aceitos quando sao o nome correto (ex.: "payload", "rollback", "throughput").
- Evite redundancias: nao repita a mesma informacao em secoes diferentes.
- Nunca use frases vagas como "de acordo com as melhores praticas" sem especificar qual pratica.

## Estrutura

- Cada secao tem um proposito claro e unico. Se duas secoes falam do mesmo assunto, consolide.
- Abre com o que mais importa: resumo primeiro, detalhes depois.
- Use **listas** para itens paralelos (3+); use **prosa** para narrativa e raciocinio.
- Use **tabelas** para comparacoes, requisitos, alternativas, tasks — sempre com cabecalho descritivo.
- Use **diagramas Mermaid** para fluxos, arquiteturas, sequencias — preferivel a descricao textual longa.
- Hierarquia de titulos: `##` para secoes principais (nivel 1 do template), `###` para subsecoes. Nao usar `#` (reservado para o titulo do doc).

## Concisao

- Cada paragrafo = um pensamento. Nao encadeie multiplos argumentos em uma so frase longa.
- Elimine pleonasmos: "planejamento previo", "resultado final", "prever antecipadamente".
- Elimine hedges desnecessarios: "talvez", "provavelmente", "pode ser que" — seja assertivo ou registre como questao em aberto.
- Limite o Resumo a <= 5 linhas.

## Lacunas e incertezas

- Lacunas de informacao viram questoes em aberto, nao suposicoes silenciosas.
- Formato padrao para questao em aberto: `> [!QUESTAO] <texto claro da duvida ou decisao pendente>`
- Nunca invente dados, metricas ou decisoes que nao estao no `02-synth/`.

## Uso de tabelas

- Use tabelas para: requisitos funcionais/nao-funcionais, alternativas, tasks, impactos comparativos.
- Cabecalho sempre em PT-BR; colunas nao devem ter celulas mescladas.
- Se uma celula nao tem valor, escreva `—` (travessao), nao deixe em branco.

## Uso de diagramas (Mermaid)

- Prefira `flowchart LR` para arquiteturas e fluxos de dados.
- Use `sequenceDiagram` para fluxos request/response ou processos com ordem temporal.
- Mantenha os rotulos curtos (max ~30 chars); detalhes vao no texto abaixo do diagrama.
- Todo TDD DEVE ter pelo menos 1 diagrama na secao "Arquitetura proposta".

## Frontmatter

- Preencha todos os campos obrigatorios: `tipo`, `titulo`, `slug|numero`, `status`, `autor`, `data`, `tema`, `relacionados`.
- `status` inicial = `rascunho`; so o time muda para `aceito`, `rejeitado`, etc.
- `autor` = nome do responsavel pelo doc (pode ser "docs-writer" se gerado automaticamente).
- `data` = data de geracao no formato `YYYY-MM-DD`.

## Do not

- Nao copie blocos inteiros do `02-synth/` para o doc final — sintetize e parafraseie.
- Nao adicione, remova ou reordene secoes fixas do template.
- Nao use emojis fora de tabelas de severidade ou listas de checklist.
- Nao escreva em ingles sem necessidade — termos tecnicos aceitos, prosa em PT-BR.
