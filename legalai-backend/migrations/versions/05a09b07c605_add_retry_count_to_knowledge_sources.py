"""add retry_count to knowledge_sources

Revision ID: 2b7c1b5a9f01
Revises: df13417b1381
Create Date: 2025-12-12
"""

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = "2b7c1b5a9f01"
down_revision = "df13417b1381"
branch_labels = None
depends_on = None


def upgrade():
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    columns = {c["name"] for c in inspector.get_columns("knowledge_sources")}

    if "retry_count" not in columns:
        op.add_column(
            "knowledge_sources",
            sa.Column("retry_count", sa.Integer(), nullable=False, server_default="0"),
        )
        op.alter_column("knowledge_sources", "retry_count", server_default=None)


def downgrade():
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    columns = {c["name"] for c in inspector.get_columns("knowledge_sources")}

    if "retry_count" in columns:
        op.drop_column("knowledge_sources", "retry_count")
