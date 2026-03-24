from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, Field, HttpUrl, field_validator


class GiftBase(BaseModel):
    name: str
    description: Optional[str] = None
    price: int = Field(..., ge=0)
    categories: List[str] = []
    image_url: HttpUrl
    gallery_image_urls: Optional[List[HttpUrl]] = None
    store_name: Optional[str] = None
    store_url: Optional[HttpUrl] = None


class GiftRead(GiftBase):
    id: int
    is_favorite: bool = False
    created_at: datetime

    @field_validator('categories', mode='before')
    @classmethod
    def parse_categories(cls, v):
        if isinstance(v, str):
            return [cat.strip() for cat in v.split(',')] if v else []
        return v

    class Config:
        orm_mode = True


class GiftListResponse(BaseModel):
    gifts: List[GiftRead]
    total: int
    page: int
    per_page: int

