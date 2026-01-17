"""add token_version to users

Revision ID: 0c2c48c4c6a1
Revises: 98a8328a1324
Create Date: 2025-12-11 00:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


revision = '0c2c48c4c6a1'
down_revision = '98a8328a1324'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column(
        'users',
        sa.Column('token_version', sa.Integer(), nullable=False, server_default='0'),
    )
    op.execute("UPDATE users SET token_version = 0 WHERE token_version IS NULL")
    op.alter_column(
        'users',
        'token_version',
        server_default='0',
        existing_type=sa.Integer(),
        nullable=False,
    )


def downgrade():
    op.drop_column('users', 'token_version')
