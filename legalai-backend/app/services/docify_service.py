import re
from ..models.content import Template
from ..models.drafts import Draft
from ..extensions import db

PLACEHOLDER_RE = re.compile(r"\{\{(.*?)\}\}")

class DocifyService:
    @staticmethod
    def generate(user, template_id: int, answers: dict, user_snapshot: dict):
        template = Template.query.get_or_404(template_id)

        def repl(match):
            key = match.group(1).strip()
            if key in answers:
                return str(answers[key])
            if key in user_snapshot:
                return str(user_snapshot[key])
            return ""

        filled = PLACEHOLDER_RE.sub(repl, template.body).strip()

        draft = Draft(
            user_id=user.id,
            template_id=template_id,
            title=template.title,
            content_text=filled,
            answers=answers,
            user_snapshot=user_snapshot
        )
        db.session.add(draft); db.session.commit()
        return draft
