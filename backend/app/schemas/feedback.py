from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class FeedbackCreate(BaseModel):
    message: str = Field(..., min_length=1, max_length=2000)
    email: Optional[str] = Field(None, max_length=255)


class FeedbackRead(BaseModel):
    id: int
    message: str
    email: Optional[str]
    user_id: Optional[int]
    created_at: datetime

    model_config = {"from_attributes": True}
