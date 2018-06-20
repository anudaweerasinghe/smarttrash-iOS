import Foundation
import ObjectMapper


class Bin : NSObject, NSCoding, Mappable{
    
    var activeStatus : Int?
    var id : Int?
    var info : String?
    var lat : Double?
    var lng : Double?
    var name : String?
    
    
    class func newInstance(map: Map) -> Mappable?{
        return Bin()
    }
    required init?(map: Map){}
    private override init(){}
    
    func mapping(map: Map)
    {
        activeStatus <- map["activeStatus"]
        id <- map["id"]
        info <- map["info"]
        lat <- map["lat"]
        lng <- map["lng"]
        name <- map["name"]
        
    }
    
    /**
     * NSCoding required initializer.
     * Fills the data from the passed decoder
     */
    @objc required init(coder aDecoder: NSCoder)
    {
        activeStatus = aDecoder.decodeObject(forKey: "activeStatus") as? Int
        id = aDecoder.decodeObject(forKey: "id") as? Int
        info = aDecoder.decodeObject(forKey: "info") as? String
        lat = aDecoder.decodeObject(forKey: "lat") as? Double
        lng = aDecoder.decodeObject(forKey: "lng") as? Double
        name = aDecoder.decodeObject(forKey: "name") as? String
        
    }
    
    /**
     * NSCoding required method.
     * Encodes mode properties into the decoder
     */
    @objc func encode(with aCoder: NSCoder)
    {
        if activeStatus != nil{
            aCoder.encode(activeStatus, forKey: "activeStatus")
        }
        if id != nil{
            aCoder.encode(id, forKey: "id")
        }
        if info != nil{
            aCoder.encode(info, forKey: "info")
        }
        if lat != nil{
            aCoder.encode(lat, forKey: "lat")
        }
        if lng != nil{
            aCoder.encode(lng, forKey: "lng")
        }
        if name != nil{
            aCoder.encode(name, forKey: "name")
        }
        
    }
    
}
