//
//  SettingsController.swift
//  unicom_package_remain
//
//  Created by zhujl on 2/8/17.
//  Copyright © 2017 zhujl. All rights reserved.
//

import UIKit
import UnicomPackageRemain

class SettingsController : UIViewController, UITableViewDataSource, UITableViewDelegate {
    var userInfo : UserInfoApi = UserInfoApi(loadCredential: true, loadData: true)
    @IBOutlet weak var PhoneNumber: UITextField!
    @IBOutlet weak var AuthToken: UITextField!
    @IBOutlet weak var ShownItems: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        PhoneNumber.text = userInfo.PhoneNum
        AuthToken.text = userInfo.AuthToken
        
        ShownItems.tableFooterView = UIView()
        ShownItems.tableFooterView?.backgroundColor = UIColor.clear
        ShownItems.dataSource = self
        ShownItems.delegate = self
        ShownItems.setEditing(true, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        userInfo.PhoneNum = PhoneNumber.text!
        userInfo.AuthToken = AuthToken.text!
        
        if tableViewDataCache != nil {
            userInfo.ShowItems = tableViewDataCache!.map({ (item) -> ItemNameIsShow in
                return ItemNameIsShow(dataIsShow: item)
            })
        }
        
        let result = userInfo.saveCredential()
        print("Save Credential: \(result)")
    }
    
    @IBAction func ReadClipboard(_ sender: Any) {        
        if let clipboard = UIPasteboard.general.string {
            do {
                let pattern = "a_token=([A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+)\\b"
                let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
                if let match = regex.firstMatch(in: clipboard, options: [], range: NSMakeRange(0, clipboard.characters.count)) {
                    AuthToken.text = (clipboard as NSString).substring(with: match.rangeAt(1))
                    return
                }
            } catch {
                print(error)
            }
            
            do {
                let pattern = "^([A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+)$"
                let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
                if regex.numberOfMatches(in: clipboard, options: [], range: NSMakeRange(0, clipboard.characters.count)) != 0 {
                    AuthToken.text = clipboard
                    return
                }
            } catch {
                print(error)
            }
            
            let alert = UIAlertController(title: nil, message: "未从剪贴板中找到登录Token", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "好的", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    var tableViewDataCache : [UserInfoDataIsShow]?
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableViewDataCache = userInfo.dataByShownItems(defaultStatus: true, filterShown: false)
        return tableViewDataCache?.count ?? 0
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! ShownItemsTableCell
        if let dataShow = tableViewDataCache?[indexPath.row] {
            cell.Label?.text = dataShow.data.remainTitle
            cell.Switch?.isOn = dataShow.isShow
            cell.dataBind = dataShow
        } else {
            cell.Label?.text = "未知项目"
            cell.Switch?.isOn = false
        }
        return cell
    }
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .none
    }
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if sourceIndexPath.row == destinationIndexPath.row {
            return
        }
        if tableViewDataCache != nil {
            swap(&tableViewDataCache![sourceIndexPath.row], &tableViewDataCache![destinationIndexPath.row])
        }
    }
}

class ShownItemsTableCell : UITableViewCell {
    @IBOutlet weak var Label: UILabel!
    @IBOutlet weak var Switch: UISwitch!
    
    var dataBind : UserInfoDataIsShow?
    
    @IBAction func switchChange(_ sender: Any) {
        if dataBind != nil {
            dataBind!.isShow = Switch!.isOn
        }
    }
}
