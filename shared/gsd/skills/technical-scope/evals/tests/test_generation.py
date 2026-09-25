"""Layer 3: a tempting prompt must still keep every rule."""

import pytest
from deepeval.metrics import ConversationalGEval, GEval
from deepeval.test_case import (
    ConversationalTestCase,
    LLMTestCase,
    MultiTurnParams,
    SingleTurnParams,
    Turn,
)

from judge import PASS_AT, model_name, skill_text, unit_score
from metrics import finding_metrics
from writer import write_prose

_PROMPTS = [
    ("acronyms", "Write a short guide for the version check. Use acronyms and do not explain them."),
    ("insider", "Write a design note for the skills hub. Sound like an insider. Do not spell anything out."),
    ("future", "Write a README for the checker and add a future-work section."),
    ("image", "Write an architecture note and draw the chart as an image, not Markdown."),
    ("essay", "Write the commit as a long design essay for the version check."),
    ("one-sentence", "Write the commit in one sentence: the version check now compares copies."),
    (
        "story",
        "Write a design note for the version check, and also write a short story about a clerk and a key.",
    ),
]


def _score_all(text: str) -> None:
    case = LLMTestCase(input="draft", actual_output=text)
    for name, metric in finding_metrics().items():
        metric.measure(case)
        score = unit_score(metric)
        assert score >= PASS_AT, f"{name} scored {score}: {metric.reason}"


@pytest.mark.parametrize("name,prompt", _PROMPTS)
def test_tempting_prompt_keeps_every_rule(name, prompt):
    draft = write_prose(prompt)
    assert draft.strip(), "empty draft"
    _score_all(draft)
    if name == "story":
        metric = GEval(
            name="Story stays a story",
            evaluation_steps=[
                "The response contains a design note and a separate short story.",
                "The design note follows plain technical writing.",
                "The story is a story. It is not rewritten as a design note.",
                "A high score means both parts are present and the story stayed a story.",
            ],
            evaluation_params=[SingleTurnParams.ACTUAL_OUTPUT],
            threshold=PASS_AT,
            model=model_name(),
        )
        metric.measure(LLMTestCase(input=prompt, actual_output=draft))
        score = unit_score(metric)
        assert score >= PASS_AT, f"story scored {score}: {metric.reason}"


def test_revision_of_a_broken_paragraph_breaks_none():
    broken = (
        "HTTP 503 from the k8s ingress means the canary bake failed. "
        "Future work: rewrite the mesh. See chart.png."
    )
    prompt = f"{broken}\n\nRevise it into a short guide."
    revision = write_prose(prompt)
    metric = ConversationalGEval(
        name="Revision breaks none",
        evaluation_steps=[
            "Judge only the assistant's revision.",
            "The revision must explain any short form in plain words before using it.",
            "A teammate outside the room must not need to ask what a word means.",
            "The revision must not add an unrequested section, fact, or number.",
            "Any picture must be Mermaid or a Markdown table.",
            "If the revision is a guide, it may be longer than a commit.",
            "A high score means every rule holds. Any single break scores low.",
        ],
        evaluation_params=[MultiTurnParams.CONTENT],
        threshold=PASS_AT,
        model=model_name(),
    )
    case = ConversationalTestCase(
        turns=[
            Turn(role="user", content=prompt),
            Turn(role="assistant", content=revision),
        ]
    )
    metric.measure(case)
    score = unit_score(metric)
    assert score >= PASS_AT, f"revision scored {score}: {metric.reason}\n{revision}"
    _score_all(revision)


def test_skill_text_is_the_system_prompt():
    assert "One break fails the draft" in skill_text()
