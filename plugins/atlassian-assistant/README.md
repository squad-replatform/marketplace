# atlassian-assistant

Plugin Cursor para leitura e escrita em Jira e Confluence via MCP, com configuracao dirigida por `Environments.yaml`.

**Diferencial frente ao plugin oficial Atlassian:** este plugin usa `Environments.yaml` para resolver automaticamente `cloudId`, `projectKey` e `spaceKey` do time, sem precisar informar esses valores a cada interacao.

## Skills incluidas

| Skill | Uso |
|-------|-----|
| `jira-assistant` | Issues, sprints, JQL, transitions, comments |
| `confluence-assistant` | Busca, leitura, criacao e edicao de paginas |

## Pre-requisito obrigatorio — Environments.yaml

O plugin depende de `Environments.yaml` na **raiz do repo** (gitignored). Sem ele as skills nao funcionam.

```bash
# Copiar o template e preencher
cp Environments-template.yaml Environments.yaml
```

Estrutura minima necessaria:

```yaml
atlassian:
  cloudId: "<seu-cloud-id>"
  url: "https://<seu-site>.atlassian.net"
  jira:
    boards:
      - id: 1
        key: "PROJ"
        name: "Meu Projeto"
        url: "https://<seu-site>.atlassian.net/jira/software/projects/PROJ/boards/1"
  confluence:
    spaces:
      - key: "SPACE"
        name: "Meu Space"
        url: "https://<seu-site>.atlassian.net/wiki/spaces/SPACE"
        keywords: ["docs", "wiki"]
```

## Validar configuracao

```bash
bash .marketplace/plugins/atlassian-assistant/scripts/preflight.sh
```

Requer `python3` e `PyYAML` (`pip install pyyaml`).

## MCP Server

Este plugin declara o server `atlassian-gsp` (mesmo endpoint OAuth do Atlassian MCP oficial).

> **Atencao:** se voce tambem tiver o **plugin oficial Atlassian** instalado, ele registra um server chamado `atlassian`. Os dois servers apontam para o mesmo endpoint — nao ha conflito funcional, mas voce tera dois servers distintos no workspace. Prefira usar apenas um dos dois.

## Autenticacao

Na primeira chamada MCP, o Cursor solicitara autenticacao OAuth com o Atlassian. Siga o fluxo exibido.
