import UIKit
import RTRootNavigationController_Swift

final class DemoMenuController: UITableViewController {
    private let scenarios: [(String, DemoPageController.Mode)] = [
        ("普通页面与独立外观", .normal), ("禁用交互返回", .disabledPop),
        ("隐藏导航栏与交互 push", .hiddenBar), ("滚动列表与大标题", .scroll),
        ("Push 后移除当前页", .remove), ("自定义导航栏类", .customBar),
        ("自定义转场", .transition), ("工具栏与网页", .web),
        ("隐藏状态栏", .hiddenStatus), ("自定义返回按钮", .customBack),
        ("返回回调接管", .callback), ("交互 push 完成与取消", .interactivePush),
        ("栈替换与完成回调", .stack)
    ]
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Swift 导航演示"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "集成信息", style: .plain, target: self, action: #selector(showIntegration))
    }
    override func numberOfSections(in tableView: UITableView) -> Int { 3 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return scenarios.count
        case 1: return 5
        default: return DemoStackOperationsController.Scenario.allCases.count
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        ["页面与转场", "容器与兼容", "按类名管理导航栈"][section]
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        switch indexPath.section {
        case 0:
            cell.textLabel?.text = scenarios[indexPath.row].0
        case 1:
            cell.textLabel?.text = ["系统返回按钮", "显式外观继承", "TabBar 中分别嵌套根导航", "根导航包裹 TabBar", "Storyboard 与 unwind"][indexPath.row]
        default:
            cell.textLabel?.text = DemoStackOperationsController.Scenario.allCases[indexPath.row].title
        }
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            navigationController?.pushViewController(DemoPageController(mode: scenarios[indexPath.row].1), animated: true)
            return
        }
        if indexPath.section == 2 {
            let scenario = DemoStackOperationsController.Scenario.allCases[indexPath.row]
            rt.navigationController?.pushViewController(scenario.makePage(at: 0), animated: true)
            return
        }
        switch indexPath.row {
        case 0:
            let root = RTRootNavigationController(rootViewController: DemoPageController(mode: .normal))
            root.useSystemBackBarButtonItem = true
            presentDemo(root)
        case 1:
            let root = RTRootNavigationController(rootViewController: DemoPageController(mode: .normal))
            root.transferNavigationBarAttributes = true
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .systemOrange
            root.navigationBar.standardAppearance = appearance
            root.navigationBar.scrollEdgeAppearance = appearance
            presentDemo(root)
        case 2, 3:
            let tab = UITabBarController()
            let pages = [DemoPageController(mode: .normal), DemoPageController(mode: .hiddenStatus)]
            for (index, page) in pages.enumerated() { page.tabBarItem = UITabBarItem(title: "分栏 \(index + 1)", image: UIImage(systemName: "square.stack"), tag: index) }
            if indexPath.row == 2 {
                tab.viewControllers = pages.map { RTRootNavigationController(rootViewController: $0) }
                presentDemo(tab)
            } else {
                tab.viewControllers = pages.map { RTContainerNavigationController(rootViewController: $0) }
                presentDemo(RTRootNavigationController(rootViewControllerNoWrapping: tab))
            }
        default:
            let storyboard = UIStoryboard(name: "UnwindFixture", bundle: .main)
            if let root = storyboard.instantiateInitialViewController() { presentDemo(root) }
        }
    }
    private func presentDemo(_ controller: UIViewController) {
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true)
    }
    @objc private func showIntegration() {
        #if DEMO_COCOAPODS
        let integration = "CocoaPods 本地路径集成"
        #else
        let integration = "SPM 本地包集成"
        #endif
        let alert = UIAlertController(title: integration, message: "所有场景共用 Swift 演示源码。\n交互 push：从右边缘向左拖动，松手完成或取消。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}
