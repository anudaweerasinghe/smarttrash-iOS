//
//  NearestBin.swift
//  SmartTrash
//
//  Created by Anuda Weerasinghe on 6/16/18.
//  Copyright © 2018 Anuda Weerasinghe. All rights reserved.
//

import Foundation
import ObjectMapper


class NearestBin : NSObject, NSCoding, Mappable{
    
    var bin : Bin?
    var distance : Double?
    
    
    class func newInstance(map: Map) -> Mappable?{
        return NearestBin()
    }
    required init?(map: Map){}
    private override init(){}
    
    func mapping(map: Map)
    {
        bin <- map["bin"]
        distance <- map["distance"]
        
    }
    
    /**
     * NSCoding required initializer.
     * Fills the data from the passed decoder
     */
    @objc required init(coder aDecoder: NSCoder)
    {
        bin = aDecoder.decodeObject(forKey: "bin") as? Bin
        distance = aDecoder.decodeObject(forKey: "distance") as? Double
        
    }
    
    /**
     * NSCoding required method.
     * Encodes mode properties into the decoder
     */
    @objc func encode(with aCoder: NSCoder)
    {
        if bin != nil{
            aCoder.encode(bin, forKey: "bin")
        }
        if distance != nil{
            aCoder.encode(distance, forKey: "distance")
        }
        
    }
    
}
