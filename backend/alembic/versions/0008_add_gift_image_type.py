"""add image_type column to gifts

Добавляем тип изображения подарка — нужно для iOS-рендеринга:
  - 'photo'       — цветное фото, занимает всю карточку (fill)
  - 'transparent' — PNG без фона, отображается по центру на белом фоне

DEFAULT 'photo' безопасно: все существующие подарки изначально
имели цветные фото, поэтому визуально ничего не сломается до запуска
скрипта update_gifts.py, который проставит правильные значения.

Revision ID: 0008
Revises: 0007
Create Date: 2026-05-18
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "0008"
down_revision: Union[str, None] = "0007"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "gifts",
        sa.Column(
            "image_type",
            sa.String(length=16),
            nullable=False,
            server_default="photo",
        ),
    )
    op.create_check_constraint(
        "ck_gifts_image_type",
        "gifts",
        "image_type IN ('photo', 'transparent')",
    )


def downgrade() -> None:
    op.drop_constraint("ck_gifts_image_type", "gifts", type_="check")
    op.drop_column("gifts", "image_type")
