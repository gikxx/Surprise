from typing import List

from fastapi import APIRouter, Depends
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from db import get_session
from models import Gift
from schemas.gift import GiftListResponse, GiftRead

router = APIRouter()


@router.get("/recommended", response_model=GiftListResponse)
async def get_recommended_gifts(
    page: int = 1,
    per_page: int = 20,
    session: AsyncSession = Depends(get_session),
) -> GiftListResponse:
    """
    Возвращает ленту рекомендованных подарков.

    Пока без персонализации: просто последние добавленные подарки.
    """
    if page < 1:
        page = 1
    if per_page < 1 or per_page > 100:
        per_page = 20

    total_stmt = select(func.count(Gift.id))
    total_result = await session.execute(total_stmt)
    total = int(total_result.scalar_one())

    stmt = (
        select(Gift)
        .order_by(Gift.created_at.desc())
        .offset((page - 1) * per_page)
        .limit(per_page)
    )
    result = await session.execute(stmt)
    gifts_orm: List[Gift] = result.scalars().all()

    gifts = [
        GiftRead.from_orm(gift).copy(update={"is_favorite": False})
        for gift in gifts_orm
    ]

    return GiftListResponse(
        gifts=gifts,
        total=total,
        page=page,
        per_page=per_page,
    )

