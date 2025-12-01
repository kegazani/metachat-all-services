"""initial archetype tables

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
        'user_archetype_data',
        sa.Column('user_id', sa.String(), nullable=False),
        sa.Column('accumulated_tokens', sa.Integer(), nullable=False),
        sa.Column('aggregated_emotion_vector', postgresql.JSON(astext_type=sa.Text()), nullable=True),
        sa.Column('topic_distribution', postgresql.JSON(astext_type=sa.Text()), nullable=True),
        sa.Column('stylistic_metrics', postgresql.JSON(astext_type=sa.Text()), nullable=True),
        sa.Column('last_updated', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.PrimaryKeyConstraint('user_id')
    )
    
    op.create_table(
        'archetype_calculations',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('user_id', sa.String(), nullable=False),
        sa.Column('archetype', sa.String(), nullable=False),
        sa.Column('archetype_probabilities', postgresql.JSON(astext_type=sa.Text()), nullable=False),
        sa.Column('confidence', sa.Float(), nullable=False),
        sa.Column('model_version', sa.String(), nullable=False),
        sa.Column('tokens_analyzed', sa.Integer(), nullable=False),
        sa.Column('used_data', postgresql.JSON(astext_type=sa.Text()), nullable=True),
        sa.Column('calculated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index('idx_archetype_calc_user_calculated', 'archetype_calculations', ['user_id', 'calculated_at'], unique=False)


def downgrade() -> None:
    op.drop_index('idx_archetype_calc_user_calculated', table_name='archetype_calculations')
    op.drop_table('archetype_calculations')
    op.drop_table('user_archetype_data')

