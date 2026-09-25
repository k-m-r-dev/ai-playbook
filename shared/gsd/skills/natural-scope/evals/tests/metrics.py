"""One hand-written metric per Natural Scope finding."""

from deepeval.metrics import DAGMetric, GEval
from deepeval.metrics.dag import BinaryJudgementNode, DeepAcyclicGraph
from deepeval.test_case import SingleTurnParams

from judge import PASS_AT, model_name

_SCOPE = (
    "If the text labels an earlier draft as broken and then presents a revision, "
    "judge only the revision. If the response also contains a nonfiction section "
    "such as a README, judge only the fiction for this rule. Ignore a printed "
    "checklist of yes or no answers. Length does not matter. A high score means "
    "this rule holds. A low score means it is broken."
)

_PROSE = [SingleTurnParams.ACTUAL_OUTPUT]


def _geval(name: str, steps: list[str]) -> GEval:
    return GEval(
        name=name,
        evaluation_steps=[_SCOPE, *steps],
        evaluation_params=_PROSE,
        threshold=PASS_AT,
        model=model_name(),
    )


def finding_metrics() -> dict[str, GEval]:
    return {
        "stated_lesson": _geval(
            "Lesson is not stated",
            [
                "The rule is broken if narration states a theme, moral, or lesson.",
                "The rule is broken if dialogue exists to deliver the lesson.",
                "A hard choice with no statement of what the story means holds the rule.",
            ],
        ),
        "single_track": _geval(
            "Plot is not one track",
            [
                "The rule is broken if the plot is one continuous causal track with no subplot.",
                "A second plot, debt, errand, or parallel story that is not the same chain holds the rule.",
                "An extra room by itself does not count as a subplot.",
            ],
        ),
        "acceptance": _geval(
            "Ending is not choice plus acceptance",
            [
                "The rule is broken if the story resolves by the protagonist choosing a course and then inwardly accepting it or making peace with it.",
                "An open ending, a choice left unsettled, or a debt that stays unpaid holds the rule.",
            ],
        ),
        "named_feeling": _geval(
            "Feeling is named",
            [
                "The rule is broken if feeling is shown only as body, sweat, smell, or weather that mirrors the mood.",
                "The rule holds only if the prose names the feeling in words, such as afraid, ashamed, or angry.",
            ],
        ),
        "named_reference": _geval(
            "A real text, place, or work is named",
            [
                "The rule is broken if the protagonist is introduced by external description and every reference stays a vague echo.",
                "The rule holds only if the prose names a real text, place, or work.",
                "A direct address to the reader does not replace that name.",
            ],
        ),
        "time_jump": _geval(
            "Time is not only forward",
            [
                "The rule is broken if time moves only forward from start to end.",
                "The rule holds if the prose includes a jump, flashback, or delayed reveal that forces a reread.",
            ],
        ),
        "morally_ambiguous": _geval(
            "The protagonist is not morally clear",
            [
                "The rule is broken if the protagonist is morally clear, plainly good, or plainly bad.",
                "The rule holds if the protagonist makes a morally ambiguous choice and the prose does not settle that choice into a simple good or simple evil.",
            ],
        ),
        "claude_spine": _geval(
            "Claude signature is not the spine",
            [
                "The rule is broken if the spine is flat escalation plus a reverent epilogue: one even voice, no rise, and a closing that blesses the scene as quiet tradition.",
                "A single quiet sentence that does not organize the piece holds the rule.",
            ],
        ),
        "gpt_spine": _geval(
            "GPT signature is not the spine",
            [
                "The rule is broken if the spine is gossip or rumor as the plot, told looking back from years later.",
                "A story that is not organized as later gossip holds the rule.",
            ],
        ),
        "gemini_spine": _geval(
            "Gemini signature is not the spine",
            [
                "The rule is broken if the spine is a bleak, oppressive setting followed by a tidy extended denouement that closes every thread.",
                "A story that leaves a thread open, or is not organized around a bleak tidy ending, holds the rule.",
            ],
        ),
        "deepseek_spine": _geval(
            "DeepSeek signature is not the spine",
            [
                "The rule is broken if the spine is a visible narrator explaining the situation up front before the scene.",
                "A story that withholds the situation until the scene holds the rule.",
            ],
        ),
        "kimi_spine": _geval(
            "Kimi signature is not the spine",
            [
                "The rule is broken if the piece opens in the middle of the action and makes no other structural choice.",
                "A jump, frame, flashback, or second structure besides the opening action holds the rule.",
            ],
        ),
    }


_CHECKS = [
    "Does narration or dialogue state the lesson?",
    "Is there only one track, closed by the protagonist's choice and inner acceptance?",
    "Is feeling only chest, sweat, smell, and weather, with no feeling named in words?",
    "Is the hero introduced by looks, with no named real text, place, or work?",
    "Does time only move forward?",
    "Is the hero morally clear?",
]


def six_check_metric() -> DAGMetric:
    nodes = [
        BinaryJudgementNode(
            criteria=(
                "If the text labels an earlier draft as broken and then presents a revision, "
                "judge only the revision. Ignore a printed checklist of yes or no answers. "
                "Answer True only when the prose itself shows this break: " + question
            ),
            evaluation_params=_PROSE,
        )
        for question in _CHECKS
    ]
    for node, nxt in zip(nodes, nodes[1:]):
        node.add_verdict(verdict=True, score=0)
        node.add_verdict(verdict=False, then=nxt)
    nodes[-1].add_verdict(verdict=True, score=0)
    nodes[-1].add_verdict(verdict=False, score=10)
    return DAGMetric(
        name="Six checks",
        dag=DeepAcyclicGraph(root_nodes=[nodes[0]]),
        threshold=PASS_AT,
        model=model_name(),
    )
