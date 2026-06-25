# gsp-guidelines plugin

Guidelines consolidados e autossuficientes da plataforma GSP (Global Sales Platform) da Natura: arquitetura event-driven, integracoes, convencoes de codigo, stack, padroes de teste, catalogo de torres (classificacao DDD) e divida tecnica. Inclui um comando e um agente para gerar apresentacoes de um sistema, torre ou projeto sob demanda.

Todo o conteudo e reescrito inline neste plugin. Ele nao depende de nenhum arquivo fora de `gsp-guidelines/` (sem `.harness/`, sem `.specs/`, sem `towers/`).

## O que faz

- Fornece rules (carregadas sob demanda) com as regras "faca / nao faca" durante a edicao de codigo no GSP.
- Fornece skills com a referencia profunda (fluxos, schemas, catalogos, exemplos) para consulta do agente.
- Disponibiliza `/gsp-present` para gerar uma apresentacao estruturada de um sistema, torre ou projeto, com diagrama Mermaid.

## Componentes

| Arquivo | Funcao |
|---|---|
| `rules/gsp-discovery-entrypoint.mdc` | Rule always-on que ancora o discovery no plugin: toda compreensao de torre/projeto/servico ou de padroes de codigo/arquitetura do GSP comeca pelas skills `gsp-*` antes de ler o repo |
| `rules/gsp-architecture.mdc` | Regras normativas curtas de arquitetura (pointer para a skill) |
| `rules/gsp-integrations.mdc` | Regras normativas curtas de integracoes (pointer para a skill) |
| `rules/gsp-code-conventions.mdc` | Regras normativas curtas de convencoes (pointer para a skill) |
| `rules/gsp-content-fidelity.mdc` | Convencao compartilhada: documentado vs nao-documentado, anti-alucinacao e anti-injecao |
| `skills/gsp-architecture/` | Referencia profunda de arquitetura, archetypes, fluxos, MessagePresenter, listener pattern |
| `skills/gsp-integrations/` | Mensageria SNS/SQS, eventos, auth, bancos, BFF, ponte Capta, enum typeMessages, blast radius |
| `skills/gsp-code-conventions/` | Naming, imports, estrutura de Command, error handling, excecoes por torre |
| `skills/gsp-stack/` | Stack Node, frontend (MFE) e legado Java |
| `skills/gsp-testing-standards/` | Jest/Vitest/Pact, organizacao, thresholds DDD por archetype |
| `skills/gsp-towers-catalog/` | Catalogo das 20 torres + classificacao DDD (fonte autoritativa) + schema de registro |
| `skills/gsp-tech-debt/` | Divida tecnica, gotchas e riscos de seguranca (sanitizado, sem segredos) |
| `skills/mermaid-diagrams/` | Guia autocontido para diagramas Mermaid em apresentacoes |
| `agents/gsp-presenter.md` | Subagent que monta a apresentacao consultando as skills |
| `commands/gsp-present.md` | Slash command `/gsp-present` — parse do alvo e delegacao ao agente |

## Uso

```
/gsp-present                       # visao geral do sistema GSP
/gsp-present 13                    # torre por numero
/gsp-present 13.orders             # torre por numero.nome
/gsp-present orders                # torre por nome
/gsp-present 13/orders-api         # projeto dentro da torre
/gsp-present 13.orders/orders-api  # projeto (forma completa)
```

## Pre-requisitos

Nenhum servidor MCP e necessario. O fluxo de apresentacao e read-only: le as skills do plugin e produz texto + diagrama Mermaid. Nao edita arquivos, nao roda shell, nao acessa a rede.

## Limitacoes conhecidas

- O catalogo cobre as 20 torres e os archetypes; nao embute os ~151 projetos individualmente. Detalhe por projeto existe apenas onde havia spec consolidada (01.commons, 04.frontend, 20.capta) e nas torres piloto 11.cart e 13.orders.
- Itens nao cobertos pelas fontes sao marcados explicitamente como `[nao-documentado]`; o agente nao inventa nomes de torre, projeto, evento ou campo.
- Conteudo refletido em 2026-06-19; pode divergir do estado atual dos repositorios.
