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
    
    func getAlbums(_ artistId: String, completionHandlerForAlbums: @escaping (_ success: Bool, _ errorMessage: String?) -> Void) {
        let parameters = [
            Constants.ParametersKeys.AlbumType: Constants.ParameterValues.Album,
            Constants.ParametersKeys.Market: Constants.ParameterValues.US
        ]
        
        let path = Constants.ParametersKeys.ArtistAlbums.replacingOccurrences(of: "{id}", with: artistId)
        
        taskForGetMethod(parameters as [String : AnyObject], path: path) { (success, errorMessage, data) in
            if success {
                self.parseAlbums(data as AnyObject?, completionHandlerforAlbumParsing: { (success, errorString) in
                    if success {
                        completionHandlerForAlbums(true, nil)
                    } else {
                        completionHandlerForAlbums(false, errorMessage)
                    }
                })
            } else {
                completionHandlerForAlbums(false, errorMessage)
            }
        }
    }
    
    func getTracks(_ albumId: String, completionHandlerForTracks: @escaping (_ success: Bool, _ errorMessage: String?) -> Void) {
        let parameters = [
            Constants.ParametersKeys.Market: Constants.ParameterValues.US
        ]
        
        let path = Constants.ParametersKeys.AlbumTracks.replacingOccurrences(of: "{id}", with: albumId)
        
        taskForGetMethod(parameters as [String : AnyObject], path: path) { (success, errorMessage, data) in
            if success {
                self.parseTracks(data as AnyObject?, completionHandlerForTrackParsing: { (success, errorMessage) in
                    if success {
                        completionHandlerForTracks(true, nil)
                    } else {
                        completionHandlerForTracks(false, errorMessage)
                    }
                })
            } else {
                completionHandlerForTracks(false, errorMessage)
            }
        }
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
    
    func parseAlbums(_ data: AnyObject?, completionHandlerforAlbumParsing: @escaping (_ success: Bool, _ errorMessage: String?) -> Void) {
        var albumNames = [String]()
        var imageURL: String?
        
        func parsingFailed(_ message: String) {
            completionHandlerforAlbumParsing(false, message)
            return
        }
        
        guard let data = data else {
            parsingFailed("No data returned in request")
            return
        }
        
        guard let items = data["items"] as? [[String:AnyObject]] else {
            parsingFailed("No value for album key 'items'")
            return
        }
        
        for item in items {
            guard let albumName = item["name"] as? String else {
                parsingFailed("No value for album key 'name'")
                return
            }
            
            let name = albumName.folding(options: .diacriticInsensitive, locale: NSLocale.current)
            
            if albumNames.contains(name) {
                continue
            }
            
            guard let albumId = item["id"] as? String else {
                parsingFailed("No value for album key 'id'")
                return
            }
            
            guard let images = item["images"] as? [[String:AnyObject]] else {
                parsingFailed("No value for album key 'images'")
                return
            }
            
            if images.isEmpty {
                imageURL = ""
            } else {
                let image = images.first!
                guard let url = image["url"] as? String else {
                    parsingFailed("No value for image key 'url'")
                    return
                }
                
                imageURL = url
            }
            
            let album = Album(context: coreData.managedContext)
            album.name = albumName
            album.id = albumId
            album.imageURL = imageURL!
            
            albumNames.append(albumName)
        }
        
        coreData.saveContext()
        completionHandlerforAlbumParsing(true, nil)
    }
    
    func parseTracks(_ data: AnyObject?, completionHandlerForTrackParsing: @escaping (_ success: Bool, _ errorMessage: String?) -> Void) {
        func parsingFailed(_ message: String) {
            completionHandlerForTrackParsing(false, message)
            return
        }
        
        guard let data = data else {
            parsingFailed("No data returned in request")
            return
        }
        
        guard let items = data["items"] as? [[String:AnyObject]] else {
            parsingFailed("No track value for key 'item'")
            return
        }
        
        for item in items {
            guard let trackName = item["name"] as? String else {
                parsingFailed("No track value for ket 'name'")
                return
            }
            
            guard let trackNumber = item["track_number"] as? Int else {
                parsingFailed("No track value for key 'track_number'")
                return
            }
            
            guard let previewURL = item["preview_url"] as? String else {
                parsingFailed("No track value for key 'preview_url'")
                return
            }
            
            let track = Track(context: coreData.managedContext)
            track.name = trackName
            track.trackNumber = Int16(trackNumber)
            track.previewURL = previewURL
        }
        
        coreData.saveContext()
        completionHandlerForTrackParsing(true, nil)
    }
    
    func getImage(_ urlString: String?, completionHandlerForImage: @escaping (_ data: Data?) -> Void) {
        if let url = urlString {
            let request = URLRequest(url: URL(string: url)!)
            
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
        } else {
            completionHandlerForImage(nil)
        }
    }
}
