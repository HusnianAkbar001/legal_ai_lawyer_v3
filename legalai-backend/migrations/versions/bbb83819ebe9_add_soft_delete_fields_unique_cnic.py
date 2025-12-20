"""add soft delete fields + unique cnic

Revision ID: bbb83819ebe9
Revises: 2b7c1b5a9f01
Create Date: 2025-12-17 12:41:07.352993

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'bbb83819ebe9'
down_revision = '2b7c1b5a9f01'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column("users", sa.Column("is_deleted", sa.Boolean(), nullable=False, server_default=sa.text("false")))
    op.add_column("users", sa.Column("deleted_at", sa.DateTime(), nullable=True))
    op.add_column("users", sa.Column("deleted_by", sa.BigInteger(), nullable=True))

    op.create_index("ix_users_is_deleted", "users", ["is_deleted"])

    # Make CNIC permanently unique (blocks reuse even after soft delete)
    op.create_unique_constraint("uq_users_cnic", "users", ["cnic"])


def downgrade():
    op.drop_constraint("uq_users_cnic", "users", type_="unique")
    op.drop_index("ix_users_is_deleted", table_name="users")

    op.drop_column("users", "deleted_by")
    op.drop_column("users", "deleted_at")
    op.drop_column("users", "is_deleted")
