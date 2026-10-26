import UIKit
import WebKit
import RTRootNavigationController_Swift

final class DemoNavigationBar: UINavigationBar {
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.borderColor = UIColor.systemPurple.cgColor
        layer.borderWidth = 2
    }
}

final class DemoPageController: UIViewController, RTNavigationCustomizing {
    enum Mode { case normal, disabledPop, hiddenBar, scroll, remove, customBar, transition, web, hiddenStatus, customBack, callback, interactivePush, stack }
    private let mode: Mode
    private let status = UILabel()
    private let fadeAnimator = DemoFadeAnimator()
    init(mode: Mode) { self.mode = mode; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { mode = .normal; super.init(coder: coder) }
    var navigationBarClass: UINavigationBar.Type? { mode == .customBar ? DemoNavigationBar.self : nil }
    var animatedTransitioning: UIViewControllerAnimatedTransitioning? { mode == .transition ? fadeAnimator : nil }
    override var prefersStatusBarHidden: Bool { mode == .hiddenStatus }
    override var preferredStatusBarStyle: UIStatusBarStyle { .darkContent }
    func customBackItem(target: Any, action: Selector) -> UIBarButtonItem? {
        guard mode == .customBack else { return nil }
        let configuration = UIImage.SymbolConfiguration(pointSize: 28, weight: .bold)
        let image = UIImage(systemName: "arrow.left.circle.fill", withConfiguration: configuration)?
            .imageFlippedForRightToLeftLayoutDirection()
        let item = UIBarButtonItem(image: image, style: .plain, target: target, action: action)
        item.tintColor = .systemBlue
        item.accessibilityLabel = "返回上一页"
        return item
    }
    func nextSiblingController() -> UIViewController? {
        mode == .interactivePush || mode == .hiddenBar ? DemoPageController(mode: .interactivePush) : nil
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "演示 · \(String(describing: mode))"
        view.backgroundColor = .systemBackground
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = mode == .normal ? .systemTeal : .secondarySystemBackground
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        if mode == .disabledPop { rt.isInteractivePopDisabled = true }
        if mode == .hiddenBar { rt.isInteractivePopDisabled = false }
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40)
        ])
        status.numberOfLines = 0
        status.font = .preferredFont(forTextStyle: .body)
        status.text = "每页拥有独立导航栏。\n右边缘拖动测试交互 push；左边缘测试返回。\n回调接管只作用于框架生成的返回按钮。"
        stack.addArrangedSubview(status)
        addButton("Push 下一页", action: #selector(pushNext), to: stack)
        addButton("程序化返回", action: #selector(popPage), to: stack)
        addButton("Pop 到根页面", action: #selector(popRoot), to: stack)
        addButton("关闭当前演示", action: #selector(closeDemo), to: stack)
        if mode == .remove { addButton("Push 后删除本页", action: #selector(pushAndRemove), to: stack) }
        if mode == .callback { addButton("启用返回接管", action: #selector(enableCallback), to: stack) }
        if mode == .stack { addButton("替换栈并 Pop 到指定页面", action: #selector(replaceStack), to: stack) }
        if mode == .scroll {
            navigationController?.navigationBar.prefersLargeTitles = true
            let scroll = UITextView()
            scroll.isEditable = false
            scroll.font = .preferredFont(forTextStyle: .body)
            scroll.text = (1...100).map { "第 \($0) 行：滚动检查导航栏与安全区域。" }.joined(separator: "\n")
            stack.addArrangedSubview(scroll)
            scroll.heightAnchor.constraint(equalToConstant: 180).isActive = true
        }
        if mode == .web {
            toolbarItems = [UIBarButtonItem(title: "返回首页", style: .plain, target: self, action: #selector(popRoot))]
            navigationController?.setToolbarHidden(false, animated: false)
            let web = WKWebView()
            web.loadHTMLString("<html><meta name='viewport' content='width=device-width'><body><h2>工具栏与网页演示</h2><p>本地内容，无网络依赖。</p></body></html>", baseURL: nil)
            stack.addArrangedSubview(web)
            web.heightAnchor.constraint(equalToConstant: 180).isActive = true
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(mode == .hiddenBar, animated: animated)
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if mode == .callback { rt.navigationController?.onBackCallback = nil }
    }
    private func addButton(_ title: String, action: Selector, to stack: UIStackView) {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.addTarget(self, action: action, for: .touchUpInside)
        stack.addArrangedSubview(button)
    }
    @objc private func pushNext() {
        let next = DemoPageController(mode: mode == .transition ? .transition : .normal)
        next.hidesBottomBarWhenPushed = true
        rt.navigationController?.pushViewController(next, animated: true) { [weak self] finished in self?.status.text = "Push 完成：\(finished)" }
    }
    @objc private func popPage() { rt.navigationController?.popViewController(animated: true) }
    @objc private func popRoot() { rt.navigationController?.popToRootViewController(animated: true) }
    @objc private func closeDemo() { dismiss(animated: true) }
    @objc private func pushAndRemove() {
        guard let root = rt.navigationController else { return }
        root.pushViewController(DemoPageController(mode: .normal), animated: true, removeCurrentViewController: true)
    }
    @objc private func enableCallback() {
        rt.navigationController?.onBackCallback = { [weak self] in
            guard let self else { return }
            let alert = UIAlertController(title: "返回已接管", message: "由调用方决定是否 pop。侧滑和程序化返回仍按原行为执行。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "留在本页", style: .cancel))
            alert.addAction(UIAlertAction(title: "返回", style: .default) { [weak self] _ in self?.rt.navigationController?.popViewController(animated: true) })
            self.present(alert, animated: true)
        }
        status.text = "已启用：点击导航栏返回按钮验证。"
    }
    @objc private func replaceStack() {
        guard let root = rt.navigationController, let first = root.rt.viewControllers.first else { return }
        let middle = DemoPageController(mode: .normal)
        root.setViewControllers([first, middle, self], animated: false)
        root.popToViewController(middle, animated: true) { finished in print("指定页面返回完成：\(finished)") }
    }
}

final class DemoFadeAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval { 0.3 }
    func animateTransition(using context: UIViewControllerContextTransitioning) {
        guard let to = context.view(forKey: .to), let controller = context.viewController(forKey: .to) else { context.completeTransition(false); return }
        to.frame = context.finalFrame(for: controller)
        context.containerView.addSubview(to)
        to.alpha = 0
        UIView.animate(withDuration: 0.3) { to.alpha = 1 } completion: { _ in
            to.alpha = 1
            if context.transitionWasCancelled { to.removeFromSuperview() }
            context.completeTransition(!context.transitionWasCancelled)
        }
    }
}
