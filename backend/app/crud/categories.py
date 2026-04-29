from typing import List

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.category import Category
from app.schemas.category import CategoryRead


async def list_all(session: AsyncSession) -> List[CategoryRead]:
    stmt = select(Category).order_by(Category.name)
    result = await session.execute(stmt)
    return [CategoryRead.model_validate(c, from_attributes=True) for c in result.scalars().all()]
