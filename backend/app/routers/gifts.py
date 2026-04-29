from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.db import get_session
from app.core.security import get_current_user_optional
from app.crud import gifts as crud_gifts
from app.models import User
from app.schemas.gift import GiftListResponse, GiftRead

router = APIRouter()


@router.get("/recommended", response_model=GiftListResponse)
async def get_recommended_gifts(
    page: int = 1,
    per_page: int = 20,
    session: AsyncSession = Depends(get_session),
    current_user: Optional[User] = Depends(get_current_user_optional),
) -> GiftListResponse:
    return await crud_gifts.get_recommended(session=session, page=page, per_page=per_page, current_user=current_user)


@router.get("", response_model=GiftListResponse)
async def list_gifts(
    category_id: Optional[int] = Query(None, description="ID категории. Отсутствие параметра = все категории."),
    min_price: Optional[int] = Query(None, ge=0, description="Минимальная цена"),
    max_price: Optional[int] = Query(None, ge=0, description="Максимальная цена"),
    page: int = 1,
    per_page: int = 20,
    session: AsyncSession = Depends(get_session),
    current_user: Optional[User] = Depends(get_current_user_optional),
) -> GiftListResponse:
    return await crud_gifts.list_gifts(
        session=session,
        page=page,
        per_page=per_page,
        category_id=category_id,
        min_price=min_price,
        max_price=max_price,
        current_user=current_user,
    )


@router.get("/search", response_model=GiftListResponse)
async def search_gifts(
    q: str = Query(..., min_length=1, description="Поисковый запрос"),
    page: int = 1,
    per_page: int = 20,
    session: AsyncSession = Depends(get_session),
    current_user: Optional[User] = Depends(get_current_user_optional),
) -> GiftListResponse:
    return await crud_gifts.search(session=session, q=q, page=page, per_page=per_page, current_user=current_user)


@router.get("/{gift_id}", response_model=GiftRead)
async def get_gift(
    gift_id: int,
    session: AsyncSession = Depends(get_session),
    current_user: Optional[User] = Depends(get_current_user_optional),
) -> GiftRead:
    gift = await crud_gifts.get_by_id(session, gift_id)
    if gift is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Gift not found")

    favorite_ids = await crud_gifts.fetch_favorite_ids(session=session, user=current_user, gift_ids=[gift.id])
    return GiftRead.model_validate(gift, from_attributes=True).model_copy(
        update={"is_favorite": gift.id in favorite_ids}
    )
