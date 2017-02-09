//  UserInfoApi.swift
//  unicom_package_remain
//
//  Created by zhujl on 2/8/17.
//  Copyright © 2017 zhujl. All rights reserved.
//

import Foundation

public class UserInfoApi {
    public var data : UserInfo?
    
    public let SuiteName = "group.com.zhujinliang.ios.unicom_package_remain"
    
    public let ApiUrl : String = "http://m.client.10010.com/mobileService/home/queryUserInfoFive.htm?desmobiel={phone}&showType=1&version=iphone_c@5.01"
    
    public let autoRefreshInterval : TimeInterval = 5 * 60
    
    public var PhoneNum : String = ""
    public var AuthToken : String = ""
    public var AuthCookie : String = ""
    public var ShowItems : [ItemNameIsShow]?
    
    public init() {
        
    }
    public init(loadCredential: Bool, loadData: Bool) {
        if loadCredential {
            self.loadCredential()
        }
        if loadData {
            self.loadData()
        }
    }
    public init(data: UserInfo) {
        self.data = data
    }
    public init(json: String) {
        _ = parseJson(json)
    }
    
    public func parseJson(_ json: String) -> Bool {
        data = UserInfo()
        if json == "" {
            return false
        }
        do{
            var res : Any
            try res = JSONSerialization.jsonObject(with: json.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions())
            
            if let resDict = res as? Dictionary<String, Any> {
                data!.code = (resDict["code"] as? String) ?? ""
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "截至 yyyy-MM-dd HH:mm"
                data!.flushDateTime = dateFormatter.date(from: (resDict["flush_date_time"] as? String) ?? "") ?? Date(timeIntervalSince1970: 0)
                
                if let resDataDict = resDict["data"] as? Dictionary<String, Any> {
                    if let resDataListDict = resDataDict["dataList"] as? [Dictionary<String, Any>] {
                        data!.data = [UserInfoData]()
                        
                        for var resItemDict in resDataListDict {
                            var item = UserInfoData()
                            item.unit = (resItemDict["unit"] as? String) ?? ""
                            item.persent = Float((resItemDict["persent"] as? String) ?? "") ?? 0
                            item.number = Float((resItemDict["number"] as? String) ?? "") ?? 0
                            item.numberStr = (resItemDict["number"] as? String) ?? ""
                            item.usedTitle = (resItemDict["usedTitle"] as? String) ?? ""
                            item.remainTitle = (resItemDict["remainTitle"] as? String) ?? ""
                            data!.data!.append(item)
                        }
                    }
                }
            }
        } catch {
            print(error)
            return false
        }
        return true
    }
    
