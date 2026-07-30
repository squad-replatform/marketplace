---
name: gsp-integrations
description: Referencia profunda das integracoes do GSP — mensageria AWS SNS/SQS, eventos criticos e enum typeMessages (~130 tipos), autenticacao (Kong/Cognito/OAM + commons-authorizer), bancos (PostgreSQL/Oracle/ScyllaDB/Redis), BFF Apollo supergraphql, comunicacao cross-MFE, ponte Capta<->GSP, AWS, CI/CD, status de contratos Pact e blast radius dos campos consumidos por listener. Use ao mexer em eventos, auth, dados ou integracao entre torres do GSP.
---

# GSP — Integracoes

Reflexo de 2026-06-19 (inclui torres 01.commons, 04.frontend, 20.capta).

## Mensageria (event bus) — torres Node

- Service: AWS SNS + SQS. Implementacao: `19.libraries/iris-nodejs-messenger/`.
- Config: `parameter://gsp/common/bus/orders/topic_arn`. Auth: IAM roles via ECS task role.
- Padrao: SNS topic por dominio -> SQS queues por consumer.

### Eventos criticos — fluxo replatform
| Tipo | Produtor tipico | Consumidores tipicos |
|---|---|---|
| `cart-convertion` | `11.cart/cart-api` | `13.orders/orders-cart-split-listener` |
| `order-create` | `13.orders/orders-api` | cart, availability, profile, payment, promotion, puf listeners |
| `parameter-updated` | `02.parameters` | `04.frontend/frontend-parameters-listener` |

### Evento strangulation — torre 01.commons
| Tipo | Produtor | Consumidores | Config |
|---|---|---|---|
| `cart-update` | `01.commons/capta-proxy` | `11.cart/cart-api`, `cart-summarization-listener` | Topico SNS `capta-proxy` / `CAPTA_PROXY_TOPIC_ARN` |

Torre 01.commons: `events_consumed: []` — nao consome SNS.

## Enum typeMessages (Published Language)

Localizacao: `19.libraries/commons/src/domains/type-messages.js`. Exportado como `globalsales-commons` -> `const { Domains: { typeMessages } } = require('globalsales-commons')`. ~130 tipos, cada um com comentario do topic SNS alvo.

```js
import { Domains } from 'globalsales-commons';
const { typeMessages } = Domains;
// em queue-routes.js:
[typeMessages.orderCreate]: CommandFactory.createAndPromisify(Factory)
```

### orders-api publica
| Chave | Valor string | Topic |
|---|---|---|
| `orderCreate` | `'order-create'` | ORDER |
| `orderCreateTest` | `'order-create-test'` | ORDER |
| `orderCreateSplitItems` | `'order-create-split-items'` | ORDER |
| `orderUpdate` | `'order-update'` | ORDER |
| `orderCancellation` | `'order-cancellation'` | ORDER |
| `orderApproval` | `'order-approval'` | PROFILE |
| `orderCompleted` | `'order-completed'` | ORDER |
| `orderCreateRetry` | `'order-create-retry'` | ORDER |

### cart-api publica
| Chave | Valor string | Topic |
|---|---|---|
| `cartCreated` | `'cart-created'` | CART |
| `cartConvertion` | `'cart-convertion'` | CART |
| `cartDeleted` | `'cart-deleted'` | CART |
| `cartSplitItems` | `'cart-split-items'` | CART |
| `cartInactivation` | `'cart-inactivation'` | CART |

`sendNotification` -> `'send-notification'` e gerado automaticamente pelo MessagePresenter.

Os valores string sao o contrato real de routing entre produtores e consumidores. Mudar uma string quebra o routing silenciosamente. `addHeaders()` duplica o valor em `headers.eventType` (intencional, para gateways que filtram por header).

## Blast radius — campos consumidos do payload de orders-api

| Listener | Consome | Campos usados | Risco de quebra |
|---|---|---|---|
| cart-order-listener (11.cart) | order-create, order-create-test | `cartUid`, `orderUid` (2 de 40+) | Baixo |
| cart-order-listener SplitItemsCommand | order-create-split-items | ~1 campo (`cartUid`) via HTTP | Baixo |
| availability-orders-listener (08) | order-cancellation | 10 campos + nested `itemDetails[0].commitmentUid` (3 niveis); `statusId in [10,11]` | CRITICO (Joi.any) |
| profile-orders-listener (05) | order-create/update/cancellation/approval | objeto completo (proxy para profile-api) | ALTO (impacto desconhecido) |
| orders-cart-split-listener (13) | cart-split-items (de cart-api) | `cart.splits` | Medio |

Antes de alterar `GetOrderPresenter` (orders-api), avalie esta tabela. Detalhe dos gotchas em `gsp-tech-debt`.

## Comunicacao cross-MFE (nao SNS)

Mecanismo: `CustomEvent` no `window`. Projetos: `mfe-host`, `mfe-profile`, `mfe-gsp`. Exemplos: `gsp-select-consultant`, `gsp-logout`, `gsp-refresh-x-app-token-success`. Nao modelado em Pact/AsyncAPI; broker conceitual e o `window`.

