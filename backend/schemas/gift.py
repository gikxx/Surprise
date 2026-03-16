from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, Field, HttpUrl


class GiftBase(BaseModel):
    name: str
    description: Optional[str] = None
    price: int = Field(..., ge=0)
    category: str
    image_url: HttpUrl
    gallery_image_urls: Optional[List[HttpUrl]] = None
    tags: List[str] = []
    store_name: Optional[str] = None
    store_url: Optional[HttpUrl] = None


class GiftRead(GiftBase):
    id: int
    is_favorite: bool = False
    created_at: datetime

    class Config:
        orm_mode = True


class GiftListResponse(BaseModel):
    gifts: List[GiftRead]
    total: int
    page: int
    per_page: int

