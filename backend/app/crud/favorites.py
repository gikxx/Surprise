from typing import List

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.favorite import favorites_table
from app.models.gift import Gift
from app.models.user import User
from app.schemas.gift import GiftRead


async def get_favorites(session: AsyncSession, user: User) -> List[GiftRead]:
    stmt = (
        select(Gift)
        .join(favorites_table, favorites_table.c.gift_id == Gift.id)
        .where(favorites_table.c.user_id == user.id)
        .order_by(favorites_table.c.created_at.desc())
    )
    result = await session.execute(stmt)
    gifts = result.scalars().all()
    return [
        GiftRead.model_validate(gift, from_attributes=True).model_copy(update={"is_favorite": True})
        for gift in gifts
    ]


async def add(session: AsyncSession, user: User, gift: Gift) -> None:
    """Идемпотентный add: если уже в избранном — ничего не делает."""
    if gift not in user.favorites:
        user.favorites.append(gift)
        await session.commit()
        await session.refresh(gift)


async def remove(session: AsyncSession, user: User, gift: Gift) -> None:
    """Идемпотентный remove: если не в избранном — ничего не делает."""
    if gift in user.favorites:
        user.favorites.remove(gift)
        await session.commit()
        await session.refresh(gift)


async def toggle(session: AsyncSession, user: User, gift: Gift) -> bool:
    """Переключает состояние избранного. Возвращает True если подарок теперь в избранном."""
    if gift in user.favorites:
        user.favorites.remove(gift)
        is_favorite = False
    else:
        user.favorites.append(gift)
        is_favorite = True
    await session.commit()
    await session.refresh(gift)
    return is_favorite
