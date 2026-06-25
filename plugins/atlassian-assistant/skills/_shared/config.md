# Configuration — Atlassian Assistant

**Unica fonte:** `Environments.yaml` (raiz do repo, gitignored). Se ausente, copiar `Environments-template.yaml` e preencher.

Nao ler `.cursor/rules/jira-config.mdc`, `.cursor/rules/confluence-config.mdc` nem pedir Cloud ID quando o YAML resolver.

## Estrutura esperada

```yaml
atlassian:
  cloudId: "<uuid-or-site-url>"
  url: "<base-url>"
  jira:
    boards: [{ id, key, name, url }]
  confluence:
    spaces: [{ key, name, url, keywords }]
```

| Variavel | Origem | Uso |
|----------|--------|-----|
| `{CLOUD_ID}` | `cloudId` | Todos os calls MCP |
| `{PROJECT_KEY}` | `jira.boards[n].key` | JQL, chaves, create |
| `{SPACE_KEY}` | `confluence.spaces[n].key` | Queries de space |

Extrair tambem board/space name, url, keywords conforme necessario. **Padrao:** primeiro board/space. **Override:** match pela chave ou keyword mencionada pelo usuario.

Reportar config apenas em falha ou se perguntado. **Seguranca:** nunca ecoar tokens ou YAML completo — apenas campos de `atlassian`.

## Tratamento de falhas

| Falha | Acao |
|-------|------|
| Arquivo ausente | Apontar para `Environments-template.yaml` |
| Sem `cloudId` | Parar; corrigir YAML |
| Boards/spaces vazios para a op | Parar; adicionar entrada |
| Erro de auth | `mcp_auth (atlassian-gsp)`, retry |

## Preflight (opcional)

`scripts/preflight.sh` (na raiz do plugin) valida o `Environments.yaml`. Requer `python3` + `PyYAML`.
