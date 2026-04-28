from datetime import datetime
from typing import Literal, Optional

from pydantic import BaseModel, Field, model_validator

EventType = Literal["birthday", "anniversary", "custom"]


class PersonBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    event_day: int = Field(..., ge=1, le=31)
    event_month: int = Field(..., ge=1, le=12)
    event_year: Optional[int] = Field(None, ge=1900, le=2100)
    event_type: EventType = "birthday"
    notes: Optional[str] = Field(None, max_length=500)
    avatar_url: Optional[str] = Field(None, max_length=1024)

    @model_validator(mode="after")
    def validate_day_month(self) -> "PersonBase":
        """
        Базовая проверка: день должен быть валидным для данного месяца.
        Не учитываем високосные годы (29 февраля пропускаем — это редкий
        день рождения, можно поддержать позже).
        """
        days_in_month = [0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
        if self.event_day > days_in_month[self.event_month]:
            raise ValueError(
                f"Day {self.event_day} is invalid for month {self.event_month}"
            )
        return self


class PersonCreate(PersonBase):
    pass


class PersonUpdate(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    event_day: Optional[int] = Field(None, ge=1, le=31)
    event_month: Optional[int] = Field(None, ge=1, le=12)
    event_year: Optional[int] = Field(None, ge=1900, le=2100)
    event_type: Optional[EventType] = None
    notes: Optional[str] = Field(None, max_length=500)
    avatar_url: Optional[str] = Field(None, max_length=1024)


class PersonRead(PersonBase):
    id: int
    user_id: int
    created_at: datetime

    class Config:
        from_attributes = True
