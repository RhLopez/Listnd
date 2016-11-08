//
//  SpotifyAPIConvinience.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 10/2/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import Foundation

extension SpotifyAPI {
    
    func searchArtist(_ userInput: String, completionHandlerForArtistSearch: @escaping (_ success: Bool, _ results: [Artist]?, _ errorMessage: String?) -> Void) {
        let parameters = [
            Constants.ParametersKeys.Query: userInput,
            Constants.ParametersKeys.SearchType: Constants.ParameterValues.Artist,
            Constants.ParametersKeys.Market: Constants.ParameterValues.US
        ]
        
        taskForGetMethod(parameters as [String : AnyObject], path: Constants.ParametersKeys.Search) { (success, errorMessage, data) in
            if success {
                self.parseArtistSearch(data as AnyObject?, completionHandlerForParseArtistSearch: { (success, results, errorMessage) in
                    if success {
                        completionHandlerForArtistSearch(true, results, nil)
                    } else {
                        completionHandlerForArtistSearch(false, nil, errorMessage)
                    }
                })
            } else {
                completionHandlerForArtistSearch(false, nil, errorMessage)
            }
        }
    }
    
    func searchAlbum(_ userInput: String, completionHandlerForAlbumSearch: (_ success: Bool, _ errorMessage: String?, _ results: [[String:AnyObject]]?) -> Void) {
        
    }
    
    func searchSong(_ userInput: String, completionHandlerForSongSearch: (_ success: Bool, _ errorMessage: String?, _ results: [[String:AnyObject]]?) -> Void) {
        
    }
    
    func getAlbums(_ artistId: String, completionHandlerForAlbums: @escaping (_ success: Bool, _ results: [Album]?, _ errorMessage: String?) -> Void) {
        let parameters = [
            Constants.ParametersKeys.AlbumType: Constants.ParameterValues.Album,
            Constants.ParametersKeys.Market: Constants.ParameterValues.US
        ]
        
        let path = Constants.ParametersKeys.ArtistAlbums.replacingOccurrences(of: "{id}", with: artistId)
        
        taskForGetMethod(parameters as [String : AnyObject], path: path) { (success, errorMessage, data) in
            if success {
                self.parseAlbums(data as AnyObject?, completionHandlerforAlbumParsing: { (success, results, errorString) in
                    if success {
                        completionHandlerForAlbums(true, results, nil)
                    } else {
                        completionHandlerForAlbums(false, nil, errorMessage)
                    }
                })
            } else {
                completionHandlerForAlbums(false, nil, errorMessage)
            }
        }
    }
    
    func getTracks(_ albumId: String, completionHandlerForTracks: @escaping (_ success: Bool, _ resutls: [Track]?, _ errorMessage: String?) -> Void) {
        let parameters = [
            Constants.ParametersKeys.Market: Constants.ParameterValues.US
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
    
    func parseAlbumDictionary(_ data: AnyObject?, completionHandlerForParseAlbumDictionary: (_ success: Bool, _ errorMessage: String?, _ result: [[String:AnyObject]]?) -> Void) {
        
    }
    
    func parseArtistSearch(_ data: AnyObject?, completionHandlerForParseArtistSearch: @escaping (_ success: Bool, _ results: [Artist]?, _ errorMessage: String?) -> Void) {

        var imageURL: String?
        var resultNumber = 0
        var artists = [Artist]()
        
        func parsingFailed(_ message: String) {
            completionHandlerForParseArtistSearch(false, nil, message)
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
            
            let artist = Artist(entity: self.artistEntity!, insertInto: nil)
            artist.name = artistName
            artist.id = artistId
            artist.imageURL = imageURL!
            artist.resultNumber = Int16(resultNumber)
            artists.append(artist)
            resultNumber = resultNumber + 1
            
        }
        
        completionHandlerForParseArtistSearch(true, artists, nil)
    }
    
    func parseAlbums(_ data: AnyObject?, completionHandlerforAlbumParsing: @escaping (_ success: Bool, _ results: [Album]?,_ errorMessage: String?) -> Void) {
        var albumNames = [String]()
        var imageURL: String?
        var albums = [Album]()
        
        func parsingFailed(_ message: String) {
            completionHandlerforAlbumParsing(false, nil, message)
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
            
            let album = Album(entity: albumEntity!, insertInto: nil)
            album.name = albumName
            album.id = albumId
            album.imageURL = imageURL!
            albums.append(album)
            
            albumNames.append(albumName)
        }
        
        completionHandlerforAlbumParsing(true, albums, nil)
    }
    
    func parseTracks(_ data: AnyObject?, completionHandlerForTrackParsing: @escaping (_ success: Bool, _ results: [Track]?, _ errorMessage: String?) -> Void) {
        var tracks = [Track]()
        
        func parsingFailed(_ message: String) {
            completionHandlerForTrackParsing(false, nil, message)
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
                parsingFailed("No track value for key 'name'")
                return
            }
            
            guard let trackId = item["id"] as? String else {
                parsingFailed("No track value for key 'id'")
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
            
            let track = Track(entity: trackEntity!, insertInto: nil)
            track.name = trackName
            track.id = trackId
            track.trackNumber = Int16(trackNumber)
            track.previewURL = previewURL
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
    
    func downloadSampleClip() {
        
    }
}
