import UIKit
import RTRootNavigationController_Swift

@objc(StoryboardRootController) final class StoryboardRootController: UIViewController {
    @IBAction func returnToRoot(_ segue: UIStoryboardSegue) { title = "Unwind 已返回" }
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Storyboard 根页面"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "关闭", style: .plain, target: self, action: #selector(close))
    }
    @objc private func close() { dismiss(animated: true) }
}
@objc(StoryboardDetailController) final class StoryboardDetailController: UIViewController {}
