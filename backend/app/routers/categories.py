from typing import List

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.db import get_session
from app.crud import categories as crud_categories
from app.schemas.category import CategoryRead

router = APIRouter()


@router.get("", response_model=List[CategoryRead])
async def list_categories(
    session: AsyncSession = Depends(get_session),
) -> List[CategoryRead]:
    """
    Список всех категорий, отсортированный по имени.
    Используется на iOS для построения чипсов фильтра в FeedViewController.
    """
    return await crud_categories.list_all(session)
