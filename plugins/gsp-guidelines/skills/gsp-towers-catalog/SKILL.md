---
name: gsp-towers-catalog
description: Catalogo autoritativo das torres do GSP — numeracao 01..20, classificacao DDD (Core/Supporting/Generic) das torres de dominio, ubiquitous language por torre, archetypes e contagem de projetos, detalhe do legado 20.capta, issues de coesao e o schema de registro de torre para lookup. Use ao apresentar, localizar ou raciocinar sobre qualquer torre ou projeto do GSP. Fonte autoritativa para classificacao e nomes de torre.
---

# GSP — Catalogo de Torres

Fonte autoritativa para classificacao DDD e nomes de torre. Reflexo de 2026-06 (`domain-analysis` de 2026-06-02; agregacao 2026-06-19).

## Numeracao

O GSP tem 20 torres numeradas, de `01` a `20`:
- Torres 01-18: contextos de dominio classificados por DDD (ver tabelas abaixo). `[documentado]`
- Torre 19.libraries: pacotes compartilhados (`commons`, `iris-nodejs-messenger`, `commons-scylladb`, ...); nao e bounded context de dominio. `[documentado]`
- Torre 20.capta: legado / system of record (Oracle, Maven/WebLogic); fora do barramento SNS Node. `[documentado]`

Papeis transversais: 01.commons e camada transversal (auth + proxy); 04.frontend e o canal digital (MFE). As torres Node usam os archetypes descritos em `gsp-architecture`. Para torres sem detalhe consolidado, apresente no nivel de bounded-context/archetype e marque `[nao-documentado]`.

## Schema de registro de torre (lookup)

Ao resolver uma torre, produza um registro neste formato. Campos sem fonte recebem `null` e `documented: false`; nunca preencha por suposicao.

```json
{
  "number": "13",
  "name": "orders",
  "ddd_class": "core | supporting | generic | library | legacy-sor | transversal | digital-channel",
  "ubiquitous_language": ["Order", "OrderSplit", "..."],
  "archetypes": ["api", "listener", "process", "domain", "repository"],
  "documented": true,
  "notes": "string | null"
}
```

## Core Domain — alta volatilidade

Vantagem competitiva da Natura; muda com frequencia. Threshold (policy DDD): api/domain/repository 95%, listeners/processes 90%.

| Torre | Ubiquitous Language | Por que e Core |
|---|---|---|
| 13.orders | Order, OrderSplit, Tracking, CancellationReason, Reorder | Coracao do fluxo — criacao e gestao do pedido |
| 11.cart | Cart, CartSummary, CartItem, Conversion, Split | Montagem do pedido pela consultora |
| 08.availability | Commitment, Reservation, INA, Stock, Release | Controle proprietario de estoque e reservas |
| 12.promotion | Promotion, ProgressivePromotion, PromotionStep, O9 | Diferenciador de incentivo a consultoras |
| 05.profile | Consultant, Credit, Debit, Incorporation, StarterKit | Gestao do relacionamento com a consultora |
| 09.quotas | QuotaBreak, QuotaCN, QuotaEC, Redistribution | Algoritmo proprietario de redistribuicao de cotas |
| 10.puf | GuaranteedPurchase, Unavailability, UnavailabilityFixHistory | Compra garantida + gestao de indisponibilidade |
| 06.products | Product, Material, BusinessCoverage, LogisticCoverage | Catalogo proprietario com cobertura de negocio |

## Supporting Subdomain — media volatilidade

Essencial para operar o Core, mas nao diferenciador. Threshold (policy DDD): 80-85%.

| Torre | Ubiquitous Language | Papel |
|---|---|---|
| 14.payment | PaymentIntent, Refund, PaymentCondition, Installment | ACL para gateways de pagamento externos |
| 15.shipping | DeliveryMode, PickupPoint, ShippingPolicy | Configuracao de modos de entrega |
| 03.integration | NCN, Credit, Debit, OrderNumber, IntegrationPolicy | ACL para sistemas legados Natura (ERP, fiscal) |
| 07.showcase | Vitrine, Banner, Tab, ProgressivePromotion, Combo | BFF de experiencia de compra (orquestra core domains) |

Atencao: 07.showcase duplica logica de promocao de 12.promotion (ver `gsp-tech-debt`).

## Generic Subdomain — baixa volatilidade

Poderia ser produto off-the-shelf. Threshold (policy DDD): 70%.

| Torre | Ubiquitous Language | Papel |
|---|---|---|
| 01.commons | Authorization, Token, JWT | Lambda Authorizer (poderia ser Cognito nativo) |
| 02.parameters | Parameter, WorkingDays, GeographicalLevel | Config centralizada parametrizavel |
| 04.frontend | Supergraph, MFE, Federation | Infraestrutura de UI (Apollo + Module Federation) |
| 16.operations | ReprocessOrder, NCNOrder, OperationRole | Backoffice de suporte operacional |
| 17.marketing | MarketingIntegration | Bridge para sistema externo de marketing |
| 18.main | AdminRole, CountryCompany, AdminUser | Admin central com gestao de roles por pais |