    public func loadCredential() {
        let userDefaults = UserDefaults(suiteName: SuiteName)
        if userDefaults == nil {
            return
        }
        
        PhoneNum = userDefaults!.string(forKey: "phoneNum") ?? ""
        AuthToken = userDefaults!.string(forKey: "authToken") ?? ""
        AuthCookie = userDefaults!.string(forKey: "authCookie") ?? ""
        
        let json = userDefaults!.string(forKey: "showItems") ?? ""
        do{
            var res : Any
            try res = JSONSerialization.jsonObject(with: json.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions())
            
            if let resDict = res as? [Dictionary<String, Any>] {
                ShowItems = resDict.map({ (item) -> ItemNameIsShow in
                    return ItemNameIsShow(name: item["name"] as? String ?? "", isShow: item["isShow"] as? Bool ?? false)
                })
            }
        } catch {
            print(error)
        }
        
    }
    public func saveCredential() -> Bool {
        let userDefaults = UserDefaults(suiteName: SuiteName)
        if userDefaults == nil {
            return false
        }
        
        userDefaults!.set(PhoneNum, forKey: "phoneNum")
        userDefaults!.set(AuthToken, forKey: "authToken")
        userDefaults!.set(AuthCookie, forKey: "authCookie")
        
        if let itemShow = self.ShowItems {
            let resDict = itemShow.map({ (item) -> Dictionary<String, Any> in
                return [
                    "name" : item.name,
                    "isShow" : item.isShow,
                    ] as Dictionary<String, Any>
            })
            do{
                var json : Data
                try json = JSONSerialization.data(withJSONObject: resDict, options: JSONSerialization.WritingOptions())
                let jsonStr = String.init(data: json, encoding: .utf8)
                userDefaults!.set(jsonStr, forKey: "showItems")
            } catch {
                print(error)
            }
        }
        
        return true
    }
    public func loadData() {
        loadData(autoFetch: false, finish: { (ok) in
        })
    }
    public func loadData(autoFetch: Bool, finish: @escaping (Bool) -> Void) {
        loadData(autoFetch: autoFetch, willFetch: { () -> Bool in
            return true
        }, finish: finish)
    }
    public func loadData(autoFetch: Bool, willFetch: @escaping () -> Bool, finish: @escaping (Bool) -> Void) {
        let userDefaults = UserDefaults(suiteName: SuiteName)
        if userDefaults == nil {
            finish(false)
            return
        }
        
        let jsonStr = userDefaults!.string(forKey: "cacheData") ?? ""
        print("Read Cached Data: \(jsonStr)")
        if !parseJson(jsonStr) {
            if autoFetch {
                if willFetch() {
                    fetchData(finish: finish)
                }
            } else {
                finish(false)
            }
            return
        }
        
        if autoFetch {
            let refreshDate = data?.flushDateTime ?? Date(timeIntervalSince1970: 0)
            let refreshInterval = abs(refreshDate.timeIntervalSinceNow)
            print("Refresh Interval: \(refreshInterval) / \(autoRefreshInterval)")
            if refreshInterval > autoRefreshInterval {
                if willFetch() {
                    fetchData(finish: finish)
                }
                // return
            }
        }
        finish(true)
    }
    public func fetchData(finish: @escaping (Bool) -> Void) {
        if !canFetchData() {
            finish(false)
            return
        }
        
        let url = URL(string: ApiUrl.replacingOccurrences(of: "{phone}", with: PhoneNum))
        print("Fetch URL: \(url!.absoluteString)")
        
        var request = URLRequest(url: url!)
        request.httpMethod = "GET"
        /*
         var cookie = AuthCookie
         if cookie == "" {
         cookie = "a_token=\(AuthToken)"
         }
         */
        let cookie = "a_token=\(AuthToken)"
        request.setValue(cookie, forHTTPHeaderField: "Cookie")
        
        let session = URLSession(configuration: URLSessionConfiguration.default)
        let task = session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print("Fetch Error: \(error.debugDescription)")
                finish(false)
                return
            }
            if response == nil {
                print("Fetch Error: Empty Response")
                finish(false)
                return
            }
            let status = (response as! HTTPURLResponse).statusCode
            if  status != 200 {
                print("Fetch Error: status \(status)")
                finish(false)
                return
            }
            if data == nil {
                print("Fetch Error: Empty Data")
                finish(false)
                return
            }
            
            let fields = (response as! HTTPURLResponse).allHeaderFields as? [String : String]
            let cookies = HTTPCookie.cookies(withResponseHeaderFields: fields!, for: response!.url!)
            for cookie in cookies {
                if cookie.name == "a_token" {
                    self.AuthToken = cookie.value
                }
            }
            print("Update Credential: \(self.AuthToken)")
            _ = self.saveCredential()
            
            let jsonStr = String.init(data: data!, encoding: String.Encoding.utf8) ?? ""
            if !self.parseJson(jsonStr) {
                finish(false)
                return
            }
            _ = self.saveData()
            
