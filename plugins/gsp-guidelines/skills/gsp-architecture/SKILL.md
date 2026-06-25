---
name: gsp-architecture
description: Referencia profunda da arquitetura do GSP — microservices event-driven com DDD, dual-path de captacao de pedido (replatform vs strangulation), os 5 archetypes Node (api/listener/process/domain/repository) e extensoes (frontend MFE, Maven Capta), padrao App.Command, envelope MessagePresenter, padrao de listener (handler -> queue-routes -> CommandFactory -> execute) e os fluxos A e B de pedido. Use ao projetar, investigar ou apresentar a arquitetura de qualquer torre, sistema ou projeto do GSP.
---

# GSP — Arquitetura

Padrao geral: microservices event-driven com Domain-Driven Design. Torres 02-19 sao bounded contexts Node; 01 e camada transversal; 04 e o canal digital (frontend); 20 e o legado SoR (Captacao). Reflexo de 2026-06-19.

## Estrutura de alto nivel

```text
Consultora
  |
  +-- 04.frontend  — mfe-host (Module Federation)
  |       remotes: mfe-gsp, mfe-profile (+ showcase externo 07)
  |       HTTP -> frontend-supergraphql (Apollo Gateway)
  |               subgraph legacy  -> frontend-graphql (REST -> GraphQL)
  |               subgraph profile -> 05.profile/profile-api
  |
  +-- 01.commons — commons-authorizer (Lambda JWT) -> API Gateway Allow/Deny
  |
  +-- Dual-path de captacao de pedido (coexistem):
          [Replatform]    supergraphql -> torres Node (02-19) -> SNS/SQS
          [Strangulation] capta-proxy -> 20.capta/captacao (Oracle) + SNS cart-update -> 11.cart

TORRES NODE (02-19) — Bounded Contexts
  05.profile -> 11.cart -> 12.promotion -> 13.orders
  08.availability, 14.payment, 15.shipping, ...
        | AWS SNS/SQS |  eventos via typeMessages (~130 tipos)
```

## Camadas especiais por torre

### 01.commons (transversal)

Nao e bounded context de dominio: sem listeners, sem pacotes compartilhados entre repos. Os tres projetos nao dependem entre si.

```text
Cliente/MFE -> API Gateway -> commons-authorizer (Lambda, stateless)
                  | Allow
                  v
          capta-proxy (REST :3000 + GraphQL subgraph :4000)
              -> HTTP -> 20.capta/captacao (EXTERNAL_CAPTA_URL)
              -> HTTP -> 11.cart, 08.availability, 06.products, 02.parameters
              -> PostgreSQL (sessao, commitment, global showcase)
              -> SNS cart-update -> 11.cart

Engenharia --PR--> automation-database --workflow_dispatch--> RDS (branches *-prd)
```

### 04.frontend (canal digital)

```text
Browser -> mfe-host (Rsbuild, container host)
            gsp/app    <- mfe-gsp (Webpack 5, React 16, Redux/Saga)
            profile/*  <- mfe-profile (Rsbuild, React 18)
            showcase/* <- 07.showcase (fora do monorepo 04)

Apollo Client (host/profile/gsp) -> frontend-supergraphql
    supergraph versionado no repo: legacy + profile

Cross-MFE: CustomEvent no window (logout, consultora, refresh token) — fora de SNS
Estado: gsp-microfrontend-state (Zustand + sessionStorage)
```

### 20.capta (legado / system of record)

Monorepo Maven multi-WAR no WebLogic; Oracle `ST_*` / `PKG_*`. Nao participa do barramento SNS do GSP Node.

```text
GSP capta-proxy --HTTP--> capta-vitrine-api / captaweb / captacao-servico
       -> SNS cart-update --> 11.cart (strangulation)

captacao-comum -> captacao-dominio -> {persistencia, integracao} -> captacao-negocio
                                                    ^
                  WARs (captaweb, captaCan, APIs REST, batch, admin)
                                  v
                            Oracle (ST_*, PKG_*)
```

