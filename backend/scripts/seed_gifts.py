import json
from pathlib import Path

from sqlalchemy.ext.asyncio import AsyncSession

from db import Base, engine, get_session
from models.gift import Gift

PROJECT_ROOT = Path(__file__).resolve().parents[2]
IOS_GIFTS_JSON = PROJECT_ROOT / "ios-app" / "SurpriseApp" / "Resources" / "gifts.json"


async def seed_gifts(session: AsyncSession) -> None:
    with IOS_GIFTS_JSON.open("r", encoding="utf-8") as f:
        data = json.load(f)

    gifts_data = data.get("gifts", [])
    categories_data = data.get("categories", [])

    category_names = {cat["id"]: cat["name"] for cat in categories_data}

    for item in gifts_data:
        gift = await session.get(Gift, item["id"])
        if gift is None:
            gift = Gift(id=item["id"])

        gift.name = item["name"]
        gift.description = item.get("description")
        gift.price = item["price"]
        
        category_ids = item.get("categoryIds", [])
        category_names_list = [category_names[cid] for cid in category_ids if cid in category_names]
        gift.categories = ", ".join(category_names_list)
        
        gift.image_url = item["imageURL"]
        gift.gallery_image_urls = None
        gift.store_name = item.get("storeName")
        gift.store_url = item.get("storeURL")

        session.add(gift)

    await session.commit()


async def main() -> None:
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async for session in get_session():
        await seed_gifts(session)
        break


if __name__ == "__main__":
    import asyncio

    asyncio.run(main())