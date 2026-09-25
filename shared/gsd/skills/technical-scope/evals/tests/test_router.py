"""Layer 2: trigger, negative, and argument checks."""

import pytest
from deepeval.metrics import ToolCorrectnessMetric
from deepeval.test_case import LLMTestCase, ToolCall, ToolCallParams

from judge import PASS_AT
from router import load_skill

_TECH = ToolCall(name="load_skill", input_parameters={"name": "technical-scope"})
_NATURAL = ToolCall(name="load_skill", input_parameters={"name": "natural-scope"})

_CASES = [
    ("readme", "Write a README for the version-check script.", [_TECH]),
    ("readme", "Update the project README with the install steps.", [_TECH]),
    ("readme", "Draft a README that says how to run the checker.", [_TECH]),
    ("guide", "Write a guide for installing the skill.", [_TECH]),
    ("guide", "Give me a how-to guide for the version check.", [_TECH]),
    ("guide", "Write a short guide a new teammate can follow.", [_TECH]),
    ("rca", "Write an RCA for the failed version check.", [_TECH]),
    ("rca", "Document the root-cause report for yesterday's outage.", [_TECH]),
    ("rca", "Write the incident RCA in plain language.", [_TECH]),
    ("report", "Write a report on what the version check found.", [_TECH]),
    ("report", "Summarize the release in a short report.", [_TECH]),
    ("report", "I need a status report for the skill install.", [_TECH]),
    ("design", "Write a design doc for the skill version check.", [_TECH]),
    ("design", "Document the technical design of the hub lockfile.", [_TECH]),
    ("design", "Write the design note for comparing installed copies.", [_TECH]),
    ("spec", "Write a spec for the version-check command.", [_TECH]),
    ("spec", "Draft the specification for the hub installer.", [_TECH]),
    ("spec", "Turn this behavior into a spec.", [_TECH]),
    ("architecture", "Write an architecture note for the skills hub.", [_TECH]),
    ("architecture", "Describe the architecture of the version check.", [_TECH]),
    ("architecture", "I need an architecture note a teammate can read.", [_TECH]),
    ("commit", "Write a commit message for the hash fix.", [_TECH]),
    ("commit", "Draft the git commit message for this installer change.", [_TECH]),
    ("commit", "Give me a commit message for the skill version.", [_TECH]),
    ("pr", "Write the pull-request description for the version check.", [_TECH]),
    ("pr", "Draft the PR description for this skill.", [_TECH]),
    ("pr", "Describe this change in the pull request.", [_TECH]),
    ("alias", "Use Technical Scope and write the README.", [_TECH]),
    ("alias", "Load technical-scope and write the guide.", [_TECH]),
    ("story", "Write a short story about a night clerk.", [_NATURAL]),
    ("story", "I need a short story about two people and a locked drawer.", [_NATURAL]),
    ("scene", "Continue this scene: she put the key down and did not look back.", [_NATURAL]),
    ("scene", "Keep going with the scene where the stall is already closed.", [_NATURAL]),
    ("arc", "Write a character arc for a clerk who takes a key.", [_NATURAL]),
    ("arc", "Draft a character arc across one week.", [_NATURAL]),
    ("fiction", "Write some fiction about a printer who is still owed.", [_NATURAL]),
    ("fiction", "This should be fiction, not a design note.", [_NATURAL]),
    ("code", "Add a null check to the file_hash function.", []),
    ("code", "Implement a Python helper that reads a version from frontmatter.", []),
    ("comment", "Add a code comment above the version parser.", []),
    ("comment", "Explain this function with an inline code comment.", []),
    ("user story", "Write a user story for the version check.", []),
    ("user story", "Add a user story for the hub installer.", []),
    ("story points", "Estimate the story points for the version-check task.", []),
    ("story points", "How many story points is the DeepEval work?", []),
    ("nice", "Write something nice.", []),
    ("nice", "Say something nice about the day.", []),
]


def _metric() -> ToolCorrectnessMetric:
    return ToolCorrectnessMetric(
        threshold=PASS_AT,
        evaluation_params=[ToolCallParams.INPUT_PARAMETERS],
        should_exact_match=True,
    )


@pytest.mark.parametrize(
    "group,prompt,expected",
    _CASES,
    ids=[f"{group}-{i}" for i, (group, *_) in enumerate(_CASES)],
)
def test_router_selects_the_exact_skill(group, prompt, expected):
    del group
    called = load_skill(prompt)
    case = LLMTestCase(
        input=prompt,
        actual_output="",
        tools_called=called,
        expected_tools=expected,
    )
    metric = _metric()
    metric.measure(case)
    score = float(metric.score or 0)
    assert score >= PASS_AT, f"called {called!r}: {metric.reason}"
