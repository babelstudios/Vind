//
//  VivaObservationsConnection.swift
//  Vind
//
//  Created by Jens Utbult on 2015-12-03.
//  Copyright © 2015 Jens Utbult. All rights reserved.
//

import Foundation

enum ResultType {
    case Success(r: WindObservation)
    case Error(e: ErrorType)
}

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
    var completionHandler:((ResultType)->Void)!
    
    func windObservationAtLocationId(locationId: Int, completion: (ResultType) -> Void) {
        completionHandler = completion
        
        let url = NSURL(string: "https://services.viva.sjofartsverket.se:8080/output/vivaoutputservice.svc/vivastation/\(locationId)")!
        Alamofire.request(.GET, url).validate().responseJSON { response in
            switch response.result {
            case .Success:
                if let value = response.result.value {
                    let json = JSON(value)
                    print("JSON: \(json)")
                }
            case .Failure(let error):
                print(error)
            }
        }
        
        
        let soapMessage = "<?xml version='1.0' encoding='utf-8'?><soap12:Envelope xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:xsd='http://www.w3.org/2001/XMLSchema' xmlns:soap12='http://www.w3.org/2003/05/soap-envelope'><soap12:Body><GetViVaDataT xmlns='http://www.sjofartsverket.se/webservice/VaderService/ViVaData.wsdl'><PlatsId>\(locationId)</PlatsId></GetViVaDataT></soap12:Body></soap12:Envelope>"
        if let soapURL = NSURL(string: "http://161.54.134.239/vivadata.asmx") {
            let request = NSMutableURLRequest(URL: soapURL)
            request.addValue("application/soap+xml; charset=utf-8", forHTTPHeaderField: "Content-Type")
            
            let contentLength = soapMessage.characters.count
            request.addValue(String(contentLength), forHTTPHeaderField: "Content-Length")
            request.HTTPMethod = "POST"
            request.HTTPBody = soapMessage.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
            
            let sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
            let urlSession = NSURLSession(configuration: sessionConfiguration)
            let task = urlSession.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
                guard let data = data else {
                    self.completionHandler(ResultType.Error(e: error ?? CreateWindErrorType.ConnectionError))
                    self.completionHandler = nil
                    return
                }
                
                let parser = NSXMLParser(data: data)
                self.parser = parser
                parser.delegate = self
                parser.parse()
                
                //                let result = NSString(data: data, encoding: NSUTF8StringEncoding)
                //                print(result)
                
            })
            task.resume()
        }
    }
    
    private func parseVivaDate(dateString: String) -> NSDate? {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'+02:00"
        dateFormatter.timeZone = NSTimeZone(forSecondsFromGMT: 2 * 60 * 60)
        return dateFormatter.dateFromString(dateString)
    }
    
    private func windFromAttributeDict(dict: [String: String]) throws -> WindObservation {
        guard let dateString = dict["Tid"] else {
            throw CreateWindErrorType.SoapParseError
        }
        
        guard let date = parseVivaDate(dateString) else {
            throw CreateWindErrorType.SoapParseError
        }
        
        return WindObservation(date: date)
    }
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        if (elementName == "ViVaDataT") {
            guard let type = attributeDict["Typ"] else {
                self.completionHandler(ResultType.Error(e: CreateWindErrorType.SoapParseError))
                parser.abortParsing()
                return
            }
            
            if type == "Medelvind" || type == "Riktning" || type == "Byvind"{
                // Create Wind from date in dict
                if self.currentWind == nil {
                    do {
                        self.currentWind = try windFromAttributeDict(attributeDict)
                    } catch {
                        self.completionHandler(ResultType.Error(e: CreateWindErrorType.SoapParseError))
                        parser.abortParsing()
                        return
                    }
                }
                
                guard let valueString = attributeDict["Varde"] else {
                    self.completionHandler(ResultType.Error(e: CreateWindErrorType.SoapParseError))
                    parser.abortParsing()
                    return
                }
                
                guard let value = Float(valueString) else {
                    self.completionHandler(ResultType.Error(e: CreateWindErrorType.SoapParseError))
                    parser.abortParsing()
                    return
                }
                
                if var wind = currentWind {
                    switch type {
                    case "Medelvind":
                        wind.speed = value
                    case "Byvind":
                        wind.gusts = value
                    case "Riktning":
                        wind.direction = value * Float(M_PI) / 180.0
                    default: break
                    }
                    currentWind = wind
                }
            }
        }
        
        currentElementName = elementName
        currentAttributes = attributeDict
    }
    
    func parser(parser: NSXMLParser, foundCharacters string: String) {
        if (currentElementName == "PlatsNamn") {
            currentLocation = string
        }
    }
    
    func parserDidEndDocument(parser: NSXMLParser) {
        if var currentWind = currentWind {
            if let location = currentLocation {
                currentWind.location = location
                currentLocation = nil
            }
            print(currentWind)
            if let completion = completionHandler {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completion(ResultType.Success(r: currentWind))
                    self.completionHandler = nil
                })
            }
        }
        currentWind = nil
    }
    
}