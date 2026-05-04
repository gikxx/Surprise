import XCTest
@testable import SurpriseApp

// MARK: - GiftDTOTests

@MainActor
final class GiftDTOTests: XCTestCase {

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    // MARK: - CategoryReadDTO

    func test_categoryReadDTO_toDomain_mapsId() throws {
        // Arrange
        let json = #"{"id": 5, "name": "Для неё"}"#.data(using: .utf8)!

        // Act
        let dto = try decoder.decode(CategoryReadDTO.self, from: json)
        let category = dto.toDomain()

        // Assert
        XCTAssertEqual(category.id, 5)
    }

    func test_categoryReadDTO_toDomain_mapsName() throws {
        // Arrange
        let json = #"{"id": 1, "name": "Для него"}"#.data(using: .utf8)!

        // Act
        let dto = try decoder.decode(CategoryReadDTO.self, from: json)
        let category = dto.toDomain()

        // Assert
        XCTAssertEqual(category.name, "Для него")
    }

    func test_categoryReadDTO_decodesFromJSON() throws {
        // Arrange
        let json = #"{"id": 99, "name": "Хобби"}"#.data(using: .utf8)!

        // Act & Assert — просто не должно бросать ошибку
        XCTAssertNoThrow(try decoder.decode(CategoryReadDTO.self, from: json))
    }

    // MARK: - GiftImageDTO

    func test_giftImageDTO_toDomain_mapsUrl() throws {
        // Arrange
        let json = #"{"url": "https://example.com/img.jpg", "sort_order": 0, "is_primary": true}"#
            .data(using: .utf8)!

        // Act
        let dto = try decoder.decode(GiftImageDTO.self, from: json)
        let image = dto.toDomain()

        // Assert
        XCTAssertEqual(image.url, "https://example.com/img.jpg")
    }

    func test_giftImageDTO_toDomain_mapsSortOrder() throws {
        // Arrange
        let json = #"{"url": "https://img.com/a.jpg", "sort_order": 3, "is_primary": false}"#
            .data(using: .utf8)!

        // Act
        let dto = try decoder.decode(GiftImageDTO.self, from: json)
        let image = dto.toDomain()

        // Assert
        XCTAssertEqual(image.sortOrder, 3)
    }

    func test_giftImageDTO_toDomain_mapsIsPrimary() throws {
        // Arrange
        let json = #"{"url": "https://img.com/b.jpg", "sort_order": 0, "is_primary": true}"#
            .data(using: .utf8)!

        // Act
        let dto = try decoder.decode(GiftImageDTO.self, from: json)
        let image = dto.toDomain()

        // Assert
        XCTAssertTrue(image.isPrimary)
    }

    func test_giftImageDTO_toDomain_isPrimaryFalse() throws {
        // Arrange
        let json = #"{"url": "https://img.com/c.jpg", "sort_order": 1, "is_primary": false}"#
            .data(using: .utf8)!

        // Act
        let dto = try decoder.decode(GiftImageDTO.self, from: json)
        let image = dto.toDomain()

        // Assert
        XCTAssertFalse(image.isPrimary)
    }

    // MARK: - GiftReadDTO

