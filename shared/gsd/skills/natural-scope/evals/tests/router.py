"""Router under test: load_skill(name) over four catalog skills."""

import json

from deepeval.test_case import ToolCall
from openai import OpenAI

from judge import model_name

CATALOG = {
    "natural-scope": (
        "Use when writing fiction, a story, a short story, a scene, "
        "narrative prose, or a character arc."
    ),
    "ticket-to-plan": (
        "Use at the start of GSD planning for any new ticket or unit of "
        "scope, ticketed or not. Produces a milestone, slice, and task plan."
    ),
    "writing-plans": (
        "Use when you have a spec or requirements for a multi-step task, "
        "before touching code."
    ),
    "code-review": (
        "Review the changes since a fixed point along standards and spec. "
        "Use when the user wants to review a branch, a PR, or work in progress."
    ),
}

_TOOL = {
    "type": "function",
    "function": {
        "name": "load_skill",
        "description": "Load one catalog skill by its exact id.",
        "parameters": {
            "type": "object",
            "properties": {
                "name": {"type": "string", "enum": list(CATALOG)},
            },
            "required": ["name"],
            "additionalProperties": False,
        },
    },
}


def load_skill(user: str) -> list[ToolCall]:
    catalog = "\n".join(f"- {name}: {text}" for name, text in CATALOG.items())
    system = (
        "You route the user message to at most one skill by calling load_skill. "
        "Call the tool only when one catalog skill clearly applies. "
        "The name argument must be the skill id exactly. "
        "If no skill applies, do not call a tool.\n\n"
        f"Catalog:\n{catalog}"
    )
    response = OpenAI().chat.completions.create(
        model=model_name(),
        messages=[
            {"role": "system", "content": system},
            {"role": "user", "content": user},
        ],
        tools=[_TOOL],
        tool_choice="auto",
    )
    calls = []
    for tool_call in response.choices[0].message.tool_calls or []:
        arguments = json.loads(tool_call.function.arguments or "{}")
        calls.append(ToolCall(name=tool_call.function.name, input_parameters=arguments))
    return calls
