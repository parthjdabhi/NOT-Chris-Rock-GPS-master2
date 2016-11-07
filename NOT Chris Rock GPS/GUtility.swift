//
//  GUtility.swift
//  NOT Chris Rock GPS
//
//  Created by iParth on 9/27/16.
//  Copyright © 2016 Harloch. All rights reserved.
//

import UIKit

class GUtility: NSObject {

}

//public PlacesList search(double latitude, double longitude, double radius, String types)
//throws Exception {
//    
//    try {
//        
//        HttpRequestFactory httpRequestFactory = createRequestFactory(HTTP_TRANSPORT);
//        HttpRequest request = httpRequestFactory
//            .buildGetRequest(new GenericUrl("https://maps.googleapis.com/maps/api/place/search/json?"));
//        request.getUrl().put("key", YOUR_API_KEY);
//        request.getUrl().put("location", latitude + "," + longitude);
//        request.getUrl().put("radius", radius);
//        request.getUrl().put("sensor", "false");
//        request.getUrl().put("types", types);
//        
//        PlacesList list = request.execute().parseAs(PlacesList.class);
//        
//        if(list.next_page_token!=null || list.next_page_token!=""){
//            Thread.sleep(4000);
//            /*Since the token can be used after a short time it has been  generated*/
//            request.getUrl().put("pagetoken",list.next_page_token);
//            PlacesList temp = request.execute().parseAs(PlacesList.class);
//            list.results.addAll(temp.results);
//            
//            if(temp.next_page_token!=null||temp.next_page_token!=""){
//                Thread.sleep(4000);
//                request.getUrl().put("pagetoken",temp.next_page_token);
//                PlacesList tempList =  request.execute().parseAs(PlacesList.class);
//                list.results.addAll(tempList.results);
//            }
//            
//        }
//        return list;
//        
//    } catch (HttpResponseException e) {
//        return null;
//    }
//    
//}


func degreesToRadians(degrees: Double) -> Double { return degrees * M_PI / 180.0 }
func radiansToDegrees(radians: Double) -> Double { return radians * 180.0 / M_PI }

func getBearingBetweenTwoPoints(point1 : CLLocation, point2 : CLLocation) -> Double {
    
    let lat1 = degreesToRadians(point1.coordinate.latitude)
    let lon1 = degreesToRadians(point1.coordinate.longitude)
    
    let lat2 = degreesToRadians(point2.coordinate.latitude)
    let lon2 = degreesToRadians(point2.coordinate.longitude)
    
    let dLon = lon2 - lon1
    
    let y = sin(dLon) * cos(lat2)
    let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
    let radiansBearing = atan2(y, x)
    
    return radiansToDegrees(radiansBearing)
}