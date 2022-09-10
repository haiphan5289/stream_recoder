//
//  Constants.swift
//  ScoreCam
//
//  Created by Rum on 26/12/2021.
//

import UIKit

enum SBName: String {
    case Main = "Main"
    case Home = "Home"
    case Video = "Video"
    case More = "More"
    case Onboard = "NewOnboard"
}

func DLog(_ object: Any, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
    #if DEBUG
    let className = (fileName as NSString).lastPathComponent
    print("<\(className)> \(functionName) [#\(lineNumber)]|\(Date().stringFromDateWithFormat("hh:mm:ss"))| \(object)\n")
    #endif
}

struct ScreenSize {
    static let SCREEN_WIDTH         = UIScreen.main.bounds.size.width
    static let SCREEN_HEIGHT        = UIScreen.main.bounds.size.height
    static let SCREEN_MAX_LENGTH    = max(ScreenSize.SCREEN_WIDTH, ScreenSize.SCREEN_HEIGHT)
    static let SCREEN_MIN_LENGTH    = min(ScreenSize.SCREEN_WIDTH, ScreenSize.SCREEN_HEIGHT)
}

struct DeviceType {
    static let IS_IPHONE_4_OR_LESS          = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.SCREEN_MAX_LENGTH < 568.0
    static let IS_IPHONE_5                  = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.SCREEN_MAX_LENGTH == 568.0
    static let IS_IPHONE_6                  = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.SCREEN_MAX_LENGTH == 667.0
    static let IS_IPHONE_6_OR_LESS          = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.SCREEN_MAX_LENGTH <= 667.0
    static let IS_IPHONE_6P                 = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.SCREEN_MAX_LENGTH == 736.0
    static let IS_IPHONE_X_OR_XS            = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.SCREEN_MAX_LENGTH == 812.0
    static let IS_IPHONE_XR_OR_XSM          = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.SCREEN_MAX_LENGTH == 896.0
    static let IS_IPAD                      = UIDevice.current.userInterfaceIdiom == .pad && ScreenSize.SCREEN_MAX_LENGTH == 1024.0
    static let IS_IPHONE_12_OR_12PRO        = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.SCREEN_MAX_LENGTH == 844.0
    static let IS_IPHONE_12MINI             = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.SCREEN_MAX_LENGTH == 812
    static let IS_IPHONE_12PRO_MAX          = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.SCREEN_MAX_LENGTH == 926.0
}

struct InApp {
    static let SercetKey = "1c0d8174d1314d55b53e7827b4828dd7"
    static let Weekly = "app.xrecorder.weekly"
    static let Monthly = "app.xrecorder.monthly"
    static let Yearly = "app.xrecorder.yearly"
}

#if DEBUG
struct Ads {
    static let Fullscreen = "ca-app-pub-3940256099942544/4411468910"
}
#else
struct Ads {
    static let Fullscreen = "ca-app-pub-9577477243181944/8483903133"
}
#endif
enum Audio_Quality: Int, CaseIterable {
    case veryhigh = 0
    case high
    case normal
    case low
    
    var title: String {
        switch self {
        case .high:
            return "High"
        case .veryhigh:
            return "Very High"
        case .low:
            return "Low"
        default:
            return "Normal"
        }
    }
}

enum Video_Resolution: Int, CaseIterable {
    case _4k = 0
    case _1440p
    case _1080p
    case hd
    case sd
    
    var title: String {
        switch self {
        case ._4k:
            return "4K"
        case ._1440p:
            return "1440p"
        case ._1080p:
            return "1080p"
        case .hd:
            return "HD"
        default:
            return "SD"
        }
    }
}

enum Video_Framerate: Int, CaseIterable {
    case _24fps = 0
    case _25fps
    case _30fps
    case _50fps
    case _60fps
    
    var title: String {
        switch self {
        case ._24fps:
            return "24 FPS"
        case ._25fps:
            return "25 FPS"
        case ._30fps:
            return "30 FPS"
        case ._50fps:
            return "50 FPS"
        default:
            return "60 FPS"
        }
    }
}

enum Video_Format: Int, CaseIterable {
    case _16_9 = 0
    case _9_16
    
    var title: String {
        switch self {
        case ._16_9:
            return "Landscape"
        default:
            return "Potrait"
        }
    }
}

enum StreamPlatform: Int, CaseIterable {
    case youtube = 0
    case facebook
    case twitch
    case twitter
    case tiktok
    case rtmp
    
    var title: String {
        switch self {
        case .youtube:
            return "YouTube"
        case .facebook:
            return "Facebook"
        case .twitch:
            return "Twitch"
        case .twitter:
            return "Twitter"
        case .tiktok:
            return "Tiktok"
        case .rtmp:
            return "RTMP"
        }
    }
    
    var image: UIImage {
        switch self {
        case .youtube:
            return #imageLiteral(resourceName: "icPlatformYoutube")
        case .facebook:
            return #imageLiteral(resourceName: "icPlatformFace")
        case .twitch:
            return #imageLiteral(resourceName: "icPlatformTwitch")
        case .twitter:
            return #imageLiteral(resourceName: "icPlatformTwitter")
        case .tiktok:
            return #imageLiteral(resourceName: "icPlatformTiktok")
        case .rtmp:
            return #imageLiteral(resourceName: "icRTMP")
        }
    }
}

enum StreamSource: Int, CaseIterable {
    case screen = 0
    case camera
    //case media
    
    var title: String {
        switch self {
        case .screen:
            return "Screen"
        case .camera:
            return "Camera"
        //case .media:
          //  return "Media File"
        }
    }
    
    var image: UIImage {
        switch self {
        case .screen:
            return #imageLiteral(resourceName: "icStreamScreen")
        case .camera:
            return #imageLiteral(resourceName: "icStreamCamera")
        //case .media:
           // return #imageLiteral(resourceName: "icStreamFile")
        }
    }
    
    var is_available: Bool {
        switch self {
        case .screen:
            return true
        case .camera:
            return true
        //case .media:
          //  return false
        }
    }
}
