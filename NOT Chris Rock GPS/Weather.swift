//
//  WeatherGetter.swift
//  NOT Chris Rock GPS
//
//  Created by Dustin Allen on 9/14/16.
//  Copyright © 2016 Harloch. All rights reserved.
//

import Foundation

struct Weather {
  
  let dateAndTime: NSDate
  
  let city: String
  let country: String
  let longitude: Double
  let latitude: Double
  
  let weatherID: Int
  let mainWeather: String
  let weatherDescription: String
  let weatherIconID: String
  
  private let temp: Double
  var tempCelsius: Double {
    get {
      return temp - 273.15
    }
  }
  var tempFahrenheit: Double {
    get {
      return (temp - 273.15) * 1.8 + 32
    }
  }
  let humidity: Int
  let pressure: Int
  let cloudCover: Int
  let windSpeed: Double

  let windDirection: Double?
  let rainfallInLast3Hours: Double?
  
  let sunrise: NSDate
  let sunset: NSDate
  
  init(weatherData: [String: AnyObject]) {
    dateAndTime = NSDate(timeIntervalSince1970: weatherData["dt"] as! NSTimeInterval)
    city = weatherData["name"] as! String
    
    let coordDict = weatherData["coord"] as! [String: AnyObject]
    longitude = coordDict["lon"] as! Double
    latitude = coordDict["lat"] as! Double
    
    let weatherDict = (weatherData["weather"] as! NSArray)[0] as! [String: AnyObject]
    weatherID = weatherDict["id"] as! Int
    mainWeather = weatherDict["main"] as! String
    weatherDescription = weatherDict["description"] as! String
    weatherIconID = weatherDict["icon"] as! String
    
    let mainDict = weatherData["main"] as! [String: AnyObject]
    temp = mainDict["temp"] as! Double
    humidity = mainDict["humidity"] as! Int
    pressure = mainDict["pressure"] as! Int
    
    cloudCover = weatherData["clouds"]!["all"] as! Int
    
    let windDict = weatherData["wind"] as! [String: AnyObject]
    windSpeed = windDict["speed"] as! Double
    windDirection = windDict["deg"] as? Double
    
    if weatherData["rain"] != nil {
      let rainDict = weatherData["rain"] as! [String: AnyObject]
      rainfallInLast3Hours = rainDict["3h"] as? Double
    }
    else {
      rainfallInLast3Hours = nil
    }
    
    let sysDict = weatherData["sys"] as! [String: AnyObject]
    country = sysDict["country"] as! String
    sunrise = NSDate(timeIntervalSince1970: sysDict["sunrise"] as! NSTimeInterval)
    sunset = NSDate(timeIntervalSince1970:sysDict["sunset"] as! NSTimeInterval)
  }
  
}