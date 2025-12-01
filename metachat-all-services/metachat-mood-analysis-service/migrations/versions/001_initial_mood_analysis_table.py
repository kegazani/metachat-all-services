"""initial mood analysis table

Revision ID: 001
Revises: 
Create Date: 2024-01-01 00:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = '001'
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        'mood_analysis',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('entry_id', sa.String(), nullable=False),
        sa.Column('user_id', sa.String(), nullable=False),
        sa.Column('emotion_vector', postgresql.ARRAY(sa.Float()), nullable=False),
        sa.Column('dominant_emotion', sa.String(), nullable=False),
        sa.Column('valence', sa.Float(), nullable=False),
        sa.Column('arousal', sa.Float(), nullable=False),
        sa.Column('confidence', sa.Float(), nullable=False),
        sa.Column('model_version', sa.String(), nullable=False),
        sa.Column('tokens_count', sa.Integer(), nullable=False),
        sa.Column('detected_topics', postgresql.ARRAY(sa.String()), nullable=True),
        sa.Column('keywords', postgresql.ARRAY(sa.String()), nullable=True),
        sa.Column('analyzed_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index('idx_mood_analysis_user_analyzed', 'mood_analysis', ['user_id', 'analyzed_at'], unique=False)
    op.create_index('idx_mood_analysis_entry', 'mood_analysis', ['entry_id'], unique=False)


def downgrade() -> None:
    op.drop_index('idx_mood_analysis_entry', table_name='mood_analysis')
    op.drop_index('idx_mood_analysis_user_analyzed', table_name='mood_analysis')
    op.drop_table('mood_analysis')

