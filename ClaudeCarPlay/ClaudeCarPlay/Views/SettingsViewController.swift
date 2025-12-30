import UIKit

protocol SettingsDelegate: AnyObject {
    func didUpdateSettings()
    func didRequestNewSession()
}

class SettingsViewController: UIViewController {

    weak var delegate: SettingsDelegate?

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
        sv.spacing = 20
        sv.alignment = .fill
        return sv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Settings"
        l.font = .monospacedSystemFont(ofSize: 24, weight: .bold)
        l.textColor = .systemGreen
        return l
    }()

    private lazy var voiceToggle = createToggleRow(title: "Voice Output", isOn: Config.shared.voiceEnabled)
    private lazy var autoListenToggle = createToggleRow(title: "Auto-Listen", isOn: Config.shared.autoListen)
    private lazy var hapticToggle = createToggleRow(title: "Haptic Feedback", isOn: Config.shared.hapticFeedback)

    private lazy var speechRateSlider: UISlider = {
        let s = UISlider()
        s.minimumValue = 0.3
        s.maximumValue = 0.7
        s.value = Config.shared.speechRate
        s.tintColor = .systemGreen
        return s
    }()

    private let apiKeyField: UITextField = {
        let f = UITextField()
        f.placeholder = "API Key"
        f.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        f.textColor = .white
        f.backgroundColor = UIColor(white: 0.15, alpha: 1)
        f.layer.cornerRadius = 8
        f.layer.borderWidth = 1
        f.layer.borderColor = UIColor.systemGreen.cgColor
        f.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        f.leftViewMode = .always
        f.isSecureTextEntry = true
        f.autocapitalizationType = .none
        return f
    }()

    private let newSessionButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("New Conversation", for: .normal)
        b.titleLabel?.font = .monospacedSystemFont(ofSize: 16, weight: .semibold)
        b.setTitleColor(.systemOrange, for: .normal)
        b.backgroundColor = UIColor(white: 0.15, alpha: 1)
        b.layer.cornerRadius = 8
        return b
    }()

    private let saveButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Save & Close", for: .normal)
        b.titleLabel?.font = .monospacedSystemFont(ofSize: 18, weight: .semibold)
        b.setTitleColor(.black, for: .normal)
        b.backgroundColor = .systemGreen
        b.layer.cornerRadius = 12
        return b
    }()

    private let versionLabel: UILabel = {
        let l = UILabel()
        l.text = "Claude CarPlay v1.0.0"
        l.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        l.textColor = .darkGray
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
        view.backgroundColor = .black

        view.addSubview(scrollView)
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20)
        ])

        // Build sections
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(createSpacer(20))

        stackView.addArrangedSubview(createSectionLabel("VOICE"))
        stackView.addArrangedSubview(voiceToggle)
        stackView.addArrangedSubview(autoListenToggle)
        stackView.addArrangedSubview(createLabeledRow(title: "Speech Rate", control: speechRateSlider))
        stackView.addArrangedSubview(createSpacer(10))

        stackView.addArrangedSubview(createSectionLabel("FEEDBACK"))
        stackView.addArrangedSubview(hapticToggle)
        stackView.addArrangedSubview(createSpacer(10))

        stackView.addArrangedSubview(createSectionLabel("API"))
        apiKeyField.heightAnchor.constraint(equalToConstant: 44).isActive = true
        stackView.addArrangedSubview(apiKeyField)
        stackView.addArrangedSubview(createSpacer(10))

        stackView.addArrangedSubview(createSectionLabel("SESSION"))
        newSessionButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        stackView.addArrangedSubview(newSessionButton)
        stackView.addArrangedSubview(createSpacer(30))

        saveButton.heightAnchor.constraint(equalToConstant: 56).isActive = true
        stackView.addArrangedSubview(saveButton)
        stackView.addArrangedSubview(createSpacer(10))
        stackView.addArrangedSubview(versionLabel)

        // Actions
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        newSessionButton.addTarget(self, action: #selector(newSessionTapped), for: .touchUpInside)

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func loadValues() {
        apiKeyField.text = Config.shared.apiKey
        (voiceToggle.subviews.last as? UISwitch)?.isOn = Config.shared.voiceEnabled
        (autoListenToggle.subviews.last as? UISwitch)?.isOn = Config.shared.autoListen
        (hapticToggle.subviews.last as? UISwitch)?.isOn = Config.shared.hapticFeedback
        speechRateSlider.value = Config.shared.speechRate
    }

    // MARK: - Actions

    @objc private func saveTapped() {
        if let key = apiKeyField.text, !key.isEmpty {
            Config.shared.apiKey = key
        }

        Config.shared.voiceEnabled = (voiceToggle.subviews.last as? UISwitch)?.isOn ?? true
        Config.shared.autoListen = (autoListenToggle.subviews.last as? UISwitch)?.isOn ?? true
        Config.shared.hapticFeedback = (hapticToggle.subviews.last as? UISwitch)?.isOn ?? true
        Config.shared.speechRate = speechRateSlider.value

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

    // MARK: - Helpers

    private func createToggleRow(title: String, isOn: Bool) -> UIView {
        let row = UIView()
        row.heightAnchor.constraint(equalToConstant: 44).isActive = true

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = title
        label.font = .monospacedSystemFont(ofSize: 16, weight: .regular)
        label.textColor = .white

        let toggle = UISwitch()
        toggle.translatesAutoresizingMaskIntoConstraints = false
        toggle.isOn = isOn
        toggle.onTintColor = .systemGreen

        row.addSubview(label)
        row.addSubview(toggle)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            label.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            toggle.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            toggle.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])

        return row
    }

    private func createLabeledRow(title: String, control: UIView) -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8

        let label = UILabel()
        label.text = title
        label.font = .monospacedSystemFont(ofSize: 16, weight: .regular)
        label.textColor = .white

        stack.addArrangedSubview(label)
        stack.addArrangedSubview(control)

        return stack
    }

    private func createSectionLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .monospacedSystemFont(ofSize: 12, weight: .bold)
        l.textColor = .gray
        return l
    }

    private func createSpacer(_ height: CGFloat) -> UIView {
        let v = UIView()
        v.heightAnchor.constraint(equalToConstant: height).isActive = true
        return v
    }
}
