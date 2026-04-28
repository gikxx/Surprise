import Foundation

// MARK: - BudgetFilter

/// Диапазон бюджета для фильтрации ленты. Хранит конкретные min/max в рублях.
/// `BudgetFilter.any` — сброшенный (неактивный) фильтр.
struct BudgetFilter: Equatable {

    // MARK: - Constants

    /// Максимум ползунка. Подарки дороже этой суммы попадают в «>50К»
    static let sliderMax: Int = 50_000

    // MARK: - Values

    let minPrice: Int
    /// maxPrice == sliderMax означает «без верхней границы»
    let maxPrice: Int

    // MARK: - Presets

    static let any = BudgetFilter(minPrice: 0, maxPrice: sliderMax)

    // MARK: - State

    var isActive: Bool { self != .any }

    // MARK: - Display

    /// Короткий лейбл для чипса в ленте (когда фильтр активен)
    var chipLabel: String {
        let lo = minPrice.priceFormatted
        if maxPrice >= Self.sliderMax {
            return minPrice == 0 ? "" : "от \(lo) ₽"
        }
        return "\(lo)–\(maxPrice.priceFormatted) ₽"
    }

    // MARK: - Filtering

    func apply(to gifts: [Gift]) -> [Gift] {
        guard isActive else { return gifts }
        return gifts.filter {
            $0.price >= minPrice &&
            (maxPrice >= Self.sliderMax || $0.price <= maxPrice)
        }
    }
}

// MARK: - Int helper

private extension Int {
    /// «15 000» (с пробелом как разделитель тысяч)
    var priceFormatted: String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.groupingSeparator = "\u{202F}" // narrow no-break space
        fmt.maximumFractionDigits = 0
        return fmt.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
