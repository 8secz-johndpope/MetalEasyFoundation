//
//  BaseListModel.swift
//  MetalEasyFoundation
//
//  Created by LFZ on 2019/6/3.
//  Copyright © 2019 LFZ. All rights reserved.
//

import UIKit

// MARK: -
@objcMembers
class BaseListModel: NSObject {
    
    /** 属性 */
    public var data:[BaseListModel] = []
    
    public var title:String = ""
    public var action:(() -> ())?
    
    
    /** 自定义构造函数 */
    init(_ dict : [String: Any]){
        super.init()
        setValuesForKeys(dict)
    }
    override func setValue(_ value: Any?, forKey key: String) {
        
        if key == "data" {
            
            for dic in value as? [Any] ?? [] {
             
                let model = BaseListModel(dic as? [String : Any] ?? [:])
                data.append(model)
             }
        } else {
            super.setValue(value, forKey: key)
        }
    }
    override func setValue(_ value: Any?, forUndefinedKey key: String) {}
}