import UIKit

protocol ModePickerDelegate: AnyObject {
    func didSelectMode(_ mode: AppMode)
}

class ModePickerView: UIView {

    weak var delegate: ModePickerDelegate?

    var selectedMode: AppMode = .drive {
        didSet { updateSelection() }
    }

    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .horizontal
        sv.distribution = .fillEqually
        sv.spacing = 8
        return sv
    }()

    private var modeButtons: [AppMode: ModeButton] = [:]

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        for mode in AppMode.allCases {
            let button = ModeButton(mode: mode)
            button.addTarget(self, action: #selector(modeTapped(_:)), for: .touchUpInside)
            stackView.addArrangedSubview(button)
            modeButtons[mode] = button
        }

        updateSelection()
    }

    @objc private func modeTapped(_ sender: ModeButton) {
        selectedMode = sender.mode
        delegate?.didSelectMode(sender.mode)

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    private func updateSelection() {
        for (mode, button) in modeButtons {
            button.isSelected = (mode == selectedMode)
        }
    }
}

class ModeButton: UIButton {

    let mode: AppMode

    override var isSelected: Bool {
        didSet { updateAppearance() }
    }

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .gray
        return iv
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 10, weight: .medium)
        l.textColor = .gray
        l.textAlignment = .center
        return l
    }()

    private let selectionIndicator: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerRadius = 2
        v.alpha = 0
        return v
    }()

    init(mode: AppMode) {
        self.mode = mode
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        addSubview(iconView)
        addSubview(nameLabel)
        addSubview(selectionIndicator)

        iconView.image = UIImage(systemName: mode.icon)
        nameLabel.text = mode.displayName
        selectionIndicator.backgroundColor = mode.color

        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),

            nameLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 4),
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            selectionIndicator.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            selectionIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            selectionIndicator.widthAnchor.constraint(equalToConstant: 20),
            selectionIndicator.heightAnchor.constraint(equalToConstant: 3),
            selectionIndicator.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
        ])

        updateAppearance()
    }

    private func updateAppearance() {
        UIView.animate(withDuration: 0.2) {
            self.iconView.tintColor = self.isSelected ? self.mode.color : .gray
            self.nameLabel.textColor = self.isSelected ? self.mode.color : .gray
            self.selectionIndicator.alpha = self.isSelected ? 1.0 : 0.0
            self.transform = self.isSelected ? CGAffineTransform(scaleX: 1.1, y: 1.1) : .identity
        }
    }
}
