from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.db import get_session
from app.core.security import get_current_user
from app.models import User
from app.models.person import Person
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
    result = await session.execute(
        select(Person)
        .where(Person.user_id == current_user.id)
        .order_by(Person.event_month, Person.event_day)
    )
    persons = result.scalars().all()
    return [PersonRead.model_validate(p, from_attributes=True) for p in persons]


@router.post("", response_model=PersonRead, status_code=status.HTTP_201_CREATED)
async def create_person(
    payload: PersonCreate,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> PersonRead:
    """Добавить нового близкого человека."""
    person = Person(
        user_id=current_user.id,
        name=payload.name,
        event_day=payload.event_day,
        event_month=payload.event_month,
        event_year=payload.event_year,
        event_type=payload.event_type,
        notes=payload.notes,
        avatar_url=payload.avatar_url,
    )
    session.add(person)
    await session.commit()
    await session.refresh(person)
    return PersonRead.model_validate(person, from_attributes=True)


@router.patch("/{person_id}", response_model=PersonRead)
async def update_person(
    person_id: int,
    payload: PersonUpdate,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> PersonRead:
    """Обновить запись о близком человеке (частичное обновление)."""
    result = await session.execute(
        select(Person).where(
            Person.id == person_id,
            Person.user_id == current_user.id,
        )
    )
    person = result.scalar_one_or_none()
    if person is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Person not found")

    if payload.name is not None:
        person.name = payload.name
    if payload.event_day is not None:
        person.event_day = payload.event_day
    if payload.event_month is not None:
        person.event_month = payload.event_month
    if payload.event_year is not None:
        person.event_year = payload.event_year
    if payload.event_type is not None:
        person.event_type = payload.event_type
    if payload.notes is not None:
        person.notes = payload.notes
    if payload.avatar_url is not None:
        person.avatar_url = payload.avatar_url

    await session.commit()
    await session.refresh(person)
    return PersonRead.model_validate(person, from_attributes=True)


@router.delete("/{person_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_person(
    person_id: int,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> None:
    """Удалить запись о близком человеке."""
    result = await session.execute(
        select(Person).where(
            Person.id == person_id,
            Person.user_id == current_user.id,
        )
    )
    person = result.scalar_one_or_none()
    if person is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Person not found")

    await session.delete(person)
    await session.commit()
