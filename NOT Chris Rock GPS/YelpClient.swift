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
        } else {
            parameters["category_filter"] = "food"
        }
        //filter - Food (food, All)
        
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
    
    /**
     Build a business request searching for the specified businessId
     
     - Parameter businessId: The Yelp businessId to search for
     
     - Returns: A fully formed request that can be sent immediately
     */
    func getBusinessDetail(with businessId: String, completion: (Business, NSError!) -> Void) {
        
        print("searchWithbusinessId : ",businessId)
        YelpClient.sharedInstance?.get("https://api.yelp.com/v2/business/\(businessId)", parameters: ["actionlinks":"True"], headers: nil, success: { (data, response) in
            
            let jsonData = try! NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments) as? NSDictionary
            
            print(jsonData)
            
            if let dictionary = jsonData
            {
                let business = Business(dictionary: dictionary)
                business.loadImages()
                completion(business, nil)
            }
        }) { (error) in
            print(error)
        }
    }

    /*
     Optional({
     categories =     (
     (
     Italian,
     italian
     ),
     (
     Pizza,
     pizza
     )
     );
     "display_phone" = "+1-415-677-9455";
     id = "il-casaro-pizzeria-and-mozzarella-bar-san-francisco";
     "image_url" = "https://s3-media3.fl.yelpcdn.com/bphoto/K62xCcAyKVskvClKvAwz_A/ms.jpg";
     "is_claimed" = 1;
     "is_closed" = 0;
     location =     {
     address =         (
     "348 Columbus Ave"
     );
     city = "San Francisco";
     coordinate =         {
     latitude = "37.7984832";
     longitude = "-122.4073981";
     };
     "country_code" = US;
     "cross_streets" = "Vallejo St & Grant Ave";
     "display_address" =         (
     "348 Columbus Ave",
     "Russian Hill",
     "San Francisco, CA 94133"
     );
     "geo_accuracy" = "9.5";
     neighborhoods =         (
     "Russian Hill",
     "North Beach/Telegraph Hill"
     );
     "postal_code" = 94133;
     "state_code" = CA;
     };
     "menu_date_updated" = 1472781393;
     "menu_provider" = "single_platform";
     "mobile_url" = "https://m.yelp.com/biz/il-casaro-pizzeria-and-mozzarella-bar-san-francisco?adjust_creative=QhdjSyz8FU-asJy7PRr_Fw&utm_campaign=yelp_api&utm_medium=api_v2_business&utm_source=QhdjSyz8FU-asJy7PRr_Fw";
     name = "Il Casaro Pizzeria & Mozzarella Bar";
     phone = 4156779455;
     rating = "4.5";
     "rating_img_url" = "https://s3-media2.fl.yelpcdn.com/assets/2/www/img/99493c12711e/ico/stars/v1/stars_4_half.png";
     "rating_img_url_large" = "https://s3-media4.fl.yelpcdn.com/assets/2/www/img/9f83790ff7f6/ico/stars/v1/stars_large_4_half.png";
     "rating_img_url_small" = "https://s3-media2.fl.yelpcdn.com/assets/2/www/img/a5221e66bc70/ico/stars/v1/stars_small_4_half.png";
     "review_count" = 544;
     reviews =     (
     {
     excerpt = "Still leaving the rating at 5, but there was one blemish with our most recent visit.  The food here is REALLY good and very reasonably priced.\n\nWe ordered...";
     id = ZkYbVkPldKq7NsiYhTE1hQ;
     rating = 5;
     "rating_image_large_url" = "https://s3-media3.fl.yelpcdn.com/assets/2/www/img/22affc4e6c38/ico/stars/v1/stars_large_5.png";
     "rating_image_small_url" = "https://s3-media1.fl.yelpcdn.com/assets/2/www/img/c7623205d5cd/ico/stars/v1/stars_small_5.png";
     "rating_image_url" = "https://s3-media1.fl.yelpcdn.com/assets/2/www/img/f1def11e4e79/ico/stars/v1/stars_5.png";
     "time_created" = 1476821539;
     user =             {
     id = "jd1ghWRsfB_tIYVggFk3tA";
     "image_url" = "https://s3-media2.fl.yelpcdn.com/photo/GsMUfSs2xa82tyWtRhURxg/ms.jpg";
     name = "Bob F.";
     };
     }
     );
     "snippet_image_url" = "https://s3-media1.fl.yelpcdn.com/photo/6ccW544Sh7xiGy_BBBMkmw/ms.jpg";
     "snippet_text" = "How do I explain the magnitude of quality for this restaurant in a measly Yelp review?!\n\nYou know when you go to the orchestra and there are all these...";
     url = "https://www.yelp.com/biz/il-casaro-pizzeria-and-mozzarella-bar-san-francisco?adjust_creative=QhdjSyz8FU-asJy7PRr_Fw&utm_campaign=yelp_api&utm_medium=api_v2_business&utm_source=QhdjSyz8FU-asJy7PRr_Fw";
     })
     */
    
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

