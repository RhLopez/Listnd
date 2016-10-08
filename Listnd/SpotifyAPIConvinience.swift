//
//  SpotifyAPIConvinience.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 10/2/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import Foundation

extension SpotifyAPI {
    
    func searchArtist(_ userInput: String, completionHandlerForArtistSearch: @escaping (_ success: Bool, _ errorMessage: String?) -> Void) {
        let parameters = [
            Constants.ParametersKeys.Query: userInput,
            Constants.ParametersKeys.SearchType: Constants.ParameterValues.Artist,
            Constants.ParametersKeys.Market: Constants.ParameterValues.US
        ]
        
        taskForGetMethod(parameters as [String : AnyObject], path: Constants.ParametersKeys.Search) { (success, errorMessage, data) in
            if success {
                self.parseArtistSearch(data as AnyObject?, completionHandlerForParseArtistSearch: { (success, errorMessage) in
                    if success {
                        completionHandlerForArtistSearch(true, nil)
                    } else {
                        completionHandlerForArtistSearch(false, errorMessage)
                    }
                })
            } else {
                completionHandlerForArtistSearch(false, errorMessage)
            }
        }
    }
    
    func searchAlbum(_ userInput: String, completionHandlerForAlbumSearch: (_ success: Bool, _ errorMessage: String?, _ results: [[String:AnyObject]]?) -> Void) {
        
    }
    
    func searchSong(_ userInput: String, completionHandlerForSongSearch: (_ success: Bool, _ errorMessage: String?, _ results: [[String:AnyObject]]?) -> Void) {
        
    }
    
    func getAlbums(_ artistId: String, completionHandlerForAlbums: (_ success: Bool, _ errorMessage: String?, _ results: [[String:AnyObject]]?) -> Void) {
        
    }
    
    func getTracks(_ albumId: String, completionHandlerForTracks: (_ success: Bool, _ errorMessage: String?, _ results: [[String:AnyObject]]?) -> Void) {
        
    }
    
    func parseAlbumDictionary(_ data: AnyObject?, completionHandlerForParseAlbumDictionary: (_ success: Bool, _ errorMessage: String?, _ result: [[String:AnyObject]]?) -> Void) {
        
    }
    
    func parseArtistSearch(_ data: AnyObject?, completionHandlerForParseArtistSearch: @escaping (_ success: Bool, _ errorMessage: String?) -> Void) {

        var imageURL: String?
        var resultNumber = 0
        
        func parsingFailed(_ message: String) {
            completionHandlerForParseArtistSearch(false, message)
            return
        }
        
        guard let data = data else {
            parsingFailed("No data returned to parse")
            return
        }
        
        guard let artistDictionary = data["artists"] as? [String:AnyObject] else {
            parsingFailed("No value for key 'artist'")
            return
        }
        
        guard let items = artistDictionary["items"] as? [[String:AnyObject]] else {
            parsingFailed("No value for key 'items'")
            return
        }
        
        for item in items {
            guard let artistName = item["name"] as? String else {
                parsingFailed("No value for key 'name'")
                return
            }
            
            guard let artistId = item["id"] as? String else {
                parsingFailed("No value for key 'id'")
                return
            }
            
            guard let images = item["images"] as? [[String:AnyObject]] else {
                parsingFailed("No value for key 'images'")
                return
            }
            
            if images.isEmpty {
                imageURL = ""
            } else {
                let item = images.first!
                guard let url = item["url"] as? String else {
                    parsingFailed("No value for key 'url'")
                    return
                }
                
                imageURL = url
                
            }
            
            let artist = Artist(context: coreData.managedContext)
            artist.name = artistName
            artist.id = artistId
            artist.imageURL = imageURL!
            artist.resultNumber = Int16(resultNumber)
            resultNumber = resultNumber + 1
        }
        
        coreData.saveContext()
        completionHandlerForParseArtistSearch(true, nil)
    }
    func parseAlbums(_ data: AnyObject?, completionHandlerforAlbumParsing: (_ success: Bool, _ errorMessage: String?, _ results: [[String:AnyObject]]?) -> Void) {
        
    }
    
    func parseTracks(_ data: AnyObject?, completionHandlerForTrackParsing: (_ success: Bool, _ errorMessage: String?, _ results: [[String:AnyObject]]?) -> Void) {
        
    }
    
    func getImage(_ urlString: String, completionHandlerForImage: @escaping (_ data: Data?) -> Void) {
        let request = URLRequest(url: URL(string: urlString)!)
        
        let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
            guard (error == nil) else {
                print(error?.localizedDescription)
                completionHandlerForImage(nil)
                return
            }
            
            guard let data = data else {
                print("No data")
                completionHandlerForImage(nil)
                return
            }
            
            completionHandlerForImage(data)
        }) 
        
        task.resume()
    }
}
