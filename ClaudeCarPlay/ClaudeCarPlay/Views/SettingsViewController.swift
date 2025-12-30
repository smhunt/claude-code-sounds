import UIKit

protocol SettingsDelegate: AnyObject {
    func didUpdateSettings()
    func didRequestNewSession()
}

class SettingsViewController: UIViewController {

    weak var delegate: SettingsDelegate?

    // Claude colors
    private let claudeOrange = UIColor(red: 0.90, green: 0.50, blue: 0.30, alpha: 1.0)
    private let claudeCream = UIColor(red: 0.98, green: 0.95, blue: 0.90, alpha: 1.0)
    private let claudeDark = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.0)
    private let cardBackground = UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1.0)

    // MARK: - UI

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .vertical
        sv.spacing = 16
        sv.alignment = .fill
        return sv
    }()

    private lazy var headerView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false

        let icon = UILabel()
        icon.text = "\\"
        icon.font = .systemFont(ofSize: 40)
        icon.translatesAutoresizingMaskIntoConstraints = false

        let title = UILabel()
        title.text = "Settings"
        title.font = .systemFont(ofSize: 28, weight: .bold)
        title.textColor = claudeCream
        title.translatesAutoresizingMaskIntoConstraints = false

        v.addSubview(icon)
        v.addSubview(title)

        NSLayoutConstraint.activate([
            icon.topAnchor.constraint(equalTo: v.topAnchor),
            icon.leadingAnchor.constraint(equalTo: v.leadingAnchor),

            title.centerYAnchor.constraint(equalTo: icon.centerYAnchor),
            title.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 12),

            v.heightAnchor.constraint(equalToConstant: 50)
        ])

        return v
    }()

    private lazy var voiceToggle = createToggleRow(title: "Voice Output", subtitle: "Claude speaks responses aloud", isOn: Config.shared.voiceEnabled)
    private lazy var autoListenToggle = createToggleRow(title: "Auto-Listen", subtitle: "Automatically listen after speaking", isOn: Config.shared.autoListen)
    private lazy var hapticToggle = createToggleRow(title: "Haptic Feedback", subtitle: "Vibrate on interactions", isOn: Config.shared.hapticFeedback)

    private lazy var speechRateSlider: UISlider = {
        let s = UISlider()
        s.minimumValue = 0.3
        s.maximumValue = 0.7
        s.value = Config.shared.speechRate
        s.tintColor = claudeOrange
        return s
    }()

    private lazy var voicePicker: UISegmentedControl = {
        let items = ["Samantha", "Daniel", "Karen", "Moira"]
        let seg = UISegmentedControl(items: items)
        seg.selectedSegmentIndex = Config.shared.selectedVoiceIndex
        seg.selectedSegmentTintColor = claudeOrange
        seg.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        seg.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .selected)
        return seg
    }()

    private lazy var providerPicker: UISegmentedControl = {
        let items = AIProviderType.allCases.map { $0.displayName }
        let seg = UISegmentedControl(items: items)
        seg.selectedSegmentIndex = AIProviderType.allCases.firstIndex(of: Config.shared.selectedProvider) ?? 0
        seg.selectedSegmentTintColor = claudeOrange
        seg.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        seg.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .selected)
        seg.addTarget(self, action: #selector(providerChanged), for: .valueChanged)
        return seg
    }()

    private lazy var apiKeyField: UITextField = {
        let f = UITextField()
        f.placeholder = Config.shared.selectedProvider.apiKeyPlaceholder
        f.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        f.textColor = .white
        f.backgroundColor = cardBackground
        f.layer.cornerRadius = 12
        f.layer.borderWidth = 1
        f.layer.borderColor = claudeOrange.withAlphaComponent(0.3).cgColor
        f.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        f.leftViewMode = .always
        f.isSecureTextEntry = true
        f.autocapitalizationType = .none
        f.attributedPlaceholder = NSAttributedString(
            string: Config.shared.selectedProvider.apiKeyPlaceholder,
            attributes: [.foregroundColor: UIColor.gray]
        )
        return f
    }()

    private lazy var providerStatusLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .medium)
        l.textAlignment = .center
        return l
    }()

    private lazy var newSessionButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Start New Conversation", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        b.setTitleColor(claudeOrange, for: .normal)
        b.backgroundColor = claudeOrange.withAlphaComponent(0.15)
        b.layer.cornerRadius = 12
        b.layer.borderWidth = 1
        b.layer.borderColor = claudeOrange.withAlphaComponent(0.3).cgColor
        return b
    }()

    private lazy var saveButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Save & Close", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        b.setTitleColor(.black, for: .normal)
        b.backgroundColor = claudeOrange
        b.layer.cornerRadius = 14
        return b
    }()

    private lazy var versionLabel: UILabel = {
        let l = UILabel()
        l.text = "Claude CarPlay v1.0.0"
        l.font = .systemFont(ofSize: 12, weight: .medium)
        l.textColor = .gray
        l.textAlignment = .center
        return l
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadValues()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    private func setupUI() {
        view.backgroundColor = claudeDark

        // Close button
        let closeButton = UIButton(type: .system)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .gray
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(closeButton)

        view.addSubview(scrollView)
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),

            scrollView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -40)
        ])

        // Build sections
        stackView.addArrangedSubview(headerView)
        stackView.addArrangedSubview(createSpacer(24))

        // Voice Section
        stackView.addArrangedSubview(createSectionCard(title: "Voice", items: [
            voiceToggle,
            autoListenToggle,
            createLabeledRow(title: "Speech Rate", control: speechRateSlider),
            createLabeledRow(title: "Voice", control: voicePicker)
        ]))

        stackView.addArrangedSubview(createSpacer(16))

        // Experience Section
        stackView.addArrangedSubview(createSectionCard(title: "Experience", items: [
            hapticToggle
        ]))

        stackView.addArrangedSubview(createSpacer(16))

        // AI Provider Section
        stackView.addArrangedSubview(createSectionCard(title: "AI Provider", items: [
            createLabeledRow(title: "Select Provider", control: providerPicker),
            apiKeyField,
            providerStatusLabel
        ]))
        apiKeyField.heightAnchor.constraint(equalToConstant: 48).isActive = true
        updateProviderStatus()

        stackView.addArrangedSubview(createSpacer(16))

        // Session Section
        newSessionButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        stackView.addArrangedSubview(newSessionButton)

        stackView.addArrangedSubview(createSpacer(24))

        saveButton.heightAnchor.constraint(equalToConstant: 56).isActive = true
        stackView.addArrangedSubview(saveButton)
        stackView.addArrangedSubview(createSpacer(16))
        stackView.addArrangedSubview(versionLabel)

        // Actions
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        newSessionButton.addTarget(self, action: #selector(newSessionTapped), for: .touchUpInside)

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func loadValues() {
        // Load provider selection
        let currentProvider = Config.shared.selectedProvider
        providerPicker.selectedSegmentIndex = AIProviderType.allCases.firstIndex(of: currentProvider) ?? 0
        apiKeyField.text = Config.shared.apiKey(for: currentProvider)
        apiKeyField.placeholder = currentProvider.apiKeyPlaceholder

        // Load other settings
        findSwitch(in: voiceToggle)?.isOn = Config.shared.voiceEnabled
        findSwitch(in: autoListenToggle)?.isOn = Config.shared.autoListen
        findSwitch(in: hapticToggle)?.isOn = Config.shared.hapticFeedback
        speechRateSlider.value = Config.shared.speechRate
        voicePicker.selectedSegmentIndex = Config.shared.selectedVoiceIndex

        updateProviderStatus()
    }

    private func findSwitch(in view: UIView) -> UISwitch? {
        for subview in view.subviews {
            if let toggle = subview as? UISwitch { return toggle }
            if let found = findSwitch(in: subview) { return found }
        }
        return nil
    }

    // MARK: - Actions

    @objc private func saveTapped() {
        // Save API key for current provider
        let currentProvider = AIProviderType.allCases[providerPicker.selectedSegmentIndex]
        Config.shared.selectedProvider = currentProvider

        if let key = apiKeyField.text, !key.isEmpty {
            Config.shared.setApiKey(key, for: currentProvider)
        }

        Config.shared.voiceEnabled = findSwitch(in: voiceToggle)?.isOn ?? true
        Config.shared.autoListen = findSwitch(in: autoListenToggle)?.isOn ?? true
        Config.shared.hapticFeedback = findSwitch(in: hapticToggle)?.isOn ?? true
        Config.shared.speechRate = speechRateSlider.value
        Config.shared.selectedVoiceIndex = voicePicker.selectedSegmentIndex

        delegate?.didUpdateSettings()
        dismiss(animated: true)
    }

    @objc private func newSessionTapped() {
        let alert = UIAlertController(
            title: "New Conversation?",
            message: "This will clear your current session and start fresh.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "New Session", style: .destructive) { [weak self] _ in
            ConversationStore.shared.newSession()
            self?.delegate?.didRequestNewSession()
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }

    @objc private func providerChanged() {
        // Save current key before switching
        if let currentText = apiKeyField.text, !currentText.isEmpty {
            Config.shared.setApiKey(currentText, for: Config.shared.selectedProvider)
        }

        // Switch provider
        let newProvider = AIProviderType.allCases[providerPicker.selectedSegmentIndex]
        Config.shared.selectedProvider = newProvider

        // Update UI
        apiKeyField.text = Config.shared.apiKey(for: newProvider)
        apiKeyField.placeholder = newProvider.apiKeyPlaceholder
        apiKeyField.attributedPlaceholder = NSAttributedString(
            string: newProvider.apiKeyPlaceholder,
            attributes: [.foregroundColor: UIColor.gray]
        )

        // Update accent color
        let color = UIColor(
            red: newProvider.accentColor.r,
            green: newProvider.accentColor.g,
            blue: newProvider.accentColor.b,
            alpha: 1.0
        )
        providerPicker.selectedSegmentTintColor = color

        updateProviderStatus()
    }

    private func updateProviderStatus() {
        let provider = AIProviderFactory.createCurrentProvider()
        if provider.isConfigured() {
            providerStatusLabel.text = "\(provider.name) is configured"
            providerStatusLabel.textColor = UIColor(red: 0.3, green: 0.8, blue: 0.4, alpha: 1.0)
        } else {
            providerStatusLabel.text = "Enter your \(provider.name) API key"
            providerStatusLabel.textColor = .gray
        }
    }

    // MARK: - Helpers

    private func createToggleRow(title: String, subtitle: String, isOn: Bool) -> UIView {
        let row = UIView()
        row.heightAnchor.constraint(equalToConstant: 56).isActive = true

        let textStack = UIStackView()
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.axis = .vertical
        textStack.spacing = 2

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = claudeCream

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .systemFont(ofSize: 12, weight: .regular)
        subtitleLabel.textColor = .gray

        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subtitleLabel)

        let toggle = UISwitch()
        toggle.translatesAutoresizingMaskIntoConstraints = false
        toggle.isOn = isOn
        toggle.onTintColor = claudeOrange

        row.addSubview(textStack)
        row.addSubview(toggle)

        NSLayoutConstraint.activate([
            textStack.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            textStack.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: toggle.leadingAnchor, constant: -16),
            toggle.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            toggle.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])

        return row
    }

    private func createLabeledRow(title: String, control: UIView) -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10

        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .gray

        stack.addArrangedSubview(label)
        stack.addArrangedSubview(control)

        return stack
    }

    private func createSectionCard(title: String, items: [UIView]) -> UIView {
        let container = UIView()
        container.backgroundColor = cardBackground
        container.layer.cornerRadius = 16

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title.uppercased()
        titleLabel.font = .systemFont(ofSize: 12, weight: .bold)
        titleLabel.textColor = claudeOrange
        container.addSubview(titleLabel)

        let itemStack = UIStackView(arrangedSubviews: items)
        itemStack.translatesAutoresizingMaskIntoConstraints = false
        itemStack.axis = .vertical
        itemStack.spacing = 12
        container.addSubview(itemStack)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),

            itemStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            itemStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            itemStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            itemStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])

        return container
    }

    private func createSpacer(_ height: CGFloat) -> UIView {
        let v = UIView()
        v.heightAnchor.constraint(equalToConstant: height).isActive = true
        return v
    }
}