            finish(true)
        }
        task.resume()
    }
    public func canFetchData() -> Bool {
        return PhoneNum != "" && AuthToken != "" && ApiUrl != ""
    }
    public func saveData() -> Bool {
        if data == nil {
            return false
        }
        var json : Data
        
        var resDataListDict = [Dictionary<String, Any>]()
        if data!.data != nil {
            for item in data!.data! {
                let resItemDict = [
                    "unit": item.unit,
                    "persent": String(item.persent),
                    "number": item.numberStr,
                    "usedTitle": item.usedTitle,
                    "remainTitle": item.remainTitle,
                    ] as Dictionary<String, Any>
                resDataListDict.append(resItemDict)
            }
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "截至 yyyy-MM-dd HH:mm"
        let flushDateStr = dateFormatter.string(from: data!.flushDateTime)
        let resDataDict = [
            "dataList" : resDataListDict,
            ] as Dictionary<String, Any>
        let resDict = [
            "data" : resDataDict,
            "code" : data!.code,
            "flush_date_time" : flushDateStr,
            ] as Dictionary<String, Any>
        
        do{
            try json = JSONSerialization.data(withJSONObject: resDict, options: JSONSerialization.WritingOptions())
        } catch {
            print(error)
            return false
        }
        
        let jsonStr = String.init(data: json, encoding: .utf8)
        
        let userDefaults = UserDefaults(suiteName: SuiteName)
        if userDefaults == nil {
            return false
        }
        print("Storage Cached Data: \(jsonStr!)")
        userDefaults!.set(jsonStr, forKey: "cacheData")
        return true
    }
    public func clearData() {
        let userDefaults = UserDefaults(suiteName: SuiteName)
        if userDefaults == nil {
            return
        }
        userDefaults!.set("", forKey: "cacheData")
    }
    
    public func dataByShownItems(defaultStatus: Bool, filterShown: Bool) -> [UserInfoDataIsShow]? {
        if ShowItems == nil {
            if filterShown == true && defaultStatus == false {
                return nil
            }
            return self.data?.data?.map({ (item) -> UserInfoDataIsShow in
                return UserInfoDataIsShow(data: item, isShow: defaultStatus)
            })
        }
        if let data = self.data?.data {
            var res = [UserInfoDataIsShow]()
            for showItem in ShowItems! {
                let find = data.first(where: { (item) -> Bool in
                    return item.remainTitle == showItem.name
                })
                if find != nil {
                    if !filterShown || showItem.isShow {
                        res.append(UserInfoDataIsShow(data: find!, isShow: showItem.isShow))
                    }
                }
            }
            if filterShown == true && defaultStatus == false {
                return res
            }
            for item in data {
                let find = ShowItems!.index(where: { (showItem) -> Bool in
                    return item.remainTitle == showItem.name
                })
                if find == nil {
                    res.append(UserInfoDataIsShow(data: item, isShow: defaultStatus))
                }
            }
            return res
        }
        return nil
    }
}
public struct ItemNameIsShow {
    public var name : String
    public var isShow : Bool
    
    public init(name: String, isShow: Bool) {
        self.name = name
        self.isShow = isShow
    }
    public init(dataIsShow: UserInfoDataIsShow) {
        self.name = dataIsShow.data.remainTitle
        self.isShow = dataIsShow.isShow
    }
    public init(data: UserInfoData, isShow: Bool) {
        self.name = data.remainTitle
        self.isShow = isShow
    }
}
public struct UserInfo {
    public var data : [UserInfoData]?
    public var code : String = ""
    public var flushDateTime: Date = Date(timeIntervalSince1970: 0)
}
public struct UserInfoData {
    public var unit : String = ""
    public var persent : Float = 0
    public var number : Float = 0
    public var numberStr : String = ""
    public var usedTitle : String = ""
    public var remainTitle : String = ""
    
    public init() {
        
    }
}
public class UserInfoDataIsShow {
    public var data : UserInfoData
    public var isShow : Bool
    
    public init(data: UserInfoData, isShow: Bool) {
        self.data = data
        self.isShow = isShow
    }
}
