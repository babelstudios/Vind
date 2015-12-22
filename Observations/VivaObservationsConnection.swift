//
//  VivaObservationsConnection.swift
//  Vind
//
//  Created by Jens Utbult on 2015-12-03.
//  Copyright © 2015 Jens Utbult. All rights reserved.
//

import Foundation

enum CreateWindErrorType: ErrorType {
    case SoapParseError
    case NoValueInDictError
    case ConnectionError
}

class VivaObservationsConnection: NSObject, NSXMLParserDelegate {
    
    var parser: NSXMLParser?
    var currentElementName = ""
    var currentAttributes = [String: String]()
    var currentWind: WindObservation?
    var currentLocation: String?
    var completionHandler:((Result<WindObservation>)->Void)!
    
    func windObservationAtLocationId(locationId: Int, completion: (Result<WindObservation>) -> Void) {
        completionHandler = completion
        
        if let url = NSURL(string: "https://services.viva.sjofartsverket.se:8080/output/vivaoutputservice.svc/vivastation/\(locationId)") {
            
            print("get data from \(url)")
            
            let request = NSMutableURLRequest(URL: url)
            request.HTTPMethod = "GET"
            
            let sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
            let urlSession = NSURLSession(configuration: sessionConfiguration)
            let task = urlSession.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
                guard let data = data else {
                    print(error)
                    self.completionHandler(Result.Error(e: error ?? CreateWindErrorType.ConnectionError))
                    self.completionHandler = nil
                    return
                }

                let result = JSON(data: data)
                let name = result["GetSingleStationResult"]["Name"].stringValue
                let samples = result["GetSingleStationResult"]["Samples"].arrayValue
                
                var averageWind:Double?
                var gustWind:Double?
                var heading:Double?
                var date:NSDate?
                
                for sample in samples {
                    let type = sample["Name"].stringValue
                    
                    switch type {
                    case "Medelvind":
                        print("Medelvind \(Double(sample["Value"].stringValue))")
                        averageWind = Double(sample["Value"].stringValue.stripNonNumberCharacters()!)!
                        heading = Double(sample["Heading"].intValue) * Double(M_PI) / 180.0
                        date = self.parseVivaDate(sample["Updated"].stringValue)
                    case "Byvind":
                        print("Byvind \(Double(sample["Value"].stringValue))")
                        gustWind = Double(sample["Value"].stringValue.stripNonNumberCharacters()!)!
                    default:
                        print("not type")
                    }
                    
                }
                
                let observation = WindObservation(location: name, speed: averageWind!, gusts: gustWind!, direction: heading!, date: date!)
                
                
                completion(Result.Success(observation))

                //print("Samples: \(samples)")
                
                //print("JSON: \(result)")
            })
            task.resume()
        }
    }
    
    private func parseVivaDate(dateString: String) -> NSDate {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd' 'HH:mm:ss"
        dateFormatter.timeZone = NSTimeZone(forSecondsFromGMT: 1 * 60 * 60)
        return dateFormatter.dateFromString(dateString)!
    }
}