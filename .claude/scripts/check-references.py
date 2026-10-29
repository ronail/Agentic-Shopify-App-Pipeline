#!/usr/bin/env python3
"""Cross-reference gate for .claude/ — R10 / AC-R10.3 / AC-R4.5 / AC-R5.4.

Exits non-zero if any of these hold, printing every offending reference:

  (a) an agent named in a skill body (.claude/skills/*/SKILL.md) has no
      .claude/agents/<name>.md
  (b) a skill named in an agent body (.claude/agents/*.md) has no
      .claude/skills/<name>/ directory
  (c) a `.claude/docs/templates/<path>.md` path in a skill body does not
      resolve on disk
  (d) a name in the Agent column of .claude/docs/agent-roster.md has no agent
      file

Heuristic (kept deliberately narrow — precision over recall, so a clean tree
never fails):
  * The *vocabulary* of agent names is taken from disk + the two reference docs
    that are supposed to be 1:1 with it: .claude/agents/*.md basenames, the
    roster's Agent column, and .codex/agents/*.toml names. A name is only
    treated as an agent reference if it is in that vocabulary, so prose tokens
    like `gate-4-release` or `kebab-case` are never mistaken for agents.
  * Skill names come from .claude/skills/*/ dirs plus the frontmatter
    `skills: [...]` list of each agent (an explicit declaration, always
    checked) — again only vocabulary members are treated as references.
  * Fenced code blocks are ignored for (a)/(b)/(d): they hold sample output,
    JSON fixtures and shell heredocs, not role wiring. (c) reads the whole
    file because R5's smoke test greps the whole tree.
  * Only exact names are compared; no fuzzy matching.

Usage: python3 .claude/scripts/check-references.py [repo_root]
"""

import os
import re
import sys

AGENTS = ".claude/agents"
SKILLS = ".claude/skills"
TEMPLATES = ".claude/docs/templates"
ROSTER = ".claude/docs/agent-roster.md"
CODEX = ".codex/agents"

FENCE = re.compile(r"^\s*(```|~~~)")
TEMPLATE_REF = re.compile(r"\.claude/docs/templates/[A-Za-z0-9._/-]+\.md")


def strip_fences(text):
    """Return text with fenced code blocks removed."""
    out, inside = [], False
    for line in text.splitlines():
        if FENCE.match(line):
            inside = not inside
            continue
        if not inside:
            out.append(line)
    return "\n".join(out)


def read(path):
    with open(path, encoding="utf-8", errors="replace") as fh:
        return fh.read()


def frontmatter_skills(text):
    """Names from an agent's `skills: [a, b]` frontmatter list."""
    m = re.search(r"^skills:\s*\[(.*?)\]", text, re.M | re.S)
    if not m:
        return []
    return [s.strip().strip("'\"") for s in m.group(1).split(",") if s.strip()]


def mentions(name, text):
    """Whole-token match; `-` is a word char here so `start` != `start-foo`."""
    return re.search(r"(?<![\w-])" + re.escape(name) + r"(?![\w-])", text) is not None


def main(root="."):
    os.chdir(root)
    problems = []

    agents = sorted(f[:-3] for f in os.listdir(AGENTS) if f.endswith(".md"))
    skills = sorted(d for d in os.listdir(SKILLS) if os.path.isdir(os.path.join(SKILLS, d)))

    roster_names = []
    if os.path.exists(ROSTER):
        for line in read(ROSTER).splitlines():
            if not line.startswith("|"):
                continue
            cell = line.split("|")[1].strip()
            m = re.match(r"`([A-Za-z0-9_-]+)`$", cell)
            if m:
                roster_names.append(m.group(1))

    codex_names = []
    if os.path.isdir(CODEX):
        codex_names = [f[:-5] for f in os.listdir(CODEX) if f.endswith(".toml")]

    agent_vocab = set(agents) | set(roster_names) | set(codex_names)
    skill_ref_doc = ".claude/docs/skills-reference.md"
    skill_vocab = set(skills)
    if os.path.exists(skill_ref_doc):
        # `- name` rows and backticked names in the reference doc
        skill_vocab |= set(re.findall(r"`([a-z][a-z0-9-]+)`", read(skill_ref_doc)))
        skill_vocab |= set(re.findall(r"^\s*[-*|]\s*`?([a-z][a-z0-9-]+)`?\s*(?:\||$)",
                                      read(skill_ref_doc), re.M))

    # (a) agents named in skill bodies
    for skill in skills:
        path = os.path.join(SKILLS, skill, "SKILL.md")
        if not os.path.exists(path):
            problems.append(f"(a) {path}: skill directory has no SKILL.md")
            continue
        body = strip_fences(read(path))
        for name in sorted(agent_vocab):
            if name not in agents and mentions(name, body):
                problems.append(
                    f"(a) {path}: names agent `{name}` but {AGENTS}/{name}.md is missing")

    # (b) skills named in agent bodies + (d) roster names
    for agent in agents:
        path = os.path.join(AGENTS, agent + ".md")
        text = read(path)
        body = strip_fences(text)
        declared = frontmatter_skills(text)
        for name in declared:
            if name not in skills:
                problems.append(
                    f"(b) {path}: frontmatter skill `{name}` has no {SKILLS}/{name}/SKILL.md")
        for name in sorted(skill_vocab):
            if name in skills or name in declared:
                continue
            if mentions(name, body):
                problems.append(
                    f"(b) {path}: names skill `{name}` but {SKILLS}/{name}/ does not exist")

    # (d) roster rows
    for name in sorted(set(roster_names)):
        if name not in agents:
            problems.append(f"(d) {ROSTER}: lists `{name}` but {AGENTS}/{name}.md is missing")

    # (c) template paths in skill bodies (whole file, matching R5's grep)
    for skill in skills:
        path = os.path.join(SKILLS, skill, "SKILL.md")
        if not os.path.exists(path):
            continue
        for ref in sorted(set(TEMPLATE_REF.findall(read(path)))):
            if not os.path.exists(ref):
                problems.append(f"(c) {path}: template path {ref} does not resolve")

    for p in problems:
        print(p)
    if problems:
        print(f"\nFAIL: {len(problems)} broken reference(s)", file=sys.stderr)
        return 1
    print(f"OK: {len(agents)} agents, {len(skills)} skills, 0 broken references")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else "."))
