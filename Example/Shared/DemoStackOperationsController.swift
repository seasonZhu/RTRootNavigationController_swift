import UIKit
import RTRootNavigationController_Swift

/// A、B、C 演示页的共用界面与流程，各字母使用独立的控制器类型。
class DemoStackOperationsController: UIViewController {
    enum Page: String {
        case a = "A", b = "B", c = "C"

        var color: UIColor {
            switch self {
            case .a: return .systemBlue
            case .b: return .systemOrange
            case .c: return .systemPurple
            }
        }
    }

    enum Scenario: CaseIterable {
        case pushCleanup, removeNames, popByName, popFallback

        var title: String {
            switch self {
            case .pushCleanup: return "A → B → C：Push 后移除 B"
            case .removeNames: return "A → B₁ → B₂ → C：批量移除 B"
            case .popByName: return "A₁ → B → A₂ → C：返回第一个 A"
            case .popFallback: return "A → B → C：找不到目标时退回 B"
            }
        }

        var pages: [Page] {
            switch self {
            case .removeNames: return [.a, .b, .b, .c]
            case .popByName: return [.a, .b, .a, .c]
            default: return [.a, .b, .c]
            }
        }

        var instructions: String {
            switch self {
            case .pushCleanup:
                return "逐页进入 A → B。在 B 点击进入 C 时，使用组合 Push 移除 B。最终为 A → C，再返回应直接看到蓝色 A。"
            case .removeNames:
                return "逐页进入 A → B₁ → B₂ → C。两个橙色 B 是同一控制器类的不同实例。在 C 按类名删除 B 后，应只剩 A → C。"
            case .popByName:
                return "逐页进入 A₁ → B → A₂ → C。两个蓝色 A 是同一控制器类的不同实例。在 C 按 A 的类名返回，应直达第一个 A₁，而非第二个 A₂。"
            case .popFallback:
                return "逐页进入 A → B → C。在 C 查找不存在的页面类名，应回退一页看到橙色 B，并显示完成回调。"
            }
        }

        func makePage(at index: Int) -> DemoStackOperationsController {
            switch pages[index] {
            case .a: return DemoStackPageAController(scenario: self, routeIndex: index)
            case .b: return DemoStackPageBController(scenario: self, routeIndex: index)
            case .c: return DemoStackPageCController(scenario: self, routeIndex: index)
            }
        }
    }

    private let scenario: Scenario
    private let routeIndex: Int
    private let stackLabel = UILabel()
    private let resultLabel = UILabel()
    private let actionButton = UIButton(type: .system)
    private var didRemovePages = false
    private var result = "按下面的按钮逐页前进，观察页面颜色和导航栈。"
    private var page: Page { scenario.pages[routeIndex] }
    private var pageName: String {
        let matching = scenario.pages.indices.filter { scenario.pages[$0] == page }
        guard matching.count > 1 else { return "页面 \(page.rawValue)" }
        let instance = scenario.pages.prefix(routeIndex + 1).filter { $0 == page }.count
        return "页面 \(page.rawValue) · 实例 \(instance)"
    }

