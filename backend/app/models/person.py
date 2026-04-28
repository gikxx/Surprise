from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import DateTime, ForeignKey, Integer, SmallInteger, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.db import Base


class Person(Base):
    """
    Близкий человек пользователя — хранит имя и дату события (день рождения,
    годовщина и т.д.). Год опциональный: пользователь может не знать год
    рождения или просто не хочет его указывать.

    event_type: 'birthday' | 'anniversary' | 'custom'
    """

    __tablename__ = "persons"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)

    user_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    name: Mapped[str] = mapped_column(String(100), nullable=False)

    # День и месяц — обязательные, год — нет
    event_day: Mapped[int] = mapped_column(SmallInteger, nullable=False)
    event_month: Mapped[int] = mapped_column(SmallInteger, nullable=False)
    event_year: Mapped[Optional[int]] = mapped_column(SmallInteger, nullable=True)

    event_type: Mapped[str] = mapped_column(
        String(32), nullable=False, default="birthday"
    )

    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    avatar_url: Mapped[Optional[str]] = mapped_column(String(1024), nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
        default=lambda: datetime.now(timezone.utc),
    )

    user: Mapped["User"] = relationship("User", back_populates="persons")  # noqa: F821
