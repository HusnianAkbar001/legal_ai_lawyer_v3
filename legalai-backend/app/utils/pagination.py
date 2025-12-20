from math import ceil
from flask import request
from sqlalchemy.orm.query import Query

DEFAULT_PAGE = 1
DEFAULT_PER_PAGE = 20
MAX_PER_PAGE = 100

def get_pagination_params():
    """
    Reads ?page= and ?perPage= from query string.
    Safe clamps perPage to MAX_PER_PAGE.
    """
    try:
        page = int(request.args.get("page", DEFAULT_PAGE))
    except ValueError:
        page = DEFAULT_PAGE

    try:
        per_page = int(request.args.get("perPage", DEFAULT_PER_PAGE))
    except ValueError:
        per_page = DEFAULT_PER_PAGE

    if page < 1:
        page = 1
    if per_page < 1:
        per_page = DEFAULT_PER_PAGE
    if per_page > MAX_PER_PAGE:
        per_page = MAX_PER_PAGE

    return page, per_page

def paginate(query: Query, serializer_fn=lambda x: x):
    """
    Usage:
        page = paginate(Right.query.order_by(...), lambda r: RightSchema().dump(r))
        return jsonify(page)
    """
    page, per_page = get_pagination_params()
    total = query.count()

    items = (query
             .limit(per_page)
             .offset((page - 1) * per_page)
             .all())

    return {
        "items": [serializer_fn(i) for i in items],
        "meta": {
            "page": page,
            "perPage": per_page,
            "total": total,
            "totalPages": ceil(total / per_page) if per_page else 0,
            "hasNext": page * per_page < total,
            "hasPrev": page > 1
        }
    }
