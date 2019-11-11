//
//  ViewController.swift
//  RTRootNavigationController_Swift
//
//  Created by m17600026862@163.com on 03/14/2018.
//  Copyright (c) 2018 m17600026862@163.com. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    //展示列表
    var tableView: UITableView!
    
    //原始数据集
    let dataSource = ["Disable Interactive Pop", "Normal", "Navigationbar Hidden", "Push and remove"]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        title = "ROOT"
        
        tableView = UITableView(frame: view.frame, style:.plain)
        tableView.delegate = self
        tableView.dataSource = self
        //创建一个重用的单元格
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "MyCell")
        view.addSubview(tableView)
    }


}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identify = "MyCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identify, for: indexPath)
        cell.textLabel?.text = dataSource[indexPath.row]
        return cell
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            navigationController?.pushViewController(DisableInteractivePopController(), animated: true)
        case 1:
            navigationController?.pushViewController(NormalController(), animated: true)
        case 2:
            navigationController?.pushViewController(NavigationbarHiddenController(), animated: true)
        case 3:
            navigationController?.pushViewController(PushAndRemoveController(), animated: true)
        default:
            break
        }
    }
}






