//
//  TodayViewController.swift
//  unicom_package_remain_widget
//
//  Created by zhujl on 2/9/17.
//  Copyright © 2017 zhujl. All rights reserved.
//

import UIKit
import NotificationCenter
import UnicomPackageRemain

class TodayViewController: UIViewController, NCWidgetProviding {
    var userInfo : UserInfoApi = UserInfoApi(loadCredential: true, loadData: true)
    var lastUpdateTime : Date = Date(timeIntervalSince1970: 0)
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var refreshTime: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
        
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 12        
        
        updateRemainData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData

        var updated = false        
        userInfo.loadData(autoFetch: true, willFetch: { () -> Bool in
            DispatchQueue.main.async {
                self.activityIndicator.startAnimating()
            }
            return true
        }) { ( ok ) in
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
            }
            if ok {
                if let flushTime = self.userInfo.data?.flushDateTime {
                    updated = flushTime > self.lastUpdateTime
                    self.lastUpdateTime = flushTime
                }
                self.updateRemainData()
                completionHandler(updated ? NCUpdateResult.newData : NCUpdateResult.noData)
                return
            }
            completionHandler(NCUpdateResult.failed)
        }
    }

    var subviewControllers : [RemainItemViewController]?
    func updateRemainData() {
        DispatchQueue.main.async {
            if let items = self.userInfo.dataByShownItems(defaultStatus: true, filterShown: true) {
                if self.subviewControllers == nil {
                    self.subviewControllers = [RemainItemViewController]()
                }
                
                for i in 0 ..< min(self.subviewControllers!.count, items.count) {
                    self.subviewControllers![i].setData(items[i].data)
                }
                if self.stackView.arrangedSubviews.count > items.count {
                    for subview in self.stackView.arrangedSubviews[items.count ..< self.stackView.arrangedSubviews.count] {
                        self.stackView.removeArrangedSubview(subview)
                    }
                } else if self.stackView.arrangedSubviews.count < items.count {
                    if self.subviewControllers!.count < items.count {
                        for item in items[self.subviewControllers!.count ..< items.count] {
                            self.subviewControllers!.append(RemainItemViewController(data: item.data))
                        }
                    }
                    for subviewCtrl in self.subviewControllers![self.stackView.arrangedSubviews.count ..< items.count] {
                        self.stackView.addArrangedSubview(subviewCtrl.view)
                    }
                }
            }
            
            if let flushTime = self.userInfo.data?.flushDateTime {
                let formatter = DateFormatter()
                formatter.dateFormat = "更新时间: yyyy-MM-dd HH:mm"
                self.refreshTime.setTitle(formatter.string(from: flushTime), for: UIControlState.normal)
            } else {
                self.refreshTime.setTitle("点击更新", for: UIControlState.normal)
            }
        }
    }
    @IBAction func refreshTimeClick(_ sender: Any) {
        self.activityIndicator.startAnimating()
        userInfo.fetchData { (ok) in
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
            }
            if ok {
                if let flushTime = self.userInfo.data?.flushDateTime {
                    self.lastUpdateTime = flushTime
                }
                self.updateRemainData()
            }
        }
    }
    
}
