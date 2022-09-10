import Foundation
import AVKit

protocol PermissionCheckerDelegate: AnyObject {
    func didCheckedPermission()
}

class PermissionChecker {
    typealias CheckCallback = () -> Void
    typealias StatusMessageCallback = (String) -> Void

    var onGranted: CheckCallback?       //Callback to be called when permissions is granted
    var showStatusMessage: StatusMessageCallback?   //Callback to show error
    weak var view: StreamCameraVC?
    weak var delegate: PermissionCheckerDelegate?
    
    init(delegate: PermissionCheckerDelegate) {
        self.delegate = delegate
        check()
    }
    
    var cameraAuthorized: Bool = false {
        didSet {
            if cameraAuthorized {
                self.checkMic()
            } else {
                checkResult(false)
            }
        }
    }
    var micAuthorized: Bool = false {
        didSet {
            checkResult(deviceAuthorized)
        }
    }

    var deviceAuthorized: Bool {
        return cameraAuthorized && micAuthorized
    }

    //Check for camera and microphone authoization. In case of sucess onGranted will be called
    func check() {
        if deviceAuthorized {
            checkResult(true)
        }
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        
        switch (status) {
        case AVAuthorizationStatus.authorized:
            cameraAuthorized = true
        case AVAuthorizationStatus.notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: {
                self.cameraAuthorized = $0
            })
        default:
            cameraAuthorized = false
        }
    }
    
    func checkMic() {
        
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.audio)
        
        switch (status) {
        case AVAuthorizationStatus.authorized:
            micAuthorized = true
        case AVAuthorizationStatus.notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.audio, completionHandler: {
                self.micAuthorized = $0
            })
        default:
            micAuthorized = false
        }
    }
    
    func checkResult(_ allowed: Bool) {
        if allowed {
            delegate?.didCheckedPermission()
            onGranted?()
        } else {
            if !cameraAuthorized {
                presentCameraAccessAlert()
            } else if !micAuthorized == false {
                presentMicAccessAlert()
            }
        }

    }
    
    func presentCameraAccessAlert() {
        let title = NSLocalizedString("Camera is disabled", comment: "")
        let message = NSLocalizedString("Allow the app to access the camera in your device's settings.", comment: "")
        presentAccessAlert(title: title, message: message)
    }
    
    func presentMicAccessAlert() {
        let title = NSLocalizedString("Microphone is disabled", comment: "")
        let message = NSLocalizedString("Allow the app to access the microphone in your device's settings.", comment: "")
        presentAccessAlert(title: title, message: message)
    }
    
    func presentAccessAlert(title: String, message: String) {
        let settingsButtonTitle = NSLocalizedString("Go to settings", comment: "")
        let cancelButtonTitle = NSLocalizedString("Cancel", comment: "")
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let settingsAction = UIAlertAction(title: settingsButtonTitle, style: .default) { [weak self] _ in
            self?.openSettings()
        }
        
        let cancelAction = UIAlertAction(title: cancelButtonTitle, style: .cancel)
        
        alertController.addAction(settingsAction)
        alertController.addAction(cancelAction)
        
        view?.present(alertController, animated: false)

        
        // Also update error message on screen, because user can occasionally cancel alert dialog
        showStatusMessage?(NSLocalizedString("Application doesn't have all permissions to use camera and microphone, please change privacy settings.", comment: ""))
    }
    
    func openSettings() {
        let settingsUrl = URL(string: UIApplication.openSettingsURLString)
        if let url = settingsUrl {
            UIApplication.shared.open(url, options: [:])
        }
    }

}
