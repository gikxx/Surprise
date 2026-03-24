from typing import List, Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy import and_, func, or_, select
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

    base_query = select(Gift).order_by(Gift.created_at.desc())
    total_query = select(func.count(Gift.id))

    return await _paginate_gifts(
        base_query=base_query,
        count_query=total_query,
        page=page,
        per_page=per_page,
        session=session,
    )


@router.get("", response_model=GiftListResponse)
async def list_gifts(
    category: Optional[str] = Query(None, description="Фильтр по категории"),
    min_price: Optional[int] = Query(None, ge=0, description="Минимальная цена"),
    max_price: Optional[int] = Query(None, ge=0, description="Максимальная цена"),
    page: int = 1,
    per_page: int = 20,
    session: AsyncSession = Depends(get_session),
) -> GiftListResponse:
    """
    Список подарков с фильтрами по категории и цене.
    """
    if page < 1:
        page = 1
    if per_page < 1 or per_page > 100:
        per_page = 20

    conditions = []

    if category:
        conditions.append(Gift.categories.ilike(f"%{category}%"))

    if min_price is not None:
        conditions.append(Gift.price >= min_price)
    if max_price is not None:
        conditions.append(Gift.price <= max_price)

    where_clause = and_(*conditions) if conditions else None

    base_query = select(Gift)
    count_query = select(func.count(Gift.id))

    if where_clause is not None:
        base_query = base_query.where(where_clause)
        count_query = count_query.where(where_clause)

    return await _paginate_gifts(
        base_query=base_query.order_by(Gift.created_at.desc()),
        count_query=count_query,
        page=page,
        per_page=per_page,
        session=session,
    )


@router.get("/search", response_model=GiftListResponse)
async def search_gifts(
    q: str = Query(..., min_length=1, description="Поисковый запрос"),
    page: int = 1,
    per_page: int = 20,
    session: AsyncSession = Depends(get_session),
) -> GiftListResponse:
    """
    Поиск подарков по названию, описанию.
    """
    if page < 1:
        page = 1
    if per_page < 1 or per_page > 100:
        per_page = 20

    ilike_pattern = f"%{q}%"

    base_query = select(Gift).where(
        or_(
            Gift.name.ilike(ilike_pattern),
            Gift.description.ilike(ilike_pattern),
        )
    )
    count_query = select(func.count(Gift.id)).where(
        or_(
            Gift.name.ilike(ilike_pattern),
            Gift.description.ilike(ilike_pattern),
        )
    )

    return await _paginate_gifts(
        base_query=base_query.order_by(Gift.created_at.desc()),
        count_query=count_query,
        page=page,
        per_page=per_page,
        session=session,
    )


async def _paginate_gifts(
    base_query,
    count_query,
    page: int,
    per_page: int,
    session: AsyncSession,
) -> GiftListResponse:
    total_result = await session.execute(count_query)
    total = int(total_result.scalar_one())

    result = await session.execute(
        base_query.offset((page - 1) * per_page).limit(per_page)
    )
    gifts_orm: List[Gift] = result.scalars().all()

    gifts = [
        GiftRead.model_validate(gift, from_attributes=True).model_copy(update={"is_favorite": False})
        for gift in gifts_orm
    ]

    return GiftListResponse(
        gifts=gifts,
        total=total,
        page=page,
        per_page=per_page,
    )

