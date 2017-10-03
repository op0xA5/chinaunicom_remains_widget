//
//  RemainsController.swift
//  unicom_package_remain
//
//  Created by zhujl on 2/8/17.
//  Copyright © 2017 zhujl. All rights reserved.
//

import UIKit
import UnicomPackageRemain

class RemainsController : UITableViewController {
    var userInfo : UserInfoApi = UserInfoApi()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userInfo.loadCredential()
        
        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: #selector(RemainsController.refreshControlRefresh), for: UIControlEvents.valueChanged)
        //refreshControl!.attributedTitle = NSAttributedString(string: "松开刷新")
        tableView.addSubview(refreshControl!)
        
        refreshData()
    }
    override func viewWillAppear(_ animated: Bool) {
        userInfo.loadCredential()
    }
    
    @IBOutlet weak var dataRefreshDateLabel: UILabel!
    func refreshData(forceFetch: Bool = false) {
        if refreshControl!.isRefreshing {
            refreshControl?.beginRefreshing()
        }
        if !userInfo.canFetchData() {
            self.dataRefreshDateLabel.text = ""
            return
        }
        let callback = { (ok: Bool) in
            if !ok {
                DispatchQueue.main.async {
                    self.dataRefreshDateLabel.text = self.userInfo.canFetchData() ? "更新失败" : ""
                    self.tableView.reloadData()
                    self.refreshControl?.endRefreshing()
                }
            }
            if ok {
                DispatchQueue.main.async {
                    if let flushTime = self.userInfo.data?.flushDateTime {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "更新时间: yyyy-MM-dd HH:mm"
                        self.dataRefreshDateLabel.text = formatter.string(from: flushTime)
                    } else {
                        self.dataRefreshDateLabel.text = "更新失败"
                    }
                    
                    self.tableView.reloadData()
                    self.refreshControl?.endRefreshing()
                }
            }

        }
        if forceFetch {
            userInfo.fetchData(finish: callback)
        } else {
            userInfo.loadData(autoFetch: true, finish: callback)
        }
    }
    func refreshControlRefresh() {
        refreshData(forceFetch: true)
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !userInfo.canFetchData() {
            return 1
        }
        return userInfo.data?.data?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if !userInfo.canFetchData() {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PleaseConfig", for: indexPath)
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "PackageItem", for: indexPath) as! RemainsTableCell
        
        let data = userInfo.data?.data?[indexPath.row] ?? UserInfoData()
        cell.setData(data)
    
        return cell
    }
}

class RemainsTableCell : UITableViewCell {
    @IBOutlet weak var remainTitle: UILabel!
    @IBOutlet weak var number: UILabel!
    @IBOutlet weak var persent: UIProgressView!
    @IBOutlet weak var usedTitle: UILabel!
    
    func setData(_ data: UserInfoData) {
        remainTitle.text = data.remainTitle
        persent.progress = data.persent / 100
        usedTitle.text = data.usedTitle
        number.text = "\(data.numberStr) \(data.unit)"
    }
}
