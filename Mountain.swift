//
//  Mountain.swift
//  GeoQuery
//
//  Created by Brian Heller on 12/16/15.
//  Copyright © 2015 Brian Heller. All rights reserved.
//

import UIKit

class Mountain: NSObject {
    var name:String
    var elevation:Int
    var latitude:Float
    var longitude:Float
    var distance:Int
    var probability:Double
    
    override init() {
        self.name = ""
        self.elevation = 0
        self.latitude = 0.0
        self.longitude = 0.0
        self.distance = 0
        self.probability = 0.0
        super.init()
    }
}
