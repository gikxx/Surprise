from typing import List

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.person import Person
from app.schemas.person import PersonCreate, PersonUpdate


async def list_by_user(session: AsyncSession, user_id: int) -> List[Person]:
    result = await session.execute(
        select(Person)
        .where(Person.user_id == user_id)
        .order_by(Person.event_month, Person.event_day)
    )
    return list(result.scalars().all())


async def get_by_id_and_user(
    session: AsyncSession, person_id: int, user_id: int
) -> Person | None:
    result = await session.execute(
        select(Person).where(Person.id == person_id, Person.user_id == user_id)
    )
    return result.scalar_one_or_none()


async def create(session: AsyncSession, user_id: int, payload: PersonCreate) -> Person:
    person = Person(
        user_id=user_id,
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
    return person


async def update(session: AsyncSession, person: Person, payload: PersonUpdate) -> Person:
    for field, value in payload.model_dump(exclude_none=True).items():
        setattr(person, field, value)
    await session.commit()
    await session.refresh(person)
    return person


async def delete(session: AsyncSession, person: Person) -> None:
    await session.delete(person)
    await session.commit()
