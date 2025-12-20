from flask_sqlalchemy import SQLAlchemy
from flask_marshmallow import Marshmallow
from flask_migrate import Migrate
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

db = SQLAlchemy()
ma = Marshmallow()
migrate = Migrate()
limiter = Limiter(key_func=get_remote_address)
