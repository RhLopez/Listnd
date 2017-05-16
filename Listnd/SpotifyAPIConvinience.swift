//
//  SpotifyAPIConvinience.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 10/2/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import Foundation

extension SpotifyAPI {
    
    func cancelRequest() {
        task?.cancel()
    }
    
    func search(_ userInput: String, completionHanderForSearch: @escaping (_ sucess: Bool, _ results: [AnyObject]?, _ errorMessage: String) -> Void) {
        let parameters = [
            Constants.ParametersKeys.Query: userInput,
            Constants.ParametersKeys.SearchType: Constants.ParameterValues.All,
            Constants.ParametersKeys.Market: Constants.ParameterValues.US,
            Constants.ParametersKeys.Limit: Constants.ParameterValues.LimitAmount
        ]
        
        taskForGetMethod(parameters as [String: AnyObject], path: Constants.ParametersKeys.Search) { (success, errorMessage, data) in
            if success {
               self.parseSearchResult(data as AnyObject, completionHandlerForSearchResult: { (success, result, errorMessage) in
                if success {
                    completionHanderForSearch(true, result, "")
                } else {
                    completionHanderForSearch(false, nil, errorMessage)
                }
               })
            } else {
                completionHanderForSearch(false, nil, "")
            }
        }
    }
    
    func getImageURL(_ artistId: String, completionHandler: @escaping (_ urlString: String?) -> Void) {
        let path = Constants.ParametersKeys.Artist.replacingOccurrences(of: "{id}", with: artistId)
        
        taskForGetMethod([:], path: path) { (success, errorMessage, result) in
            if success {
                self.parseArtistImageUrl(result, completionHandler: { (urlString) in
                    completionHandler(urlString)
                })
            } else {
                completionHandler(nil)
            }
        }
    }
    
    func searchArtist(_ userInput: String, completionHandlerForArtistSearch: @escaping (_ success: Bool, _ results: [Artist]?, _ errorMessage: String) -> Void) {
        let parameters = [
            Constants.ParametersKeys.Query: userInput,
            Constants.ParametersKeys.SearchType: Constants.ParameterValues.All,
            Constants.ParametersKeys.Market: Constants.ParameterValues.US,
            Constants.ParametersKeys.Limit: Constants.ParameterValues.LimitAmount
        ]
        
        taskForGetMethod(parameters as [String : AnyObject], path: Constants.ParametersKeys.Search) { (success, errorMessage, data) in
            if success {
                self.parseArtistSearch(data as AnyObject?, completionHandlerForParseArtistSearch: { (success, results, errorMessage) in
                    if success {
                        completionHandlerForArtistSearch(true, results, "")
                    } else {
                        completionHandlerForArtistSearch(false, nil, errorMessage)
                    }
                })
            } else {
                completionHandlerForArtistSearch(false, nil, errorMessage)
            }
        }
    }
    
    func getAlbums(_ artistId: String, completionHandlerForAlbums: @escaping (_ results: [Album]?, _ errorMessage: String) -> Void) {
        let parameters = [
            Constants.ParametersKeys.AlbumType: Constants.ParameterValues.AlbumSearch,
            Constants.ParametersKeys.Market: Constants.ParameterValues.US,
            Constants.ParametersKeys.Limit: Constants.ParameterValues.LimitAmount
        ]
        
        let path = Constants.ParametersKeys.ArtistAlbums.replacingOccurrences(of: "{id}", with: artistId)
        
        taskForGetMethod(parameters as [String : AnyObject], path: path) { (success, errorMessage, data) in
            if success {
                self.parseAlbums(data as AnyObject?, completionHandlerforAlbumParsing: { (success, results, errorString) in
                    if success {
                        completionHandlerForAlbums(results, "")
                    } else {
                        completionHandlerForAlbums(nil, errorMessage)
                    }
                })
            } else {
                completionHandlerForAlbums(nil, errorMessage)
            }
        }
    }
    
    func getAlbum(_ albumId: String, completionHandlerForAlbum: @escaping (_ result: Album?, _ errorMessage: String) -> Void) {
        let path = Constants.ParametersKeys.Albums.replacingOccurrences(of: "{id}", with: albumId)
        taskForGetMethod([:], path: path) { (success, errorMessage, data) in
            if success {
                self.parseAlbum(data as AnyObject?, completionHandlerforAlbumParsing: { (success, result, errorMessage) in
                    if success {
                        completionHandlerForAlbum(result, "")
                    } else {
                        completionHandlerForAlbum(nil, errorMessage)
                    }
                })
            } else {
                completionHandlerForAlbum(nil, errorMessage)
            }
        }
    }
    
    func getTracks(_ albumId: String, completionHandlerForTracks: @escaping (_ resutls: [Track]?, _ errorMessage: String) -> Void) {
        let parameters = [
            Constants.ParametersKeys.Market: Constants.ParameterValues.US,
            Constants.ParametersKeys.Limit: Constants.ParameterValues.LimitAmount
        ]
        
        let path = Constants.ParametersKeys.AlbumTracks.replacingOccurrences(of: "{id}", with: albumId)
        
        taskForGetMethod(parameters as [String : AnyObject], path: path) { (success, errorMessage, data) in
            if success {
                self.parseTracks(data as AnyObject?, completionHandlerForTrackParsing: { (success, results, errorMessage) in
                    if success {
                        completionHandlerForTracks(results, "")
                    } else {
                        completionHandlerForTracks(nil, errorMessage)
                    }
                })
            } else {
                completionHandlerForTracks(nil, errorMessage)
            }
        }
    }
    
