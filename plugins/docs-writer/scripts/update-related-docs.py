#!/usr/bin/env python3
"""
Hook: postToolUse / Write
Detecta quando um doc em .docs/**/*.md e gravado e retorna additional_context
listando todos os docs associados (dependentes, dependencias e referenciados)
que podem precisar de atualizacao.
"""
import sys
import json
import os
import re

try:
    import yaml
    HAS_YAML = True
except ImportError:
    HAS_YAML = False


# --------------------------------------------------------------------------- #
# Frontmatter                                                                  #
# --------------------------------------------------------------------------- #

def extract_frontmatter(content):
    if not content.startswith("---"):
        return {}, content
    end = content.find("\n---", 3)
    if end == -1:
        return {}, content
    fm_str = content[3:end].strip()
    body = content[end + 4:]
    if not HAS_YAML:
        return _parse_frontmatter_simple(fm_str), body
    try:
        return yaml.safe_load(fm_str) or {}, body
    except Exception:
        return {}, body


def _parse_frontmatter_simple(fm_str):
    """Fallback parser when PyYAML is unavailable (handles simple scalar + list)."""
    result = {}
    lines = fm_str.splitlines()
    current_key = None
    current_list = None
    for line in lines:
        list_item = re.match(r"^\s+-\s+(.+)$", line)
        key_val = re.match(r"^(\w+):\s*(.*)$", line)
        if list_item and current_key:
            if current_list is None:
                current_list = []
                result[current_key] = current_list
            current_list.append(list_item.group(1).strip())
        elif key_val:
            current_key = key_val.group(1)
            current_list = None
            val = key_val.group(2).strip()
            if val.startswith("[") and val.endswith("]"):
                inner = val[1:-1]
                result[current_key] = [
                    v.strip().strip("'\"") for v in inner.split(",") if v.strip()
                ]
            else:
                result[current_key] = val if val else None
    return result


# --------------------------------------------------------------------------- #
# Helpers                                                                      #
# --------------------------------------------------------------------------- #

_MD_LINK_RE = re.compile(r"\[(?:[^\]]+)\]\(([^)]+\.md(?:#[^)]*)?)?\)", re.IGNORECASE)


def find_md_links_in_body(body):
    """Retorna todos os hrefs de links markdown que apontam para .md."""
    return [m.group(1).split("#")[0] for m in _MD_LINK_RE.finditer(body) if m.group(1)]


def resolve_link(from_file, link):
    """Resolve link relativo a partir do diretorio do arquivo de origem."""
    base = os.path.dirname(from_file)
    return os.path.normpath(os.path.join(base, link))


def is_docs_md(path, cwd):
    """Retorna True se path e um .md dentro de .docs/ (excluindo .work/)."""
    rel = os.path.relpath(path, cwd)
    parts = rel.replace("\\", "/").split("/")
    return (
        parts[0] == ".docs"
        and ".work" not in parts
        and rel.endswith(".md")
    )


# --------------------------------------------------------------------------- #
# Coleta de docs associados                                                    #
# --------------------------------------------------------------------------- #

def collect_related(changed_path, cwd):
    """
    Retorna dict com:
      dependencias: docs listados em 'relacionados' ou linkados no corpo do doc alterado
      dependentes:  docs que listam o doc alterado em 'relacionados' ou linkam para ele
    """
    try:
        with open(changed_path, encoding="utf-8") as f:
            content = f.read()
    except OSError:
        return {"dependencias": [], "dependentes": []}

    fm, body = extract_frontmatter(content)

    # -- dependencias diretas (o doc alterado aponta para outros) ------------ #
    dependencias = set()

    relacionados_raw = fm.get("relacionados") or []
    if isinstance(relacionados_raw, str):
        relacionados_raw = [relacionados_raw]
    for r in relacionados_raw:
        resolved = resolve_link(changed_path, str(r))
        if os.path.isfile(resolved) and is_docs_md(resolved, cwd):
            dependencias.add(os.path.normpath(resolved))

    for link in find_md_links_in_body(body):
        if not link:
            continue
        resolved = resolve_link(changed_path, link)
        if os.path.isfile(resolved) and is_docs_md(resolved, cwd):
            dependencias.add(os.path.normpath(resolved))

    # -- dependentes (outros docs que apontam para o doc alterado) ----------- #
    dependentes = set()
    changed_norm = os.path.normpath(changed_path)
    docs_root = os.path.join(cwd, ".docs")

    for root, dirs, files in os.walk(docs_root):
        dirs[:] = [d for d in dirs if d != ".work"]
        for fname in files:
            if not fname.endswith(".md"):
                continue
            fpath = os.path.normpath(os.path.join(root, fname))
            if fpath == changed_norm:
                continue
            try:
                with open(fpath, encoding="utf-8") as f:
                    other_content = f.read()
            except OSError:
                continue
            other_fm, other_body = extract_frontmatter(other_content)

            other_rel = other_fm.get("relacionados") or []
            if isinstance(other_rel, str):
                other_rel = [other_rel]
            for r in other_rel:
                resolved = resolve_link(fpath, str(r))
                if os.path.normpath(resolved) == changed_norm:
                    dependentes.add(fpath)
                    break
            else:
                for link in find_md_links_in_body(other_body):
                    if not link:
                        continue
                    resolved = resolve_link(fpath, link)
                    if os.path.normpath(resolved) == changed_norm:
                        dependentes.add(fpath)
                        break

    return {
        "dependencias": sorted(dependencias - {changed_norm}),
        "dependentes": sorted(dependentes),
    }


# --------------------------------------------------------------------------- #
# Formatacao do additional_context                                             #
# --------------------------------------------------------------------------- #

def fmt_list(paths, cwd):
    return "\n".join(f"  - `{os.path.relpath(p, cwd)}`" for p in paths)


def build_context(changed_rel, related, cwd):
    dependencias = related["dependencias"]
    dependentes = related["dependentes"]

    if not dependencias and not dependentes:
        return None

    lines = [
        f"**[docs-writer hook]** O doc `{changed_rel}` foi modificado.",
        "",
        "Os docs associados abaixo podem precisar de atualizacao:",
        "",
    ]

    if dependentes:
        lines.append("**Dependentes** — docs que dependem do doc alterado")
        lines.append(
            "(verifique secoes de status de derivados, links e referencias cruzadas):"
        )
        lines.append(fmt_list(dependentes, cwd))
        lines.append("")

    if dependencias:
        lines.append("**Dependencias** — docs que o doc alterado referencia")
        lines.append("(verifique se o link ainda e valido e se o conteudo divergiu):")
        lines.append(fmt_list(dependencias, cwd))
        lines.append("")

    lines.append(
        "Avalie cada doc listado e atualize apenas o necessario para manter "
        "a consistencia (secoes de referencias cruzadas, frontmatter `relacionados`, "
        "status de derivados, etc.)."
    )
    return "\n".join(lines)


# --------------------------------------------------------------------------- #
# Entrypoint                                                                   #
# --------------------------------------------------------------------------- #

def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    file_path = (data.get("input") or {}).get("path", "")
    if not file_path:
        sys.exit(0)

    cwd = os.getcwd()
    if not os.path.isabs(file_path):
        file_path = os.path.join(cwd, file_path)
    file_path = os.path.normpath(file_path)

    if not is_docs_md(file_path, cwd):
        sys.exit(0)

    related = collect_related(file_path, cwd)
    changed_rel = os.path.relpath(file_path, cwd)
    context = build_context(changed_rel, related, cwd)

    if context:
        print(json.dumps({"additional_context": context}))

    sys.exit(0)


if __name__ == "__main__":
    main()
