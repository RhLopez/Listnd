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
    
    func searchArtist(_ userInput: String, completionHandlerForArtistSearch: @escaping (_ success: Bool, _ results: [Artist]?, _ errorMessage: String) -> Void) {
        let parameters = [
            Constants.ParametersKeys.Query: userInput,
            Constants.ParametersKeys.SearchType: Constants.ParameterValues.Artist,
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
    
    func getTracks(_ albumId: String, completionHandlerForTracks: @escaping (_ success: Bool, _ resutls: [Track]?, _ errorMessage: String?) -> Void) {
        let parameters = [
            Constants.ParametersKeys.Market: Constants.ParameterValues.US,
            Constants.ParametersKeys.Limit: Constants.ParameterValues.LimitAmount
        ]
        
        let path = Constants.ParametersKeys.AlbumTracks.replacingOccurrences(of: "{id}", with: albumId)
        
        taskForGetMethod(parameters as [String : AnyObject], path: path) { (success, errorMessage, data) in
            if success {
                self.parseTracks(data as AnyObject?, completionHandlerForTrackParsing: { (success, results, errorMessage) in
                    if success {
                        completionHandlerForTracks(true, results, nil)
                    } else {
                        completionHandlerForTracks(false, nil, errorMessage)
                    }
                })
            } else {
                completionHandlerForTracks(false, nil, errorMessage)
            }
        }
    }
    
    func parseArtistSearch(_ data: AnyObject?, completionHandlerForParseArtistSearch: @escaping (_ success: Bool, _ results: [Artist]?, _ errorMessage: String) -> Void) {

        var imageURL: String?
        var resultNumber = 0
        var artists = [Artist]()
        
        func parsingFailed() {
            completionHandlerForParseArtistSearch(false, nil, "Unable to process data from Spotify. Please try again.")
            return
        }
        
        guard let data = data else {
            parsingFailed()
            return
        }
        
        guard let artistDictionary = data["artists"] as? [String:AnyObject] else {
            parsingFailed()
            return
        }
        
        guard let items = artistDictionary["items"] as? [[String:AnyObject]] else {
            parsingFailed()
            return
        }
        
        for item in items {
            guard let artistName = item["name"] as? String else {
                parsingFailed()
                return
            }
            
            guard let artistId = item["id"] as? String else {
                parsingFailed()
                return
            }
            
            guard let images = item["images"] as? [[String:AnyObject]] else {
                parsingFailed()
                return
            }
            
            if images.isEmpty {
                imageURL = nil
            } else {
                let item = images.first!
                guard let url = item["url"] as? String else {
                    parsingFailed()
                    return
                }
                
                imageURL = url
            }
            
            let artist = Artist(entity: self.artistEntity!, insertInto: nil)
            artist.name = artistName
            artist.id = artistId
            artist.imageURL = imageURL
            artist.resultNumber = Int16(resultNumber)
            artists.append(artist)
            resultNumber = resultNumber + 1
            
        }
        
        completionHandlerForParseArtistSearch(true, artists, "")
    }
    
    func parseAlbums(_ data: AnyObject?, completionHandlerforAlbumParsing: @escaping (_ success: Bool, _ results: [Album]?,_ errorMessage: String) -> Void) {
        var albumNames = [String]()
        var imageURL: String?
        var albums = [Album]()
        
        func parsingFailed() {
            completionHandlerforAlbumParsing(false, nil, "Unable to process data from Spotify. Please try again")
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
        
        for item in items {
            guard let albumName = item["name"] as? String else {
                parsingFailed()
                return
            }
            
            let name = albumName.folding(options: .diacriticInsensitive, locale: NSLocale.current)
            
            if albumNames.contains(name) {
                continue
            }
            
            guard let albumId = item["id"] as? String else {
                parsingFailed()
                return
            }
            
            guard let uri = item["uri"] as? String else {
                parsingFailed()
                return
            }
            
            guard let album_type = item["album_type"] as? String else {
                parsingFailed()
                return
            }
            
            guard let images = item["images"] as? [[String:AnyObject]] else {
                parsingFailed()
                return
            }
            
            if images.isEmpty {
                imageURL = nil
            } else {
                let image = images.first!
                guard let url = image["url"] as? String else {
                    parsingFailed()
                    return
                }
                
                imageURL = url
            }
            
            let album = Album(entity: albumEntity!, insertInto: nil)
            album.name = albumName
            album.id = albumId
            album.uri = uri
            album.type = album_type
            album.imageURL = imageURL
            albums.append(album)
            album.listened = false
            albumNames.append(albumName)
        }
        
        completionHandlerforAlbumParsing(true, albums, "")
    }
    
    func parseTracks(_ data: AnyObject?, completionHandlerForTrackParsing: @escaping (_ success: Bool, _ results: [Track]?, _ errorMessage: String?) -> Void) {
        var tracks = [Track]()
        var previewURL: String?

        func parsingFailed() {
            completionHandlerForTrackParsing(false, nil, "Unable to process data from Spotify. Please try again")
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
        
        for item in items {
            guard let trackName = item["name"] as? String else {
                parsingFailed()
                return
            }
            
            guard let trackId = item["id"] as? String else {
                parsingFailed()
                return
            }
            
            guard let trackNumber = item["track_number"] as? Int else {
                parsingFailed()
                return
            }
            
            guard let uri = item["uri"] as? String else {
                parsingFailed()
                return
            }
            
            guard let duration = item["duration_ms"] as? Int else {
                parsingFailed()
                return
            }
            
            if let url = item["preview_url"] as? String {
                previewURL = url
            } else {
                previewURL = nil
            }
            
            let track = Track(entity: trackEntity!, insertInto: nil)
            track.name = trackName
            track.id = trackId
            track.trackNumber = Int16(trackNumber)
            track.previewURL = previewURL
            track.uri = uri
            track.duration = Int32(duration)
            track.listened = false
            tracks.append(track)
        }
        
        completionHandlerForTrackParsing(true, tracks, nil)
    }
    
    func getImage(_ urlString: String?, completionHandlerForImage: @escaping (_ data: Data?) -> Void) {
        if let url = urlString {
            let request = URLRequest(url: URL(string: url)!)

            let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
                guard (error == nil) else {
                    print(error?.localizedDescription as Any)
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
