---
name: gsp-present
description: Gera uma apresentacao estruturada de um sistema, torre ou projeto do GSP, com diagrama, a partir dos guidelines consolidados do plugin.
---

# /gsp-present

Dispara o agente `gsp-presenter` para montar uma apresentacao do GSP no nivel pedido (sistema, torre ou projeto), usando exclusivamente as skills `gsp-*` do plugin.

## Uso

```
/gsp-present [sistema | <NN> | <NN.nome> | <nome-torre> | <NN>/<projeto> | <torre>/<projeto>]
```

Sem argumento: apresenta o sistema GSP inteiro (visao geral).

## Gramatica do alvo e parsing

Faca o parse do argumento e produza este objeto de alvo, repassado ao agente:

```json
{
  "scope": "system | tower | project",
  "tower": { "number": "01..20 | null", "name": "string | null" },
  "project": "string | null",
  "raw": "string"
}
```

Regras de parse:
- Vazio ou `sistema`/`system` -> `{ "scope": "system", "tower": { "number": null, "name": null }, "project": null }`.
- `<NN>` (ex.: `13`): `scope=tower`, `tower.number="13"`. Normalize um digito para dois (`7` -> `07`).
- `<NN.nome>` (ex.: `13.orders`): `scope=tower`, `tower.number="13"`, `tower.name="orders"`.
- `<nome-torre>` (ex.: `orders`): `scope=tower`, `tower.name="orders"`, `tower.number=null` (o agente resolve o numero pelo catalogo).
- `<NN>/<projeto>` ou `<NN.nome>/<projeto>` ou `<nome-torre>/<projeto>` (ex.: `13/orders-api`): `scope=project`, preencha `tower` e `project="orders-api"`.
- Sempre preserve o texto original em `raw`.

## Comportamento

1. Faz o parse do argumento na estrutura acima.
2. Repassa o objeto de alvo ao subagent `gsp-presenter`.
3. O subagent resolve o alvo no catalogo, consulta as skills relevantes e retorna a apresentacao nas 6 secoes fixas + diagrama.

## Exemplos

```
/gsp-present
/gsp-present 13
/gsp-present 13.orders
/gsp-present orders
/gsp-present 13/orders-api
/gsp-present 13.orders/orders-api
```

## Erros comuns

- Torre fora de 01..20 ou nome desconhecido: o agente responde que o alvo nao consta e lista as torres validas (nao inventa).
- Alvo ambiguo (casa com mais de uma torre/projeto): o agente lista os candidatos e pergunta qual usar.
- Projeto sem spec consolidada: o agente apresenta no nivel de bounded-context/archetype e marca `[nao-documentado]`.

## Pre-requisitos

Nenhum. O fluxo e read-only e usa apenas as skills do plugin (sem MCP, sem rede, sem edicao de arquivos).
