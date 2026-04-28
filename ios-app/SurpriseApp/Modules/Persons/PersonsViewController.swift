import UIKit

// MARK: - PersonsViewController

final class PersonsViewController: UIViewController {

    // MARK: - Dependencies

    private let viewModel: PersonsViewModelProtocol

    // MARK: - Views

    private let backButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(named: "back_icon"), for: .normal)
        b.tintColor = .appSecondary
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 72
        tv.showsVerticalScrollIndicator = false
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.text = "Добавь близких,\nчтобы не забыть поздравить"
        l.font = .miama(size: 22)
        l.textColor = .appTextMain
        l.numberOfLines = 0
        l.textAlignment = .center
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let addButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "plus",
                               withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .medium))
        config.baseBackgroundColor = UIColor(hex: "#BDD3E9")
        config.baseForegroundColor = .appPrimary
        config.cornerStyle = .capsule
        let btn = UIButton(configuration: config)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    // MARK: - Init

    init(viewModel: PersonsViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .appBackground
        setupHeader()       // titleLabel должен быть в иерархии до setupTableView
        setupTableView()
        setupEmptyState()
        setupAddButton()
        setupBackButton()
        view.bringSubviewToFront(backButton)
        view.bringSubviewToFront(titleLabel)
        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadPersons()
    }

    // MARK: - Setup

    private func setupBackButton() {
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        view.addSubview(backButton)
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),
        ])
    }

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Мои близкие"
        l.font = .miama(size: 32)
        l.textColor = .appPrimary
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private func setupHeader() {
        view.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate   = self
        tableView.register(PersonCell.self, forCellReuseIdentifier: PersonCell.identifier)
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        tableView.contentInset.bottom = 100
    }

    private func setupEmptyState() {
        view.addSubview(emptyLabel)
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
        ])
    }

    private func setupAddButton() {
        addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        view.addSubview(addButton)
        NSLayoutConstraint.activate([
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -110),
            addButton.widthAnchor.constraint(equalToConstant: 56),
            addButton.heightAnchor.constraint(equalToConstant: 56),
        ])
    }

    private func bindViewModel() {
        viewModel.onStateChanged = { [weak self] in
            self?.applyState()
        }
        viewModel.onError = { [weak self] message in
            self?.showError(message)
        }
    }

    // MARK: - State

    private func applyState() {
        tableView.reloadData()
        emptyLabel.isHidden = !viewModel.persons.isEmpty
    }

    private func showError(_ message: String) {
        Toast.show(message)
    }

    // MARK: - Actions

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func addTapped() {
        HapticFeedback.selection()
        presentAddEdit(person: nil)
    }

    private func presentAddEdit(person: Person?) {
        let vc = AddEditPersonViewController(person: person)
        vc.onSave = { [weak self] name, day, month, year, type, notes in
            guard let self else { return }
            if let existing = person {
                self.viewModel.updatePerson(
                    id: existing.id,
                    name: name,
                    eventDay: day,
                    eventMonth: month,
                    eventYear: year,
                    eventType: type,
                    notes: notes
                )
            } else {
                self.viewModel.createPerson(
                    name: name,
                    eventDay: day,
                    eventMonth: month,
                    eventYear: year,
                    eventType: type,
                    notes: notes
                )
            }
        }
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = false
            sheet.preferredCornerRadius = 24
        }
        NotificationCenter.default.post(name: .tapBarShouldHide, object: nil)
        present(vc, animated: true) {
            // на случай если шит закроют свайпом вниз
            vc.presentationController?.delegate = self
        }
    }
}

// MARK: - UITableViewDataSource

extension PersonsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.persons.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PersonCell.identifier, for: indexPath) as! PersonCell
        cell.configure(with: viewModel.persons[indexPath.row])
        return cell
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension PersonsViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        NotificationCenter.default.post(name: .tapBarShouldShow, object: nil)
    }
}

// MARK: - UITableViewDelegate

extension PersonsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let person = viewModel.persons[indexPath.row]
        presentAddEdit(person: person)
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: nil) { [weak self] _, _, completion in
            HapticFeedback.selection()
            self?.viewModel.deletePerson(at: indexPath.row)
            completion(true)
        }
        delete.image = UIImage(systemName: "trash")
        delete.backgroundColor = UIColor(hex: "#E87C7C")
        return UISwipeActionsConfiguration(actions: [delete])
    }
}
