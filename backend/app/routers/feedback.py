from typing import Optional

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.db import get_session
from app.core.security import get_current_user_optional
from app.crud import feedback as crud_feedback
from app.models import User
from app.schemas.feedback import FeedbackCreate, FeedbackRead

router = APIRouter()


@router.post("", response_model=FeedbackRead, status_code=status.HTTP_201_CREATED)
async def submit_feedback(
    payload: FeedbackCreate,
    session: AsyncSession = Depends(get_session),
    current_user: Optional[User] = Depends(get_current_user_optional),
) -> FeedbackRead:
    """
    Сохраняет сообщение в поддержку.
    Доступно как авторизованным пользователям, так и гостям.
    """
    feedback = await crud_feedback.create_feedback(
        session=session,
        data=payload,
        user_id=current_user.id if current_user else None,
    )
    return FeedbackRead.model_validate(feedback)
