import UIKit

class DrawerOverlayHeaderView: UIView {

//    var headerBlurAlpha: CGFloat {
//        get { _blurView.alpha }
//        set {
//            UIView.animate(withDuration: Constants.animationDurationSmall) {
//                self._blurView.alpha = newValue
//            }
//        }
//    }

    private var _dragAccessoryView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 2.5
        view.layer.masksToBounds = true
        return view
    }()

//    private var _blurView: BlurBackgroundView = {
//        let view = BlurBackgroundView()
//        view.alpha = 0
//        return view
//    }()

    private var _stackView: UIStackView = {
        let sv = UIStackView()
        sv.alignment = .fill
        sv.axis = .vertical
        sv.spacing = 16
        return sv
    }()

    var calculatedSize: CGSize {
        return CGSize(width: CGFloat.infinity, height: 12)
    }

    private var _dragAccessorySize = CGSize(width: 36, height: 5)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
    }

    private func setupViews() {
//        addSubview(_blurView)
//        _blurView.edgesToSuperview()

        _dragAccessoryView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(_dragAccessoryView)
        NSLayoutConstraint.activate([
            _dragAccessoryView.widthAnchor.constraint(equalToConstant: _dragAccessorySize.width),
            _dragAccessoryView.heightAnchor.constraint(equalToConstant: _dragAccessorySize.height),
            _dragAccessoryView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            _dragAccessoryView.topAnchor.constraint(equalTo: self.topAnchor, constant: 16)
        ])

        _stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(_stackView)
        NSLayoutConstraint.activate([
            _stackView.topAnchor.constraint(equalTo: _dragAccessoryView.bottomAnchor),
            _stackView.leftAnchor.constraint(equalTo: leftAnchor),
            _stackView.rightAnchor.constraint(equalTo: rightAnchor),
            _stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

extension DrawerOverlayHeaderView {
    func addHeader(view: UIView) {
        _stackView.addArrangedSubview(view)
        view.layoutIfNeeded()
    }

    func setAccessoryViewColor(_ color: UIColor) {
//        dragAccessoryViewColor = color
    }

    func setBlurViewColor(_ color: UIColor) {
//        _blurView.setCustomBlurColor(color: color)
    }
}
