from typing import Optional, Sequence

from sqlalchemy import and_, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.category import Category
from app.models.favorite import favorites_table
from app.models.gift import Gift
from app.schemas.gift import GiftListResponse, GiftRead


def _normalize_pagination(page: int, per_page: int) -> tuple[int, int]:
    if page < 1:
        page = 1
    if per_page < 1 or per_page > 100:
        per_page = 20
    return page, per_page


async def fetch_favorite_ids(
    session: AsyncSession,
    user,
    gift_ids: Sequence[int],
) -> set[int]:
    """
    Возвращает подмножество gift_ids, лежащих в favorites текущего юзера.
    Если юзер не залогинен или список пуст — пустой set, без обращения в БД.
    """
    if user is None or not gift_ids:
        return set()
    stmt = select(favorites_table.c.gift_id).where(
        favorites_table.c.user_id == user.id,
        favorites_table.c.gift_id.in_(gift_ids),
    )
    result = await session.execute(stmt)
    return set(result.scalars().all())


async def _paginate(
    session: AsyncSession,
    base_query,
    count_query,
    page: int,
    per_page: int,
    current_user,
) -> GiftListResponse:
    total_result = await session.execute(count_query)
    total = int(total_result.scalar_one())

    result = await session.execute(
        base_query.offset((page - 1) * per_page).limit(per_page)
    )
    gifts_orm: list[Gift] = list(result.scalars().all())

    favorite_ids = await fetch_favorite_ids(session, current_user, [g.id for g in gifts_orm])

    gifts = [
        GiftRead.model_validate(gift, from_attributes=True).model_copy(
            update={"is_favorite": gift.id in favorite_ids}
        )
        for gift in gifts_orm
    ]
    return GiftListResponse(gifts=gifts, total=total, page=page, per_page=per_page)


async def get_by_id(session: AsyncSession, gift_id: int) -> Gift | None:
    return await session.get(Gift, gift_id)


async def get_recommended(
    session: AsyncSession,
    page: int,
    per_page: int,
    current_user=None,
) -> GiftListResponse:
    page, per_page = _normalize_pagination(page, per_page)
    base_query = select(Gift).order_by(Gift.created_at.desc())
    count_query = select(func.count(Gift.id))
    return await _paginate(session, base_query, count_query, page, per_page, current_user)


async def list_gifts(
    session: AsyncSession,
    page: int,
    per_page: int,
    category_id: Optional[int] = None,
    min_price: Optional[int] = None,
    max_price: Optional[int] = None,
    current_user=None,
) -> GiftListResponse:
    page, per_page = _normalize_pagination(page, per_page)

    conditions = []
    if category_id is not None:
        conditions.append(Gift.categories.any(Category.id == category_id))
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

    return await _paginate(
        session,
        base_query.order_by(Gift.created_at.desc()),
        count_query,
        page,
        per_page,
        current_user,
    )


async def search(
    session: AsyncSession,
    q: str,
    page: int,
    per_page: int,
    current_user=None,
) -> GiftListResponse:
    page, per_page = _normalize_pagination(page, per_page)
    ilike_pattern = f"%{q}%"
    where_clause = or_(
        Gift.name.ilike(ilike_pattern),
        Gift.description.ilike(ilike_pattern),
    )
    base_query = select(Gift).where(where_clause).order_by(Gift.created_at.desc())
    count_query = select(func.count(Gift.id)).where(where_clause)
    return await _paginate(session, base_query, count_query, page, per_page, current_user)
