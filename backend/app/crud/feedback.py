from typing import Optional

from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Feedback
from app.schemas.feedback import FeedbackCreate


async def create_feedback(
    session: AsyncSession,
    data: FeedbackCreate,
    user_id: Optional[int] = None,
) -> Feedback:
    feedback = Feedback(
        message=data.message,
        email=data.email,
        user_id=user_id,
    )
    session.add(feedback)
    await session.commit()
    await session.refresh(feedback)
    return feedback
