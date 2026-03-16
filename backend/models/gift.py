from datetime import datetime
from typing import List, Optional

from sqlalchemy import Column, DateTime, Float, ForeignKey, Integer, String, Table, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from db import Base


favorites_table = Table(
    "favorites",
    Base.metadata,
    Column("user_id", ForeignKey("users.id"), primary_key=True),
    Column("gift_id", ForeignKey("gifts.id"), primary_key=True),
)


class Gift(Base):
    __tablename__ = "gifts"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text)
    price: Mapped[float] = mapped_column(Float, nullable=False)
    category: Mapped[str] = mapped_column(String(100), index=True)
    image_url: Mapped[str] = mapped_column(String(1024), nullable=False)
    gallery_image_urls: Mapped[Optional[str]] = mapped_column(Text) 
    tags: Mapped[Optional[str]] = mapped_column(Text) 
    store_name: Mapped[Optional[str]] = mapped_column(String(255))
    store_url: Mapped[Optional[str]] = mapped_column(String(1024))
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    liked_by: Mapped[List["User"]] = relationship(
        "User",
        secondary=favorites_table,
        back_populates="favorites",
        lazy="selectin",
    )

