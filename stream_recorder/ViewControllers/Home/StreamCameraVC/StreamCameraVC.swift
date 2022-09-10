//
//  StreamCameraVC.swift
//  stream_recorder
//
//  Created by HHumorous on 08/04/2022.
//

import UIKit
import AVFoundation
import Photos
import FaceCamFW

class StreamCameraVC: UIViewController {
    
    @IBOutlet weak var vStart: UIView!
    @IBOutlet weak var vStop: UIView!
    @IBOutlet weak var vCamera: UIView!
    @IBOutlet weak var lblTimer: UILabel!
    @IBOutlet weak var stvButton: UIStackView!
    
    lazy var vLoadingStream: StartStreamView = {
        let view = StartStreamView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        return view
    }()
    
    var streamer: Streamer?                             // Class to control camera and broadcasting
    var previewLayer: AVCaptureVideoPreviewLayer?       // Camera preview
    var permissionChecker: PermissionChecker?           // Class to check camera/mic permission
    var canStartCapture = true                          // Used to prevent start capture when it already running
    var mediaResetPending = false                       // Used to reintialize capture after reset
    var isBroadcasting = false                          // Set to true when streaming is active
    var connectionId: Int32 = -1                        // ID of active connection
    var connectionState: ConnectionState = .disconnected
    var timer: CountdownService?
    var isMulticam: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()

        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIScene.didActivateNotification, object: nil)

        nc.addObserver(self, selector: #selector(applicationWillResignActive), name: UIScene.willDeactivateNotification, object: nil)
        // Do any additional setup after loading the view.
        AudioSession.sharedInstance?.observer = self
        
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        permissionChecker = PermissionChecker(delegate: self)
        permissionChecker?.view = self
    }
    
    @objc func applicationDidBecomeActive() {
        if viewIfLoaded?.window != nil {
            permissionChecker?.check()
        }
   }
    
    @objc func applicationWillResignActive() {
        if viewIfLoaded?.window != nil {
            stopBroadcast()
            removePreview()
            stopCapture()
        }
    }
    
    @objc func orientationDidChange(notification: Notification) {
        let frame = vCamera.frame
        previewLayer?.frame = frame

        let deviceOrientation = UIApplication.shared.statusBarOrientation
        let newOrientation = AVCaptureVideoOrientation(rawValue: deviceOrientation.rawValue) ?? AVCaptureVideoOrientation.portrait
        previewLayer?.connection?.videoOrientation = newOrientation
    }
    
    func toAVCaptureVideoOrientation(deviceOrientation: UIInterfaceOrientation, defaultOrientation: AVCaptureVideoOrientation) -> AVCaptureVideoOrientation {
        
        var captureOrientation: AVCaptureVideoOrientation
        
        switch (deviceOrientation) {
        case .portrait:
            // Device oriented vertically, home button on the bottom
            //DDLogVerbose("AVCaptureVideoOrientationPortrait")
            captureOrientation = AVCaptureVideoOrientation.portrait
        case .portraitUpsideDown:
            // Device oriented vertically, home button on the top
            //DDLogVerbose("AVCaptureVideoOrientationPortraitUpsideDown")
            captureOrientation = AVCaptureVideoOrientation.portraitUpsideDown
        case .landscapeLeft:
            // Device oriented horizontally, home button on the right
            //DDLogVerbose("AVCaptureVideoOrientationLandscapeLeft")
            captureOrientation = AVCaptureVideoOrientation.landscapeLeft
        case .landscapeRight:
            // Device oriented horizontally, home button on the left
            //DDLogVerbose("AVCaptureVideoOrientationLandscapeRight")
            captureOrientation = AVCaptureVideoOrientation.landscapeRight
        default:
            captureOrientation = defaultOrientation
        }
        return captureOrientation
    }
    
    func startCapture() {
        guard canStartCapture else {
            return
        }
        do {
            let audioOnly = Settings.sharedInstance.radioMode
            canStartCapture = false
            
            removePreview()
            
            if !audioOnly && StreamerMultiCam.isSupported() {
                streamer = StreamerMultiCam()
                isMulticam = streamer != nil
            }
            if streamer == nil {
                streamer = StreamerSingleCam()
                isMulticam = false
            }
            streamer?.delegate = self
            if !audioOnly {
                streamer?.videoConfig = Settings.sharedInstance.videoConfig
            }
            streamer?.audioConfig = Settings.sharedInstance.audioConfig
            DispatchQueue.main.async {
                let deviceOrientation = UIApplication.shared.statusBarOrientation
                let newOrientation = self.toAVCaptureVideoOrientation(deviceOrientation: deviceOrientation, defaultOrientation: AVCaptureVideoOrientation.portrait)
                if let stereoOrientation = AVAudioSession.StereoOrientation(rawValue: newOrientation.rawValue) {
                    self.streamer?.stereoOrientation = stereoOrientation
                }
            }

            try streamer?.startCapture(startAudio: true, startVideo: !audioOnly)
            
            let nc = NotificationCenter.default
            nc.addObserver(
                self,
                selector: #selector(orientationDidChange(notification:)),
                name: UIDevice.orientationDidChangeNotification,
                object: nil)
            
        } catch {
            canStartCapture = true
        }
    }
    
    func stopCapture() {
        NSLog("stopCapture")
        canStartCapture = true

        streamer?.stopCapture()
        streamer = nil
        let nc = NotificationCenter.default
        nc.removeObserver(self, name: UIDevice.orientationDidChangeNotification,
                          object: nil)
    }
    
    func setupUI() {
        vStart.isHidden = false
        vStop.isHidden = true
    }
    
    @IBAction func onPressStart(_ sender: UIButton) {
        self.startBroadcast()
        self.streamer?.startRecord()
    }
    
    @IBAction func onPressStop(_ sender: UIButton) {
        stopBroadcast()
        self.streamer?.stopRecord()
    }
    
    @IBAction func onPressFlip(_ sender: UIButton) {
        streamer?.changeCamera()
    }
    
    @IBAction func onPressFlash(_ sender: UIButton) {
        _ = streamer?.toggleFlash()
    }
    
    @IBAction func onPressMic(_ sender: UIButton) {
        streamer?.isMuted = !(streamer?.isMuted ?? true)
    }

    @IBAction func onPressClose(_ sender: UIButton) {
        dismiss(animated: true)
    }

    // MARK: Connection utitlites
    func createConnection(urlTo: String) {
        var id: Int32 = -1
        let url = URL.init(string: urlTo)
        
        if let scheme = url?.scheme?.lowercased(), let host = url?.host {

            if scheme.hasPrefix("rtmp") || scheme.hasPrefix("rtsp") {
                let config = ConnectionConfig()
                config.uri = url
                id = streamer?.createConnection(config: config) ?? -1
                
            } else if scheme == "srt", let port = url?.port {
                let config = SrtConfig()
                config.host = host
                config.port = Int32(port)
                id = streamer?.createStrConnection(config: config) ?? -1
            } else if scheme == "rist" {
                let config = RistConfig()
                config.uri = url

                id = streamer?.createRistConnection(config: config) ?? -1
            }
        } else {
            UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseInOut]) {
                self.vLoadingStream.updateUIFalse()
            }
            
            return
        }
        
        if id != -1 {
            connectionId = id
        }
        
        DLog("SwiftApp::create connection: \(id), \(urlTo)")
    }
    
    func releaseConnection(id: Int32) {
        if id != -1 {
            connectionId = -1
            connectionState = .disconnected
            streamer?.releaseConnection(id: id)
        }
    }
    
    func removePreview() {
        previewLayer?.removeFromSuperlayer()
        previewLayer = nil
    }
    
    func startBroadcast() {
        guard let stream_url = Cache.shared.stream_url,
              let stream_key = Cache.shared.stream_key else { return }
        broadcastWillStart()
        let streamURL = stream_url + "/" + stream_key
        
        vLoadingStream = StartStreamView()
        view.addSubview(vLoadingStream)
        vLoadingStream.fillSuperview()
        vLoadingStream.delegate = self
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.createConnection(urlTo: streamURL)
        }
        
    }
    
    func stopBroadcast() {
        broadcastWillStop()
        releaseConnection(id: connectionId)
    }
    
    func broadcastWillStart() {
        if !isBroadcasting {
            NSLog("start broadcasting")
            isBroadcasting = true
        }
    }
    
    func broadcastWillStop() {
        if isBroadcasting {
            NSLog("stop broadcasting")
            isBroadcasting = false
        }
    }
}

