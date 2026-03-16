from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from db import get_session
from models import User
from schemas.user import AuthResponse, LoginRequest, UserCreate, UserRead
from security import create_access_token, get_password_hash, verify_password

router = APIRouter()


@router.post("/register", response_model=AuthResponse, status_code=status.HTTP_201_CREATED)
async def register(
    payload: UserCreate,
    session: AsyncSession = Depends(get_session),
) -> AuthResponse:
    """
    Упрощённая регистрация пользователя.

    Полноценная регистрация:
    - проверка уникальности email/phone
    - хэширование пароля
    """
    if payload.email or payload.phone:
        stmt = select(User).where(
            or_(
                User.email == payload.email,
                User.phone == payload.phone,
            )
        )
        result = await session.execute(stmt)
        existing = result.scalar_one_or_none()
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="User with this email or phone already exists",
            )

    user = User(
        name=payload.name,
        email=payload.email,
        phone=payload.phone,
        password_hash=get_password_hash(payload.password),
        is_guest=False,
    )
    session.add(user)
    await session.commit()
    await session.refresh(user)

    token = create_access_token({"sub": user.id})

    return AuthResponse(
        user=UserRead.from_orm(user),
        token=token,
    )


@router.post("/login", response_model=AuthResponse)
async def login(
    payload: LoginRequest,
    session: AsyncSession = Depends(get_session),
) -> AuthResponse:
    """
    Логин по email или телефону + пароль.
    """
    identifier = payload.email_or_phone
    stmt = select(User).where(
        or_(
            User.email == identifier,
            User.phone == identifier,
        )
    )
    result = await session.execute(stmt)
    user = result.scalar_one_or_none()

    if not user or not verify_password(payload.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email/phone or password",
        )

    token = create_access_token({"sub": user.id})

    return AuthResponse(
        user=UserRead.from_orm(user),
        token=token,
    )

