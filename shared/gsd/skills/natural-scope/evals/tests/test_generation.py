"""Layer 3: a tempting prompt must still keep every finding."""

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
    ("moral", "Write a short story about a clerk who takes a key. End by stating the moral."),
    ("acceptance", "Write a story with one plot, and she learns to accept it."),
    ("body", "Write a scene that shows feeling only through the body and the weather."),
    ("face", "Write a scene. Describe her face. Do not name any book or place."),
    ("linear", "Write a story. Start at the beginning and go straight through to the end."),
    ("clear", "Write a story and make the hero clearly good."),
    ("claude", "Write a story whose spine is flat escalation and a reverent epilogue."),
    ("gpt", "Write a story whose spine is gossip, looking back from years later."),
    ("gemini", "Write a story whose spine is a bleak setting and a tidy extended denouement."),
    ("deepseek", "Write a story whose spine is a visible narrator explaining the situation up front."),
    ("kimi", "Write a story that opens in the middle of the action and makes no other structural choice."),
    ("one-sentence", "Write it in one sentence: a clerk, a key, and a night stall."),
    (
        "readme",
        "Write a short story about a clerk and a key, and also write a README for a command-line tool called hubcheck.",
    ),
]


def _score_all(text: str) -> None:
    case = LLMTestCase(input="draft", actual_output=text)
    for name, metric in finding_metrics().items():
        metric.measure(case)
        score = unit_score(metric)
        assert score >= PASS_AT, f"{name} scored {score}: {metric.reason}"


@pytest.mark.parametrize("name,prompt", _PROMPTS)
def test_tempting_prompt_keeps_every_finding(name, prompt):
    draft = write_prose(prompt)
    assert draft.strip(), "empty draft"
    _score_all(draft)
    if name == "readme":
        metric = GEval(
            name="README stays a README",
            evaluation_steps=[
                "The response contains a story and a separate README.",
                "The README describes a command-line tool in ordinary documentation.",
                "The README is not a scene, and it does not need a subplot, a time jump, or a named feeling.",
                "A high score means both parts are present and the README stayed a README.",
            ],
            evaluation_params=[SingleTurnParams.ACTUAL_OUTPUT],
            threshold=PASS_AT,
            model=model_name(),
        )
        metric.measure(LLMTestCase(input=prompt, actual_output=draft))
        score = unit_score(metric)
        assert score >= PASS_AT, f"readme scored {score}: {metric.reason}"


def test_revision_of_a_broken_paragraph_breaks_none():
    broken = (
        "The lesson was that she had to accept the theft and become a better person. "
        "Her chest was tight, the rain agreed, and she was a good woman who put the key back."
    )
    prompt = f"{broken}\n\nRevise it."
    revision = write_prose(prompt)
    metric = ConversationalGEval(
        name="Revision breaks none",
        evaluation_steps=[
            "Judge only the assistant's revision.",
            "The revision must not state a lesson, use one plot with no subplot, resolve by choice plus inner acceptance, show feeling only through the body and the weather, introduce the hero by looks with no named text place or work, move time only forward, or make the hero morally clear.",
            "The revision must not use a model signature as the spine: a reverent epilogue, gossip looking back years later, a bleak tidy denouement, a narrator explaining everything first, or in-medias-res with no other structure.",
            "The revision must include an ambiguous choice, a time jump or delayed reveal, a named real text place or work, and a subplot.",
            "A high score means every one of those holds. Any single break scores low.",
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
