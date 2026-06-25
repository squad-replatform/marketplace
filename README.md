# GSP Replatform Tools

Cursor plugin collection for the Natura GSP replatform team.

This repository follows the [Cursor plugin marketplace format](https://cursor.com/docs/reference/plugins#multi-plugin-repositories). Each plugin lives under `plugins/` and is registered in `.cursor-plugin/marketplace.json`.

## Repository structure

```text
.cursor-plugin/
  marketplace.json       # Plugin registry manifest
plugins/
  <plugin-name>/         # One directory per plugin (to be added)
    .cursor-plugin/
      plugin.json        # Per-plugin manifest
    rules/               # Optional: .mdc rule files
    skills/              # Optional: skill folders with SKILL.md
    agents/              # Optional: subagent definitions
    commands/            # Optional: agent commands
    hooks/               # Optional: hooks.json + scripts
    mcp.json             # Optional: MCP server config
    assets/              # Optional: logos and static assets
docs/
  add-a-plugin.md        # Step-by-step guide for new plugins
scripts/
  validate-marketplace.mjs
```

## Getting started

1. Update `.cursor-plugin/marketplace.json` with your team owner details if needed.
2. Add your first plugin under `plugins/` (see [docs/add-a-plugin.md](docs/add-a-plugin.md)).
3. Register the plugin in the manifest.
4. Validate locally:

   ```bash
   node scripts/validate-marketplace.mjs
   ```

5. Push to GitHub and import the repository as a team plugin source in Cursor:
   **Dashboard → Settings → Plugins → Import from Repo**.

## Publishing

- **Team plugins**: Import this Git repository in Cursor team settings.
- **Public marketplace**: Submit at [cursor.com/marketplace/publish](https://cursor.com/marketplace/publish) after plugins are ready and validated.

## References

- [Cursor Plugins docs](https://cursor.com/docs/plugins)
- [Plugins reference](https://cursor.com/docs/reference/plugins)
- [Official plugin template](https://github.com/cursor/plugin-template)
