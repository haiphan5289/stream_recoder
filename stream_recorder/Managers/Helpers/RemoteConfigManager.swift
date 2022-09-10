//
//  RemoteConfigManager.swift
//  stream_recorder
//
//  Created by Huy on 14/03/2022.
//

import Foundation
import FirebaseRemoteConfig

enum RemoteConfigKey: String {
    case appModeV19 /*
                     1: Không onboarding, ko khóa ngoài, khóa các tính năng bên trong
                     2: Onboarding, khóa ngoài
                     3: Onboarding, ko khóa ngoài
                     */
    case lockStreamScreen
    case lockStreamCamera
    case lockSreenRecording
    case lockFaceCam
}

class RemoteConfigManager {
    
    static let sharedInstance = RemoteConfigManager()
    
    var loadingDoneCallback: (() -> Void)?
    var fetchComplete = false

    private init() {
        #if DEBUG
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        RemoteConfig.remoteConfig().configSettings = settings
        #endif
        loadDefaultValues()
        fetchCloudValues()
    }
    
    func fetchCloudValues() {
        RemoteConfig.remoteConfig().fetch {
            [weak self] (status, error) in

                if let error = error {
                    debugPrint("Uh-oh. Got an error fetching remote values \(error)")
                    return
                }

            RemoteConfig.remoteConfig().activate(completion: { (status, error) in
                if let error = error {
                    debugPrint(error)
                    return
                }
                debugPrint("Retrieved values from the cloud!")
                self?.fetchComplete = true
                self?.loadingDoneCallback?()
            })
                
        }
    }
    
    func loadDefaultValues() {
        let appDefaults: [String: Any?] = [
            RemoteConfigKey.appModeV19.rawValue: 1,
            RemoteConfigKey.lockStreamScreen.rawValue: true,
            RemoteConfigKey.lockStreamCamera.rawValue: true,
            RemoteConfigKey.lockSreenRecording.rawValue: true,
            RemoteConfigKey.lockFaceCam.rawValue: true,
        ]
        
        RemoteConfig.remoteConfig().setDefaults(appDefaults as? [String: NSObject])
    }
    
    func double(forKey key: RemoteConfigKey) -> Double {
       let numberValue = RemoteConfig.remoteConfig()[key.rawValue].numberValue
        return numberValue.doubleValue
        
    }
    
    func boolValue(forKey key: RemoteConfigKey) -> Bool {
        return RemoteConfig.remoteConfig()[key.rawValue].boolValue
    }
    
    func numberValue(forKey key: RemoteConfigKey) -> NSNumber? {
        return RemoteConfig.remoteConfig()[key.rawValue].numberValue
    }

    func stringValue(forKey key: RemoteConfigKey) -> String? {
        return RemoteConfig.remoteConfig()[key.rawValue].stringValue
    }
    
    func jsonValue(forKey key: RemoteConfigKey) -> Any? {
        return RemoteConfig.remoteConfig()[key.rawValue].jsonValue
    }

}