Regra de camadas: apresentacao chama `captacao-negocio` only (nunca WAR -> persistencia direto). Famílias: Core JAR, Servicos (SOAP hub, UC4), CaptaWeb GWT, APIs REST, Conecta/JSP, Admin, Config (`captacao-external-resources`). Repos satelite: `gcp` (batch), `promocao` (engine legado), `cotas`, `box-mensagens` (Ant).

## Archetypes — projetos Node (torres 02-19)

Identifique o archetype pelo sufixo do nome do projeto.

### api (`*-api`) — 14 projetos
Entry point HTTP REST da torre; publica SNS. Ex.: `orders-api`, `cart-api`, `payment-api`, `products-api`, `availability-api`.

```text
src/
  domain/commands/      <- App.Command (um por use case)
  domain/queries/       <- query handlers
  domain/services/      <- business logic
  domain/presenters/    <- formata output/eventos
  infrastructure/routers/                    <- Express routes (excluido do Sonar)
  infrastructure/repositories/               <- DB (Knex/TypeORM/Cassandra)
  infrastructure/services/message-publisher/ <- SNS publish
  db/migrations/        <- Knex migrations (apis com DB)
```

### listener (`*-listener`, `*-listerner`) — 59 projetos
Consumer assincrono de eventos SNS/SQS via Lambda. Maioria do sistema. Ex.: `cart-order-listener`.

```text
src/
  handler.js                     <- MessageQueue.LambdaHandler entry point
  infrastructure/queue-routes.js <- { [typeMessages.X]: CommandFactory }
  domain/command/<action>/       <- App.Command: execute(params)
  infrastructure/factories/      <- injecao de dependencias
  infrastructure/services/       <- HTTP clients para outros servicos
```

### process (`*-process`) — 14 projetos
Batch/scheduled sem trigger HTTP. Ex.: `orders-cancellation-process`, `payment-expiration-process`.

### domain (`*-domain`) — 3 projetos
Regras puras sem infra (sem DB, sem HTTP). Ex.: `products-domain`, `availability-domain`, `shipping-domain`.

### repository (`*-repository`) — 3 projetos
Persistencia isolada. Ex.: `products-repository`, `availability-repository`, `shipping-repository`.

### Archetypes secundarios (inferidos por setup)
| Sufixo/Prefixo | Archetype |
|---|---|
| `*-admin-fe`, `mfe-*` | admin-fe |
| `*-admin-graphql`, `*-supergraphql`, `*-graphql` | admin-graphql |
| `*-s3`, `*-sync`, `*-spreadsheet-importer` | utility |
| libs em `19.libraries/` | library |

## Archetypes — extensoes

### 01.commons (utility)
| Subtipo | Exemplo | Runtime |
|---|---|---|
| Lambda authorizer | `commons-authorizer` | Node >=22, Vitest, sem `globalsales-node-base` |
| Repositorio operacional | `automation-database` | Shell + GitHub Actions, sem app Node |

### 04.frontend
- admin-fe: apps MFE (`mfe-host`, `mfe-profile`, `mfe-gsp`) e utilitarios frontend.
- admin-graphql: `frontend-supergraphql` (gateway-only), `frontend-graphql` (subgraph com resolvers).
- Nota: libs npm (`mfe-devkit`, `mfe-toolkit`, etc.) aparecem como `admin-fe` no setup — desalinhamento; tratar como pacotes publicados.

### 20.capta (Maven)
| Tipo | Exemplo |
|---|---|
| `jar-core` | `captacao-negocio`, `captacao-dominio`, `captaweb-integracao` |
| `jar-gwt-client` | `captaweb-lib`, `captaweb-core` |
| `war-apresentacao` | `captaweb`, `captaCan-apresentacao`, `capta-vitrine-api` |
| `war-servico` | `captacao-servico`, `captaweb-servico` |
| `pom-agregador` | `captaCan-aplicacao`, `captaweb-build` |
| `utility` | `captacao-webapp-dev`, `box-mensagens`, `cotas` |

## Padrao de Comando (App.Command)

Handlers em torres Node (nao em `commons-authorizer`):

```js
class CreateOrderCommand extends App.Command {
  async execute(params) {
    try {
      const result = await this.service.process(params);
      this.emit(success, result);
    } catch (err) {
      App.Logger.current().error({ error: err.message, stack: err.stack });
      this.emit(error, err);
    }
  }
}
```

