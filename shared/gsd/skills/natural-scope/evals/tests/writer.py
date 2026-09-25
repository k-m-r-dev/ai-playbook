"""Draft narrative with the playbook skill in the system prompt."""

from openai import OpenAI

from judge import model_name, skill_text


def write_prose(user: str) -> str:
    response = OpenAI().chat.completions.create(
        model=model_name(),
        messages=[
            {"role": "system", "content": skill_text()},
            {"role": "user", "content": user},
        ],
    )
    return response.choices[0].message.content or ""
