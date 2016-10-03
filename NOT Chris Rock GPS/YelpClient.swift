//
//  YelpClient.swift
//  MyYelp
//
//  Created by Nhung Huynh on 7/15/16.
//  Copyright © 2016 Nhung Huynh. All rights reserved.
//

import UIKit
import OAuthSwift

// You can register for Yelp API keys here: http://www.yelp.com/developers/manage_api_keys
var yelpConsumerKey = "QhdjSyz8FU-asJy7PRr_Fw"
var yelpConsumerSecret = "vzYggBL0kTsF66MpaAQyu90g5wM"
var yelpToken = "N2fPmQ1netA-wY4BWd6TKCMCtkZPvtin"
var yelpTokenSecret = "IRdvdF6xe5roFhb-C4io4eBzMj0"

enum YelpSortMode: Int {
    case BestMatched = 0, Distance, HighestRated
}

class YelpClient : OAuthSwiftClient {
    
    var accessToken: String!
    var accessSecret: String!
    
    var location: String?
    
    class var sharedInstance : YelpClient? {
        struct Static {
            static var token : dispatch_once_t = 0
            static var instance : YelpClient? = nil
        }
        
        dispatch_once(&Static.token) {
            Static.instance = YelpClient(consumerKey: yelpConsumerKey, consumerSecret: yelpConsumerSecret, accessToken: yelpToken, accessTokenSecret: yelpTokenSecret)
        }
        return Static.instance
    }

    
    func searchWithTerm(term: String, completion: ([Business], NSError!) -> Void) {
        return searchWithTerm(term, sort: nil, categories: nil, deals: nil, completion: completion)
    }

    func searchWithTerm(term: String, sort: Int?, categories: [String]?, deals: Bool?, completion: ([Business], NSError!) -> Void) {
        // For additional parameters, see http://www.yelp.com/developers/documentation/v2/search_api
        
        // Default the location to San Francisco
        var parameters: [String : AnyObject] = ["term": term, "ll": location ?? ""]   //"ll": "37.785771,-122.406165"
        
        if sort != nil {
//            parameters["sort"] = sort!.rawValue
            parameters["sort"] = sort
        }
        
        if categories != nil && categories!.count > 0 {
            parameters["category_filter"] = (categories!).joinWithSeparator(",")
        }
        
        if deals != nil {
            parameters["deals_filter"] = deals!
        }
        
        print("searchWithTerm : ",parameters)
        YelpClient.sharedInstance?.get("https://api.yelp.com/v2/search", parameters: parameters, headers: nil, success: { (data, response) in
            
            let jsonData = try! NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments) as? NSDictionary
            
            //            print(jsonData)
            //let businesses =  Business(dictionary: jsonData!)
//            completion(bu, <#T##NSError!#>)
            let dictionaries = jsonData!["businesses"] as? [NSDictionary]
            if dictionaries != nil {
                completion(Business.businesses(array: dictionaries!), nil)
            }
        }) { (error) in
            print(error)
        }
        
//        return self.GET("search", parameters: parameters, success: { (operation: AFHTTPRequestOperation!, response: AnyObject!) -> Void in
//            let dictionaries = response["businesses"] as? [NSDictionary]
//            if dictionaries != nil {
//                completion(Business.businesses(array: dictionaries!), nil)
//            }
//            }, failure: { (operation: AFHTTPRequestOperation?, error: NSError!) -> Void in
//                completion(nil, error)
//        })!
        
    }
    
//    init() {
//        let baseUrl = NSURL(string: "https://api.yelp.com/v2/")
////        super.init(baseURL: baseUrl, consumerKey: key, consumerSecret: secret);
//        
//        let oathSwift = OAuthSwiftClient(consumerKey: yelpConsumerKey, consumerSecret: yelpConsumerSecret, accessToken: yelpToken, accessTokenSecret: yelpTokenSecret)
////        oathSwift.get("https://api.yelp.com/v2/", success: { (data, response) in
////                print(data)
////            }, failure: nil)
//        
//        
//        var parameters: [String : AnyObject] = ["term": "a", "ll": "37.785771,-122.406165"]
//        
//        print(parameters)
//        oathSwift.get("https://api.yelp.com/v2/search", parameters: parameters, headers: nil, success: { (data, response) in
//            
//            }) { (error) in
//                print(error)
//        }
//        
////        oathSwift.get("https://api.yelp.com/v2/", success: { (data, response) in
////            print(data)
////            }) { (error) in
////                print(error.code)
////                print(error)
////        }
//    }
    
    
}

