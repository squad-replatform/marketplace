---
name: gsp-tech-debt
description: Referencia de divida tecnica, gotchas, bugs conhecidos, areas frageis e riscos de seguranca do GSP (sanitizada, sem segredos). Cobre exclusoes amplas de Sonar, ausencia de AsyncAPI, thresholds frouxos, gotchas de listener (payment-cart, Joi.any em availability, promotion duplicada) e legado 20.capta. Use ao revisar riscos, planejar mudancas sensiveis ou apresentar a saude tecnica de uma torre ou projeto.
---

# GSP — Divida Tecnica e Gotchas

Auditoria de 2026-06-19 (torres 01.commons, 04.frontend, 20.capta). Conteudo sanitizado: nenhum segredo, token ou credencial real e reproduzido aqui.

## Gotchas de listener (alto valor)

### payment-cart-listener NAO consome eventos de orders-api
`14.payment/payment-cart-listener/src/infrastructure/queue-routes.js` mapeia apenas `typeMessages.cartDeleted` -> `CartDeletedFactory`. Consome `cart-deleted` de cart-api. Usa de `params.cart.summary`: `cartUid`, `companyId`, `countryCode` e status para logica condicional `countryCode === 'MY'` (cancela/reembolsa pagamento quando o carrinho e deletado; fluxo Malasia). O nome descreve destino (`payment`) e fonte (`cart`), nao o evento. Sempre leia `queue-routes.js`. O elo orders->payment esta em outros projetos (`payment-acknowledge-process`, `payment-integration-listener`, `payment-expiration-process`).

### Joi.any() em availability-orders-listener — zero validacao
`08.availability/availability-orders-listener/.../order-cancellation-validation.js` usa `Joi.any()` (aceita qualquer payload). O handler segue para `AvailabilityService` que acessa `order.giftItems[0].itemDetails[0].commitmentUid` e `order.purchasedItems[0].itemDetails[0].commitmentUid` (3 niveis) e `order.trackingHistory` com `statusId in [10, 11]` (magic numbers). Se orders-api mudar o schema (ex.: `itemDetails` -> `itemDetail`), o service roda com `undefined` e os comprometimentos de estoque nunca sao liberados — sem erro, sem alerta. Impacto: estoque preso, inconsistencia silenciosa. Fix: schema Joi explicito com campos obrigatorios (`cartUid`, `companyId`, `countryCode`, `orderNumber`, `statusId`, arrays `giftItems`/`purchasedItems` com `itemDetails[].commitmentUid`).

### ApplyPromotionService duplicado em showcase-al
`07.showcase/showcase-al/src/domain/services/apply-promotion.service.js` reimplementa calculo de desconto que existe em 12.promotion (Functional Coupling Simetrico). Regras de calculo (`calcPurchasePriceTo()`, arredondamento `Math.rounder`) podem divergir silenciosamente. Fix: showcase (BFF) deve chamar 12.promotion-api em vez de reimplementar. Ao escrever contrato de 12.promotion, verifique consistencia do `appliedPromotions[]` no evento de orders.

## Divida tecnica cross-cutting

- sonar.exclusions amplos em products-api e orders-api cobrem `src/domain/**`, `src/infrastructure/repositories/**`, `services/**`, `aggregates/**` — exatamente a logica critica. Coverage reportada e ficticia. Fix: remover exclusoes indevidas no Sonar, torre por torre.
- Contratos de evento sem spec formal (AsyncAPI ausente): os ~130 tipos em `type-messages.js` nao tem schema; Pact foi reverse-engineered (bottom-up). 59 listeners sem contrato validado. Fix: criar `asyncapi.yaml` para eventos criticos (order-create, cart-convertion, availability-confirmed) e derivar Pact top-down.
- `test.json` com threshold 50% e sem enforcement real; CI pode injetar 80% via `--config` Jest, mas o fix permanente exige atualizar test.json + quality gate por projeto.
- 149 workflows YAML individuais em `naturacode/workflows-application-config`: melhorias de CI exigem replicar em ~149 arquivos. Fix: Reusable Workflows por archetype.

## Por torre

### 01.commons
- Node 20 (doc) vs Node 22 (authorizer): `npm test` pode falhar sem nvm correto por projeto.
- Coverage divergente: commons-authorizer 100% no `test.json` vs 70% da policy DDD Generic; capta-proxy 0% vs 80% esperado.
- capta-proxy expoe Apollo subgraph nao federado no `supergraph-config.yaml` (gap produto vs codigo).
- SNS error swallow: falhas ao publicar `cart-update` podem ser silenciadas.
- automation-database: specs finas; parametros `hml` em secao `prd`.
- commons-authorizer: re-export quebrado `types/jwk`; logs Cognito/OAM trocados; `principalId` vazio.

### 04.frontend
- Stubs de teste em CI: frontend-graphql (`test` = `echo OK`), mfe-host (Jest aponta `src/tests/` inexistente), mfe-devkit/mfe-gsp sem suite, mfe-state testado via mfe-profile.
- Archetype `admin-fe` aplicado a libs npm (mfe-devkit/toolkit/components/state/locales) — config potencialmente errada; falta archetype `library`.
- React 16 (mfe-gsp) vs 18 (host/profile) no Module Federation — risco de incompatibilidade shared.
- 07.showcase remote externo ao monorepo 04 (deploy separado).
- Eventos DOM cross-MFE sem contrato formal — acoplamento implicito via `window`.

### 20.capta
- Sem enforcement de cobertura Jest/Sonar no legado (`coverage: null`); ~20 modulos Maven sem specs completas.
- Java 6, dual Spring, god-module `captacao-negocio`; `captacao-persistencia` depende de `captaweb-coherence` (dependencia invertida).
- Promo dual stack (legado `promocao` + GSP proxy F7).
- Sem Pact HTTP/SOAP com capta-proxy: breaking changes invisiveis.

## Bugs conhecidos

- Typo no nome do listener de availability-cart: `availability-cart-inactivation-listerner` tem `listerner` (typo) no diretorio e repo; buscas por `listener` nao acham. Renomear requer coordenacao com a Natura (owner do repo).

## Areas frageis

- `npm test` em projeto sem `npm install` previo pode falhar silenciosamente (sem verificacao defensiva no script do projeto).

## Gaps de cobertura de teste

- Provider-side Pact ausente em orders-api: nada verifica que o producer publica o schema que os consumers esperam (gap central do SDD).
- ~75/151 projetos sem diretorio `test/`; metade do sistema sem automacao de comportamento.
- cart-incorporation-listener sem `test/` algum (handler de `incorporation.processed`).

## Riscos de seguranca (sanitizado)

- JWT_SECRET hardcoded em `Environments.yaml` de `13.orders/orders-api` (ambiente dev): um valor de segredo aparece em plaintext (valor omitido aqui por seguranca — `***REDACTED***`). Producao usa `secretsManager://`. Recomendacao: mesmo em dev/qa, usar `parameter://` ou variavel de ambiente; remover o valor hardcoded do arquivo commitado.
## Dependencias em risco

- Node.js v12 como runtime padrao do sistema vs v20 dos projetos: definir `nvm use 20` no shell profile.
- `@pact-foundation/pact ^13`: API em transicao (`testPathPattern` -> `testPathPatterns`; provider verification mudou entre v11->v13). Fixar versao `13.1.4` sem `^`.
