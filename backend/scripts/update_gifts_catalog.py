"""Обновление каталога подарков из gifts_fixed.json.

Что делает:
  1. Читает gifts_fixed.json из той же папки (backend/scripts/).
  2. Резолвит категории по имени (не по ID!) — безопасно при любых ID в БД.
  3. Обновляет подарки 1-50: image_url, image_type, category_ids.
  4. Вставляет подарки 51-80 (если ещё не существуют).
  5. Синхронизирует gift_images (обложку) для всех затронутых подарков.

Идемпотентный: можно запускать несколько раз.

Запуск:
  cd backend && .venv/bin/python -m scripts.update_gifts_catalog
"""
import asyncio
import json
from pathlib import Path

from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.db import get_session
from app.models.category import Category
from app.models.gift import Gift
from app.models.gift_image import GiftImage
from app.models.category import gift_categories_table

GIFTS_JSON = Path(__file__).resolve().parent / "gifts_fixed.json"

# JSON category ID → имя категории в БД
# (5 = "23 февраля" и 6 = "14 февраля" удалены из приложения, не маппим)
JSON_CAT_NAMES = {
    1: "для пары",
    2: "для неё",
    3: "для него",
    4: "унисекс",
}


async def resolve_categories(session: AsyncSession) -> dict[int, int]:
    """
    Возвращает map: json_category_id → db_category_id.
    Создаёт категорию в БД, если её ещё нет (на случай первого запуска).
    """
    result: dict[int, int] = {}
    for json_id, name in JSON_CAT_NAMES.items():
        existing = (
            await session.execute(select(Category).where(Category.name == name))
        ).scalar_one_or_none()

        if existing is None:
            existing = Category(name=name)
            session.add(existing)
            await session.flush()
            print(f"  Создана категория: '{name}' → id={existing.id}")
        else:
            print(f"  Категория: '{name}' → id={existing.id}")

        result[json_id] = existing.id

    return result


async def upsert_gift(
    session: AsyncSession,
    item: dict,
    cat_map: dict[int, int],
) -> None:
    gift_id = item["id"]
    gift = await session.get(Gift, gift_id)

    if gift is None:
        gift = Gift(id=gift_id)
        session.add(gift)
        action = "INSERT"
    else:
        action = "UPDATE"

    gift.name = item["name"]
    gift.description = item.get("description") or None
    gift.price = int(item["price"])
    gift.image_url = item["image_url"]
    gift.image_type = item["image_type"]
    gift.store_name = item.get("store_name") or None
    gift.store_url = item.get("store_url") or None

    await session.flush()

    # Пересобираем M2M категории
    await session.execute(
        delete(gift_categories_table).where(
            gift_categories_table.c.gift_id == gift_id
        )
    )
    inserted_cats = []
    for json_cat_id in item.get("category_ids", []):
        db_cat_id = cat_map.get(json_cat_id)
        if db_cat_id is None:
            continue
        await session.execute(
            gift_categories_table.insert().values(
                gift_id=gift_id, category_id=db_cat_id
            )
        )
        inserted_cats.append(db_cat_id)

    # Синхронизируем обложку в gift_images
    primary = (
        await session.execute(
            select(GiftImage).where(
                GiftImage.gift_id == gift_id,
                GiftImage.is_primary.is_(True),
            )
        )
    ).scalar_one_or_none()

    if primary is None:
        primary = GiftImage(
            gift_id=gift_id,
            url=item["image_url"],
            sort_order=0,
            is_primary=True,
        )
        session.add(primary)
    else:
        primary.url = item["image_url"]

    await session.flush()
    print(f"  [{action}] id={gift_id:3d} type={item['image_type']:11s} cats={inserted_cats} — {item['name'][:40]}")


async def main() -> None:
    if not GIFTS_JSON.exists():
        raise FileNotFoundError(
            f"Файл не найден: {GIFTS_JSON}\n"
            "Положите gifts_fixed.json в корень проекта (рядом с backend/)."
        )

    with open(GIFTS_JSON, encoding="utf-8") as f:
        data = json.load(f)

    gifts_data = data["gifts"]
    print(f"Загружено {len(gifts_data)} подарков из {GIFTS_JSON}")

    async for session in get_session():
        async with session.begin():
            print("\n=== Резолвим категории ===")
            cat_map = await resolve_categories(session)

            print(f"\n=== Обновляем/вставляем подарки ===")
            for item in gifts_data:
                await upsert_gift(session, item, cat_map)

        print(f"\n✅ Готово. Обработано {len(gifts_data)} подарков.")


if __name__ == "__main__":
    asyncio.run(main())
