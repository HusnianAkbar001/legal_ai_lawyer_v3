from flask import Blueprint, jsonify
from ._auth_guard import require_auth
from app.models.lawyer import Lawyer
from app.utils.pagination import paginate

bp = Blueprint("lawyers", __name__)

@bp.get("")
@require_auth()
def list_lawyers():
    q = Lawyer.query.filter_by(is_active=True).order_by(Lawyer.created_at.desc())
    return jsonify(
        paginate(
            q,
            lambda l: {
                "id": l.id,
                "name": l.full_name,
                "email": l.email,
                "phone": l.phone,
                "category": l.category,
                "profilePicturePath": l.profile_picture_path,
            },
        )
    )
