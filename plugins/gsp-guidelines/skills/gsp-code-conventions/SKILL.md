---
name: gsp-code-conventions
description: Referencia profunda das convencoes de codigo do GSP — naming (kebab/Pascal/camel), ordem de imports, estrutura de arquivo de Command, error handling com App.Logger, mensagens centralizadas, organizacao de testes *.spec.js, configuracao via Environments.yaml e as convencoes distintas das torres 01.commons, 04.frontend e 20.capta. Use ao escrever ou revisar codigo JS/TS/Java do GSP.
---

# GSP — Convencoes de Codigo

## Naming

- Arquivos: kebab-case para JS/TS (`create-order-command.js`, `cart-service.js`, `queue-routes.js`, `get-order-presenter.js`). Excecao: `index.js` como barrel de modulo.
- Classes: PascalCase (`CreateOrderCommand`, `MessagePresenter`, `OrderCreatePresenter`, `CartService`).
- Funcoes/metodos: camelCase (`getFormattedMessages()`, `buildAcknowledgeBody()`, `formatOrderItemsWithMaterials()`).
- Constantes/Enums: objetos freeze; SCREAMING_SNAKE_CASE dentro, camelCase no export (`typeMessages.orderCreate`, `ENUM.ACKNOWLEDGE.DESTINATION_SYSTEM.ORDERS`). Status: `orderStatusEnum.pendingSplit`, `cartPaymentTypes.creditCard`.
- Variaveis: camelCase descritivo; desestruturacao preferida.

## Imports

```js
// 1. Libs externas (globalsales-*, node-base)
import { App } from 'globalsales-node-base';
import { Domains, CommandFactory } from 'globalsales-commons';
// 2. Modulos internos (caminhos relativos)
import MESSAGES from '../../../commons/messages';
import ENUM from '../../domain/enum';
import config from '../../config';
```

## Estrutura de arquivo (Commands)

```text
1. Imports
2. Desestruturacao de enums/constants
3. class ... extends App.Command
   - constructor com injecao de dependencias
   - async execute(params)
       try: logica + this.emit(success, ...)
       catch: App.Logger.current().error(...) + this.emit(error, ...)
4. export default
```

## Error handling

```js
// orders-api/src/domain/commands/order/create/create.js
} catch (error) {
  App.Logger.current().error({
    ...MESSAGES.create.fail,
    cartUid,
    error: error.message,
    stack: error.stack,
  });
  this.emit(validationFailed, { ...MESSAGES.create.fail, cartUid, errors: error.message });
}
```

Mensagens centralizadas em `src/commons/messages.js` / `src/domain/messages/` com codigos numericos:

```js
order: {
  createError:    { errorCode: 12, message: 'new.order.create.error' },
  newOrderCreated: { code: 17, message: 'new.order.successfully.created' },
}
```

## Testes

- Localizacao: `test/unit/` e `test/integration/` (nao em `src/`).
- Naming: `*.spec.js` (jest testMatch `**/?(*.)(spec).js?(x)`).
- Config: `test.json` na raiz (nao `jest.config.js`). Setup: `test/scripts/setupAfterEnv.js`.

## Configuracao

`Environments.yaml` + AWS Parameter Store / Secrets Manager (`parameter://`, `secretsManager://`). Config local em `src/config/index.js` (le `process.env`). Nunca hardcode segredos.

## TypeScript

`tsconfig.json` apenas em MFEs e algumas libraries; `global.d.ts` para globais; strict mode nao padronizado.

## Comentarios

Minimos no codigo operacional. `// eslint-disable` para excecoes pontuais (max-lines, complexity). JSDoc apenas em presenters complexos. TODO/FIXME nao sistematicos.

## Torre 01.commons — convencoes distintas

- `commons-authorizer`: camadas `application/` vs `infrastructure/` (nao `domain/commands`); env validado em `config/env.ts` (`@t3-oss/env-core`); nao usa `App.Command` nem `src/commons/messages.js`.
- `capta-proxy`: padrao GSP API (`App.Command`/`BaseCommand`, factories por rota); alias `@base/*`; `AuthenticatedHandler` para JWT; dual server `EXPRESS_PORT` (REST) + `GRAPHQL_PORT` (subgraph).
- `automation-database`: branch nomeia o RDS alvo (`products-prd`); um unico `sql/script.sql` por PR; merge nao executa SQL.
- Regra: projetos nao compartilham `src/commons/` entre repos.

## Torre 04.frontend — convencoes MFE

- Apps modernos (host, profile): `define*Config` + `mergeDeepObjects` via `mfe-devkit`; path aliases TS; Clean Architecture em `mfe-profile` (domain/application/infra/presentation).
- Legado (mfe-gsp): Redux modules + `commons/`; dual entry `index.js` standalone vs `app.jsx` federado.
- Cross-MFE: estado via `gsp-microfrontend-state` (Zustand), nao Redux global; eventos via `CustomEvent` no `window` (convencao informal, sem enum central).

## Torre 20.capta — convencoes Java

- Pacotes `net.natura.captacao.*` vs `net.natura.captacaoweb.*`.
- WAR apresentacao -> facades em `captacao-negocio` only (nunca -> persistencia direto).
- Spring XML (`captacaoService-consumer.xml`, `captaweb-integracao.xml`); CaptaWeb servidor Crux `@RestService`.
- Properties: `-Dambiente` + `captacao-external-resources`. Build: `mvn -pl <modulo> -am package -Dambiente=dev|hml|prd`.