`capta-proxy` segue o mesmo padrao via `globalsales-node-base` (`BaseCommand`). Commands emitem `success` (ok), `error` (falha tecnica) ou `discart` (descartado por regra de negocio).

## Padrao de Listener

```text
handler.js -> instancia MessageQueue.LambdaHandler(config, queueHandlers)
queue-routes.js -> { [typeMessages.<tipo>]: CommandFactory.createAndPromisify(Factory) }
execute(params) -> recebe o payload desserializado do evento SNS/SQS
```

Para descobrir qual evento um listener consome, leia SEMPRE `infrastructure/queue-routes.js` primeiro — nunca infira pelo nome do projeto (ver gotchas em `gsp-tech-debt`). Exemplo canonico: `cart-order-listener` mapeia `typeMessages.orderCreate` -> `CreateOrderCommandFactory`.

## Padrao de Evento (MessagePresenter)

Envelope padronizado (torres Node), montado por `MessagePresenter.getFormattedMessages()`:

```js
{
  companyId: string,    // order.companyId
  countryCode: string,  // order.countryCode
  type: string,         // typeMessages enum (ex.: 'order-create')
  order: Order,         // GetOrderPresenter.format(order) — 40+ campos
  headers: { companyId, countryCode, eventType }  // eventType == type
}
```

Enum central: `typeMessages` em `19.libraries/commons/src/domains/type-messages.js` (~130 tipos). Chaves do fluxo replatform:
- `cartConvertion` -> `'cart-convertion'`
- `orderCreate` -> `'order-create'`
- `cartUpdate` -> `'cart-update'` (publicado por capta-proxy, nao por cart-api)

### Objeto Order (garantido pelo presenter)
Campos sempre presentes incluem: identificacao (`orderUid`, `orderNumber`, `cartUid`, `parentOrderUid`), empresa (`companyId`, `countryCode`, `businessModelId`, `orderTypeId`), status (`statusId`, `systemId`, `channelId`), pessoa (`userId`, `personId`, `personCode`), financeiro (`orderTotal`, `orderTotalWithTaxes`, `totalPrice`, `totalProfitability`, `totalCreditConsumed`, `totalItemsQuantity`, `totalPoints`, ...), impostos (`taxAmount`, `taxesParameters`, `taxPercentage`), ciclo (`currentCycle`, `orderCycle`, `kpiCycle`, ...) e datas (`orderDate`, `createdAt`, `updatedAt`, ...).

Arrays sempre presentes (podendo ser `[]`): `addresses`, `appliedPromotions`, `deliveryModes`, `giftItems`, `incorporations`, `payments`, `pendingReasons`, `purchasedItems`, `resilience`, `roleFunctions`, `structures`, `trackingHistory`.

## Fluxo A — Criacao de pedido (Replatform, GSP Node)

```text
1. Consultora finaliza carrinho no MFE
2. frontend-supergraphql -> cart-api (HTTP POST /cart/convert)
3. cart-api publica 'cart-convertion' no SNS
4. orders-cart-split-listener consome -> orders-api
5. orders-api persiste PostgreSQL -> publica 'order-create'
6. Consumers paralelos: cart-order-listener, availability-orders-listener,
   profile-orders-listener, payment-cart-listener, promotion-orders-listener, ...
```

## Fluxo B — Sync Capta -> GSP (Strangulation)

```text
1. MFE ou profile (warmup) -> capta-proxy (REST/GraphQL autenticado)
2. capta-proxy -> 20.capta/captacao (sessao legado, cookies JSESSIONID)
3. capta-proxy sincroniza carrinho / availability / showcase
4. Publica 'cart-update' no SNS -> 11.cart (cart-api, cart-summarization-listener)
```

Os fluxos A e B coexistem; PostgreSQL (orders) e Oracle (Captacao) sao SoR em contextos diferentes.

## Deploy (Node)

Por projeto tipico: `Dockerfile`, `Environments.yaml`, `canary/`, `.github/workflows/main.yaml` -> `naturacode/workflows-application-config`. Legado: WARs WebLogic ordenados por agregadores Maven.