## Bancos de dados

- PostgreSQL 14 (replatform): orders-api, cart-api, payment-api, shipping-api. ORM Knex.js + TypeORM (products-api, capta-proxy). Credenciais via `secretsManager://`.
- Oracle (Captacao, SoR legado): `20.capta/captacao/captacao-persistencia` -> procedures `ST_*` / `PKG_*`. Pool JDBC JNDI WebLogic. Paralelo ao PostgreSQL de orders.
- ScyllaDB / Cassandra: availability-api, products-repository. Client `19.libraries/commons-scylladb/`.
- Redis: cache consultora (profile-cache-api/adapter), tokens/parametros frontend (frontend-graphql, invalidacao via frontend-parameters-listener), sessao capta-proxy (`REDIS_TOKEN_*`, DB compartilhado com profile).

## Autenticacao

### API Gateway + Lambda (01.commons)
| Componente | Funcao |
|---|---|
| `commons-authorizer` | Request Authorizer Lambda -> policy Allow/Deny |
| Amazon Cognito | JWKS `{COGNITO_IDP_URL}/.well-known/jwks.json` |
| Oracle OAM | JWKS `{OAM_IDP_URL}/oauth2/rest/security` |

### Kong + JWT (torres Node)
Rate limiting, roteamento de APIs privadas. Config `parameter://gsp/common/api/private/kong`. JWT validation; o `JWT_SECRET` deve vir de `parameter://` / `secretsManager://` (nao hardcoded — ver `gsp-tech-debt`).

### Frontend (04.frontend)
Cognito (LATAM) + OAM/OIDC (BR), ambos via `mfe-toolkit`. Storage `sessionStorage` (`gsp-auth`). Headers GraphQL: `Authorization`, `x-app-token`, `sessionIdentifier`, `correlation-id`. Em capta-proxy: `AuthenticatedHandler` via `globalsales-commons`, apos passar pelo authorizer no gateway.

## BFF Frontend (04.frontend)

```text
MFE Apollo Client
  -> frontend-supergraphql (Apollo Gateway, ECS)
       subgraph legacy  -> frontend-graphql (REST DataSources -> torres 02-19)
       subgraph profile -> 05.profile/profile-api
```

Supergraph versionado no repo: `legacy` + `profile` apenas. Parameter Store pode listar `capta-proxy`, `al-showcase` — nao federados no `supergraph-config.yaml` atual. Build: `rover supergraph compose` + `subgraph-replace-url.js`. Subscriptions: `cartCalculated` in-process; WebSocket definido mas nao iniciado em `start()`. REST downstream (subgraph legacy): cart, orders, products, parameters, availability, promotion, payment, shipping, marketing, presales, profile, people, BRM/CMM.

## Ponte Capta <-> GSP (01.commons + 20)

| Env / destino | Direcao | Sistema |
|---|---|---|
| `EXTERNAL_CAPTA_URL` | GSP -> Capta | `20.capta/captacao` (captaweb, captacao-servico) |
| `CAPTA_X_API_KEY` | Header | Autenticacao API legado |
| `INTERNAL_CART_URL` | -> | `11.cart` |
| `INTERNAL_AVAILABILITY_URL` | -> | `08.availability` |
| `INTERNAL_PRODUCTS_URL` | -> | `06.products` |
| `INTERNAL_PARAMETERS_URL` | -> | `02.parameters` |

Legado outbound: `captacao-integracao` (JiBX/SOAP) — Party, NCN, SAP, promo, pagamentos. Config em `captacao-external-resources`. APIs REST fronteira: `capta-vitrine-api` (MFE vitrine, capta-proxy), `capta-convivencia-api` (status pagamento). Promo GSP: `12.promotion/gsp-promotion-soap-proxy` (dual stack com `20.capta/promocao`). Captacao nao tem SNS/SQS no monorepo.

## Cloud AWS

ECR / ECS Fargate (microservicos Node e BFF GraphQL); Lambda (`commons-authorizer`, `frontend-parameters-listener`); Secrets Manager / Parameter Store (`secretsManager://`, `parameter://`); S3 (orders-s3, termos PDF, buckets de tokens graphql). API Gateway: Kong (auth, rate limit, APIs privadas) + `gsp-apigw-mfe` (GraphQL em producao).

## CI/CD

- Node: GitHub Actions -> `naturacode/workflows-application-config` (149/151).
- Captacao: `20.capta/captacao/.github/workflows` -> `capta-captacao.yaml`.
- Automation DB: `gsp-automation-database.yaml` (reusable). PR em `sql/script.sql` + branch `*-prd` -> `workflow_dispatch` -> `.cicd/scripts/postgres.sh`.

## Qualidade & contratos Pact

SonarQube (149/151 projetos Node; torre 20 excluida do gate Sonar Node padrao). ArcherySec (SAST) no PR. Pact Broker e contratos:
| Par | Status |
|---|---|
| cart-order-listener <- orders-api | Configurado |
| cart-update (11.cart <- capta-proxy) | Pendente (backlog) |
| frontend-parameters-listener <- parameter-updated | Consumer documentado |
