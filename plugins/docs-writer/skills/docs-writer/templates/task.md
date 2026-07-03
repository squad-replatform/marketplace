---
tipo: task
titulo: ""
slug: ""
id: ""
jira: ""
tipo_item: feat
status: rascunho
story_points: 0
tema: ""
phase: ""
tdd: ""
torres: []
gate: quick
depende_de: []
relacionados: []
autor: ""
data: ""
---

# {{id}} — {{titulo}}

> **Em uma frase:** <!-- Resultado entregue pelo dev — 1 linha acionável -->

## 1 Metadados

| Campo | Valor |
|-------|-------|
| Work Item | — |
| Epic / Tema | — |
| Status | rascunho |
| Estimativa | 0 SP |
| Fase / TDD | — |
| Torre(s) / Componente | — |
| Depends on / Blocks | — |
| Gate / Testes | quick / unit |

## 2 Contexto

<!-- Por que esta task existe (2–4 frases). Referenciar backlog e docs de origem. -->

### Fora de escopo

| Item | Dono |
|------|------|
| — | — |

## 3 Objetivo

<!-- Resultado esperado em 1 frase. Sem o "como". -->

## 4 Requisitos e critérios de aceite

### Requisitos funcionais

| ID | Requisito | Rastreio | Verificação |
|----|-----------|----------|-------------|
| FR-001 | O sistema MUST … | RN-xx | teste / cenário |

### Cenários (opcional — tasks Core ou comportamento complexo)

**US1 — título** `FR-001`

- **Given** … **When** … **Then** …

### Casos limite

| Condição | Comportamento esperado |
|----------|------------------------|
| — | — |

## 5 Especificação técnica

<!-- Onde e como codar: arquivos, contratos, diagramas, decisões. Sem comandos bash. -->

| # | Artefato | Path | Método / API | Alteração | FR | Teste |
|---|----------|------|--------------|-----------|----|-------|
| 1 | — | — | — | — | FR-001 | — |

### Contrato mínimo (opcional)

```json
{}
```

## 6 Como executar

<!-- Operação: repos, branch, semver, verify, armadilhas. Gitflow padrão no backlog §6. -->

| Item | Valor |
|------|-------|
| Repositório(s) | — |
| Branch | `feature/JGR-XXX` |
| Classificação DDD | Supporting — 85% / 80% |

### SemVer (se lib compartilhada)

N/A — <!-- ou fluxo MINOR: domain → Nexus → bump consumidores -->

### Verify

```bash
# comandos de teste local e harness
```

### Armadilhas

- —

**Primeiro passo:** <!-- ação literal para começar -->

## 7 Dependências e referências

- **Upstream:** —
- **Downstream:** —
- [Backlog](../backlog/backlog01.md) · [PRD](../prd/prd01.md) · [TDD](../tdd/tdd01.md)

## 8 Definition of Done

DoD global do tema: ver [backlog §6](../backlog/backlog01.md#6-definition-of-done-global).

- [ ] Requisitos FR-00x verificados
- [ ] Testes e gate do projeto passando
- [ ] PR vinculado ao Work Item Jira