extension StreamCameraVC: StartStreamViewDelegate {
    func didRetryConnect() {
        guard let stream_url = Cache.shared.stream_url,
              let stream_key = Cache.shared.stream_key else { return }
        broadcastWillStart()
        let streamURL = stream_url + "/" + stream_key

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.createConnection(urlTo: streamURL)
        }
    }
    
    func didCancelConnect() {
        vLoadingStream.stateConnect = .connecting
        vLoadingStream.removeFromSuperview()
    }
    
    func didPrepareLivestreamDone() {
        vLoadingStream.removeFromSuperview()
        UIView.animate(withDuration: 0.25, delay: 0, options: [.showHideTransitionViews]) {
            self.vStop.isHidden = false
            self.stvButton.isHidden = false
            self.vStart.isHidden = true
            
            if self.timer == nil {
                self.timer = CountdownService()
                self.timer?.start(beginingValue: 0, interval: 1, countDown: false)
                self.timer?.delegate = self
            }
        }
    }
}

extension StreamCameraVC: PermissionCheckerDelegate {
    func didCheckedPermission() {
        startCapture()
    }
}

extension StreamCameraVC: AudioSessionStateObserver {
    func mediaServicesWereLost() {
        if viewIfLoaded?.window != nil && (permissionChecker?.deviceAuthorized ?? true) {
            mediaResetPending = streamer?.session != nil
            stopBroadcast()
            removePreview()
            stopCapture()
        }
    }
    
