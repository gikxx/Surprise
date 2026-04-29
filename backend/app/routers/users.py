from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.db import get_session
from app.core.security import get_current_user
from app.crud import users as crud_users
from app.models import User
from app.schemas.user import UserRead, UserUpdate

router = APIRouter()


@router.get("/me", response_model=UserRead)
async def get_current_user_profile(
    current_user: User = Depends(get_current_user),
) -> UserRead:
    return UserRead.model_validate(current_user, from_attributes=True)


@router.put("/me", response_model=UserRead)
async def update_current_user_profile(
    payload: UserUpdate,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> UserRead:
    if payload.email is not None:
        existing = await crud_users.get_by_email(session, payload.email)
        if existing and existing.id != current_user.id:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Email already exists")
    if payload.phone is not None:
        existing = await crud_users.get_by_phone(session, payload.phone)
        if existing and existing.id != current_user.id:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Phone already exists")

    updated = await crud_users.update(session=session, user=current_user, payload=payload)
    return UserRead.model_validate(updated, from_attributes=True)
