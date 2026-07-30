---
name: gsp-stack
description: Referencia da stack tecnologica do GSP — Node.js 20 + globalsales-node-base nas torres 02-19, excecoes de runtime em 01.commons (authorizer Node 22/Vitest, capta-proxy), frontend MFE (React 16/18, Rsbuild/Webpack/Rollup, Module Federation, Apollo Federation), legado Java 6/WebLogic/Spring/GWT em 20.capta, bancos, mensageria, cloud AWS e ferramentas. Use ao escolher dependencias, configurar runtime, build ou tooling no GSP.
---

# GSP — Tech Stack

Agregacao de 2026-06-19 (torres 01, 04, 20).

## Core — GSP Node (torres 02-19)

- Runtime: Node.js 20 (`.nvmrc=20`; excecao authorizer >=22).
- Linguagem: JavaScript (ES6+) com Babel; TypeScript em APIs modernas e MFEs.
- Package manager: npm. Module system: ESM via Babel -> CommonJS (`build/`).
- Framework de aplicacao: `globalsales-node-base` (App.Command, App.Logger); `globalsales-commons` (typeMessages, Domains, CommandFactory); MessageQueue.LambdaHandler.
- Backend: REST (Express via node-base); GraphQL (Apollo Server / Federation); ORM Knex.js + TypeORM (products-api, capta-proxy).

## Torre 01.commons — excecoes de runtime

| Projeto | Runtime | Testes | Notas |
|---|---|---|---|
| `commons-authorizer` | Node >=22, ESM, `tsup` | Vitest 3, threshold projeto 100% | `jose`, `zod`; sem `globalsales-node-base` |
| `capta-proxy` | Node >=20, Babel -> `build/` | Jest 29, threshold projeto 0% | `globalsales-node-base` ^6, Express + Apollo Subgraph 4, TypeORM + Knex |
| `automation-database` | shell/GitHub Actions | N/A | SQL manual |

## Frontend (04.frontend)

| Projeto | React | Bundler | Linguagem |
|---|---|---|---|
| `mfe-host`, `mfe-profile` | 18 | Rsbuild/Rspack + MF devkit | TypeScript |
| `mfe-gsp` | 16 | Webpack 5 MF | JavaScript JSX |
| `mfe-{devkit,toolkit,components,state}` | peer 18 | Rollup | TypeScript |
| `mfe-locales` | — | estatico | JSON |
| `frontend-graphql`, `frontend-supergraphql` | — | Babel -> Docker node20 | JS, Apollo 4, Federation 2.3 |

BFF `frontend-supergraphql`: subgraphs `legacy` + `profile`. Estado: Zustand (`mfe-state`); Redux + Saga legado (`mfe-gsp`). Auth: `mfe-toolkit` (Cognito LATAM, OAM/OIDC BR). Restricao: React 16 (gsp) vs 18 (host/profile) — shared singletons no Module Federation.

## Bancos e mensageria

- DB: PostgreSQL 14, ScyllaDB, Redis (detalhe em `gsp-integrations`).
- Mensageria: AWS SNS + SQS via `iris-nodejs-messenger`.

## Cloud (AWS)

ECS Fargate, ECR, Lambda (authorizer, parameters-listener), Secrets Manager, Parameter Store, S3. Auth Kong + Cognito/OAM.

## Legado Java (20.capta) — fora do escopo Jest das torres Node

| Aspecto | Stack |
|---|---|
| JDK | 1.6 |
| App server | WebLogic 10.3 |
| Framework | Spring 3.0.x / 3.2.x |
| UI | GWT + Crux 5.3.4; JSP |
| Integracao | Spring-WS 1.5, JiBX |
| Build | Maven, `-Dambiente`, profiles dev/hml/prd |
| DB | Oracle (procedures PL/SQL) |
| Cache | Oracle Coherence + JCS (`captaweb-coherence`) |
| Encoding | ISO-8859-1 (persistencia) |

## Testing (por contexto)

| Contexto | Ferramenta |
|---|---|
| Torres Node | Jest 29 + babel-jest |
| commons-authorizer | Vitest 3 |
| MFE modernos | Jest via `gsp-microfrontend-devkit/testing` |
| Contratos | @pact-foundation/pact 13.1.4 |
| Legado Captacao | JUnit/DBUnit, `mvn package`, Jetty |

Detalhe em `gsp-testing-standards`.

## CI/CD e tooling

- Node: GitHub Actions -> `workflows-application-config` (149/151). Deploy Canary ECS 10% -> 100%.
- Captacao: `capta-captacao.yaml`. Deploy legado: WARs WebLogic por agregadores.
- ESLint (`eslint-config-globalsales-natura`, `natura-eslint-config-typescript`); Babel transpile; Docker Compose para integracao Node.