## Issues de coesao detectados

- Alta: 07.showcase duplica `ApplyPromotionService` de 12.promotion (Functional Coupling Simetrico); 09.quotas mistura QuotaCN e QuotaEC (dois bounded contexts numa torre).
- Media: 10.puf mistura GuaranteedPurchase e Unavailability (linguagens e ciclos de vida distintos); 07.showcase chama cart + products + promotion direto, sem ACL.
- Volatilidade: os 5 pares analisados entre torres Core resultaram em CRITICAL (High x High x High) — Core muda com frequencia e alto impacto cross-tower.

## Contagem de projetos por archetype (torres Node)

| Archetype | Sufixo | Qtd | Exemplos |
|---|---|---|---|
| api | `*-api` | 14 | orders-api, cart-api, payment-api, products-api, availability-api |
| listener | `*-listener` / `*-listerner` | 59 | cart-order-listener (maioria do sistema) |
| process | `*-process` | 14 | orders-cancellation-process, payment-expiration-process |
| domain | `*-domain` | 3 | products-domain, availability-domain, shipping-domain |
| repository | `*-repository` | 3 | products-repository, availability-repository, shipping-repository |

Total aproximado: ~151 projetos Node. Estrutura `src/` por archetype: ver `gsp-architecture`. `[nao-documentado]` o detalhe de projetos individuais fora das torres com spec consolidada (01.commons, 04.frontend, 20.capta) e das piloto (11.cart, 13.orders).

## Torre 20.capta (legado) — detalhe

Monorepo Maven `captacao` (repo `capta-captacao`) + 4 repos satelite. SoR Oracle (`ST_*`, schemas USERCNT/USERCPT). JDK 1.6, WebLogic 10.3, Spring 3.x, GWT/Crux + JSP. Sem mensageria SNS/SQS no monorepo. Sem enforcement de cobertura Jest (`coverage: null`).

### Familias de modulos
| Familia | Modulos-chave | Papel |
|---|---|---|
| Core | `captacao-comum` -> `dominio` -> `persistencia` + `integracao` -> `negocio` | DAG; `negocio` = composition root |
| Servicos | `captacao-servico`, `captacao-robo`, `captacao-ws-client` | SOAP hub, batch UC4 |
| CaptaWeb | `captaweb-lib` -> `captaweb-parent` -> `captaweb-*` -> `captaweb` WAR | UI consultora GWT |
| APIs REST | `capta-vitrine-api`, `capta-convivencia-api` | Fronteira HTTP para GSP/MFE |
| Conecta / JSP | `captaCan-*`, `captaWeb-*` | WARs legados |
| Admin | `captaAdm-*` | Stack paralela sem `captacao-integracao` |
| Config | `captacao-external-resources` | Properties `-Dambiente` |

Regra de camadas: apresentacao (WAR/GWT) -> `captacao-negocio` -> persistencia/integracao (nunca WAR -> persistencia direto).

### Fluxos legados (MODULE_GRAPH)
| ID | Fluxo | Entrada |
|---|---|---|
| F1 | Pedido CaptaWeb | GWT -> `captaweb-servico` -> negocio -> Oracle |
| F2 | Pedido Conecta | JSP -> negocio (equivalente F1) |
| F3 | SOAP externo | Cliente -> `captacao-servico` |
| F4 | Pre-pedido | `captaPrePedido-apresentacao` -> `ST_PRE_*` |
| F5 | UC4 batch | `captacao-ws-client` -> reprocessamento -> SOA |
| F6 | Vitrine/GSP | MFE / `capta-proxy` -> vitrine API ou captaweb |
| F7 | Promo GSP | integracao -> `gsp-promotion-soap-proxy` (12.promotion) |

### Repos satelite (20.capta)
| Repo | Papel | Integracao |
|---|---|---|
| `gcp` | Batch conversao/harmonizacao | SOA/UC4 (F5) |
| `promocao` | Engine promo legado | Dual stack com GSP via `captacao-integracao` (F7) |
| `cotas` | Cotas standalone | Acoplamento organizacional |
| `box-mensagens` | Box mensagens | Build Ant |

Integracao com o replatform: GSP -> Capta por HTTP via `01.commons/capta-proxy` (`EXTERNAL_CAPTA_URL`, cookies JSESSIONID); capta-proxy -> GSP por SNS `cart-update` -> 11.cart; Capta -> GSP promo por SOAP (`captacao-integracao` -> `12.promotion/gsp-promotion-soap-proxy`). PostgreSQL de orders e paralelo ao Oracle (nao substitui o SoR na migracao).
