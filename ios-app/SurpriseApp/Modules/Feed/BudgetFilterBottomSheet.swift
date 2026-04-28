import UIKit

// MARK: - BudgetFilterBottomSheet

/// Боттом-шит с ползунком диапазона бюджета.
///
/// Вызов:
///     let sheet = BudgetFilterBottomSheet(current: viewModel.activeBudgetFilter)
///     sheet.onApply = { [weak self] filter in
///         self?.viewModel.setBudgetFilter(filter)
///     }
///     present(sheet, animated: true)
final class BudgetFilterBottomSheet: UIViewController {

    // MARK: - Callback

    var onApply: ((BudgetFilter) -> Void)?

    // MARK: - State

    private var currentFilter: BudgetFilter
    private let sliderMin = CGFloat(0)
    private let sliderMax = CGFloat(BudgetFilter.sliderMax)

    // MARK: - Views

    private let handleView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.appPrimary.withAlphaComponent(0.2)
        v.layer.cornerRadius = 2.5
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Диапазон бюджета"
        l.font = .helveticaRegular(size: 20)
        l.textColor = .appPrimary
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    /// Лейбл левого предела (минимум)
    private let minLabel: UILabel = {
        let l = UILabel()
        l.font = .helveticaRegular(size: 15)
        l.textColor = .appPrimary
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    /// Лейбл правого предела (максимум)
    private let maxLabel: UILabel = {
        let l = UILabel()
        l.font = .helveticaRegular(size: 15)
        l.textColor = .appPrimary
        l.textAlignment = .right
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var rangeSlider: RangeSliderView = {
        let s = RangeSliderView(
            min: sliderMin,
            max: sliderMax,
            low: CGFloat(currentFilter.minPrice),
            high: CGFloat(currentFilter.maxPrice)
        )
        s.step = 500
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private let applyButton: UIButton = UIButton.createPrimary(title: "применить")

    private let resetButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("сбросить фильтр", for: .normal)
        b.setTitleColor(UIColor.appPrimary.withAlphaComponent(0.5), for: .normal)
        b.titleLabel?.font = .helveticaRegular(size: 15)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    // MARK: - Init

    init(current: BudgetFilter) {
        self.currentFilter = current
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupSheet()
        setupActions()
        updatePriceLabels(
            low: CGFloat(currentFilter.minPrice),
            high: CGFloat(currentFilter.maxPrice)
        )
    }

    // MARK: - Setup

    private func setupSheet() {
        if let sheet = sheetPresentationController {
            if #available(iOS 16.0, *) {
                let compact = UISheetPresentationController.Detent.custom(
                    identifier: .init("budget_slider")
                ) { _ in 320 }
                sheet.detents = [compact]
            } else {
                sheet.detents = [.medium()]
            }
            sheet.prefersGrabberVisible = false
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            sheet.preferredCornerRadius = 24
        }
    }

    private func setupUI() {
        view.backgroundColor = UIColor(hex: "#FAF7F4")

        applyButton.translatesAutoresizingMaskIntoConstraints = false
        resetButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(handleView)
        view.addSubview(titleLabel)
        view.addSubview(minLabel)
        view.addSubview(maxLabel)
        view.addSubview(rangeSlider)
        view.addSubview(applyButton)
        view.addSubview(resetButton)

        NSLayoutConstraint.activate([
            // Handle
            handleView.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            handleView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            handleView.widthAnchor.constraint(equalToConstant: 40),
            handleView.heightAnchor.constraint(equalToConstant: 5),

            // Title
            titleLabel.topAnchor.constraint(equalTo: handleView.bottomAnchor, constant: 22),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),

            // Price labels row
            minLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 28),
            minLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),

            maxLabel.topAnchor.constraint(equalTo: minLabel.topAnchor),
            maxLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            // Slider
            rangeSlider.topAnchor.constraint(equalTo: minLabel.bottomAnchor, constant: 12),
            rangeSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            rangeSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            rangeSlider.heightAnchor.constraint(equalToConstant: 40),

            // Apply button
            applyButton.topAnchor.constraint(equalTo: rangeSlider.bottomAnchor, constant: 28),
            applyButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            applyButton.heightAnchor.constraint(equalToConstant: 50),
            applyButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            applyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            // Reset button
            resetButton.topAnchor.constraint(equalTo: applyButton.bottomAnchor, constant: 12),
            resetButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            resetButton.heightAnchor.constraint(equalToConstant: 36),
        ])
    }

    private func setupActions() {
        rangeSlider.onChanged = { [weak self] low, high in
            self?.updatePriceLabels(low: low, high: high)
        }
        applyButton.addTarget(self, action: #selector(applyTapped), for: .touchUpInside)
        resetButton.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)
    }

    // MARK: - Actions

    @objc private func applyTapped() {
        HapticFeedback.tap()
        let filter = BudgetFilter(
            minPrice: Int(rangeSlider.lowValue),
            maxPrice: Int(rangeSlider.highValue)
        )
        onApply?(filter)
        dismiss(animated: true)
    }

    @objc private func resetTapped() {
        HapticFeedback.selection()
        rangeSlider.setValues(low: sliderMin, high: sliderMax, animated: true)
        updatePriceLabels(low: sliderMin, high: sliderMax)
        onApply?(.any)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.dismiss(animated: true)
        }
    }

    // MARK: - Helpers

    private func updatePriceLabels(low: CGFloat, high: CGFloat) {
        minLabel.text = "от \(Int(low).priceFormatted) ₽"
        if Int(high) >= BudgetFilter.sliderMax {
            maxLabel.text = "до 50 000+ ₽"
        } else {
            maxLabel.text = "до \(Int(high).priceFormatted) ₽"
        }
    }
}

// MARK: - Int formatting helper (private to this file)

private extension Int {
    var priceFormatted: String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.groupingSeparator = "\u{202F}"
        fmt.maximumFractionDigits = 0
        return fmt.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