    func mediaServicesWereReset() {
        if viewIfLoaded?.window != nil && (permissionChecker?.deviceAuthorized ?? true) {
            NSLog("mediaServicesWereReset, pending:\(mediaResetPending)")
            if mediaResetPending {
                startCapture()
                mediaResetPending = false
            }
        }
    }
}

extension StreamCameraVC: StreamerAppDelegate {
    func notification(notification: StreamerNotification) {
        //
    }
    
    func photoSaved(fileUrl: URL) {
        //
    }
    
    func videoRecordStarted() {
        //
    }
    
    func videoSaved(fileUrl: URL) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileUrl)
        }) { saved, error in
            if saved {
                DLog("Save")
            }
        }
    }
    
    func captureStateDidChange(state: CaptureState, status: Error) {
        DispatchQueue.main.async {
            self.onCaptureStateChange(state: state, status: status)
        }
    }
    
    func onCaptureStateChange(state: CaptureState, status: Error) {
        switch (state) {
        case .CaptureStateStarted:
            if let session = streamer?.session {
                previewLayer = AVCaptureVideoPreviewLayer(session: session)
                previewLayer?.frame = view.frame
                previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
                if let preview = previewLayer {
                    vCamera.layer.insertSublayer(preview, at: 0)
                }
            }
            
        case .CaptureStateFailed:
            if streamer == nil {
                return
            }
            stopBroadcast()
            removePreview()
            stopCapture()
        case .CaptureStateCanRestart:
            break
            
        case .CaptureStateSetup:
            break
        default: break
        }
    }
    
    func connectionStateDidChange(id: Int32, state: ConnectionState, status: ConnectionStatus, info: [AnyHashable:Any]!) {
        DispatchQueue.main.async {
            self.onConnectionStateChange(id: id, state: state, status: status, info: info)
        }
    }
    
    func onConnectionStateChange(id: Int32, state: ConnectionState, status: ConnectionStatus, info: [AnyHashable:Any]!) {
        
        // ignore disconnect confirmation after releaseConnection call
        if id != connectionId {
            if self.timer != nil {
                self.timer?.end()
            }
            
            UIView.animate(withDuration: 0.25, delay: 0, options: [.showHideTransitionViews]) {
                self.vStop.isHidden = true
                self.vStart.isHidden = false
                self.stvButton.isHidden = false
            }
            return
        }
            
        connectionState = state
        
        if state == .connected {
            self.vLoadingStream.updateUISuccess()
        }
        
        if state != .disconnected {
            return
        }
        
        releaseConnection(id: id)
            
        switch (status) {
        case .connectionFail:
            self.vLoadingStream.updateUIFalse()
        case .unknownFail:
            self.vLoadingStream.updateUIFalse()
            
            var status: String?
            if let info = info, info.count > 0 {
                if let jsonData = try? JSONSerialization.data(withJSONObject: info) {
                    status = String(data: jsonData, encoding: .utf8)
                }
            }
            
            if let status = status {
                DLog(NSLocalizedString("Error: \(status)", comment: ""))
            } else {
                DLog(NSLocalizedString("Unknown connection error", comment: ""))
            }
        case .authFail:
            self.vLoadingStream.updateUIFalse()
        case .success:
            DLog("Disconnected")
        @unknown default:
            break
        }

        stopBroadcast()
    }
}

extension StreamCameraVC: CountdownServiceDelegate {
    func timerDidUpdateCounterValue(newValueString: String) {
        self.lblTimer.text = newValueString
    }
    
    func timerDidEnd() {
        timer = nil
    }
}
