from datetime import datetime
from typing import Optional

from pydantic import BaseModel, EmailStr, Field


class UserBase(BaseModel):
    name: str = Field(..., max_length=100)
    email: Optional[EmailStr] = None
    phone: Optional[str] = None


class UserCreate(UserBase):
    password: str = Field(..., min_length=6, max_length=128)


class UserRead(UserBase):
    id: int
    is_guest: bool = False
    created_at: datetime

    class Config:
        orm_mode = True


class AuthResponse(BaseModel):
    user: UserRead
    token: str


class LoginRequest(BaseModel):
    email_or_phone: str
    password: str


class TokenData(BaseModel):
    user_id: int

