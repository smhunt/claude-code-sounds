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

    private let containerView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .black
        return v
    }()

    private let iconLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 80)
        l.textAlignment = .center
        return l
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .monospacedSystemFont(ofSize: 28, weight: .bold)
        l.textColor = .systemGreen
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .monospacedSystemFont(ofSize: 16, weight: .regular)
        l.textColor = .lightGray
        l.textAlignment = .center
        l.numberOfLines = 0
        return l
    }()

    private let apiKeyField: UITextField = {
        let f = UITextField()
        f.translatesAutoresizingMaskIntoConstraints = false
        f.placeholder = "sk-ant-..."
        f.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        f.textColor = .white
        f.backgroundColor = UIColor(white: 0.15, alpha: 1)
        f.layer.cornerRadius = 8
        f.layer.borderWidth = 1
        f.layer.borderColor = UIColor.systemGreen.cgColor
        f.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
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
        b.setTitle("Continue", for: .normal)
        b.titleLabel?.font = .monospacedSystemFont(ofSize: 18, weight: .semibold)
        b.setTitleColor(.black, for: .normal)
        b.backgroundColor = .systemGreen
        b.layer.cornerRadius = 12
        return b
    }()

    private let pageControl: UIPageControl = {
        let p = UIPageControl()
        p.translatesAutoresizingMaskIntoConstraints = false
        p.numberOfPages = 4
        p.currentPageIndicatorTintColor = .systemGreen
        p.pageIndicatorTintColor = .darkGray
        return p
    }()

    private let skipButton: UIButton = {
        let b = UIButton(type: .system)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setTitle("Skip", for: .normal)
        b.titleLabel?.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        b.setTitleColor(.gray, for: .normal)
        return b
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateForPage(0)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    private func setupUI() {
        view.backgroundColor = .black

        view.addSubview(containerView)
        containerView.addSubview(iconLabel)
        containerView.addSubview(titleLabel)
        containerView.addSubview(subtitleLabel)
        containerView.addSubview(apiKeyField)
        containerView.addSubview(primaryButton)
        containerView.addSubview(pageControl)
        containerView.addSubview(skipButton)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            iconLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            iconLabel.topAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.topAnchor, constant: 80),

            titleLabel.topAnchor.constraint(equalTo: iconLabel.bottomAnchor, constant: 30),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 40),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -40),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            subtitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 40),
            subtitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -40),

            apiKeyField.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 30),
            apiKeyField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 40),
            apiKeyField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -40),
            apiKeyField.heightAnchor.constraint(equalToConstant: 50),

            primaryButton.bottomAnchor.constraint(equalTo: pageControl.topAnchor, constant: -30),
            primaryButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 40),
            primaryButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -40),
            primaryButton.heightAnchor.constraint(equalToConstant: 56),

            pageControl.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            pageControl.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),

            skipButton.topAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.topAnchor, constant: 10),
            skipButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20)
        ])

        primaryButton.addTarget(self, action: #selector(primaryTapped), for: .touchUpInside)
        skipButton.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - Page Updates

    private func updateForPage(_ page: Int) {
        currentPage = page
        pageControl.currentPage = page
        apiKeyField.isHidden = true

        switch pages[page] {
        case "welcome":
            iconLabel.text = "🚗"
            titleLabel.text = "Claude CarPlay"
            subtitleLabel.text = "Your AI copilot for the road.\nVoice-powered, hands-free."
            primaryButton.setTitle("Get Started", for: .normal)
            skipButton.isHidden = false

        case "permissions":
            iconLabel.text = "🎤"
            titleLabel.text = "Permissions"
            subtitleLabel.text = "We need microphone and speech recognition access to hear your commands."
            primaryButton.setTitle("Grant Access", for: .normal)
            skipButton.isHidden = true

        case "apikey":
            iconLabel.text = "🔑"
            titleLabel.text = "API Key"
            subtitleLabel.text = "Enter your Anthropic API key.\nGet one at console.anthropic.com"
            apiKeyField.isHidden = false
            apiKeyField.text = Config.shared.apiKey
            primaryButton.setTitle("Save & Continue", for: .normal)
            skipButton.isHidden = true

        case "ready":
            iconLabel.text = "✅"
            titleLabel.text = "Ready to Drive"
            subtitleLabel.text = "Connect to CarPlay and start talking.\nClaude is listening."
            primaryButton.setTitle("Launch Terminal", for: .normal)
            skipButton.isHidden = true
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
            delegate?.onboardingDidComplete()
        default:
            break
        }
    }

    @objc private func skipTapped() {
        // Skip to API key page
        updateForPage(2)
    }

    private func shakeField() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.5
        animation.values = [-10, 10, -8, 8, -5, 5, 0]
        apiKeyField.layer.add(animation, forKey: "shake")
        apiKeyField.layer.borderColor = UIColor.red.cgColor

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.apiKeyField.layer.borderColor = UIColor.systemGreen.cgColor
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
