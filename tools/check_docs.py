"""Checks the docs: every relative link points at a real file (and heading), and every page under docs/
can be reached from docs/HOME.md. Run after editing docs:  python tools/check_docs.py"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
HOME = ROOT / "docs" / "HOME.md"
LINK = re.compile(r"\[[^\]]*\]\(([^)\s]+)\)")
CODE = re.compile(r"```.*?```|`[^`\n]*`", re.S)


def anchor(heading):
    # GitHub-style heading anchor: lowercase, drop punctuation, spaces to dashes.
    return re.sub(r"[^\w\- ]", "", heading.strip().lower()).replace(" ", "-")


def links(md):
    """(target file, anchor) for each relative link in a markdown file."""
    text = CODE.sub("", md.read_text(encoding="utf-8"))
    for target in LINK.findall(text):
        if re.match(r"[a-z]+:", target):  # http:, mailto:, ...
            continue
        path, _, frag = target.partition("#")
        yield (md.parent / path).resolve() if path else md, frag


def code_map():
    """Code files named in the docs must exist, and every code file and tool must be named in the docs."""
    docs = "\n".join(md.read_text(encoding="utf-8") for md in (ROOT / "docs").rglob("*.md"))
    problems = []
    for path in sorted(set(re.findall(r"\b(?:src|tools)/[\w/.-]+\.(?:luau|py|lua|sh|ps1)\b", docs))):
        if not (ROOT / path).exists():
            problems.append(f"docs name {path}, which no longer exists")
    for f in sorted((ROOT / "src").rglob("*.luau")):
        rel = f.relative_to(ROOT).as_posix()
        if "/Packages/" in rel or rel.startswith("src/generated/"):  # third party / generated from config
            continue
        if rel not in docs:
            problems.append(f"{rel} is not on any docs page (add it to its system page's Code table)")
    tools_page = (ROOT / "docs" / "workshop" / "tools.md").read_text(encoding="utf-8")
    for f in sorted((ROOT / "tools").rglob("*")):
        if f.suffix in {".py", ".lua", ".sh", ".ps1"} and "__pycache__" not in f.parts and f.name not in tools_page:
            problems.append(f"{f.relative_to(ROOT).as_posix()} is not in docs/workshop/tools.md")
    return problems


def main():
    pages = [ROOT / "AGENTS.md", ROOT / "README.md", ROOT / "state" / "STATE.md", *sorted((ROOT / "docs").rglob("*.md"))]
    problems = []
    for md in pages:
        for target, frag in links(md):
            where = md.relative_to(ROOT)
            if not target.exists():
                problems.append(f"{where}: broken link to {target}")
            elif frag and target.suffix == ".md":
                heads = {anchor(h) for h in re.findall(r"^#+ (.+)$", target.read_text(encoding="utf-8"), re.M)}
                if frag not in heads:
                    problems.append(f"{where}: no heading #{frag} in {target.relative_to(ROOT)}")
    # Every docs page reachable from HOME, like a vault with no orphans.
    seen, todo = set(), [HOME.resolve()]
    while todo:
        md = todo.pop()
        if md in seen or md.suffix != ".md" or not md.exists():
            continue
        seen.add(md)
        todo += [t for t, _ in links(md)]
    for md in sorted((ROOT / "docs").rglob("*.md")):
        if md.resolve() not in seen:
            problems.append(f"{md.relative_to(ROOT)}: not reachable from docs/HOME.md")
    problems += code_map()
    print("\n".join(problems) or f"docs OK: {len(seen)} pages reachable, every link works, every code file is on a page")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
