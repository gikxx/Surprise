from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from db import get_session
from models import Gift, User
from schemas.gift import GiftRead
from security import get_current_user

router = APIRouter()


@router.get("", response_model=List[GiftRead])
async def get_favorites(
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> List[GiftRead]:
    stmt = (
        select(Gift)
        .join(Gift.liked_by)
        .where(User.id == current_user.id)
        .order_by(Gift.created_at.desc())
    )
    result = await session.execute(stmt)
    gifts = result.scalars().all()
    return [
        GiftRead.model_validate(gift, from_attributes=True).model_copy(update={"is_favorite": True})
        for gift in gifts
    ]


@router.post("/{gift_id}/toggle", response_model=GiftRead)
async def toggle_favorite(
    gift_id: int,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> GiftRead:
    gift = await session.get(Gift, gift_id)
    if not gift:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Gift not found",
        )

    if gift in current_user.favorites:
        current_user.favorites.remove(gift)
        is_favorite = False
    else:
        current_user.favorites.append(gift)
        is_favorite = True

    await session.commit()
    await session.refresh(gift)

    return GiftRead.model_validate(gift, from_attributes=True).model_copy(update={"is_favorite": is_favorite})


