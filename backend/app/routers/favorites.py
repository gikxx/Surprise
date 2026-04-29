from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.db import get_session
from app.core.security import get_current_user
from app.crud import favorites as crud_favorites
from app.crud import gifts as crud_gifts
from app.models import User
from app.schemas.gift import GiftRead

router = APIRouter()


@router.get("", response_model=List[GiftRead])
async def get_favorites(
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> List[GiftRead]:
    """
    Список избранного текущего юзера, отсортированный по дате добавления
    (сначала свежее). Дата берётся из favorites.created_at, не из gifts.created_at.
    """
    return await crud_favorites.get_favorites(session=session, user=current_user)


@router.post("/{gift_id}", response_model=GiftRead, status_code=status.HTTP_201_CREATED)
async def add_favorite(
    gift_id: int,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> GiftRead:
    """Идемпотентный add: если уже в избранном — просто вернёт текущее состояние."""
    gift = await crud_gifts.get_by_id(session, gift_id)
    if gift is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Gift not found")

    await crud_favorites.add(session=session, user=current_user, gift=gift)
    return GiftRead.model_validate(gift, from_attributes=True).model_copy(update={"is_favorite": True})


@router.delete("/{gift_id}", response_model=GiftRead)
async def remove_favorite(
    gift_id: int,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> GiftRead:
    """Идемпотентный remove: если не в избранном — просто вернёт is_favorite=false."""
    gift = await crud_gifts.get_by_id(session, gift_id)
    if gift is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Gift not found")

    await crud_favorites.remove(session=session, user=current_user, gift=gift)
    return GiftRead.model_validate(gift, from_attributes=True).model_copy(update={"is_favorite": False})


@router.post("/{gift_id}/toggle", response_model=GiftRead)
async def toggle_favorite(
    gift_id: int,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> GiftRead:
    """
    Сохранён для обратной совместимости с текущим iOS-кодом
    (FavoritesService использует /favorites/{id}/toggle).
    Внутри — то же самое, что POST + DELETE по состоянию.
    """
    gift = await crud_gifts.get_by_id(session, gift_id)
    if gift is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Gift not found")

    is_favorite = await crud_favorites.toggle(session=session, user=current_user, gift=gift)
    return GiftRead.model_validate(gift, from_attributes=True).model_copy(update={"is_favorite": is_favorite})
