import UIKit
import Resources

// swiftlint:disable file_length
protocol DrawerOverlayScrollListener: AnyObject {
    func didScrollAboveMaxPosition(_ above: Bool)
}

protocol DrawerOverlayViewListener: AnyObject {
    func drawerView(_ drawerView: DrawerOverlayView,
                    willBeginAnimationToState state: DrawerOverlayView.State?)
    func drawerView(_ drawerView: DrawerOverlayView,
                    didEndAnimationToState state: DrawerOverlayView.State?)
}

class DrawerOverlayView: UIView {
    enum State: Equatable {
        case top
        case middle
        case bottom
        case dismissed
        case custom(height: CGFloat)
    }

    private lazy var configuration: DrawerOverlayConfiguration = DrawerOverlayConfiguration()

    var enabledState: [State] = [.top, .dismissed]
    private let notifier = Notifier<DrawerOverlayViewListener>()

    weak var scrollListener: DrawerOverlayScrollListener?

    var dragRecognizer: UIPanGestureRecognizer!
    var backgroundTapRecognizer: UITapGestureRecognizer!

    let animationDamping = DrawerConstants.animationDampingRatioBase
    let animationDuration = DrawerConstants.animationDurationBase

    var maxDrawerPosition: CGFloat = Metrics.Sizes.screenSize.height - Metrics.Sizes.statusBar.height {
        didSet {
            minDrawerPosition = maxDrawerPosition/2
        }
    }

    lazy var midDrawerPosition: CGFloat = (maxDrawerPosition / 2) + Metrics.Sizes.statusBar.height
    lazy var _minDrawerPosition: CGFloat = max(max(headerView.frame.height, headerHeight), UIScreen.main.bounds.height / 4)

    var minDrawerPosition: CGFloat {
        get {
            _minDrawerPosition
        }

        set {
            _minDrawerPosition = newValue + Metrics.Sizes.safeAreaInsets.bottom
        }
    }

    var contentsOffsetTop: CGFloat = 0
    var drawerHeight: CGFloat = 0
    var isScrollViewBeingDragged: Bool = false
    var backgroundView: UIView = UIView()

    var needChangeHeaderAlpha = true {
        didSet {
            if !needChangeHeaderAlpha {
//                headerView.headerBlurAlpha = 0
            }
        }
    }

    var containerView: UIView = {
        let view = UIView()
        view.isHidden = true

        view.applyBaseShadow()
//        view.addShadow(offset: CGSize(width: 0, height: 10),
//                       color: UIColor(red: 0.106, green: 0.125, blue: 0.169, alpha: 0.25),
//                       radius: 30,
//                       opacity: 1)

        return view
    }()

    lazy var headerView: DrawerOverlayHeaderView = {
        let headerView = DrawerOverlayHeaderView()
        return headerView
    }()

    open override var cornerRadius: CGFloat {
        get {
            headerView.layer.cornerRadius
        }
        set {
            let cornerRadius: CGFloat
            let maskedCorners: CACornerMask

            if newValue > 0 {
                cornerRadius = newValue
                maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
            } else {
                cornerRadius = 0
                maskedCorners = []
            }

            containerView.layer.cornerRadius = cornerRadius
            containerView.layer.maskedCorners = maskedCorners

            headerView.layer.masksToBounds = true
            headerView.layer.cornerRadius = cornerRadius
            headerView.layer.maskedCorners = maskedCorners

            drawerContentView?.layer.masksToBounds = true
            drawerContentView?.layer.cornerRadius = cornerRadius
            drawerContentView?.layer.maskedCorners = maskedCorners
        }
    }

    var drawerContentView: UIView? {
        willSet {
            if let drawerContentView = drawerContentView {
                drawerContentView.removeFromSuperview()
            }
        }

        didSet {
            guard let drawerContentView = drawerContentView else { return }

            drawerContentView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(drawerContentView)
            NSLayoutConstraint.activate([
                drawerContentView.leftAnchor.constraint(equalTo: containerView.leftAnchor),
                drawerContentView.rightAnchor.constraint(equalTo: containerView.rightAnchor),
                drawerContentView.topAnchor.constraint(equalTo: containerView.topAnchor),
                drawerContentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])

            containerView.bringSubviewToFront(headerView)

            drawerContentView.layer.masksToBounds = true
            drawerContentView.layer.cornerRadius = containerView.layer.cornerRadius
            drawerContentView.layer.maskedCorners = containerView.layer.maskedCorners
        }
    }

    var scrollableDrawerContent: ScrollableDrawerContent? {
        willSet {
            scrollableDrawerContent?.scrollViewDelegate = nil
        }

        didSet {
            scrollableDrawerContent?.scrollViewDelegate = self
        }
    }

    init(_ configuration: DrawerOverlayConfiguration) {
        super.init(frame: .zero)

        self.configuration = configuration
        setupViews()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        setupViews()
    }

    func setDrawerPosition(_ position: State,
                           animated: Bool = true,
                           fastUpdate: Bool = false,
                           completion: @escaping EmptyClosure) {

        updateDrawerPosition(position, fastUpdate: fastUpdate, animated: animated, completion: completion)
        notifier.forEach { $0.drawerView(self, willBeginAnimationToState: position)}
        self.handleDrawerPosition(position, fastUpdate: fastUpdate, animated: animated, completion: completion)
    }

