"""add persons table

Таблица для хранения «близких людей» пользователя: дни рождения,
годовщины и другие персональные праздники.

event_day / event_month — обязательные (день + месяц события).
event_year — опциональный (пользователь может не знать год).
event_type — тип события: birthday | anniversary | custom.

Revision ID: 0007
Revises: 0006
Create Date: 2026-05-06
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0007"
down_revision: Union[str, None] = "0006"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "persons",
        sa.Column("id", sa.Integer(), primary_key=True, index=True),
        sa.Column(
            "user_id",
            sa.Integer(),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
            index=True,
        ),
        sa.Column("name", sa.String(length=100), nullable=False),
        sa.Column("event_day", sa.SmallInteger(), nullable=False),
        sa.Column("event_month", sa.SmallInteger(), nullable=False),
        sa.Column("event_year", sa.SmallInteger(), nullable=True),
        sa.Column(
            "event_type",
            sa.String(length=32),
            nullable=False,
            server_default="birthday",
        ),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("avatar_url", sa.String(length=1024), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
    )


def downgrade() -> None:
    op.drop_table("persons")