    private func makeGiftJSON(
        id: Int = 1,
        name: String = "Подарок",
        description: String? = nil,
        price: Int = 1000,
        imageURL: String = "https://img.com/gift.jpg",
        storeName: String? = nil,
        storeURL: String? = nil,
        isFavorite: Bool = false,
        categories: String = "[]",
        images: String = "[]",
        createdAt: String = "2024-01-15T12:00:00Z"
    ) -> Data {
        let descField   = description.map { #""description": "\#($0)","# } ?? #""description": null,"#
        let storeNField = storeName.map   { #""store_name": "\#($0)","# } ?? #""store_name": null,"#
        let storeUField = storeURL.map    { #""store_url": "\#($0)","#  } ?? #""store_url": null,"#
        let raw = """
        {
            "id": \(id),
            "name": "\(name)",
            \(descField)
            "price": \(price),
            "image_url": "\(imageURL)",
            \(storeNField)
            \(storeUField)
            "created_at": "\(createdAt)",
            "is_favorite": \(isFavorite),
            "categories": \(categories),
            "images": \(images)
        }
        """
        return raw.data(using: .utf8)!
    }

    func test_giftReadDTO_toDomain_mapsId() throws {
        // Arrange
        let data = makeGiftJSON(id: 42)

        // Act
        let dto = try decoder.decode(GiftReadDTO.self, from: data)
        let gift = dto.toDomain()

        // Assert
        XCTAssertEqual(gift.id, 42)
    }

    func test_giftReadDTO_toDomain_mapsName() throws {
        // Arrange
        let data = makeGiftJSON(name: "Умные часы")

        // Act
        let gift = try decoder.decode(GiftReadDTO.self, from: data).toDomain()

        // Assert
        XCTAssertEqual(gift.name, "Умные часы")
    }

    func test_giftReadDTO_toDomain_mapsPrice() throws {
        // Arrange
        let data = makeGiftJSON(price: 9990)

        // Act
        let gift = try decoder.decode(GiftReadDTO.self, from: data).toDomain()

        // Assert
        XCTAssertEqual(gift.price, 9990)
    }

    func test_giftReadDTO_toDomain_mapsDescription() throws {
        // Arrange
        let data = makeGiftJSON(description: "Отличный подарок")

        // Act
        let gift = try decoder.decode(GiftReadDTO.self, from: data).toDomain()

        // Assert
        XCTAssertEqual(gift.description, "Отличный подарок")
    }

    func test_giftReadDTO_toDomain_nilDescriptionIsNil() throws {
        // Arrange
        let data = makeGiftJSON(description: nil)

        // Act
        let gift = try decoder.decode(GiftReadDTO.self, from: data).toDomain()

        // Assert
        XCTAssertNil(gift.description)
    }

    func test_giftReadDTO_toDomain_mapsStoreName() throws {
        // Arrange
        let data = makeGiftJSON(storeName: "Wildberries")

        // Act
        let gift = try decoder.decode(GiftReadDTO.self, from: data).toDomain()

        // Assert
        XCTAssertEqual(gift.storeName, "Wildberries")
    }

    func test_giftReadDTO_toDomain_mapsStoreURL() throws {
        // Arrange
        let data = makeGiftJSON(storeURL: "https://wb.ru/item/123")

        // Act
        let gift = try decoder.decode(GiftReadDTO.self, from: data).toDomain()

        // Assert
        XCTAssertEqual(gift.storeURL, "https://wb.ru/item/123")
    }

    func test_giftReadDTO_toDomain_mapsIsFavoriteTrue() throws {
        // Arrange
        let data = makeGiftJSON(isFavorite: true)

        // Act
        let gift = try decoder.decode(GiftReadDTO.self, from: data).toDomain()

        // Assert
        XCTAssertTrue(gift.isFavorite)
    }

    func test_giftReadDTO_toDomain_mapsIsFavoriteFalse() throws {
        // Arrange
        let data = makeGiftJSON(isFavorite: false)

        // Act
        let gift = try decoder.decode(GiftReadDTO.self, from: data).toDomain()

        // Assert
        XCTAssertFalse(gift.isFavorite)
    }

    func test_giftReadDTO_toDomain_mapsCategories() throws {
        // Arrange
        let categoriesJSON = #"[{"id": 1, "name": "Для неё"}, {"id": 2, "name": "Для него"}]"#
        let data = makeGiftJSON(categories: categoriesJSON)

        // Act
        let gift = try decoder.decode(GiftReadDTO.self, from: data).toDomain()

        // Assert
        XCTAssertEqual(gift.categories.count, 2)
        XCTAssertEqual(gift.categories.first?.name, "Для неё")
    }

    func test_giftReadDTO_toDomain_emptyCategories_returnsEmptyArray() throws {
        // Arrange
        let data = makeGiftJSON(categories: "[]")

        // Act
        let gift = try decoder.decode(GiftReadDTO.self, from: data).toDomain()

        // Assert
        XCTAssertTrue(gift.categories.isEmpty)
    }

    func test_giftReadDTO_toDomain_mapsImages() throws {
        // Arrange
        let imagesJSON = #"[{"url": "https://img.com/1.jpg", "sort_order": 0, "is_primary": true}]"#
        let data = makeGiftJSON(images: imagesJSON)

        // Act
        let gift = try decoder.decode(GiftReadDTO.self, from: data).toDomain()

        // Assert
        XCTAssertEqual(gift.images.count, 1)
        XCTAssertEqual(gift.images.first?.url, "https://img.com/1.jpg")
    }

    func test_giftReadDTO_toDomain_nilImages_returnsEmptyArray() throws {
        // Arrange — images: null
        let raw = """
        {
            "id": 1, "name": "Test", "description": null, "price": 100,
            "image_url": "https://img.com/x.jpg",
            "store_name": null, "store_url": null,
            "created_at": "2024-01-01T00:00:00Z",
            "is_favorite": false,
            "categories": [],
            "images": null
        }
        """.data(using: .utf8)!

        // Act
        let gift = try decoder.decode(GiftReadDTO.self, from: raw).toDomain()

        // Assert
        XCTAssertTrue(gift.images.isEmpty)
    }

    // MARK: - imageType mapping

    func test_giftReadDTO_toDomain_imageTypePhoto() throws {
        // Arrange — API возвращает "photo"
        let raw = makeGiftJSON() // image_type не передаём → nil → дефолт .photo

        // Act
        let gift = try decoder.decode(GiftReadDTO.self, from: raw).toDomain()

        // Assert
        XCTAssertEqual(gift.imageType, .photo)
    }

    func test_giftReadDTO_toDomain_imageTypeTransparent() throws {
        // Arrange — API возвращает "transparent"
        let baseJSON = makeGiftJSON()
        var obj = try JSONSerialization.jsonObject(with: baseJSON) as! [String: Any]
        obj["image_type"] = "transparent"
        let data = try JSONSerialization.data(withJSONObject: obj)

        // Act
        let gift = try decoder.decode(GiftReadDTO.self, from: data).toDomain()

        // Assert
        XCTAssertEqual(gift.imageType, .transparent)
    }

    func test_giftReadDTO_toDomain_unknownImageType_defaultsToPhoto() throws {
        // Arrange — API вернул неизвестное значение (forward-compat)
        let baseJSON = makeGiftJSON()
        var obj = try JSONSerialization.jsonObject(with: baseJSON) as! [String: Any]
        obj["image_type"] = "video"
        let data = try JSONSerialization.data(withJSONObject: obj)

        // Act
        let gift = try decoder.decode(GiftReadDTO.self, from: data).toDomain()

        // Assert
        XCTAssertEqual(gift.imageType, .photo)
    }

    // MARK: - GiftListResponseDTO

    func test_giftListResponseDTO_decodesCorrectly() throws {
        // Arrange
        let raw = """
        {
            "gifts": [],
            "total": 42,
            "page": 1,
            "per_page": 20
        }
        """.data(using: .utf8)!

        // Act
        let dto = try decoder.decode(GiftListResponseDTO.self, from: raw)

        // Assert
        XCTAssertEqual(dto.total, 42)
        XCTAssertEqual(dto.page, 1)
        XCTAssertEqual(dto.perPage, 20)
        XCTAssertTrue(dto.gifts.isEmpty)
    }

    func test_giftListResponseDTO_withGifts_decodesGiftsArray() throws {
        // Arrange
        let giftJSON = """
        {
            "id": 7, "name": "Книга", "description": null, "price": 500,
            "image_url": "https://img.com/book.jpg",
            "store_name": null, "store_url": null,
            "created_at": "2024-03-01T10:00:00Z",
            "is_favorite": false,
            "categories": [],
            "images": []
        }
        """
        let raw = """
        {"gifts": [\(giftJSON)], "total": 1, "page": 1, "per_page": 20}
        """.data(using: .utf8)!

        // Act
        let dto = try decoder.decode(GiftListResponseDTO.self, from: raw)

        // Assert
        XCTAssertEqual(dto.gifts.count, 1)
        XCTAssertEqual(dto.gifts.first?.id, 7)
        XCTAssertEqual(dto.gifts.first?.name, "Книга")
    }
}