    init(scenario: Scenario, routeIndex: Int) {
        self.scenario = scenario
        self.routeIndex = routeIndex
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("请通过场景初始化演示页面") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = pageName
        view.backgroundColor = page.color.withAlphaComponent(0.16)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = page.color.withAlphaComponent(0.24)
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "回到菜单", style: .plain, target: self, action: #selector(returnToMenu))

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -48)
        ])

        let heading = UILabel()
        heading.text = page.rawValue
        heading.font = UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: .systemFont(ofSize: 76, weight: .heavy))
        heading.textColor = page.color
        heading.adjustsFontForContentSizeCategory = true
        stack.addArrangedSubview(heading)
        let nameLabel = UILabel()
        nameLabel.text = pageName
        nameLabel.font = .preferredFont(forTextStyle: .largeTitle)
        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.numberOfLines = 0
        stack.addArrangedSubview(nameLabel)
        let classLabel = UILabel()
        classLabel.text = "控制器类：\(rt.className)"
        classLabel.font = .preferredFont(forTextStyle: .caption1)
        classLabel.numberOfLines = 0
        classLabel.textColor = .secondaryLabel
        stack.addArrangedSubview(classLabel)
        let instructions = UILabel()
        instructions.text = scenario.instructions
        for label in [instructions, stackLabel, resultLabel] {
            label.numberOfLines = 0
            label.font = .preferredFont(forTextStyle: .body)
            label.adjustsFontForContentSizeCategory = true
            stack.addArrangedSubview(label)
        }
        stackLabel.font = .preferredFont(forTextStyle: .headline)
        actionButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        actionButton.titleLabel?.numberOfLines = 0
        actionButton.titleLabel?.textAlignment = .center
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.backgroundColor = page.color
        actionButton.layer.cornerRadius = 12
        actionButton.contentEdgeInsets = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        actionButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 52).isActive = true
        actionButton.addTarget(self, action: #selector(performOperation), for: .touchUpInside)
        stack.addArrangedSubview(actionButton)
        let refresh = UIButton(type: .system)
        refresh.setTitle("刷新当前页面栈", for: .normal)
        refresh.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        refresh.addTarget(self, action: #selector(refreshStack), for: .touchUpInside)
        stack.addArrangedSubview(refresh)
        refreshStack()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshStack()
    }

    @objc private func performOperation() {
        guard let root = rt.navigationController else { return }
        if routeIndex < scenario.pages.count - 1 {
            let next = scenario.makePage(at: routeIndex + 1)
            if scenario == .pushCleanup, next.page == .c {
                let message = "操作：从 B Push 到 C，并移除 B。\n预期：菜单 → A → C；返回时直接看到蓝色 A。"
                next.result = message
                root.rt.viewControllers.compactMap { $0 as? DemoStackOperationsController }.forEach { $0.result = message }
                root.pushViewController(next, animated: true,
                                        removeViewControllerClassNameList: [rt.className],
                                        removeCurrentViewController: true)
            } else {
                root.pushViewController(next, animated: true)
            }
            return
        }
        switch scenario {
        case .pushCleanup:
            root.popViewController(animated: true)
        case .removeNames:
            if didRemovePages {
                root.popViewController(animated: true)
                return
            }
            let names = root.rt.viewControllers.compactMap { ($0 as? DemoStackPageBController)?.rt.className }
            root.removeViewControllerByClassNames(names, animated: false)
            didRemovePages = true
            let message = "已按 DemoStackPageBController 类名移除 B₁、B₂。\n预期：菜单 → A → C；返回时不会再经过橙色 B。"
            root.rt.viewControllers.compactMap { $0 as? DemoStackOperationsController }.forEach { $0.result = message }
            refreshStack()
        case .popByName, .popFallback:
            let destination: DemoStackOperationsController?
            let targetName: String
            if scenario == .popByName {
                destination = root.rt.viewControllers.first { $0 is DemoStackPageAController } as? DemoStackOperationsController
                targetName = destination?.rt.className ?? "DemoStackPageAController"
            } else {
                destination = root.rt.viewControllers.dropLast().last as? DemoStackOperationsController
                targetName = "MissingDemoController"
            }
            root.popToViewController(className: targetName, animated: true) { [weak destination] finished in
                guard let destination else { return }
                destination.result = "完成回调：\(finished)\n\(targetName)\n已回到\(destination.pageName)。"
                destination.refreshStack()
            }
        }
    }

    @objc private func refreshStack() {
        let pages = rt.navigationController?.rt.viewControllers ?? []
        let names = pages.map { controller in
            if let demo = controller as? DemoStackOperationsController {
                return demo.pageName + (demo === self ? "（当前）" : "")
            }
            return controller is DemoMenuController ? "菜单" : controller.rt.className
        }
        stackLabel.text = "当前栈 · \(pages.count) 页\n" + names.joined(separator: " → ")
        resultLabel.text = result
        if routeIndex < scenario.pages.count - 1 {
            let next = scenario.pages[routeIndex + 1].rawValue
            let suffix = scenario == .pushCleanup && page == .b ? "，同时移除 B" : ""
            actionButton.setTitle("进入页面 \(next)\(suffix)", for: .normal)
        } else {
            switch scenario {
            case .pushCleanup: actionButton.setTitle("返回 A，验证 B 已移除", for: .normal)
            case .removeNames: actionButton.setTitle(didRemovePages ? "返回 A，验证两个 B 已移除" : "按类名移除全部橙色 B 页面", for: .normal)
            case .popByName: actionButton.setTitle("按 A 的类名返回蓝色 A₁", for: .normal)
            case .popFallback: actionButton.setTitle("查找不存在的类名，回退到 B", for: .normal)
            }
        }
    }

    @objc private func returnToMenu() {
        guard let root = rt.navigationController,
              let menu = root.rt.viewControllers.first(where: { $0 is DemoMenuController }) else { return }
        root.popToViewController(menu, animated: true)
    }
}
