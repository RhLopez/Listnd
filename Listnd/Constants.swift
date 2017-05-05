//
//  Constants.swift
//  Listnd
//
//  Created by Ramiro H. Lopez on 10/2/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import Foundation

extension SpotifyAPI {
    
    struct Constants {
        struct API {
            static let APIScheme = "https"
            static let BaseURL = "api.spotify.com"
            static let APIPath = "/v1"
        }
        
        struct ParametersKeys {
            static let Search = "/search"
            static let Query = "q"
            static let SearchType = "type"
            static let Albums = "/albums/{id}"
            static let AlbumTracks = "/albums/{id}/tracks"
            static let Artist = "/artist"
            static let ArtistAlbums = "/artists/{id}/albums"
            static let Track = "/tracks/{id}"
            static let Market = "market"
            static let AlbumType = "album_type"
            static let Limit = "limit"
        }
        
        struct ParameterValues {
            static let All = "artist,album,track"
            static let Artist = "artist"
            static let AlbumSearch = "album,single"
            static let Track = "track"
            static let US = "US"
            static let LimitAmount = "50"
        }
    }
}
