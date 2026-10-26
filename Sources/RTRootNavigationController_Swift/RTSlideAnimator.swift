import UIKit

/// 内建交互 push 的滑动动画，只使用公开 UIKit API。
final class RTSlideAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let direction: CGFloat

    init(direction: CGFloat) { self.direction = direction }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval { 0.35 }

    func animateTransition(using context: UIViewControllerContextTransitioning) {
        guard let from = context.viewController(forKey: .from), let to = context.viewController(forKey: .to),
              let fromView = context.view(forKey: .from), let toView = context.view(forKey: .to) else {
            context.completeTransition(false)
            return
        }
        let container = context.containerView
        let fromTransform = fromView.transform, toTransform = toView.transform

        fromView.frame = context.initialFrame(for: from)
        toView.frame = context.finalFrame(for: to)
        container.addSubview(toView)
        let width = container.bounds.width
        toView.transform = CGAffineTransform(translationX: -direction * width, y: 0)
        UIView.animate(withDuration: transitionDuration(using: context), delay: 0, options: [.curveLinear]) {
            fromView.transform = CGAffineTransform(translationX: self.direction * width * 0.3, y: 0)
            toView.transform = toTransform
        } completion: { _ in
            fromView.transform = fromTransform
            toView.transform = toTransform
            let finished = !context.transitionWasCancelled
            if !finished { toView.removeFromSuperview() }
            context.completeTransition(finished)
        }
    }
}
