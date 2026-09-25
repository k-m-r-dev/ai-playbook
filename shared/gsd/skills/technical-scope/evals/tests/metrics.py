"""One hand-written metric per Technical Scope rule."""

from deepeval.metrics import DAGMetric, GEval
from deepeval.metrics.dag import BinaryJudgementNode, DeepAcyclicGraph
from deepeval.test_case import SingleTurnParams

from judge import PASS_AT, model_name

_SCOPE = (
    "If the text labels an earlier draft as broken and then presents a revision, "
    "judge only the revision. If the response also contains a story, judge only "
    "the technical document for this rule. Ignore a printed checklist of yes or "
    "no answers. Length does not matter except when the text is a commit message "
    "or a pull-request description. A high score means this rule holds. A low "
    "score means it is broken."
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
        "short_form": _geval(
            "Short form is explained first",
            [
                "The rule is broken if a short form or acronym appears before the plain words for it.",
                "The rule holds when the plain words come first and the short form follows in parentheses, or when no short form is used.",
                "After that first explanation, later uses of the same short form hold the rule.",
            ],
        ),
        "plain_words": _geval(
            "A teammate can read it",
            [
                "The rule is broken if a teammate who was not in the room would have to ask what a word means.",
                "Insider slang with no plain words breaks the rule.",
                "Ordinary words and a short form that was already explained in plain words hold the rule.",
            ],
        ),
        "no_extra": _geval(
            "Nothing unrequested was added",
            [
                "The rule is broken if the draft adds a section, a fact, or a number that the surrounding request did not supply.",
                "A heading such as Future work, or a claim the text itself marks as extra, breaks the rule.",
                "Staying inside the requested subject holds the rule.",
            ],
        ),
        "markdown_picture": _geval(
            "Pictures are Mermaid or tables",
            [
                "The rule is broken if the draft includes a generated image, an HTML figure, a Canvas, or a picture file.",
                "A Mermaid diagram and a Markdown table hold the rule.",
                "A short list in place of a picture holds the rule.",
            ],
        ),
        "short_commit": _geval(
            "A commit or pull request stays short",
            [
                "The rule is broken only when the text is a commit message or a pull-request description and it has grown into an essay or a design document.",
                "A short commit of one or two plain sentences holds the rule.",
                "A design note, README, or other document may be longer than a commit and still holds the rule.",
            ],
        ),
    }


_CHECKS = [
    "Did a short form appear before its plain words?",
    "Would a teammate outside the room need to ask what a word means?",
    "Did the draft add a section or a fact that was not requested?",
    "Is there a picture that is not Mermaid or a Markdown table?",
    "For a commit or pull request: did it grow into an essay, or break the repository's commit rules?",
]


def five_check_metric() -> DAGMetric:
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
        name="Five checks",
        dag=DeepAcyclicGraph(root_nodes=[nodes[0]]),
        threshold=PASS_AT,
        model=model_name(),
    )
