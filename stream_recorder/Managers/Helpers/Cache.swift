//
//  Cache.swift
//  ScoreCam
//
//  Created by Rum on 26/12/2021.
//

import UIKit

class Cache: NSObject {
    static let shared = Cache()
    
    let userDefaults = UserDefaults.standard
    
    var app_language: AppLanguage {
        get {
            if let language = userDefaults.string(forKey: "app_language") {
                return AppLanguage(rawValue: language) ?? .English
            } else {
                let current = NSLocale.current.languageCode
                if current == AppLanguage.Vietnamese.rawValue {
                    return .Vietnamese
                } else {
                    return .English
                }
            }
        }
        set {
            userDefaults.setValue(newValue.rawValue, forKey: "app_language")
            userDefaults.synchronize()
        }
    }
    
    var stream_platform: StreamPlatform {
        get {
            let cached = userDefaults.integer(forKey: "stream_platform")
            return StreamPlatform(rawValue: cached) ?? .youtube
        }
        set {
            userDefaults.setValue(newValue.rawValue, forKey: "stream_platform")
        }
    }
    
    var stream_source: StreamSource {
        get {
            let cached = userDefaults.integer(forKey: "stream_source")
            return StreamSource(rawValue: cached) ?? .screen
        }
        set {
            userDefaults.setValue(newValue.rawValue, forKey: "stream_source")
        }
    }
    
    var video_resolution: Video_Resolution {
        get {
            let cached = userDefaults.integer(forKey: "app_video_resolution")
            return Video_Resolution(rawValue: cached) ?? ._4k
        }
        set {
            userDefaults.setValue(newValue.rawValue, forKey: "app_video_resolution")
        }
    }
    
    var audio_quality: Audio_Quality {
        get {
            let cached = userDefaults.integer(forKey: "app_audio_quality")
            return Audio_Quality(rawValue: cached) ?? .veryhigh
        }
        set {
            userDefaults.setValue(newValue.rawValue, forKey: "app_audio_quality")
        }
    }
    
    var video_framerate: Video_Framerate {
        get {
            let cached = userDefaults.integer(forKey: "app_video_framerate")
            return Video_Framerate(rawValue: cached) ?? ._30fps
        }
        set {
            userDefaults.setValue(newValue.rawValue, forKey: "app_video_framerate")
        }
    }
    
    var video_format: Video_Format {
        get {
            let cached = userDefaults.integer(forKey: "app_video_format")
            return Video_Format(rawValue: cached) ?? ._16_9
        }
        set {
            userDefaults.setValue(newValue.rawValue, forKey: "app_video_format")
        }
    }
    
    var video_bitrate: String? {
        get {
            let cached = userDefaults.string(forKey: "app_video_bitrate")
            return cached
        }
        set {
            userDefaults.setValue(newValue, forKey: "app_video_bitrate")
        }
    }
    
    var show_livestream: Bool {
        get {
            let cached = userDefaults.bool(forKey: "show_livestream")
            return cached
        }
        set {
            userDefaults.setValue(newValue, forKey: "show_livestream")
        }
    }
    
    var stream_url: String? {
        get {
            let cached = UserDefaults(suiteName: "group.beelab.stream.xrecorder.broadcast")?.string(forKey: "stream_url")
            return cached
        }
        set {
            UserDefaults(suiteName: "group.beelab.stream.xrecorder.broadcast")?.setValue(newValue, forKey: "stream_url")
        }
    }
    
    var stream_key: String? {
        get {
            let cached = UserDefaults(suiteName: "group.beelab.stream.xrecorder.broadcast")?.string(forKey: "stream_key")
            return cached
        }
        set {
            UserDefaults(suiteName: "group.beelab.stream.xrecorder.broadcast")?.setValue(newValue, forKey: "stream_key")
        }
    }
    
    var show_chat: Bool {
        get {
            let cached = userDefaults.bool(forKey: "app_show_chat")
            return cached
        }
        set {
            userDefaults.setValue(newValue, forKey: "app_show_chat")
        }
    }
    
    var zoom_button: Bool {
        get {
            let cached = userDefaults.bool(forKey: "app_zoom_button")
            return cached
        }
        set {
            userDefaults.setValue(newValue, forKey: "app_zoom_button")
        }
    }
    
    var front_camera: Bool {
        get {
            let cached = userDefaults.bool(forKey: "app_front_camera")
            return cached
        }
        set {
            userDefaults.setValue(newValue, forKey: "app_front_camera")
        }
    }
    
    var save_video: Bool {
        get {
            let cached = userDefaults.bool(forKey: "app_save_video")
            return cached
        }
        set {
            userDefaults.setValue(newValue, forKey: "app_save_video")
        }
    }
    
    var grid_mode: Bool {
        get {
            let cached = userDefaults.bool(forKey: "app_grid_mode")
            return cached
        }
        set {
            userDefaults.setValue(newValue, forKey: "app_grid_mode")
        }
    }
    
    var full_screen: Bool {
        get {
            let cached = userDefaults.bool(forKey: "full_screen")
            return cached
        }
        set {
            userDefaults.setValue(newValue, forKey: "full_screen")
        }
    }
    
    var zoom_control: Bool {
        get {
            let cached = userDefaults.bool(forKey: "zoom_control")
            return cached
        }
        set {
            userDefaults.setValue(newValue, forKey: "zoom_control")
        }
    }
    
    var is_premium: Bool {
        get {
            let cached = userDefaults.bool(forKey: "is_premium")
            return cached
        }
        set {
            userDefaults.setValue(newValue, forKey: "is_premium")
        }
    }
    
    var app_launch: Bool {
        get {
            let cached = userDefaults.bool(forKey: "app_launch")
            return cached
        }
        set {
            userDefaults.setValue(newValue, forKey: "app_launch")
        }
    }
}
