---
name: gsp-testing-standards
description: Referencia dos padroes de teste do GSP — frameworks (Jest 29, Vitest 3, Pact 13), organizacao de testes (test/unit e test/integration, *.spec.js, test.json), matriz por camada de codigo, paralelismo, gate checks e os thresholds de cobertura por classificacao DDD e archetype (Core 95/90, Supporting 85/80, Generic 70). Use ao escrever testes, definir cobertura ou configurar contratos no GSP.
---

# GSP — Padroes de Teste

Reflexo de 2026-06-19.

## Frameworks

- Unit/Integration: Jest 29 + babel-jest (backend Node). `commons-authorizer` usa Vitest 3.
- Contract: @pact-foundation/pact 13.1.4 (fixar versao sem `^`; API mudou entre v11->v13).
- Coverage: lcov via Jest -> SonarQube. Reports: jest-junit (JUnit XML), gsp-jest-sonar (Sonar XML).

## Organizacao

- Localizacao: `test/unit/` e `test/integration/` na raiz do projeto (nao em `src/`).
- Naming: `*.spec.js` (testMatch `**/?(*.)(spec).js?(x)`). Config: `test.json` na raiz. Setup: `test/scripts/setupAfterEnv.js`.
- Unit: domain logic e commands isolados com mocks de infra; um diretorio por area de dominio em `test/unit/<area>/`.
- Integration: banco real via Docker Compose; setup/limpeza em `test/scripts/`.

## Thresholds por classificacao DDD e archetype

A cobertura exigida depende da classificacao DDD da torre (ver `gsp-towers-catalog`) cruzada com o archetype:

```text
Core      api / domain / repository : 95%
Core      listeners / processes     : 90%
Supporting api                      : 85%
Supporting listeners / repository   : 80%
Supporting processes                : 80%
Generic   (todos)                   : 70%
```

Notas por archetype: `domain` (regras puras) tende ao maior threshold por ser logica testavel; `infrastructure/routers/` e excluido. Enforcement atual: `test.json` define 50% global (baixo); o harness injeta 80%+ via `--config`. Politica de cobertura por sprint (codigo novo): Sprint 1-2 80%, 3-5 85%, 6-7 90%, 8+ 95% (SonarQube New Code Policy).

## Excecoes por torre

| Torre / projeto | Runner | Threshold projeto | Threshold harness | Notas |
|---|---|---|---|---|
| 01.commons / commons-authorizer | Vitest 3 | 100% | 70% | Node >=22; fora do Jest padrao |
| 01.commons / capta-proxy | Jest 29 | 0% | 80% | Gap critico de cobertura |
| 01.commons / automation-database | — | N/A | N/A | Sem testes automatizados |
| 04.frontend / frontend-graphql | Jest (config) | — | 80% | CI `test` = stub `echo OK` |
| 04.frontend / mfe-host | Jest devkit | — | 80% | Path `src/tests/` inexistente |
| 04.frontend / mfe-devkit, mfe-gsp | — | — | 80% | Sem suite propria |
| 04.frontend / mfe-state | — | — | 80% | Cobertura via consumidor profile |
| 04.frontend / frontend-parameters-listener | Jest | — | 85% | Unico Pact consumer SNS na torre |
| 20.capta/captacao/* | Maven/JUnit | — | null | Fora de `harness.sh test` v1 |
| 20.capta/{gcp,promocao,cotas,box-mensagens} | Maven/Ant | — | null | Brownfield; sem enforcement |

Libs npm MFE: politica observada e testar no consumidor (`mfe-profile`) quando a lib nao tem `npm test`.

## Matriz por camada de codigo

| Camada | Tipo de teste | Local | Comando |
|---|---|---|---|
| domain/commands/ | unit | test/unit/**/*.spec.js | npm run ci:unit |
| domain/services/ | unit | test/unit/**/*.spec.js | npm run ci:unit |
| domain/entities/ | unit | test/unit/**/*.spec.js | npm run ci:unit |
| domain/presenters/ | unit | test/unit/**/*.spec.js | npm run ci:unit |
| infrastructure/repositories/ | integration | test/integration/**/*.spec.js | npm run ci:integration |
| infrastructure/services/ | integration | test/integration/**/*.spec.js | npm run ci:integration |
| infrastructure/routers/ | none (excluido) | — | — |
| Event contracts | contract (Pact) | tests/contract/ | contract run |
| cart-update (strangulation) | contract (Pact) — pendente | capta-proxy <-> 11.cart | backlog |

## Paralelismo

| Tipo | Parallel-safe? | Isolamento |
|---|---|---|
| Unit | Sim | Mocks de infra; sem estado compartilhado |
| Integration | Nao | Compartilham PostgreSQL Docker; limpeza em `beforeAll` |
| Contract (Pact) | Sim | Sem DB; apenas JSON payloads |

## Comandos de teste (por projeto)

```bash
npm run ci:unit          # unit com coverage -> coverage/unit/
npm run ci:integration   # integration com coverage -> coverage/integration/
npm run test:unit        # unit (dev)
npm run test:integration # integration (dev)
npm run test             # todos os testes
```

## Gate checks

| Nivel | Quando | Comando |
|---|---|---|
| Quick | Apos tarefas so de unit | `npm run ci:unit` |
| Full | Apos mexer em integration | `npm run ci:unit && npm run ci:integration` |
| Contract | Apos mudar schema de evento | contract run do projeto |
| Build | Ao concluir fase | `npm run lint && npm run ci:unit && npm run transpile` |
