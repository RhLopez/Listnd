//
//  SpotifyAPI.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 10/2/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import Foundation
import RealmSwift

class SpotifyAPI {
    
    static let sharedInstance = SpotifyAPI()

    let session = URLSession.shared
    var task: URLSessionDataTask?
    var accessToken = ""
    var tokenType = ""
    var experationTime = 0
    
    func taskForTokenMethod(completion: @escaping (_ success: Bool) -> Void) {
        let url = tokenURL()
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let parameterString = "\(Constants.ParametersKeys.GrantType)=\(Constants.ParameterValues.ClientCred)"
        let httpBody = NSMutableData(data: parameterString.data(using: .utf8)!)
        request.httpBody = httpBody as Data
        let string = SpotifyAPIKey.IDSecret
        let base64Encoded = Data(string.utf8).base64EncodedString()
        request.addValue("Basic \(base64Encoded)", forHTTPHeaderField: "Authorization")
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        task = session.dataTask(with: request, completionHandler: { (data, response, error) in
            guard (error == nil) else {
                print(error!)
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else { return }
            guard let data = data else { return }
            self.serializeData(data, completionHandlerForSerialization: { (success, errorMessage, data) in
                if success {
                    self.parseToken(withData: data)
                    completion(true)
                } else {
                    completion(false)
                }
            })
        })
        
        task?.resume()
    }
    
    func taskForGetMethod(_ parameters: [String:AnyObject], path: String, completionHandlerForArtistSearch: @escaping (_ success: Bool, _ errorMessage: String, _ data: Any?) -> Void) {
        var request = URLRequest(url: spotifyURL(parameters, path: path))
        request.addValue("\(tokenType) \(accessToken)", forHTTPHeaderField: "Authorization")
        
        task?.cancel()
        
        task = session.dataTask(with: request, completionHandler: { (data, response, error) in
            
            func reportError(_ message: String) {
                completionHandlerForArtistSearch(false, message, nil)
                return
            }
            
            if let error = error as NSError?, error.code == -999 {
                return
            }
            
            guard (error == nil) else {
                reportError("There was an error with request. Please try again.")
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode , statusCode >= 200 && statusCode <= 299 else {
                reportError("The request did not return a valid response. Please try again.")
                return
            }
            
            guard let data = data else {
                reportError("There was no data returned from the request. Please try again.")
                return
            }
            
            self.serializeData(data, completionHandlerForSerialization: completionHandlerForArtistSearch)
        })
        
        task?.resume()
    }
    
    func serializeData(_ data: Data, completionHandlerForSerialization: (_ success: Bool, _ errorMessage: String, _ data: Any?) -> Void) {
        var serializedData: Any?
        
        do {
            serializedData = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
        } catch {
            completionHandlerForSerialization(false, "Unable to process data response from server. Please try again.", nil)
        }
        
        completionHandlerForSerialization(true, "", serializedData)
    }
    
    func tokenURL() -> URL {
        var components = URLComponents()
        components.scheme = Constants.API.APIScheme
        components.host = Constants.API.TokenURL
        components.path = Constants.API.API + Constants.ParametersKeys.Token
        
        return components.url!
    }
    
    func spotifyURL(_ parameters: [String:AnyObject], path: String) -> URL {
        var components = URLComponents()
        components.scheme = Constants.API.APIScheme
        components.host = Constants.API.BaseURL
        components.path = Constants.API.APIVersion + path
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
}
