//
//  SpotifyAPI.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 10/2/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import Foundation
import CoreData

class SpotifyAPI {
    
    static let sharedInstance = SpotifyAPI()
    let coreData = CoreDataStack.sharedInstance
    
    let session = URLSession.shared
    
    func taskForGetMethod(_ parameters: [String:AnyObject], path: String, completionHandlerForArtistSearch: @escaping (_ success: Bool, _ errorMessage: String?, _ data: Any?) -> Void) {
        let request = URLRequest(url: spotifyURL(parameters, path: path))
        
        let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
            
            func reportError(_ message: String) {
                completionHandlerForArtistSearch(false, message, nil)
                return
            }
            
            guard (error == nil) else {
                reportError((error?.localizedDescription)!)
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode , statusCode >= 200 && statusCode <= 299 else {
                reportError("Status code returned response other than 200")
                return
            }
            
            guard let data = data else {
                reportError("No data was returned")
                return
            }
            
            self.serializeData(data, completionHandlerForSerialization: completionHandlerForArtistSearch)
        })
        
        task.resume()
    }
    
    func serializeData(_ data: Data, completionHandlerForSerialization: (_ success: Bool, _ errorMessage: String?, _ data: Any?) -> Void) {
        var serializedData: Any?
        
        do {
            serializedData = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
        } catch {
            completionHandlerForSerialization(false, "Unable to serialize data", nil)
        }
        
        completionHandlerForSerialization(true, nil, serializedData)
    }
    
    fileprivate func spotifyURL(_ parameters: [String:AnyObject], path: String) -> URL {
        var components = URLComponents()
        components.scheme = Constants.API.APIScheme
        components.host = Constants.API.BaseURL
        components.path = Constants.API.APIPath + path
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        print(components.url!)
        
        return components.url!
    }
}
