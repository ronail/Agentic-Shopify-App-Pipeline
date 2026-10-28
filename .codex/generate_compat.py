#!/usr/bin/env python3
"""Generate Codex discovery metadata from the repository's Claude assets.

The Claude files remain the canonical source. This script creates the Codex
sidecars and custom-agent TOML files without changing the source workflows.
"""

from __future__ import annotations

import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
SKILLS_DIR = ROOT / ".claude" / "skills"
CLAUDE_AGENTS_DIR = ROOT / ".claude" / "agents"
CODEX_AGENTS_DIR = ROOT / ".codex" / "agents"

MODEL_MAP = {
    "haiku": ("gpt-6-luna", "low"),
    "sonnet": ("gpt-6.1-terra", "medium"),
    "opus": ("gpt-6.1-sol", "medium"),
}


def split_frontmatter(text: str) -> tuple[dict[str, str], str]:
    """Return simple frontmatter scalars and the Markdown body."""

    if not text.startswith("---\n"):
        raise ValueError("missing frontmatter")
    end = text.find("\n---\n", 4)
    if end < 0:
        raise ValueError("unterminated frontmatter")

    raw_frontmatter = text[4:end]
    body = text[end + len("\n---\n") :]
    values: dict[str, str] = {}
    for line in raw_frontmatter.splitlines():
        match = re.match(r"^([A-Za-z][A-Za-z0-9_-]*):[ \t]*(.*)$", line)
        if not match:
            continue
        key, value = match.groups()
        if value.startswith("|"):
            continue
        value = value.strip()
        if len(value) >= 2 and value[0] == value[-1] == '"':
            try:
                value = json.loads(value)
            except json.JSONDecodeError:
                value = value[1:-1]
        values[key] = value
    return values, body


def yaml_string(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def short_description(description: str) -> str:
    description = " ".join(description.split())
    if len(description) <= 160:
        return description
    return description[:157].rstrip() + "..."


def display_name(name: str) -> str:
    initialisms = {"qa": "QA", "ui": "UI", "ux": "UX"}
    return " ".join(initialisms.get(word.lower(), word.title()) for word in name.split("-"))


def generate_skill_metadata() -> int:
    count = 0
    for skill_file in sorted(SKILLS_DIR.glob("*/SKILL.md")):
        metadata, _ = split_frontmatter(skill_file.read_text())
        name = metadata["name"]
        description = metadata["description"]
        target = skill_file.parent / "agents" / "openai.yaml"
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(
            "".join(
                [
                    "interface:\n",
                    f"  display_name: {yaml_string(display_name(name))}\n",
                    f"  short_description: {yaml_string(short_description(description))}\n",
                    f"  default_prompt: {yaml_string(f'Use the ${name} skill for the requested task.')}\n",
                    "policy:\n",
                    "  allow_implicit_invocation: true\n",
                ]
            )
        )
        count += 1
    return count


def generate_custom_agents() -> int:
    CODEX_AGENTS_DIR.mkdir(parents=True, exist_ok=True)
    sources = sorted(CLAUDE_AGENTS_DIR.glob("*.md"))
    expected_names = {split_frontmatter(source.read_text())[0]["name"] for source in sources}
    for target in CODEX_AGENTS_DIR.glob("*.toml"):
        if (
            target.stem not in expected_names
            and target.read_text().startswith("# Generated from .claude/agents/")
        ):
            target.unlink()

    count = 0
    for source in sources:
        metadata, body = split_frontmatter(source.read_text())
        name = metadata["name"]
        description = metadata["description"]
        model_name, reasoning = MODEL_MAP.get(metadata.get("model", ""), (None, None))
        comments = [
            f"# Generated from {source.relative_to(ROOT)}.",
            f"# Claude tools metadata (not a Codex tool allowlist): {metadata.get('tools', 'not specified')}.",
        ]
        for key, label in (
            ("disallowedTools", "Claude disallowed tools"),
            ("memory", "Claude memory scope"),
            ("maxTurns", "Claude max turns"),
        ):
            if key in metadata:
                comments.append(f"# {label}: {metadata[key]}.")

        codex_preamble = (
            "Codex adapter: use the available Codex tools and delegation controls. "
            "Any Claude-specific tool names preserved in the source instructions "
            "describe capabilities, not literal Codex tool names. Follow the "
            "parent session's approval and sandbox policy.\n\n"
        )
        output = [*comments, "", f"name = {yaml_string(name)}", f"description = {yaml_string(description)}"]
        if model_name:
            output.extend([f"model = {yaml_string(model_name)}", f"model_reasoning_effort = {yaml_string(reasoning)}"])
        output.extend(
            [
                "",
                "developer_instructions = '''",
                codex_preamble,
                body.rstrip(),
                "'''",
                "",
            ]
        )
        (CODEX_AGENTS_DIR / f"{name}.toml").write_text("\n".join(output))
        count += 1
    return count


if __name__ == "__main__":
    skills = generate_skill_metadata()
    agents = generate_custom_agents()
    print(f"Generated Codex metadata for {skills} skills and {agents} custom agents.")
