import UIKit

extension DrawerOverlayView {

    func setupGestureRecognizer() {
        dragRecognizer = UIPanGestureRecognizer(target: self, action: #selector(dragRecognizerHandler))
        containerView.addGestureRecognizer(dragRecognizer)

        backgroundTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapBackgroundView(recognizer:)))
        backgroundView.addGestureRecognizer(backgroundTapRecognizer)
    }

    @objc func didTapBackgroundView(recognizer: UITapGestureRecognizer) {
        let state = self.enabledState.contains(.bottom) ? State.bottom : State.dismissed
        self.setDrawerPosition(state, animated: true, fastUpdate: true, completion: {

        })
    }

    @objc func dragRecognizerHandler(recognizer: UIPanGestureRecognizer) {
        let offset = recognizer.translation(in: containerView).y
        let velocity = recognizer.velocity(in: containerView).y

        switch recognizer.state {
        case .changed:
            let newHeight = max(0, min(maxDrawerPosition, drawerHeight - offset))
            dragDrawer(height: newHeight)
            recognizer.setTranslation(CGPoint.zero, in: containerView)

        case .ended:
            finalizeDrag(velocity: -velocity)

        case .cancelled:
            finalizeDrag(velocity: 0)

        default:
            break
        }

        containerView.endEditing(false)
    }

    func dragDrawer(height: CGFloat) {
        drawerHeight = height
        let origin = CGPoint(x: 0, y: Metrics.Sizes.screenSize.height - height)
        let size = CGSize(width: Metrics.Sizes.screenSize.width, height: height)
        containerView.frame = CGRect(origin: origin, size: size)
    }

    func finalizeDrag(velocity: CGFloat) {
        guard shouldDrag else { return }

        let targetHeight = drawerHeight + velocity * CGFloat(animationDuration)

        let midPositionIsEnabled = enabledState.contains(where: {$0 == .middle})
        let botPositionIsEnabled = enabledState.contains(where: {$0 == .bottom})

        if targetHeight > minDrawerPosition {
            if midPositionIsEnabled {
                if targetHeight > midDrawerPosition {
                    setDrawerPosition(.top) {}
                } else {
                    setDrawerPosition(.middle) {}
                }
            } else {
                setDrawerPosition(.top) {}
            }
        } else if botPositionIsEnabled {
            setDrawerPosition(.bottom) {}
        } else {
            setDrawerPosition(.dismissed) {}
        }
    }
}
