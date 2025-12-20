"""add content_hash to knowledge_sources

Revision ID: df13417b1381
Revises: 0c2c48c4c6a1
Create Date: 2025-12-12 07:41:01.018393

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'df13417b1381'
down_revision = '0c2c48c4c6a1'
branch_labels = None
depends_on = None


def upgrade():
    # Safe / idempotent migration: do not fail if the column or index already exist.
    bind = op.get_bind()
    inspector = sa.inspect(bind)

    columns = {c["name"] for c in inspector.get_columns("knowledge_sources")}
    if "content_hash" not in columns:
        op.add_column(
            "knowledge_sources",
            sa.Column("content_hash", sa.String(length=64), nullable=True),
        )

    # Ensure unique index exists (Postgres allows multiple NULLs in a unique index)
    indexes = {idx["name"] for idx in inspector.get_indexes("knowledge_sources")}
    if "uq_knowledge_sources_content_hash" not in indexes:
        op.create_index(
            "uq_knowledge_sources_content_hash",
            "knowledge_sources",
            ["content_hash"],
            unique=True,
        )


def downgrade():
    bind = op.get_bind()
    inspector = sa.inspect(bind)

    indexes = {idx["name"] for idx in inspector.get_indexes("knowledge_sources")}
    if "uq_knowledge_sources_content_hash" in indexes:
        op.drop_index("uq_knowledge_sources_content_hash", table_name="knowledge_sources")

    columns = {c["name"] for c in inspector.get_columns("knowledge_sources")}
    if "content_hash" in columns:
        op.drop_column("knowledge_sources", "content_hash")

