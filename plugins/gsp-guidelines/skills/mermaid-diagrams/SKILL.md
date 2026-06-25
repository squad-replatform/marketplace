---
name: mermaid-diagrams
description: Guia autocontido para gerar diagramas Mermaid (arquitetura/flowchart, sequencia, fluxo de dados) em apresentacoes de sistemas, torres e projetos. Inclui templates, regras de sintaxe seguras e um fallback textual quando Mermaid nao puder ser renderizado. Use ao montar a secao de diagrama de uma apresentacao do GSP.
---

# Diagramas Mermaid para Apresentacoes

Skill autocontida (nao depende de outras skills). Escolha o tipo de diagrama conforme a intencao e gere um bloco ```mermaid valido. Se o ambiente nao renderizar Mermaid, use o fallback textual ao final.

## Escolha do tipo

| Intencao | Tipo Mermaid |
|---|---|
| Estrutura / componentes / dependencias | `flowchart` |
| Interacao temporal entre servicos/atores | `sequenceDiagram` |
| Fluxo de evento/dados ponta a ponta | `flowchart LR` |

## Regras de sintaxe (evitam erro de parse)

- IDs de no sem espaco: use camelCase ou underscore (`ordersApi`, `cart_api`). Nunca `orders api`.
- Rotulos com caracteres especiais entre aspas: `A["Process (main)"]`, `B["Step 1: Init"]`.
- Rotulos de aresta com parenteses entre aspas: `A -->|"O(1) lookup"| B`.
- Nao use palavras reservadas como ID (`end`, `graph`, `subgraph`). Use `endNode`.
- Subgraph com ID explicito: `subgraph auth [Authentication Flow]`.
- Nao use angle brackets nem cores/estilos explicitos; deixe o tema padrao.

## Template — arquitetura (flowchart)

```mermaid
flowchart TD
  consultora[Consultora] --> mfeHost[mfe-host]
  mfeHost --> bff["frontend-supergraphql (Apollo)"]
  bff --> cartApi[cart-api]
  cartApi -->|"cart-convertion"| sns[(SNS/SQS)]
  sns --> ordersListener[orders-cart-split-listener]
  ordersListener --> ordersApi[orders-api]
  ordersApi -->|"order-create"| sns
```

## Template — sequencia (fluxo de pedido)

```mermaid
sequenceDiagram
  participant MFE
  participant BFF as supergraphql
  participant Cart as cart-api
  participant Bus as SNS/SQS
  participant Orders as orders-api
  MFE->>BFF: POST /cart/convert
  BFF->>Cart: convert cart
  Cart->>Bus: publish cart-convertion
  Bus->>Orders: orders-cart-split-listener
  Orders->>Bus: publish order-create
  Bus-->>Cart: cart-order-listener (ack)
```

## Template — fluxo de dados/evento (LR)

```mermaid
flowchart LR
  captaProxy[capta-proxy] -->|"cart-update"| cartApi[cart-api]
  cartApi --> summarization[cart-summarization-listener]
```

## Boas praticas para o GSP

- Marque produtor e consumidor de evento com rotulo de aresta = valor string do `typeMessages` (ex.: `"order-create"`).
- Use `[(DB)]` para bancos (PostgreSQL/Oracle/ScyllaDB/Redis) e `[(SNS/SQS)]` para o barramento.
- Mantenha o diagrama focado no alvo apresentado (sistema, torre ou projeto); nao desenhe o sistema inteiro para um projeto especifico.
- Inclua apenas elementos `[documentado]`; nao invente componentes para completar o desenho.

## Fallback textual (quando Mermaid nao renderiza)

Se o diagrama nao puder ser renderizado, entregue a mesma informacao como lista de nos e arestas:

```text
Nos: Consultora, mfe-host, supergraphql, cart-api, SNS/SQS, orders-api
Arestas:
  Consultora -> mfe-host
  mfe-host -> supergraphql
  supergraphql -> cart-api
  cart-api -> SNS/SQS  [cart-convertion]
  SNS/SQS -> orders-api (via orders-cart-split-listener)
  orders-api -> SNS/SQS  [order-create]
```

A apresentacao nunca deve falhar por ausencia de diagrama: na pior hipotese, descreva o fluxo em texto.
