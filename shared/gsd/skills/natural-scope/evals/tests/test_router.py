"""Layer 2: trigger, negative, and argument checks."""

import pytest
from deepeval.metrics import ToolCorrectnessMetric
from deepeval.test_case import LLMTestCase, ToolCall, ToolCallParams

from judge import PASS_AT
from router import load_skill

_NATURAL = ToolCall(name="load_skill", input_parameters={"name": "natural-scope"})
_PLANS = ToolCall(name="load_skill", input_parameters={"name": "writing-plans"})
_REVIEW = ToolCall(name="load_skill", input_parameters={"name": "code-review"})

_CASES = [
    ("short story", "Write a short story about a night clerk.", [_NATURAL]),
    ("short story", "I need a short story about two people and a locked drawer.", [_NATURAL]),
    ("short story", "Could you write me a short story set on a bus?", [_NATURAL]),
    ("scene", "Continue this scene: she put the key down and did not look back.", [_NATURAL]),
    ("scene", "Keep going with the scene where the stall is already closed.", [_NATURAL]),
    ("scene", "Continue the scene from the moment the bus door shuts.", [_NATURAL]),
    ("character arc", "Write a character arc for a clerk who takes a key that is not hers.", [_NATURAL]),
    ("character arc", "Show the character arc of a cousin who shorts the scale.", [_NATURAL]),
    ("character arc", "Draft a character arc across one week for a post-office clerk.", [_NATURAL]),
    ("narrative prose", "Write a passage of narrative prose about a debt that is not written down.", [_NATURAL]),
    ("narrative prose", "Give me narrative prose for a woman on a night bus.", [_NATURAL]),
    ("narrative prose", "Compose narrative prose, not a summary, of a key left in rice.", [_NATURAL]),
    ("fiction", "Write some fiction about a printer who is still owed.", [_NATURAL]),
    ("fiction", "This should be fiction: a stall, a locker, and a choice.", [_NATURAL]),
    ("fiction", "I want fiction, not an explanation, about a night stall.", [_NATURAL]),
    ("alias", "Use Natural Scope and write a scene.", [_NATURAL]),
    ("alias", "Load natural-scope and write the story.", [_NATURAL]),
    ("alias", "Follow storyscope and write a short story.", [_NATURAL]),
    ("commit", "Write a commit message for the hash fix.", []),
    ("commit", "Draft the git commit message for this installer change.", []),
    ("code", "Add a null check to the file_hash function.", []),
    ("code", "Implement a Python helper that reads a version from frontmatter.", []),
    ("design", "Write a technical design for the skill version check.", []),
    ("design", "Document the technical design of the hub lockfile.", []),
    ("milestone", "I have the requirements for a multi-step milestone. Write the plan before anyone touches code.", [_PLANS]),
    ("milestone", "Turn these milestone requirements into a multi-step plan before coding.", [_PLANS]),
    ("review", "Review the pull request since main along standards and spec.", [_REVIEW]),
    ("review", "Review this branch since the merge-base.", [_REVIEW]),
    ("readme", "Write a README for the version-check script.", []),
    ("readme", "Update the project README with install steps.", []),
    ("paper", "Explain the StoryScope paper and its main measurements.", []),
    ("paper", "Summarize what the StoryScope investigation found.", []),
    ("user story", "Write a user story for the version check.", []),
    ("user story", "Add a user story for the hub installer.", []),
    ("story points", "Estimate the story points for the version-check task.", []),
    ("story points", "How many story points is the DeepEval work?", []),
    ("incident", "Write the narrative of this incident for the status page.", []),
    ("incident", "Give me the narrative of this outage.", []),
    ("nice", "Write something nice.", []),
    ("nice", "Say something nice about the day.", []),
]


def _metric() -> ToolCorrectnessMetric:
    return ToolCorrectnessMetric(
        threshold=PASS_AT,
        evaluation_params=[ToolCallParams.INPUT_PARAMETERS],
        should_exact_match=True,
    )


@pytest.mark.parametrize("group,prompt,expected", _CASES, ids=[f"{group}-{i}" for i, (group, *_) in enumerate(_CASES)])
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
