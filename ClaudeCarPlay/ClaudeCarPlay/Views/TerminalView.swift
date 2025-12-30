import UIKit

class TerminalView: UIView {

    private let textView: UITextView = {
        let tv = UITextView()
        tv.isEditable = false
        tv.isSelectable = true
        tv.backgroundColor = .black
        tv.textColor = .green
        tv.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.contentInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        return tv
    }()

    private(set) var fullText = ""

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        backgroundColor = .black
        addSubview(textView)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
        ])

        // Initial prompt
        append("Claude CarPlay Terminal v1.0\n")
        append("============================\n\n")
    }

    func append(_ text: String) {
        fullText += text
        textView.text = fullText
        scrollToBottom()
    }

    func clear() {
        fullText = ""
        textView.text = ""
    }

    private func scrollToBottom() {
        guard textView.text.count > 0 else { return }
        let bottom = NSRange(location: textView.text.count - 1, length: 1)
        textView.scrollRangeToVisible(bottom)
    }
}

// MARK: - Terminal View Controller

class TerminalViewController: UIViewController {

    let terminalView = TerminalView()
    var conversationManager: ConversationManager?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black
        terminalView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(terminalView)

        NSLayoutConstraint.activate([
            terminalView.topAnchor.constraint(equalTo: view.topAnchor),
            terminalView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            terminalView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            terminalView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
}
