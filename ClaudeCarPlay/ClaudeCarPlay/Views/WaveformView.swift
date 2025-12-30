import UIKit

class WaveformView: UIView {

    enum State {
        case idle
        case listening
        case processing
        case speaking
    }

    var state: State = .idle {
        didSet { updateForState() }
    }

    var accentColor: UIColor = .systemGreen {
        didSet { setNeedsDisplay() }
    }

    private var displayLink: CADisplayLink?
    private var phase: CGFloat = 0
    private var amplitudes: [CGFloat] = Array(repeating: 0.3, count: 50)
    private var targetAmplitudes: [CGFloat] = Array(repeating: 0.3, count: 50)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .clear
        isOpaque = false
    }

    private func updateForState() {
        switch state {
        case .idle:
            stopAnimation()
            targetAmplitudes = Array(repeating: 0.1, count: 50)
        case .listening:
            startAnimation()
            randomizeAmplitudes(base: 0.3, variance: 0.4)
        case .processing:
            startAnimation()
            targetAmplitudes = Array(repeating: 0.2, count: 50)
        case .speaking:
            startAnimation()
            randomizeAmplitudes(base: 0.5, variance: 0.5)
        }
    }

    private func randomizeAmplitudes(base: CGFloat, variance: CGFloat) {
        targetAmplitudes = (0..<50).map { _ in
            base + CGFloat.random(in: -variance...variance)
        }
    }

    private func startAnimation() {
        guard displayLink == nil else { return }
        displayLink = CADisplayLink(target: self, selector: #selector(tick))
        displayLink?.add(to: .main, forMode: .common)
    }

    private func stopAnimation() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func tick() {
        phase += 0.05

        // Smoothly interpolate towards target
        for i in 0..<amplitudes.count {
            amplitudes[i] += (targetAmplitudes[i] - amplitudes[i]) * 0.1
        }

        // Add variation for listening/speaking
        if state == .listening || state == .speaking {
            if Int.random(in: 0..<10) == 0 {
                randomizeAmplitudes(base: state == .speaking ? 0.5 : 0.3, variance: state == .speaking ? 0.5 : 0.4)
            }
        }

        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        let midY = rect.height / 2
        let barWidth: CGFloat = 3
        let gap: CGFloat = 2
        let totalWidth = CGFloat(amplitudes.count) * (barWidth + gap)
        let startX = (rect.width - totalWidth) / 2

        for (index, amplitude) in amplitudes.enumerated() {
            let x = startX + CGFloat(index) * (barWidth + gap)

            // Wave effect
            let waveOffset = sin(phase + CGFloat(index) * 0.2) * 0.1
            let finalAmplitude = max(0.05, min(1.0, amplitude + waveOffset))

            let barHeight = rect.height * finalAmplitude * 0.8
            let y = midY - barHeight / 2

            let barRect = CGRect(x: x, y: y, width: barWidth, height: barHeight)

            // Gradient color based on amplitude
            let alpha = 0.5 + finalAmplitude * 0.5
            context.setFillColor(accentColor.withAlphaComponent(alpha).cgColor)

            let path = UIBezierPath(roundedRect: barRect, cornerRadius: barWidth / 2)
            context.addPath(path.cgPath)
            context.fillPath()
        }
    }

    deinit {
        stopAnimation()
    }
}

// MARK: - Pulsing Mic Button

class PulsingMicButton: UIButton {

    private let pulseLayer = CAShapeLayer()
    private let glowLayer = CAShapeLayer()

    var isActive: Bool = false {
        didSet { updateState() }
    }

    var accentColor: UIColor = .systemGreen {
        didSet { updateColors() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .clear

        // Glow layer
        glowLayer.fillColor = UIColor.clear.cgColor
        glowLayer.strokeColor = accentColor.withAlphaComponent(0.3).cgColor
        glowLayer.lineWidth = 4
        layer.insertSublayer(glowLayer, at: 0)

        // Pulse layer
        pulseLayer.fillColor = UIColor.clear.cgColor
        pulseLayer.strokeColor = accentColor.withAlphaComponent(0.5).cgColor
        pulseLayer.lineWidth = 2
        layer.insertSublayer(pulseLayer, at: 0)

        setImage(UIImage(systemName: "mic.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)), for: .normal)
        tintColor = accentColor
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - 4

        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        pulseLayer.path = path.cgPath
        glowLayer.path = path.cgPath

        pulseLayer.frame = bounds
        glowLayer.frame = bounds
    }

    private func updateState() {
        if isActive {
            startPulsing()
            setImage(UIImage(systemName: "mic.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)), for: .normal)
        } else {
            stopPulsing()
            setImage(UIImage(systemName: "mic.slash", withConfiguration: UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)), for: .normal)
        }
    }

    private func updateColors() {
        tintColor = accentColor
        pulseLayer.strokeColor = accentColor.withAlphaComponent(0.5).cgColor
        glowLayer.strokeColor = accentColor.withAlphaComponent(0.3).cgColor
    }

    private func startPulsing() {
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 1.0
        scaleAnimation.toValue = 1.3
        scaleAnimation.duration = 1.0
        scaleAnimation.autoreverses = true
        scaleAnimation.repeatCount = .infinity

        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 0.5
        opacityAnimation.toValue = 0.0
        opacityAnimation.duration = 1.0
        opacityAnimation.autoreverses = true
        opacityAnimation.repeatCount = .infinity

        pulseLayer.add(scaleAnimation, forKey: "pulse")
        pulseLayer.add(opacityAnimation, forKey: "fade")
    }

    private func stopPulsing() {
        pulseLayer.removeAllAnimations()
    }
}
