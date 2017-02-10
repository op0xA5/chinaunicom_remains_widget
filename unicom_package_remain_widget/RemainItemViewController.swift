//
//  RemainItemViewController.swift
//  unicom_package_remain
//
//  Created by zhujl on 2/9/17.
//  Copyright © 2017 zhujl. All rights reserved.
//

import UIKit
import UnicomPackageRemain

class RemainItemViewController: UIViewController {
    var data : UserInfoData?
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    convenience init() {
        self.init(nibName: "RemainItemViewController", bundle: nil)
    }
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(data: UserInfoData) {
        self.init()
        self.data = data
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        if data != nil {
            setData(data!)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBOutlet weak var remainTitle: UILabel!
    @IBOutlet weak var remainNum: UILabel!
    @IBOutlet weak var progress: UIProgressView!
    func setData(_ data: UserInfoData){
        self.data = data
        
        //DispatchQueue.main.async {
            self.remainTitle.text = data.remainTitle
            self.remainNum.text = "\(data.numberStr) \(data.unit)"
            self.progress.progress = data.persent / 100
        //}
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
