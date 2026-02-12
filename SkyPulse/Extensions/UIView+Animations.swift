import UIKit

/// Набор переиспользуемых анимаций для UI-элементов.
extension UIView {

    /// Плавное появление (alpha 0 → 1)
    func fadeIn(duration: TimeInterval = 0.3, delay: TimeInterval = 0, completion: VoidClosure? = nil) {
        alpha = 0
        UIView.animate(withDuration: duration, delay: delay, options: .curveEaseInOut) {
            self.alpha = 1
        } completion: { _ in
            completion?()
        }
    }

    /// Плавное исчезновение (alpha 1 → 0)
    func fadeOut(duration: TimeInterval = 0.3, delay: TimeInterval = 0, completion: VoidClosure? = nil) {
        UIView.animate(withDuration: duration, delay: delay, options: .curveEaseInOut) {
            self.alpha = 0
        } completion: { _ in
            completion?()
        }
    }

    /// Пружинная анимация масштаба (для кнопки "избранное")
    func bounce(scale: CGFloat = 1.2, duration: TimeInterval = 0.15) {
        UIView.animate(
            withDuration: duration,
            animations: { self.transform = CGAffineTransform(scaleX: scale, y: scale) },
            completion: { _ in
                UIView.animate(withDuration: duration) {
                    self.transform = .identity
                }
            }
        )
    }

    /// Появление со сдвигом снизу
    func slideInFromBottom(duration: TimeInterval = 0.4, offset: CGFloat = 50) {
        let originalTransform = transform
        transform = originalTransform.translatedBy(x: 0, y: offset)
        alpha = 0

        UIView.animate(
            withDuration: duration,
            delay: 0,
            usingSpringWithDamping: AppConfiguration.cardSpringDamping,
            initialSpringVelocity: 0.5,
            options: .curveEaseOut
        ) {
            self.transform = originalTransform
            self.alpha = 1
        }
    }

    /// Анимация тряски (для ошибок ввода)
    func shake(intensity: CGFloat = 10, duration: TimeInterval = 0.5) {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.duration = duration
        animation.values = [-intensity, intensity, -intensity * 0.6, intensity * 0.6, 0]
        layer.add(animation, forKey: "shake")
    }

    /// Анимация пульсации (для индикаторов live-статуса)
    func pulse(duration: TimeInterval = 1.0) {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1.0
        animation.toValue = 0.4
        animation.duration = duration
        animation.autoreverses = true
        animation.repeatCount = .infinity
        layer.add(animation, forKey: "pulse")
    }

    func stopPulse() {
        layer.removeAnimation(forKey: "pulse")
    }
}
