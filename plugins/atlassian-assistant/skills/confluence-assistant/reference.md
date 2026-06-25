# Confluence Assistant — Reference

Ler ao criar ou atualizar paginas Confluence.

## Buscar e atualizar uma pagina

```
1. search("API documentation")
2. getConfluencePage(cloudId, pageId="found-id")
3. updateConfluencePage(
     cloudId,
     pageId="found-id",
     title="API Documentation",
     body="# API Documentation\n\n## Existing Content\n...\n\n## New Section\nNew content..."
   )
```

## Criar uma pagina em um space

```
1. getConfluenceSpaces(cloudId, keys=["{SPACE_KEY}"])
2. createConfluencePage(
     cloudId,
     spaceId="space-id-from-step-1",
     title="ADR-001: Title",
     body="# ADR-001\n\n## Status\nAccepted\n\n## Context\n...\n\n## Decision\n..."
   )
```

## Estrutura do body de pagina

```markdown
# Titulo Principal

## Introducao

Visao geral breve.

## Secoes

- Headings claros (##, ###)
- Bullet points para listas
- Code blocks para exemplos

## Proximos Passos

1. Passo 1
2. Passo 2
```

## Regras de body

- **Markdown only** — sem HTML
- Headings com `##` e `###`
- Listas com `-` ou numeradas
- Code blocks com triple backticks
- Nao incluir file paths do repo no conteudo
