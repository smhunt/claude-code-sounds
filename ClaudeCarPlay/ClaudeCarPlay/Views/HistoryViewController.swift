import UIKit

class HistoryViewController: UIViewController {

    // Claude colors
    private let claudeOrange = UIColor(red: 0.90, green: 0.50, blue: 0.30, alpha: 1.0)
    private let claudeCream = UIColor(red: 0.98, green: 0.95, blue: 0.90, alpha: 1.0)
    private let claudeDark = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.0)
    private let cardBackground = UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1.0)

    private var sessions: [(id: String, date: Date, preview: String)] = []

    // MARK: - UI

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = claudeDark
        tv.separatorStyle = .none
        tv.delegate = self
        tv.dataSource = self
        tv.register(HistoryCell.self, forCellReuseIdentifier: "HistoryCell")
        return tv
    }()

    private lazy var emptyLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = "No conversations yet.\nStart talking to Claude!"
        l.textColor = .gray
        l.font = .systemFont(ofSize: 16, weight: .medium)
        l.textAlignment = .center
        l.numberOfLines = 0
        l.isHidden = true
        return l
    }()

    private lazy var headerView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = claudeDark

        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.text = "History"
        title.font = .systemFont(ofSize: 28, weight: .bold)
        title.textColor = claudeCream

        let closeButton = UIButton(type: .system)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .gray
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        v.addSubview(title)
        v.addSubview(closeButton)

        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 20),
            title.centerYAnchor.constraint(equalTo: v.centerYAnchor),

            closeButton.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: -20),
            closeButton.centerYAnchor.constraint(equalTo: v.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32)
        ])

        return v
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadSessions()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    private func setupUI() {
        view.backgroundColor = claudeDark

        view.addSubview(headerView)
        view.addSubview(tableView)
        view.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 60),

            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func loadSessions() {
        sessions = ConversationStore.shared.getAllSessions()
        emptyLabel.isHidden = !sessions.isEmpty
        tableView.reloadData()
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}

// MARK: - TableView DataSource & Delegate

extension HistoryViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sessions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell", for: indexPath) as! HistoryCell
        let session = sessions[indexPath.row]
        cell.configure(date: session.date, preview: session.preview)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let session = sessions[indexPath.row]
        // Load this session's messages
        ConversationStore.shared.loadSession(id: session.id)
        dismiss(animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        80
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            guard let self = self else { return }
            let session = self.sessions[indexPath.row]
            ConversationStore.shared.deleteSession(id: session.id)
            self.sessions.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            self.emptyLabel.isHidden = !self.sessions.isEmpty
            completion(true)
        }
        delete.backgroundColor = .systemRed
        return UISwipeActionsConfiguration(actions: [delete])
    }
}

// MARK: - History Cell

class HistoryCell: UITableViewCell {

    private let claudeOrange = UIColor(red: 0.90, green: 0.50, blue: 0.30, alpha: 1.0)
    private let claudeCream = UIColor(red: 0.98, green: 0.95, blue: 0.90, alpha: 1.0)
    private let cardBackground = UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1.0)

    private let containerView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerRadius = 12
        return v
    }()

    private let dateLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 12, weight: .medium)
        return l
    }()

    private let previewLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 15, weight: .regular)
        l.numberOfLines = 2
        return l
    }()

    private let chevron: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "chevron.right"))
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.tintColor = .gray
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none

        containerView.backgroundColor = cardBackground
        contentView.addSubview(containerView)

        containerView.addSubview(dateLabel)
        containerView.addSubview(previewLabel)
        containerView.addSubview(chevron)

        dateLabel.textColor = claudeOrange
        previewLabel.textColor = claudeCream

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            dateLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            dateLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),

            previewLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 4),
            previewLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            previewLabel.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -12),

            chevron.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            chevron.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            chevron.widthAnchor.constraint(equalToConstant: 12),
            chevron.heightAnchor.constraint(equalToConstant: 16)
        ])
    }

    func configure(date: Date, preview: String) {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        dateLabel.text = formatter.string(from: date)
        previewLabel.text = preview.isEmpty ? "New conversation" : preview
    }
}
