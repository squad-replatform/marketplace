# Jira Assistant — Reference

Ler ao criar issues Jira ou construir queries JQL.

## Task Description Template

**Sempre** usar para `createJiraIssue` descriptions. Markdown only — sem HTML, sem file paths.

```markdown
## Context

[Breve explicacao do problema ou necessidade]

## Objective

[O que precisa ser realizado]

## Technical Requirements

[Objetivo tecnico de alto nivel — sem file paths]

- [ ] Requisito 1
- [ ] Requisito 2
- [ ] Requisito 3

## Acceptance Criteria

- [ ] Criterio 1
- [ ] Criterio 2
- [ ] Criterio 3

## Technical Notes

[Dependencias, links relevantes — alto nivel, sem file paths]

## Estimate

[Estimativa de tempo ou story points, se aplicavel]
```

## JQL Snippets

Substituir `{PROJECT_KEY}` pelo valor do `Environments.yaml`. **Toda query deve incluir** `project = {PROJECT_KEY}`.

```jql
# Minhas tarefas em progresso
project = {PROJECT_KEY} AND assignee = currentUser() AND status = "In Progress"

# Issues recentes
project = {PROJECT_KEY} AND created >= -7d

# Bugs de alta prioridade
project = {PROJECT_KEY} AND type = Bug AND priority = High

# Epics abertos
project = {PROJECT_KEY} AND type = Epic AND status != Done

# Backlog sem responsavel
project = {PROJECT_KEY} AND assignee is EMPTY AND status = "To Do"

# Atualizados esta semana
project = {PROJECT_KEY} AND updated >= startOfWeek()
```
