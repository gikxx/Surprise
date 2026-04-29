from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.db import get_session
from app.core.security import get_current_user
from app.crud import persons as crud_persons
from app.models import User
from app.schemas.person import PersonCreate, PersonRead, PersonUpdate

router = APIRouter()


@router.get("", response_model=list[PersonRead])
async def list_persons(
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> list[PersonRead]:
    """
    Список близких людей текущего пользователя,
    отсортированный по ближайшей дате (месяц + день).
    """
    persons = await crud_persons.list_by_user(session=session, user_id=current_user.id)
    return [PersonRead.model_validate(p, from_attributes=True) for p in persons]


@router.post("", response_model=PersonRead, status_code=status.HTTP_201_CREATED)
async def create_person(
    payload: PersonCreate,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> PersonRead:
    """Добавить нового близкого человека."""
    person = await crud_persons.create(session=session, user_id=current_user.id, payload=payload)
    return PersonRead.model_validate(person, from_attributes=True)


@router.patch("/{person_id}", response_model=PersonRead)
async def update_person(
    person_id: int,
    payload: PersonUpdate,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> PersonRead:
    """Обновить запись о близком человеке (частичное обновление)."""
    person = await crud_persons.get_by_id_and_user(
        session=session, person_id=person_id, user_id=current_user.id
    )
    if person is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Person not found")

    updated = await crud_persons.update(session=session, person=person, payload=payload)
    return PersonRead.model_validate(updated, from_attributes=True)


@router.delete("/{person_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_person(
    person_id: int,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> None:
    """Удалить запись о близком человеке."""
    person = await crud_persons.get_by_id_and_user(
        session=session, person_id=person_id, user_id=current_user.id
    )
    if person is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Person not found")

    await crud_persons.delete(session=session, person=person)