    private func updateDrawerPosition(_ position: State, fastUpdate: Bool, animated: Bool, completion: @escaping EmptyClosure) {
        var newSize = containerView.frame.size
        var oldSize = containerView.frame.size

        containerView.isHidden = false

        newSize.height = self.drawerHeight

        if newSize.height > oldSize.height {
            oldSize.height = self.drawerHeight
        }

        containerView.frame = CGRect(origin: containerView.frame.origin,
                                     size: newSize)

        if animated {
            UIView.animate(withDuration: animationDuration, delay: 0.0, usingSpringWithDamping: animationDamping,
                           initialSpringVelocity: 0, options: [ .beginFromCurrentState ], animations: {
                self.updateDrawer(with: oldSize)
                self.backgroundView.alpha = position == .bottom ? 0 : 1
            }, completion: { _ in
                oldSize.height = self.drawerHeight
                self.updateDrawer(with: oldSize)
                self.notifier.forEach { $0.drawerView(self, didEndAnimationToState: position)}
                completion()
            })
        } else if fastUpdate {
            oldSize.height = self.drawerHeight
            updateDrawer(with: oldSize)
            self.notifier.forEach { $0.drawerView(self, didEndAnimationToState: position)}
            completion()
        } else {
            UIView.animate(withDuration: animationDuration/2) {
                self.updateDrawer(with: oldSize)
                self.backgroundView.alpha = position == .bottom ? 0 : 1
            } completion: { (_) in
                oldSize.height = self.drawerHeight
                self.updateDrawer(with: oldSize)
                self.notifier.forEach { $0.drawerView(self, didEndAnimationToState: position)}
                completion()
            }
        }
    }

    private func handleDrawerPosition(_ position: State,
                                      fastUpdate: Bool,
                                      animated: Bool,
                                      completion: @escaping EmptyClosure) {
        switch position {
        case .top:
            drawerHeight = maxDrawerPosition
            updateDrawerPosition(position, fastUpdate: fastUpdate, animated: animated, completion: completion)

        case .middle:
            drawerHeight = midDrawerPosition
            updateDrawerPosition(position, fastUpdate: fastUpdate, animated: animated, completion: completion)

        case .bottom:
            drawerHeight = minDrawerPosition
            updateDrawerPosition(position, fastUpdate: fastUpdate, animated: animated, completion: completion)

        case .custom(let height):
            drawerHeight = height
            updateDrawerPosition(position, fastUpdate: fastUpdate, animated: animated, completion: completion)

        case .dismissed:
            guard drawerHeight != 0 else {
                completion()
                return
            }

            drawerHeight = 0

            UIView.animate(withDuration: animationDuration, animations: {
                self.backgroundView.alpha = 0
                self.updateDrawer(with: self.containerView.frame.size)
            }, completion: { _ in
                self.notifier.forEach { $0.drawerView(self, didEndAnimationToState: position)}
                self.containerView.isHidden = true
                completion()
            })
        }
    }

    private func setupViews() {
        backgroundView.alpha = 0

        addSubview(backgroundView)
        NSLayoutConstraint.activate([
            backgroundView.leftAnchor.constraint(equalTo: self.leftAnchor),
            backgroundView.rightAnchor.constraint(equalTo: self.rightAnchor),
            backgroundView.topAnchor.constraint(equalTo: self.topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])

        if configuration.showHeader {
            containerView.addSubview(headerView)
        }
        addSubview(containerView)

        setupGestureRecognizer()
        setupConstraints()

        cornerRadius = DrawerConstants.cornerRadius
    }

    private func setupConstraints() {
        let origin = CGPoint(x: 0, y: Metrics.Sizes.screenSize.height)
        let size = CGSize(width: Metrics.Sizes.screenSize.width, height: 0)
        containerView.frame = CGRect(origin: origin, size: size)

        if configuration.showHeader {
            headerView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                headerView.leftAnchor.constraint(equalTo: leftAnchor),
                headerView.rightAnchor.constraint(equalTo: rightAnchor),
                headerView.topAnchor.constraint(equalTo: topAnchor),
                headerView.heightAnchor.constraint(greaterThanOrEqualToConstant: DrawerConstants.cornerRadius),
                headerView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor)
            ])
        }
    }

    private func updateDrawer(with oldSize: CGSize) {
        let origin = CGPoint(x: 0, y: Metrics.Sizes.screenSize.height - drawerHeight)
        containerView.frame = CGRect(origin: origin, size: oldSize)
    }
}

extension DrawerOverlayView {
    var headerHeight: CGFloat {
        return headerView.frame.height
    }

    var shouldDrag: Bool {
        return drawerHeight < maxDrawerPosition
    }
}

extension DrawerOverlayView {
    func addListener(_ listener: DrawerOverlayViewListener) {
        notifier.subscribe(listener)
    }

    func removeListener(_ listener: DrawerOverlayViewListener) {
        notifier.unsubscribe(listener)
    }
}

extension DrawerOverlayView {

    func setHeader(view: UIView) {
        headerView.addHeader(view: view)
    }

    func setCustomHeaderColor(color: UIColor) {
        headerView.setBlurViewColor(color)
    }

    func setNeedChangeHeaderAlpha(needChage: Bool) {
        self.needChangeHeaderAlpha = needChage
    }

    func clearBackgroundColor() {
        self.backgroundView.backgroundColor = .clear
    }
}
