import UIKit
import Speech
import AVFoundation

protocol OnboardingDelegate: AnyObject {
    func onboardingDidComplete()
}

class OnboardingViewController: UIViewController {

    weak var delegate: OnboardingDelegate?

    private var currentPage = 0
    private let pages = ["welcome", "permissions", "apikey", "ready"]

    // MARK: - UI Elements

    private let backgroundView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = AppMode.claudeDark
        return v
    }()

    private let iconContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = AppMode.claudeOrange.withAlphaComponent(0.15)
        v.layer.cornerRadius = 60
        return v
    }()

    private let iconLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 50)
        l.textAlignment = .center
        return l
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 32, weight: .bold)
        l.textColor = .white
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 17, weight: .regular)
        l.textColor = UIColor(white: 0.7, alpha: 1)
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    private let apiKeyField: UITextField = {
        let f = UITextField()
        f.translatesAutoresizingMaskIntoConstraints = false
        f.placeholder = "sk-ant-api..."
        f.font = .monospacedSystemFont(ofSize: 15, weight: .regular)
        f.textColor = .white
        f.backgroundColor = UIColor(white: 0.15, alpha: 1)
        f.layer.cornerRadius = 12
        f.layer.borderWidth = 2
        f.layer.borderColor = AppMode.claudeOrange.cgColor
        f.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        f.leftViewMode = .always
        f.autocapitalizationType = .none
        f.autocorrectionType = .no
        f.isSecureTextEntry = true
        f.isHidden = true
        return f
    }()

    private let primaryButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = AppMode.claudeOrange
        b.layer.cornerRadius = 14
        return b
    }()

    private let pageControl: UIPageControl = {
        let p = UIPageControl()
        p.translatesAutoresizingMaskIntoConstraints = false
        p.numberOfPages = 4
        p.currentPageIndicatorTintColor = AppMode.claudeOrange
        p.pageIndicatorTintColor = UIColor(white: 0.3, alpha: 1)
        return p
    }()

    private let modePreviewStack: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .horizontal
        sv.distribution = .equalSpacing
        sv.spacing = 20
        sv.isHidden = true
        return sv
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateForPage(0)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    private func setupUI() {
        view.addSubview(backgroundView)
        view.addSubview(iconContainer)
        iconContainer.addSubview(iconLabel)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(modePreviewStack)
        view.addSubview(apiKeyField)
        view.addSubview(primaryButton)
        view.addSubview(pageControl)

        // Add mode preview items
        for mode in AppMode.allCases {
            let item = createModePreviewItem(mode: mode)
            modePreviewStack.addArrangedSubview(item)
        }

        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            iconContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
            iconContainer.widthAnchor.constraint(equalToConstant: 120),
            iconContainer.heightAnchor.constraint(equalToConstant: 120),

            iconLabel.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconLabel.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),

            titleLabel.topAnchor.constraint(equalTo: iconContainer.bottomAnchor, constant: 32),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            modePreviewStack.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 32),
            modePreviewStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            apiKeyField.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 32),
            apiKeyField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            apiKeyField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            apiKeyField.heightAnchor.constraint(equalToConstant: 56),

            primaryButton.bottomAnchor.constraint(equalTo: pageControl.topAnchor, constant: -32),
            primaryButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            primaryButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            primaryButton.heightAnchor.constraint(equalToConstant: 56),

            pageControl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        primaryButton.addTarget(self, action: #selector(primaryTapped), for: .touchUpInside)

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }

    private func createModePreviewItem(mode: AppMode) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let iconBg = UIView()
        iconBg.translatesAutoresizingMaskIntoConstraints = false
        iconBg.backgroundColor = mode.color.withAlphaComponent(0.2)
        iconBg.layer.cornerRadius = 24

        let icon = UIImageView()
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.image = UIImage(systemName: mode.icon)
        icon.tintColor = mode.color
        icon.contentMode = .scaleAspectFit

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = mode.displayName
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = UIColor(white: 0.6, alpha: 1)
        label.textAlignment = .center

        container.addSubview(iconBg)
        iconBg.addSubview(icon)
        container.addSubview(label)

        NSLayoutConstraint.activate([
            iconBg.topAnchor.constraint(equalTo: container.topAnchor),
            iconBg.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            iconBg.widthAnchor.constraint(equalToConstant: 48),
            iconBg.heightAnchor.constraint(equalToConstant: 48),

            icon.centerXAnchor.constraint(equalTo: iconBg.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: iconBg.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 24),
            icon.heightAnchor.constraint(equalToConstant: 24),

            label.topAnchor.constraint(equalTo: iconBg.bottomAnchor, constant: 8),
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            container.widthAnchor.constraint(equalToConstant: 56)
        ])

        return container
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - Page Updates

    private func updateForPage(_ page: Int) {
        currentPage = page
        pageControl.currentPage = page
        apiKeyField.isHidden = true
        modePreviewStack.isHidden = true

        switch pages[page] {
        case "welcome":
            iconLabel.text = "🚗"
            titleLabel.text = "Claude for CarPlay"
            subtitleLabel.text = "Your AI copilot for the road.\nVoice-powered. Hands-free. Thoughtful."
            primaryButton.setTitle("Get Started", for: .normal)
            modePreviewStack.isHidden = false

        case "permissions":
            iconLabel.text = "🎤"
            titleLabel.text = "Voice Access"
            subtitleLabel.text = "Claude needs to hear you.\nWe'll ask for microphone and speech recognition."
            primaryButton.setTitle("Grant Access", for: .normal)

        case "apikey":
            iconLabel.text = "🔑"
            titleLabel.text = "Connect to Claude"
            subtitleLabel.text = "Enter your Anthropic API key.\nGet one at console.anthropic.com"
            apiKeyField.isHidden = false
            apiKeyField.text = Config.shared.apiKey
            primaryButton.setTitle("Continue", for: .normal)

        case "ready":
            iconLabel.text = "✨"
            titleLabel.text = "Ready to Drive"
            subtitleLabel.text = "Just say what you need.\nNavigation. Music. Games. Conversation."
            primaryButton.setTitle("Start Driving", for: .normal)
            modePreviewStack.isHidden = false
        }
    }

    // MARK: - Actions

    @objc private func primaryTapped() {
        switch pages[currentPage] {
        case "welcome":
            updateForPage(1)

        case "permissions":
            requestPermissions { [weak self] in
                self?.updateForPage(2)
            }

        case "apikey":
            guard let key = apiKeyField.text, !key.isEmpty else {
                shakeField()
                return
            }
            Config.shared.apiKey = key
            if Config.shared.hasValidApiKey {
                updateForPage(3)
            } else {
                shakeField()
            }

        case "ready":
            Config.shared.hasCompletedOnboarding = true
            Config.shared.voiceEnabled = true
            Config.shared.autoListen = true
            delegate?.onboardingDidComplete()
        default:
            break
        }
    }

    private func shakeField() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.5
        animation.values = [-10, 10, -8, 8, -5, 5, 0]
        apiKeyField.layer.add(animation, forKey: "shake")
        apiKeyField.layer.borderColor = UIColor.red.cgColor

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.apiKeyField.layer.borderColor = AppMode.claudeOrange.cgColor
        }
    }

    private func requestPermissions(completion: @escaping () -> Void) {
        let group = DispatchGroup()

        group.enter()
        AVAudioSession.sharedInstance().requestRecordPermission { _ in
            group.leave()
        }

        group.enter()
        SFSpeechRecognizer.requestAuthorization { _ in
            group.leave()
        }

        group.notify(queue: .main) {
            completion()
        }
    }
}
