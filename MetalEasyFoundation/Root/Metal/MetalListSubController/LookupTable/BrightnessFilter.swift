//
//  BrightnessFilter.swift
//  MetalEasyFoundation
//
//  Created by LangFZ on 2019/7/10.
//  Copyright © 2019 LFZ. All rights reserved.
//

public class BrightnessFilter: BasicOperation {
    
    public var brightness: Float = 0.0 {
        didSet {
            uniformSettings["brightness"] = brightness
        }
    }
    
    public init() {
        super.init(fragmentFunctionName: "brightnessMetalFragment", numberOfInputs: 1)
        ({brightness = 0.0})()
    }
}
