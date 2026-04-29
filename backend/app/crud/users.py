from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User
from app.schemas.user import UserUpdate


async def get_by_email(session: AsyncSession, email: str) -> User | None:
    result = await session.execute(select(User).where(User.email == email))
    return result.scalar_one_or_none()


async def get_by_phone(session: AsyncSession, phone: str) -> User | None:
    result = await session.execute(select(User).where(User.phone == phone))
    return result.scalar_one_or_none()


async def get_by_id(session: AsyncSession, user_id: int) -> User | None:
    return await session.get(User, user_id)


async def get_by_email_or_phone(session: AsyncSession, identifier: str) -> User | None:
    result = await session.execute(
        select(User).where(or_(User.email == identifier, User.phone == identifier))
    )
    return result.scalar_one_or_none()


async def create(
    session: AsyncSession,
    *,
    name: str,
    email: str | None,
    phone: str | None,
    password_hash: str,
) -> User:
    user = User(
        name=name,
        email=email,
        phone=phone,
        password_hash=password_hash,
        is_guest=False,
    )
    session.add(user)
    await session.commit()
    await session.refresh(user)
    return user


async def update(session: AsyncSession, user: User, payload: UserUpdate) -> User:
    for field, value in payload.model_dump(exclude_none=True).items():
        setattr(user, field, value)
    await session.commit()
    await session.refresh(user)
    return user


async def delete(session: AsyncSession, user: User) -> None:
    await session.delete(user)
    await session.commit()