    func parseSearchResult(_ data: AnyObject?, completionHandlerForSearchResult: @escaping (_ success: Bool, _ results: [AnyObject]?, _ errorMessage: String) -> Void) {
        var results = [AnyObject]()
        
        func parsingFailed() {
            completionHandlerForSearchResult(false, nil, "Unable to process search data from Spotify. Please try again.")
            return
        }
        
        guard let data = data else {
            parsingFailed()
            return
        }
        
        let artistResult = data["artists"]
        let albumResult = data["albums"]
        let trackResult = data["tracks"]
        
        self.parseArtistSearch(artistResult as AnyObject) { (success, result, errorMessage) in
            if success {
                for item in result! {
                    results.append(item)
                }
            } else {
                completionHandlerForSearchResult(false, nil, errorMessage)
            }
        }
        
        self.parseAlbums(albumResult as AnyObject) { (success, result, errorMessage) in
            if success {
                for item in result! {
                    results.append(item)
                }
            } else {
                completionHandlerForSearchResult(false, nil, errorMessage)
            }
        }
        
        self.parseTracks(trackResult as AnyObject) { (success, result, errorMessage) in
            if success {
                for item in result! {
                    results.append(item)
                }
            } else {
                completionHandlerForSearchResult(false, nil, errorMessage)
            }
        }
        
        completionHandlerForSearchResult(true, results, "")
    }
    
    func parseArtistSearch(_ data: AnyObject?, completionHandlerForParseArtistSearch: @escaping (_ success: Bool, _ results: [Artist]?, _ errorMessage: String) -> Void) {

        var imageURL: String?
        var artists = [Artist]()
        var artistCount: Int16 = 0
        
        func parsingFailed() {
            completionHandlerForParseArtistSearch(false, nil, "Unable to process artist data from Spotify. Please try again.")
            return
        }
        
        guard let data = data else {
            parsingFailed()
            return
        }
        
        guard let items = data["items"] as? [[String:AnyObject]] else {
            parsingFailed()
            return
        }
        
        artists = items.flatMap { Artist(json: $0, context: nil) }
        completionHandlerForParseArtistSearch(true, artists, "")
    }
    
    func parseAlbums(_ data: AnyObject?, completionHandlerforAlbumParsing: @escaping (_ success: Bool, _ results: [Album]?,_ errorMessage: String) -> Void) {
        var albumNames = [String]()
        var imageURL: String?
        var albums = [Album]()
        var artistName = ""
        
        func parsingFailed() {
            completionHandlerforAlbumParsing(false, nil, "Unable to process album data from Spotify. Please try again")
            return
        }
        
        guard let data = data else {
            parsingFailed()
            return
        }
        
        guard let items = data["items"] as? [[String:AnyObject]] else {
            parsingFailed()
            return
        }
        
        for jsonDictionary in items {
            guard let albumName = jsonDictionary["name"] as? String else {
                continue
            }
            
            // Prevent duplicate albums from being parsed
            if !albumNames.contains(albumName) {
                if let album = Album(json: jsonDictionary) {
                    albums.append(album)
                    albumNames.append(albumName)
                }
            }
        }
        
        completionHandlerforAlbumParsing(true, albums, "")
    }
    
    func parseAlbum(_ data: AnyObject?, completionHandlerforAlbumParsing: @escaping (_ success: Bool, _ results: Album?,_ errorMessage: String) -> Void) {
        var imageURL: String?
        
        func parsingFailed() {
            completionHandlerforAlbumParsing(false, nil, "Unable to process album data from Spotify. Please try again")
            return
        }
        
        guard let data = data else {
            parsingFailed()
            return
        }
        
        guard let json = data as? [String: AnyObject] else {
            parsingFailed()
            return
        }
        
        let album = Album(json: json)
        
        completionHandlerforAlbumParsing(true, album, "")
    }
    
    func parseTracks(_ data: AnyObject?, completionHandlerForTrackParsing: @escaping (_ success: Bool, _ results: [Track]?, _ errorMessage: String) -> Void) {
        var tracks = [Track]()

        func parsingFailed() {
            completionHandlerForTrackParsing(false, nil, "Unable to process track data from Spotify. Please try again")
            return
        }
        
        guard let data = data else {
            parsingFailed()
            return
        }
        
        guard let items = data["items"] as? [[String: AnyObject]] else {
            parsingFailed()
            return
        }

        tracks = items.flatMap { Track(json: $0, context: nil) }

        completionHandlerForTrackParsing(true, tracks, "")
    }
    
    func parseArtistImageUrl(_ data: Any?, completionHandler: @escaping (_ imageURL: String?) -> Void) {
        var imageURL: String?
        
        guard let data = data as? [String: AnyObject] else {
            completionHandler(nil)
            return
        }
        
        guard let images = data["images"] as? [[String: AnyObject]] else {
            completionHandler(nil)
            return
        }
        
        for item in images {
            guard let url = item["url"] as? String else {
                completionHandler(nil)
                return
            }
            
            imageURL = url
            break
        }
        
        completionHandler(imageURL)
    }
    
    func getImage(_ urlString: String?, completionHandlerForImage: @escaping (_ data: Data?) -> Void) {
        if let url = urlString {
            let request = URLRequest(url: URL(string: url)!)

            let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
                guard (error == nil) else {
                    completionHandlerForImage(nil)
                    return
                }
                
                guard let data = data else {
                    completionHandlerForImage(nil)
                    return
                }
                
                completionHandlerForImage(data)
            }) 
            
            task.resume()
        } else {
            completionHandlerForImage(nil)
        }
    }
}
