"""initial

Revision ID: 1ce0e2077b83
Revises: 
Create Date: 2025-12-08 11:51:07.176480

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql
from pgvector.sqlalchemy import Vector

revision = '1ce0e2077b83'
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    op.create_table('checklist_categories',
    sa.Column('id', sa.BigInteger(), nullable=False),
    sa.Column('title', sa.String(length=200), nullable=False),
    sa.Column('icon', sa.String(length=80), nullable=True),
    sa.Column('order', sa.Integer(), nullable=True),
    sa.PrimaryKeyConstraint('id')
    )
    op.create_table('knowledge_sources',
    sa.Column('id', sa.BigInteger(), nullable=False),
    sa.Column('title', sa.String(length=255), nullable=False),
    sa.Column('source_type', sa.String(length=20), nullable=False),
    sa.Column('file_path', sa.String(length=512), nullable=True),
    sa.Column('url', sa.Text(), nullable=True),
    sa.Column('language', sa.String(length=10), nullable=True),
    sa.Column('created_at', sa.DateTime(), nullable=True),
    sa.PrimaryKeyConstraint('id')
    )
    op.create_table('pathways',
    sa.Column('id', sa.BigInteger(), nullable=False),
    sa.Column('title', sa.String(length=200), nullable=False),
    sa.Column('summary', sa.Text(), nullable=True),
    sa.Column('steps', sa.JSON().with_variant(postgresql.JSONB(astext_type=sa.Text()), 'postgresql'), nullable=False),
    sa.Column('category', sa.String(length=120), nullable=True),
    sa.Column('language', sa.String(length=10), nullable=True),
    sa.Column('tags', sa.ARRAY(sa.String()), nullable=True),
    sa.PrimaryKeyConstraint('id')
    )
    with op.batch_alter_table('pathways', schema=None) as batch_op:
        batch_op.create_index(batch_op.f('ix_pathways_category'), ['category'], unique=False)

    op.create_table('rights',
    sa.Column('id', sa.BigInteger(), nullable=False),
    sa.Column('topic', sa.String(length=200), nullable=False),
    sa.Column('body', sa.Text(), nullable=False),
    sa.Column('category', sa.String(length=120), nullable=True),
    sa.Column('language', sa.String(length=10), nullable=True),
    sa.Column('tags', sa.ARRAY(sa.String()), nullable=True),
    sa.Column('created_at', sa.DateTime(), nullable=True),
    sa.Column('updated_at', sa.DateTime(), nullable=True),
    sa.PrimaryKeyConstraint('id')
    )
    with op.batch_alter_table('rights', schema=None) as batch_op:
        batch_op.create_index(batch_op.f('ix_rights_category'), ['category'], unique=False)
        batch_op.create_index(batch_op.f('ix_rights_topic'), ['topic'], unique=False)

    op.create_table('templates',
    sa.Column('id', sa.BigInteger(), nullable=False),
    sa.Column('title', sa.String(length=200), nullable=False),
    sa.Column('description', sa.Text(), nullable=True),
    sa.Column('body', sa.Text(), nullable=False),
    sa.Column('category', sa.String(length=120), nullable=True),
    sa.Column('language', sa.String(length=10), nullable=True),
    sa.Column('tags', sa.ARRAY(sa.String()), nullable=True),
    sa.Column('created_at', sa.DateTime(), nullable=True),
    sa.Column('updated_at', sa.DateTime(), nullable=True),
    sa.PrimaryKeyConstraint('id')
    )
    with op.batch_alter_table('templates', schema=None) as batch_op:
        batch_op.create_index(batch_op.f('ix_templates_category'), ['category'], unique=False)

    op.create_table('users',
    sa.Column('id', sa.BigInteger(), nullable=False),
    sa.Column('name', sa.String(length=120), nullable=False),
    sa.Column('email', sa.String(length=255), nullable=False),
    sa.Column('phone', sa.String(length=30), nullable=False),
    sa.Column('cnic', sa.String(length=30), nullable=False),
    sa.Column('father_name', sa.String(length=120), nullable=True),
    sa.Column('father_cnic', sa.String(length=30), nullable=True),
    sa.Column('mother_name', sa.String(length=120), nullable=True),
    sa.Column('mother_cnic', sa.String(length=30), nullable=True),
    sa.Column('city', sa.String(length=120), nullable=True),
    sa.Column('gender', sa.String(length=30), nullable=True),
    sa.Column('age', sa.Integer(), nullable=True),
    sa.Column('total_siblings', sa.Integer(), nullable=True),
    sa.Column('brothers', sa.Integer(), nullable=True),
    sa.Column('sisters', sa.Integer(), nullable=True),
    sa.Column('password_hash', sa.String(length=255), nullable=False),
    sa.Column('is_admin', sa.Boolean(), nullable=True),
    sa.Column('is_email_verified', sa.Boolean(), nullable=True),
    sa.Column('avatar_path', sa.String(length=512), nullable=True),
    sa.Column('timezone', sa.String(length=64), nullable=True),
    sa.Column('created_at', sa.DateTime(), nullable=True),
    sa.Column('updated_at', sa.DateTime(), server_default=sa.text('now()'), nullable=True),
    sa.PrimaryKeyConstraint('id')
    )
    with op.batch_alter_table('users', schema=None) as batch_op:
        batch_op.create_index(batch_op.f('ix_users_cnic'), ['cnic'], unique=False)
        batch_op.create_index(batch_op.f('ix_users_email'), ['email'], unique=True)

    op.create_table('activity_events',
    sa.Column('id', sa.BigInteger(), nullable=False),
    sa.Column('user_id', sa.BigInteger(), nullable=True),
    sa.Column('event_type', sa.String(length=30), nullable=False),
    sa.Column('payload', sa.JSON().with_variant(postgresql.JSONB(astext_type=sa.Text()), 'postgresql'), nullable=True),
    sa.Column('created_at', sa.DateTime(), nullable=True),
    sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id')
    )
    with op.batch_alter_table('activity_events', schema=None) as batch_op:
        batch_op.create_index(batch_op.f('ix_activity_events_user_id'), ['user_id'], unique=False)

    op.create_table('bookmarks',
    sa.Column('id', sa.BigInteger(), nullable=False),
    sa.Column('user_id', sa.BigInteger(), nullable=True),
    sa.Column('item_type', sa.String(length=20), nullable=False),
    sa.Column('item_id', sa.BigInteger(), nullable=False),
    sa.Column('created_at', sa.DateTime(), nullable=True),
    sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id')
    )
    with op.batch_alter_table('bookmarks', schema=None) as batch_op:
        batch_op.create_index(batch_op.f('ix_bookmarks_user_id'), ['user_id'], unique=False)

    op.create_table('chat_messages',
    sa.Column('id', sa.BigInteger(), nullable=False),
    sa.Column('user_id', sa.BigInteger(), nullable=True),
    sa.Column('role', sa.String(length=10), nullable=False),
    sa.Column('content', sa.Text(), nullable=False),
    sa.Column('created_at', sa.DateTime(), nullable=True),
    sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id')
    )
    with op.batch_alter_table('chat_messages', schema=None) as batch_op:
        batch_op.create_index(batch_op.f('ix_chat_messages_user_id'), ['user_id'], unique=False)

    op.create_table('checklist_items',
    sa.Column('id', sa.BigInteger(), nullable=False),
    sa.Column('category_id', sa.BigInteger(), nullable=True),
    sa.Column('text', sa.String(length=300), nullable=False),
    sa.Column('required', sa.Boolean(), nullable=True),
    sa.Column('order', sa.Integer(), nullable=True),
    sa.ForeignKeyConstraint(['category_id'], ['checklist_categories.id'], ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id')
    )
    op.create_table('device_tokens',
    sa.Column('id', sa.BigInteger(), nullable=False),
    sa.Column('user_id', sa.BigInteger(), nullable=True),
    sa.Column('platform', sa.String(length=10), nullable=False),
    sa.Column('token', sa.String(length=512), nullable=False),
    sa.Column('created_at', sa.DateTime(), nullable=True),
    sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id'),
    sa.UniqueConstraint('token')
    )
    with op.batch_alter_table('device_tokens', schema=None) as batch_op:
        batch_op.create_index(batch_op.f('ix_device_tokens_user_id'), ['user_id'], unique=False)

    op.create_table('drafts',
    sa.Column('id', sa.BigInteger(), nullable=False),
    sa.Column('user_id', sa.BigInteger(), nullable=True),
    sa.Column('template_id', sa.BigInteger(), nullable=True),
    sa.Column('title', sa.String(length=200), nullable=False),
    sa.Column('content_text', sa.Text(), nullable=False),
    sa.Column('pdf_path', sa.String(length=512), nullable=True),
    sa.Column('docx_path', sa.String(length=512), nullable=True),
    sa.Column('answers', sa.JSON().with_variant(postgresql.JSONB(astext_type=sa.Text()), 'postgresql'), nullable=False),
    sa.Column('user_snapshot', sa.JSON().with_variant(postgresql.JSONB(astext_type=sa.Text()), 'postgresql'), nullable=False),
    sa.Column('created_at', sa.DateTime(), nullable=True),
    sa.ForeignKeyConstraint(['template_id'], ['templates.id'], ),
    sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id')
    )
    with op.batch_alter_table('drafts', schema=None) as batch_op:
        batch_op.create_index(batch_op.f('ix_drafts_template_id'), ['template_id'], unique=False)
        batch_op.create_index(batch_op.f('ix_drafts_user_id'), ['user_id'], unique=False)

    op.create_table('email_verification_tokens',
    sa.Column('id', sa.BigInteger(), nullable=False),
    sa.Column('user_id', sa.BigInteger(), nullable=False),
    sa.Column('token', sa.String(length=512), nullable=False),
    sa.Column('expires_at', sa.DateTime(), nullable=False),
    sa.Column('used', sa.Boolean(), nullable=True),
    sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id')
    )
    with op.batch_alter_table('email_verification_tokens', schema=None) as batch_op:
        batch_op.create_index(batch_op.f('ix_email_verification_tokens_token'), ['token'], unique=True)

    op.create_table('knowledge_chunks',
    sa.Column('id', sa.BigInteger(), nullable=False),
    sa.Column('source_id', sa.BigInteger(), nullable=True),
    sa.Column('chunk_text', sa.Text(), nullable=False),
    sa.Column('embedding', Vector(dim=3072), nullable=True),
    sa.Column('created_at', sa.DateTime(), nullable=True),
    sa.ForeignKeyConstraint(['source_id'], ['knowledge_sources.id'], ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id')
    )
    op.create_table('password_reset_tokens',
    sa.Column('id', sa.BigInteger(), nullable=False),
    sa.Column('user_id', sa.BigInteger(), nullable=False),
    sa.Column('token', sa.String(length=512), nullable=False),
    sa.Column('expires_at', sa.DateTime(), nullable=False),
    sa.Column('used', sa.Boolean(), nullable=True),
    sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id')
    )
    with op.batch_alter_table('password_reset_tokens', schema=None) as batch_op:
        batch_op.create_index(batch_op.f('ix_password_reset_tokens_token'), ['token'], unique=True)

    op.create_table('reminders',
    sa.Column('id', sa.BigInteger(), nullable=False),
    sa.Column('user_id', sa.BigInteger(), nullable=True),
    sa.Column('title', sa.String(length=200), nullable=False),
    sa.Column('notes', sa.Text(), nullable=True),
    sa.Column('scheduled_at', sa.DateTime(), nullable=False),
    sa.Column('timezone', sa.String(length=64), nullable=False),
    sa.Column('is_done', sa.Boolean(), nullable=True),
    sa.Column('created_at', sa.DateTime(), nullable=True),
    sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id')
    )
    with op.batch_alter_table('reminders', schema=None) as batch_op:
        batch_op.create_index(batch_op.f('ix_reminders_user_id'), ['user_id'], unique=False)

    # ### end Alembic commands ###


def downgrade():
    # ### commands auto generated by Alembic - please adjust! ###
    with op.batch_alter_table('reminders', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_reminders_user_id'))

    op.drop_table('reminders')
    with op.batch_alter_table('password_reset_tokens', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_password_reset_tokens_token'))

    op.drop_table('password_reset_tokens')
    op.drop_table('knowledge_chunks')
    with op.batch_alter_table('email_verification_tokens', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_email_verification_tokens_token'))

    op.drop_table('email_verification_tokens')
    with op.batch_alter_table('drafts', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_drafts_user_id'))
        batch_op.drop_index(batch_op.f('ix_drafts_template_id'))

    op.drop_table('drafts')
    with op.batch_alter_table('device_tokens', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_device_tokens_user_id'))

    op.drop_table('device_tokens')
    op.drop_table('checklist_items')
    with op.batch_alter_table('chat_messages', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_chat_messages_user_id'))

    op.drop_table('chat_messages')
    with op.batch_alter_table('bookmarks', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_bookmarks_user_id'))

    op.drop_table('bookmarks')
    with op.batch_alter_table('activity_events', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_activity_events_user_id'))

    op.drop_table('activity_events')
    with op.batch_alter_table('users', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_users_email'))
        batch_op.drop_index(batch_op.f('ix_users_cnic'))

    op.drop_table('users')
    with op.batch_alter_table('templates', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_templates_category'))

    op.drop_table('templates')
    with op.batch_alter_table('rights', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_rights_topic'))
        batch_op.drop_index(batch_op.f('ix_rights_category'))

    op.drop_table('rights')
    with op.batch_alter_table('pathways', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_pathways_category'))

    op.drop_table('pathways')
    op.drop_table('knowledge_sources')
    op.drop_table('checklist_categories')
    # ### end Alembic commands ###
