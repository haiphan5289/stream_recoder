import AVFoundation
import CoreImage
import CocoaLumberjackSwift
import UIKit

enum StreamerError: Error {
    case DeviceNotAuthorized
    case NoDelegate
    case NoVideoConfig
    case NoAudioConfig
    case SetupFailed
    case MultiCamNotSupported
}

enum MultiCamPicturePosition {
    case off
    case pip_front
    case pip_back
    case left_front
    case left_back
}

extension StreamerError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .DeviceNotAuthorized:
            return NSLocalizedString("Allow the app to access camera and microphone in your device's settings", comment: "")            
        case .SetupFailed:
            return NSLocalizedString("Can't initialize capture", comment: "")
        default:
            return NSLocalizedString("Can't initialize streamer", comment: "")
        }
    }
}

// add seconds to CMTime, may be useful to shift presentation time stamp
extension CMTime {
    func timeWithOffset(offset: TimeInterval) -> CMTime {
        let seconds = CMTimeGetSeconds(self)
        let secondsWithOffset = seconds + offset
        return CMTimeMakeWithSeconds(secondsWithOffset, preferredTimescale: timescale)
    }
}

class StreamerSingleton {
    static let sharedEngine = StreamerEngineProxy()
    static let sharedQueue = DispatchQueue(label: "stream_recorder")
    private init() {} // This prevents others from using the default '()' initializer for this class.
}

class Streamer: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate,
AVCapturePhotoCaptureDelegate, StreamerEngineDelegate {
    
    override init() {
        silenceGenerator = SilenceGenerator()
        super.init()
    
        engine.setDelegate(self)
        engine.setInterleaving(true)
        
    }
    
    weak var delegate: StreamerAppDelegate?
    var videoConfig: VideoConfig?
    var audioConfig: AudioConfig?
    
    var session: AVCaptureSession?
    internal var workQueue = StreamerSingleton.sharedQueue
    var isPaused: Bool = false {
        didSet {
            engine.setSilence(isMuted || isPaused)
        }
    }
    
    // audio
    internal var recordDevice: AVCaptureDevice?
    private var audioIn: AVCaptureInput?
    private var audioOut: AVCaptureAudioDataOutput?
    private var audioConnection: AVCaptureConnection?
    internal var silenceGenerator: SilenceGenerator

    // mp4 record
    internal var isRecording = false
    internal var isRecordSessionStarted = false
    private var recordMode: ConnectionMode = .videoAudio
    // jpeg capture
    internal var photoFileName: String?

    internal let PixelFormat_YUV = kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
    var baseZoomFactor: CGFloat = 1
    var maxZoomFactor: CGFloat = 1

    // live rotation
    var orientation: AVCaptureVideoOrientation = .landscapeLeft
    var stereoOrientation: AVAudioSession.StereoOrientation = .landscapeLeft {
        didSet {
            updateStereo()
        }
    }
    internal var ciContext: CIContext?
    internal var position: AVCaptureDevice.Position = .back
    internal let PixelFormat_RGB = kCVPixelFormatType_32BGRA
    
    internal var streamWidth: Int = 192
    internal var streamHeight: Int = 144
    
    internal var engine = StreamerSingleton.sharedEngine

    internal var postprocess: Bool {
        false
    }
    internal var currentFpsRange: AVFrameRateRange?
    internal var currentFps: Double = 0.0
    
    internal var stereo: Bool = false
    
    
    internal var videoOrientation: AVCaptureVideoOrientation {
        // CoreImage filters enabled, we will rotate video on app side, so request not rotated buffers
        if postprocess {
            return .landscapeRight
        } else {
            // CoreImage filters disabled; camera will rotate buffers for us
            if videoConfig?.portrait == true {
                return .portrait
            } else {
                return .landscapeRight
            }
        }
    }
    
    var fps: Int {
        let fps = engine.getFps()
        return Int(round(fps))
    }
    
    var videoCodecType: CMVideoCodecType {
        return videoConfig?.type ?? kCMVideoCodecType_H264
    }
    
    // MARK: Mute OnOff
    var isMuted: Bool = false {
        didSet {
            engine.setSilence(isMuted)
        }
    }
    
    var previewPosition: MultiCamPicturePosition {
        return .off
    }
    
    var previewPositionPip: MultiCamPicturePosition {
        return .off
    }
    
    // MARK: Rtmp connection
    func createConnection(config: ConnectionConfig) -> Int32 {
        return engine.createConnection(config)
    }
    
    func createStrConnection(config: SrtConfig) -> Int32 {
        return engine.createSrtConnection(config)
    }

    func createRistConnection(config: RistConfig) -> Int32 {
        return engine.createRistConnection(config)
    }

    func releaseConnection(id: Int32) {
        engine.releaseConnection(id)
    }
    
    // MARK: Rtmp connection: notifications
    public func connectionStateDidChangeId(_ connectionID: Int32, state: ConnectionState, status: ConnectionStatus, info: [AnyHashable:Any]) {
        delegate?.connectionStateDidChange(id: connectionID, state: state, status: status, info: info)
    }
    
    // MARK: File recording notification
    internal func recordStateDidChange(_ state: RecordState, url: URL?) {
        switch state {
        case .initialized:
            isRecording = true
        case .started:
            isRecordSessionStarted = true
            delegate?.videoRecordStarted()
        case .stopped:
            isRecording = false
            if let url = url {
                delegate?.videoSaved(fileUrl: url)
            }
        case .failed:
            isRecording = false
        default:
            DDLogError("Unknown recording state");
        }
    }
    
    // MARK: Rtmp connection: statistics
    func bytesSent(connection: Int32) -> UInt64 {
        return engine.getBytesSent(connection)
    }

    func bytesDelivered(connection: Int32) -> UInt64 {
        return engine.getBytesDelivered(connection)
    }

    func bytesRecv(connection: Int32) -> UInt64 {
        return engine.getBytesRecv(connection)
    }
    
    func udpPacketsLost(connection: Int32) -> UInt64 {
        return engine.getUdpPacketsLost(connection)
    }
    
    // MARK: Capture setup
    func startCapture(startAudio: Bool, startVideo: Bool) throws {
        guard delegate != nil else {
            throw StreamerError.NoDelegate
        }
        if startAudio && startVideo {
            recordMode = .videoAudio
        } else if startAudio {
            recordMode = .audioOnly
        } else if startVideo {
            recordMode = .videoOnly
        }
        if startAudio {
            guard AVCaptureDevice.authorizationStatus(for: AVMediaType.audio) == AVAuthorizationStatus.authorized else {
                throw StreamerError.DeviceNotAuthorized
            }
            guard audioConfig != nil else {
                throw StreamerError.NoAudioConfig
            }
        }
        if startVideo {
            guard AVCaptureDevice.authorizationStatus(for: AVMediaType.video) == AVAuthorizationStatus.authorized else {
                throw StreamerError.DeviceNotAuthorized
            }
            guard videoConfig != nil else {
                throw StreamerError.NoVideoConfig
            }
        }
        
        workQueue.async {
            do {
                guard self.session == nil else {
                    DDLogVerbose("session is running (guard)")
                    return
                }
                DDLogVerbose("startCapture (async)")
                
                self.notifySetupProgress(step: CaptureStatus.CaptureStatusStepInitial)
                
                // IMPORTANT NOTE:
                
                // The way applications handle audio is through the use of audio sessions. When your app is launched, behind the scenes it is provided with a singleton instance of an AVAudioSession. Your app use the shared instance of AVAudioSession to configure the behavior of audio in the application.
                
                // https://developer.apple.com/documentation/avfoundation/avaudiosession
                
                // Before configuring AVCaptureSession app MUST configure and activate audio session. Refer to AppDelegate.swift for details.
                
                // ===============


                // AVCaptureSession is completely managed by application, libmbl2 will not change neither CaptureSession's settings nor camera settings.
                self.session = self.createSession()

                // We want to select input port (Built-in mic./Headset mic./AirPods) on our own
                // Also it keeps h/w sample rate as is (48kHz for Built-in mic. and 16kHz for AirPods)
                self.session?.automaticallyConfiguresApplicationAudioSession = false

                // Raw audio and video will be delivered to app in form of CMSampleBuffer. Refer to func captureOutput for details.
                
                if startAudio {
                    self.notifySetupProgress(step: CaptureStatus.CaptureStatusStepAudioSession)
                    
                    // Prerequisites: AVAudioSession is active.
                    // Refer to AppDelegate.swift / startAudio() for details.
                    try self.setupAudioSession()
                    
                    self.engine.setAudioConfig(self.createAudioEncoderConfig())
                    
                    self.notifySetupProgress(step: CaptureStatus.CaptureStatusStepAudio)
                    try self.setupAudio()
                    
                    self.isMuted = false
                }
                
                if startVideo {
                    
                    // If "Live rotation" is on, we will use CoreImage filters. You can add any custom filter like wartermark, etc.
                    // https://developer.apple.com/library/content/documentation/GraphicsImaging/Conceptual/CoreImaging/ci_tasks/ci_tasks.html
                    // All of the processing of a core image is done in a CIContext. You will always need one when outputting the CIImage object.
                    
                    // Consider disabling color management if: Your app needs the absolute highest performance. Users won't notice the quality differences after exaggerated manipulations.
                    // To disable color management, set the kCIImageColorSpace key to null. If you are using an EAGL context, also set the context colorspace to null when you create the EAGL context.
                    
                    if self.postprocess {
                        self.notifySetupProgress(step: CaptureStatus.CaptureStatusStepFilters)
                        
                        let options = [CIContextOption.workingColorSpace: NSNull(),
                                       CIContextOption.outputColorSpace: NSNull(),
                                       CIContextOption.useSoftwareRenderer: NSNumber(value: false)]
                        self.ciContext = CIContext(options: options)
                        guard self.ciContext != nil else {
                            self.delegate?.captureStateDidChange(state: CaptureState.CaptureStateFailed, status: CaptureStatus.CaptureStatusErrorCoreImage)
                            return
                        }
                    }
                    
                    // Start VTCompressionSession to encode raw video to h264, and then feed libmbl2 with CMSampleBuffer produced by AVCaptureSession.
                    
                    self.engine.setVideoConfig(self.createVideoEncoderConfig())
                    self.notifySetupProgress(step: CaptureStatus.CaptureStatusStepH264)
                    
                    let h264Started = self.engine.startVideoEncoding()
                    guard h264Started else {
                        self.delegate?.captureStateDidChange(state: CaptureState.CaptureStateFailed, status: CaptureStatus.CaptureStatusErrorH264)
                        return
                    }
                    
                    self.notifySetupProgress(step: CaptureStatus.CaptureStatusStepVideoIn)
                    try self.setupVideoIn()
                    
                    self.notifySetupProgress(step: CaptureStatus.CaptureStatusStepVideoOut)
                    try self.setupVideoOut()
                    
                    self.notifySetupProgress(step: CaptureStatus.CaptureStatusStepStillImage)
                    try self.setupStillImage()
                }
                
                self.notifySetupProgress(step: CaptureStatus.CaptureStatusStepSessionStart)
                
                // Only setup observers and start the session running if setup succeeded.
                self.registerForNotifications()
                self.session!.startRunning()
                // Wait for AVCaptureSessionDidStartRunning notification.
                
            } catch {
                DDLogError("can't start capture: \(error)")
                self.delegate?.captureStateDidChange(state: CaptureState.CaptureStateFailed, status: error)
            }
        }
    }
    
    internal func createSession() -> AVCaptureSession? {
        return nil
    }
    
    private func notifySetupProgress(step: CaptureStatus) {
        delegate?.captureStateDidChange(state: CaptureState.CaptureStateSetup, status: step)
    }
    
    private func setupAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(audioSessionRouteChange(notification:)),
            name: AVAudioSession.routeChangeNotification,
            object: audioSession)
        
        if let inputs = audioSession.availableInputs, let preferredInput = Settings.sharedInstance.preferredInput {
            for input in inputs {
                DDLogVerbose("\(input)")
                if input.portType == preferredInput {
                    if !setupStereo(input: input) {
                        unsetStereo(input: input)
                    }
                    try audioSession.setPreferredInput(input)
                }
            }
        } else {
            try audioSession.setPreferredInput(nil)
        }
        if #available(iOS 13.0, *) {
            try audioSession.setAllowHapticsAndSystemSoundsDuringRecording(true)
        }
        DispatchQueue.main.async {
            self.showMicInfo()
        }
    }
    
    private func createAudioEncoderConfig() -> AudioEncoderConfig {
        let config = AudioEncoderConfig()
        guard let audioConfig = audioConfig else {
            DDLogError("No audioConfig provided")
            return config
        }

        config.channelCount = Int32(audioConfig.channelCount)
        config.sampleRate = audioConfig.sampleRate
        config.bitrate = Int32(audioConfig.bitrate)
        
        config.manufacturer = kAppleSoftwareAudioCodecManufacturer
        
        DDLogVerbose("sampleRate = \(config.sampleRate)")
        DDLogVerbose("channelCount = \(config.channelCount)")
        DDLogVerbose("bitrate = \(config.bitrate)")
        
        return config
    }
    
    private func createVideoEncoderConfig() -> VideoEncoderConfig {
        let config = VideoEncoderConfig()
        guard let videoConfig = videoConfig else {
            DDLogError("No videoConfig provided")
            return config
        }
        config.pixelFormat = PixelFormat_YUV
        
        if videoConfig.portrait {
            streamHeight = Int(videoConfig.videoSize.width)
            streamWidth = Int(videoConfig.videoSize.height)
            
            config.height = Int32(videoConfig.videoSize.width)
            config.width = Int32(videoConfig.videoSize.height)
            
        } else {
            streamWidth = Int(videoConfig.videoSize.width)
            streamHeight = Int(videoConfig.videoSize.height)
            
            config.width = Int32(videoConfig.videoSize.width)
            config.height = Int32(videoConfig.videoSize.height)
        }
        silenceGenerator.setStreamSize(width: streamWidth, height: streamHeight)
        
        config.type = videoConfig.type
        config.profileLevel = videoConfig.profileLevel as String
        
        config.fps = Int32(videoConfig.fps)
        // Convert key frame interval from seconds to number of frames. A key frame interval of 1 indicates that every frame must be a keyframe, 2 indicates that at least every other frame must be a keyframe, and so on.
        config.maxKeyFrameInterval = Int32(videoConfig.keyFrameIntervalDuration * videoConfig.fps)
        
        // https://developer.apple.com/documentation/videotoolbox/kvtcompressionpropertykey_averagebitrate
        config.bitrate = Int32(videoConfig.bitrate)
        
        // https://developer.apple.com/documentation/videotoolbox/kvtcompressionpropertykey_dataratelimits
        if #available (iOS 13.0, *) {
            // Workaround issue on iOS 13: app must set both AverageBitRate and DataRateLimits, otherwise hevc output may be corrupted
            if config.type == kCMVideoCodecType_HEVC {
                config.limit = config.bitrate * 2
            }
        }
        
        // later you can update video bitrate  using engine?.updateBitrate() api; this can be used to lower bitrate on the fly in case of slow connection
        
        DDLogVerbose("camera id = \(videoConfig.cameraID)")
        DDLogVerbose("portrait = \(videoConfig.portrait)")
        DDLogVerbose("width = \(config.width)")
        DDLogVerbose("height = \(config.height)")
        DDLogVerbose("bitrate = \(config.bitrate)")
        DDLogVerbose("limit = \(config.limit)")
        DDLogVerbose("framerate = \(config.fps)")
        DDLogVerbose("keyframe = \(config.maxKeyFrameInterval)")
        DDLogVerbose("profileLevel = \(String(describing: config.profileLevel))")
        
        return config
    }
    
    internal func setupVideoIn() throws {
        throw StreamerError.SetupFailed
    }

    internal func setupVideoOut() throws {
        throw StreamerError.SetupFailed
    }
    
    internal func setCameraParams(camera: AVCaptureDevice) -> AVCaptureDevice.Format? {
        guard let videoConfig = videoConfig else {
            return nil
        }
        var activeFormat: AVCaptureDevice.Format?
        
        let formats: [AVCaptureDevice.Format] = camera.formats.filter { (format) -> Bool in
            if !isValidFormat(format)  {
                return false
            }
            //DDLogInfo("format: \(format.debugDescription)")

            let resolution = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            if resolution.width == videoConfig.videoSize.width && resolution.height == videoConfig.videoSize.height {
                for range in format.videoSupportedFrameRateRanges {
                    DDLogVerbose("\(camera.localizedName) found \(resolution.width)x\(resolution.height) [\(range.minFrameRate)..\(range.maxFrameRate)]")
                }
                return true
            }
            return false
        }
        
        DDLogVerbose("\(camera.localizedName) has \(formats.count) format(s)")
        activeFormat = formats.first(where: { (format) -> Bool in
            format.videoSupportedFrameRateRanges.contains { (range) -> Bool in
                range.maxFrameRate >= videoConfig.fps && range.minFrameRate <= videoConfig.fps
            }
        })

        // Requested frame rate is not supported by active camera, fallback to 30 fps
        if activeFormat == nil {
            self.videoConfig?.fps = Settings.sharedInstance.video_framerate_def
            self.delegate?.notification(notification: StreamerNotification.FrameRateNotSupported)
            DDLogVerbose("Unsupported fps, reset to: \(videoConfig.fps)")
            activeFormat = formats.first(where: { (format) -> Bool in
                format.videoSupportedFrameRateRanges.contains { (range) -> Bool in
                    range.maxFrameRate >= videoConfig.fps && range.minFrameRate <= videoConfig.fps
                }
            })
        }
        
        guard let format = activeFormat  else {
            DDLogError("streamer fail: can't find video output format")
            return nil
        }
        do {
            try camera.lockForConfiguration()
        } catch {
            DDLogError("streamer fail: can't lock video device for configuration: \(error)")
           return nil
        }

        camera.activeFormat = format
        camera.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(videoConfig.fps))
        camera.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(videoConfig.fps))
        self.currentFps = videoConfig.fps

        defaultFocus(camera: camera)
        baseZoomFactor = getInitZoomFactor(forDevice: camera)
        let initZoom: CGFloat
        if camera.position == .back && Settings.sharedInstance.backCameraZoom > 0 {
            initZoom = Settings.sharedInstance.backCameraZoom
        } else {
            initZoom = self.baseZoomFactor
        }
        camera.videoZoomFactor = initZoom
        
        camera.unlockForConfiguration()
        
        return format
    }
    
    internal func isValidFormat(_ format: AVCaptureDevice.Format) -> Bool {
        return CMFormatDescriptionGetMediaType(format.formatDescription) == kCMMediaType_Video
    }
    
    internal func setVideoStabilizationMode(connection: AVCaptureConnection, camera: AVCaptureDevice) {
        let cameraName = camera.localizedName
        if dynamicLogLevel == .verbose {
            var dict:[AVCaptureVideoStabilizationMode:String] = [
                .off: "off",
                .standard: "standard",
                .cinematic: "cinematic",
                .auto: "auto"
            ]
            if #available(iOS 13.0, *) {
                dict[.cinematicExtended] = "cinematic extended"
            }
            DDLogVerbose("\(cameraName) supports stabilization: \(connection.isVideoStabilizationSupported)")
            var modes: [AVCaptureVideoStabilizationMode] = [.off, .standard, .cinematic, .auto]
            if #available(iOS 13.0, *) {
                modes.append(.cinematicExtended)
            }

            for (_, value) in modes.enumerated() {
                DDLogVerbose("\(String(describing: dict[value])) \(camera.activeFormat.isVideoStabilizationModeSupported(value))")
            }
        }
        
        let mode = Settings.sharedInstance.videoStabilizationMode
        if connection.isVideoStabilizationSupported, camera.activeFormat.isVideoStabilizationModeSupported(mode) {
            connection.preferredVideoStabilizationMode = mode
            DDLogVerbose("\(cameraName) preferred stabilization mode: \(connection.preferredVideoStabilizationMode.rawValue)")
            DDLogVerbose("\(cameraName) active stabilization mode: \(connection.activeVideoStabilizationMode.rawValue)")
        }
    }    
    
    internal func setupAudio() throws {
        guard let session = session else {
            throw StreamerError.SetupFailed
        }

        // start audio input configuration
        recordDevice = AVCaptureDevice.default(for: AVMediaType.audio)
        guard recordDevice != nil else {
            DDLogError("streamer fail: can't open audio device")
            throw StreamerError.SetupFailed
        }
        
        do {
            audioIn = try AVCaptureDeviceInput(device: recordDevice!)
        } catch {
            DDLogError("streamer fail: can't allocate audio input: \(error)")
            throw StreamerError.SetupFailed
        }
        
        if session.canAddInput(audioIn!) {
            session.addInput(audioIn!)
        } else {
            DDLogError("streamer fail: can't add audio input")
            throw StreamerError.SetupFailed
        }
        // audio input configuration completed
        
        // start audio output configuration
        audioOut = AVCaptureAudioDataOutput()
        audioOut!.setSampleBufferDelegate(self, queue: workQueue)
        
        if session.canAddOutput(audioOut!) {
            session.addOutput(audioOut!)
        } else {
            DDLogError("streamer fail: can't add audio output")
            throw StreamerError.SetupFailed
        }
        
        self.audioConnection = audioOut!.connection(with: AVMediaType.audio)
        guard self.audioConnection != nil else {
            DDLogError("streamer fail: can't allocate audio connection")
            throw StreamerError.SetupFailed
        }
        // audio output configuration completed
    }
    
    internal func setupStillImage() throws {
        throw StreamerError.SetupFailed
    }
    
    func setupStereo(input: AVAudioSessionPortDescription) -> Bool {
        stereo = false
        guard #available(iOS 14.0, *) else {
            return false
        }
        if audioConfig?.channelCount == 1 {
            return false
        }
        
        guard let dataSources = input.dataSources?.filter({ (source) -> Bool in
            source.supportedPolarPatterns?.contains(.stereo) ?? false
        }), !dataSources.isEmpty
            else { return false }
        var preferredSource: AVAudioSessionDataSourceDescription?
        let position = Settings.sharedInstance.cameraPosition
        if position == .front {
            preferredSource = dataSources.first(where: { $0.dataSourceName == "Front" })
        } else {
            preferredSource = dataSources.first(where: { $0.dataSourceName == "Back" })
        }
        if preferredSource == nil {
            preferredSource = dataSources.first
        }
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try preferredSource!.setPreferredPolarPattern(.stereo)

            try input.setPreferredDataSource(preferredSource)
            
            try audioSession.setPreferredInputOrientation(stereoOrientation)
            stereo = true
        } catch {
            DDLogError("Unable to select audio source.")
        }
        return stereo
    }
    
    func unsetStereo(input: AVAudioSessionPortDescription) {
        guard #available(iOS 14.0, *) else {
            return
        }
        do {
            try input.setPreferredDataSource(nil)
            if let source = input.preferredDataSource {
                try source.setPreferredPolarPattern(.omnidirectional)
            }
        } catch {
            DDLogError("Unable to reset audio source")
        }
    }
    
    func updateStereo() {
        guard #available(iOS 14.0, *), stereo else {
            return
        }
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setPreferredInputOrientation(stereoOrientation)
        } catch {
            DDLogError("Unable to set stereo orientation")
        }
    }
    
    func connectPreview(back: AVCaptureVideoPreviewLayer, front: AVCaptureVideoPreviewLayer) -> Bool {
        return false
    }
    
    func stopCapture() {
        DDLogVerbose("stopCapture")
        
        workQueue.async {
            self.releaseCapture()
        }
    }
    
    internal func releaseCapture() {
        audioOut?.setSampleBufferDelegate(nil, queue: nil)
        NotificationCenter.default.removeObserver(self)
        silenceGenerator.stop()
        engine.stopFileWriter()
        engine.stopVideoEncoding()
        engine.stopAudioEncoding()
        
        if session?.isRunning == true {
            DDLogVerbose("stopRunning")
            session?.stopRunning()
        }
        
        audioConnection = nil
        audioIn = nil
        audioOut = nil
        recordDevice = nil
        ciContext = nil
        
        session = nil
        
        delegate?.captureStateDidChange(state: CaptureState.CaptureStateStopped, status: CaptureStatus.CaptureStatusSuccess)
        
        DDLogVerbose("all capture released")
    }
    
    func changeCamera() {
        
    }

    // MARK: Notifications from capture session
    internal func registerForNotifications() {
        let nc = NotificationCenter.default
        
        nc.addObserver(
            self,
            selector: #selector(sessionDidStartRunning(notification:)),
            name: NSNotification.Name.AVCaptureSessionDidStartRunning,
            object: session)
        
        nc.addObserver(
            self,
            selector: #selector(sessionDidStopRunning(notification:)),
            name: NSNotification.Name.AVCaptureSessionDidStopRunning,
            object: session)
        
        nc.addObserver(
            self,
            selector: #selector(sessionRuntimeError(notification:)),
            name: NSNotification.Name.AVCaptureSessionRuntimeError,
            object: session)
        
        nc.addObserver(
            self,
            selector: #selector(sessionWasInterrupted(notification:)),
            name: NSNotification.Name.AVCaptureSessionWasInterrupted,
            object: session)
        
        nc.addObserver(
            self,
            selector: #selector(sessionInterruptionEnded(notification:)),
            name: NSNotification.Name.AVCaptureSessionInterruptionEnded,
            object: session)
    }
    
    @objc private func sessionDidStartRunning(notification: Notification) {
        DDLogVerbose("AVCaptureSessionDidStartRunning")
        delegate?.captureStateDidChange(state: CaptureState.CaptureStateStarted, status: CaptureStatus.CaptureStatusSuccess)
    }
    
    @objc private func sessionDidStopRunning(notification: Notification) {
        DDLogVerbose("AVCaptureSessionDidStopRunning")
    }
    
    @objc private func sessionRuntimeError(notification: Notification) {
        guard let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError else {
            return
        }
        DDLogError("AVCaptureSessionRuntimeError: \(error)")
        delegate?.captureStateDidChange(state: CaptureState.CaptureStateFailed, status: CaptureStatus.CaptureStatusErrorCaptureSession)
    }
    
    @objc private func sessionWasInterrupted(notification: Notification) {
        if let userInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?, let reasonIntegerValue = userInfoValue.integerValue, let reason = AVCaptureSession.InterruptionReason(rawValue: reasonIntegerValue) {
            DDLogVerbose("AVCaptureSessionWasInterrupted \(reason)")
            
            if reason == .videoDeviceNotAvailableInBackground {
                return // Session will be stopped by Larix app when it goes to background, ignore notification
            }
            
            var status = CaptureStatus.CaptureStatusErrorSessionWasInterrupted // Unknown error
            if reason == .audioDeviceInUseByAnotherClient {
                status = CaptureStatus.CaptureStatusErrorMicInUse
                if session?.isRunning == true {
                    let fps = recordMode == .audioOnly ? 0.0 : videoConfig?.fps ?? 0.0
                    silenceGenerator.start(fps: fps, withAudio: recordMode != .videoOnly)
                }
            } else if reason == .videoDeviceInUseByAnotherClient {
                status = CaptureStatus.CaptureStatusErrorCameraInUse
            } else if reason == .videoDeviceNotAvailableWithMultipleForegroundApps {
                status = CaptureStatus.CaptureStatusErrorCameraUnavailable
            }
            delegate?.captureStateDidChange(state: CaptureState.CaptureStateFailed, status: status)
        }
    }
    
    @objc private func sessionInterruptionEnded(notification: Notification) {
        DDLogVerbose("AVCaptureSessionInterruptionEnded")
        silenceGenerator.stop()
        delegate?.captureStateDidChange(state: CaptureState.CaptureStateCanRestart, status: CaptureStatus.CaptureStatusSuccess)
    }
    
    @objc private func audioSessionRouteChange(notification: Notification) {
        
        if let value = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? NSNumber, let routeChangeReason = AVAudioSession.RouteChangeReason(rawValue: UInt(value.intValue)) {
            
            if let routeChangePreviousRoute = notification.userInfo?[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription {
                DDLogVerbose("\(#function) routeChangePreviousRoute: \(routeChangePreviousRoute)")
            }
            
            switch routeChangeReason {
                
            case AVAudioSession.RouteChangeReason.unknown:
                DDLogVerbose("\(#function) routeChangeReason: AVAudioSessionRouteChangeReasonUnknown")
                
            case AVAudioSession.RouteChangeReason.newDeviceAvailable:
                // e.g. a headset was added or removed
                DDLogVerbose("\(#function) routeChangeReason: AVAudioSessionRouteChangeReasonNewDeviceAvailable")
                
            case AVAudioSession.RouteChangeReason.oldDeviceUnavailable:
                // e.g. a headset was added or removed
                DDLogVerbose("\(#function) routeChangeReason: AVAudioSessionRouteChangeReasonOldDeviceUnavailable")
                
            case AVAudioSession.RouteChangeReason.categoryChange:
                // called at start - also when other audio wants to play
                DDLogVerbose("\(#function) routeChangeReason: AVAudioSessionRouteChangeReasonCategoryChange")
                
            case AVAudioSession.RouteChangeReason.override:
                DDLogVerbose("\(#function) routeChangeReason: AVAudioSessionRouteChangeReasonOverride")
                
            case AVAudioSession.RouteChangeReason.wakeFromSleep:
                DDLogVerbose("\(#function) routeChangeReason: AVAudioSessionRouteChangeReasonWakeFromSleep")
                
            case AVAudioSession.RouteChangeReason.noSuitableRouteForCategory:
                DDLogVerbose("\(#function) routeChangeReason: AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory")
                
            case AVAudioSession.RouteChangeReason.routeConfigurationChange:
                DDLogVerbose("\(#function) routeChangeReason: AVAudioSessionRouteChangeReasonRouteConfigurationChange")
                
            default:
                break
            }
            
            showMicInfo()
        }
    }
    
    private func showMicInfo() {
        let audioSession = AVAudioSession.sharedInstance()
        for input in audioSession.currentRoute.inputs {
            let message = input.portName
            DDLogVerbose("Active input: \(input), h/w sample rate: \(audioSession.sampleRate)")
        }
    }
    
    // The method signatures in Streamer.swift are using Swift 4. The AVCaptureVideoDataOutputSampleBufferDelegate methods will not be called in Swift 3.
    // Swift 4:
    // func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection)
    // Swift 3:
    // func captureOutput(_ output: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!)
    
    // MARK: AVCaptureVideoDataOutputSampleBufferDelegate
    // MARK: AVCaptureAudioDataOutputSampleBufferDelegate
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard CMSampleBufferDataIsReady(sampleBuffer) else {
            DDLogVerbose("sample buffer is not ready, skipping sample")
            return
        }
        
        if let videoDataOutput = output as? AVCaptureVideoDataOutput {
            processVideoSampleBuffer(sampleBuffer, fromOutput: videoDataOutput)
        } else if let audioDataOutput = output as? AVCaptureAudioDataOutput {
            processsAudioSampleBuffer(sampleBuffer, fromOutput: audioDataOutput)
        }
    }
    
    internal func processVideoSampleBuffer(_ sampleBuffer: CMSampleBuffer, fromOutput videoDataOutput: AVCaptureVideoDataOutput) {
    }

    internal func processsAudioSampleBuffer(_ sampleBuffer: CMSampleBuffer, fromOutput audioDataOutput: AVCaptureAudioDataOutput) {
        silenceGenerator.handleAudioSampleBuffer(sampleBuffer)
        engine.didOutputAudioSampleBuffer(sampleBuffer)
    }
    
    // MARK: mp4 record
    func startRecord() {
        let fileUrl = getFileUrl(mode: recordMode)
        workQueue.async {
            if fileUrl == nil || !self.engine.startFileWriter(fileUrl, mode: self.recordMode) {
                DDLogError("can't start record")
            }
        }
    }

    func stopRecord(restart: Bool = false) {
        DDLogVerbose("stopRecord")
        if (restart) {
            let nextUrl = getFileUrl(mode: recordMode)
            engine.switchFileWriter(nextUrl)
        } else {
            engine.stopFileWriter()
        }
    }
    
    func getFileUrl(mode: ConnectionMode) -> URL? {
        guard let documents = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) else {
            DDLogError("Cant' get document directory")
            return nil
        }
        
        let df = DateFormatter()
        df.dateFormat = "yyyyMMddHHmmss"
        let prefix = mode == .audioOnly ? "AUD_" : "MVI_"
        let ext = mode == .audioOnly ? ".m4a" : ".mov"
        let fileName = prefix + df.string(from: Date()) + ext
        let fileUrl = documents.appendingPathComponent(fileName)
        return fileUrl
        
    }

    var isWriting: Bool {
        return isRecording && isRecordSessionStarted
    }
    
    // MARK: jpeg capture
    func captureStillImage() {
    }

    // MARK: Autofocus
    func continuousFocus(at focusPoint: CGPoint, position: AVCaptureDevice.Position = .unspecified) {
    }

    func autoFocus(at focusPoint: CGPoint, position: AVCaptureDevice.Position = .unspecified) {
        
    }
        
    func canFocus(position: AVCaptureDevice.Position = .unspecified) -> Bool {
        return false
    }
    
    internal func focusSupported(camera: AVCaptureDevice?) -> Bool {
        return camera?.isFocusPointOfInterestSupported ?? false
    }
    
    internal func focus(at focusPoint: CGPoint, mode: AVCaptureDevice.FocusMode, camera: AVCaptureDevice?) {
        workQueue.async {
            guard let camera = camera else { return }
            do {
                try camera.lockForConfiguration()
                if camera.isFocusModeSupported(mode) {
                    camera.focusMode = mode
                }
                if camera.isFocusPointOfInterestSupported {
                    //DDLogVerbose("focus point (x,y): \(focusPoint.x) \(focusPoint.y)")
                    camera.focusPointOfInterest = focusPoint
                }
                camera.unlockForConfiguration()
            } catch {
                DDLogError("can't lock video device for configuration: \(error)")
            }
        }
    }
    
    func resetFocus() {
    
    }
    
    internal func defaultFocus(camera: AVCaptureDevice?) {
        // https://developer.apple.com/library/content/documentation/AudioVideo/Conceptual/AVFoundationPG/Articles/04_MediaCapture.html
        // If you change the focus mode settings, you can return them to the default configuration as follows:
        guard let camera = camera else { return }
        if camera.isFocusModeSupported(.continuousAutoFocus) {
            if camera.isFocusPointOfInterestSupported {
                //DDLogVerbose("reset focusPointOfInterest")
                camera.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
            }
            //DDLogVerbose("reset focusMode")
            camera.focusMode = .continuousAutoFocus
        }
    }
    
    func zoomTo(factor: CGFloat) {

    }
    
    func getCurrentZoom() -> CGFloat {
        return 1.0
    }
    
    func findMaxZoom(camera: AVCaptureDevice, format: AVCaptureDevice.Format) -> CGFloat {
        if camera.position != .back {
            return 1
        }
        let zoom = min(format.videoMaxZoomFactor, 16.0)
        return zoom
    }
    

    func setExposureCompensation(_ ev: Float, position: AVCaptureDevice.Position = .unspecified) {
        
    }
    
    func getExposureCompensation(position: AVCaptureDevice.Position = .unspecified) -> Float {
        return 0.0
    }

    // MARK: RTMP metadata
    // https://helpx.adobe.com/adobe-media-server/dev/adding-metadata-live-stream.html
    
    // Larix sets the following metadata properties and values.
    // Do not add this metadata to live streams:
    // "width", "height", "videodatarate", "videocodecid"
    // "audiosamplerate", "audiodatarate", "audiosamplesize", "stereo", "audiocodecid"
    
    func pushMetaData(connection: Int32, meta: Dictionary<String, Any>) {
        engine.pushMetaData(connection, metadata: meta)
    }
    
    func sendDirect(connection: Int32, handler: String, meta: Dictionary<String, Any>) {
        engine.sendDirect(connection, handler:handler, metadata: meta)
    }
    //    var meta = Dictionary<String, Any>()
    //    meta["artist"] = "Michael Jackson"
    //    meta["title"] = "Beat It"
    //    meta["booleanValue"] = false
    //    meta["integerValue"] = 10
    //    meta["doubleValue"] = 22.22
    //    Streamer.sharedInstance.pushMetaData(connection: id, meta:meta)
    
    func changeBitrate(newBitrate: Int32) {
        DDLogInfo("Change bitrate: \(newBitrate)")
        if Settings.sharedInstance.adaptiveFps {
            updateFps(newBitrate: newBitrate)
        }
        engine.updateBitrate(newBitrate)
    }
    
    func updateFps(newBitrate: Int32) {

    }
    
    func getInitZoomFactor(forDevice camera: AVCaptureDevice) -> CGFloat {
        var factor: CGFloat = 1.0
        if #available(iOS 13.0, *) {
            if camera.isVirtualDevice == true {
                //Set initial zoom matching primary (wide angle) camera
                let subDevices = camera.constituentDevices
                if subDevices.count <= 1 { return 1.0 }
                let mainCameraIndex = subDevices.firstIndex { $0.deviceType == .builtInWideAngleCamera }
                guard let index = mainCameraIndex, index > 0 else { return 1.0 }
                let zoom = camera.virtualDeviceSwitchOverVideoZoomFactors[index - 1]
                let fZoom = CGFloat(truncating: zoom)
                DDLogInfo("Set initial zoom to \(fZoom)")
                factor = fZoom
            }
        }
        return factor
    }
    
    // Get switching zoom factors for virtual camera and maximum zoom
    internal func getSwitchZoomFactors(forDevice camera: AVCaptureDevice) -> [CGFloat] {
        var factors: [CGFloat] = []
        if #available(iOS 13.0, *) {
            if camera.isVirtualDevice == true {
                let zoom = camera.virtualDeviceSwitchOverVideoZoomFactors.map { CGFloat($0.floatValue) }
                factors.append(contentsOf: zoom)
            }
        }
        return factors
    }
    
    func getSwitchZoomFactors() -> [CGFloat] {
        return []
    }
    
    func findFormat(fps: inout Double, camera: AVCaptureDevice?) -> AVCaptureDevice.Format? {
        guard let formats = camera?.formats, let videoConfig = videoConfig else {return nil}
        var nearestFps: Double = 0
        var nearestFormat: AVCaptureDevice.Format?
        let matchFormat = formats.first { format in
            if !isValidFormat(format) {
                return false
            }
            let resolution = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            if  resolution.width != videoConfig.videoSize.width || resolution.height != videoConfig.videoSize.height {
                return false
            }
            let fmtRanges = format.videoSupportedFrameRateRanges
//            for range in fmtRanges {
//                NSLog("Range \(range.minFrameRate) - \(range.maxFrameRate) FPS")
//            }
            let match = fmtRanges.first (where: { $0.minFrameRate <= fps && $0.maxFrameRate >= fps } ) != nil
            if match {
                return true
            } else {
                for range in fmtRanges {
                    var marginFps:Double = 0.0
                    if abs(range.maxFrameRate - fps) < abs(range.minFrameRate - fps) {marginFps = range.maxFrameRate} else {marginFps = range.minFrameRate}
                    if abs(marginFps - fps) < abs(nearestFps - fps) {
                        nearestFps = marginFps
                        nearestFormat = format
                    }
                }
                return false
            }
        }
        if matchFormat == nil {
            fps = nearestFps
            return nearestFormat
        } else {
            return matchFormat
        }
    }
    
    func toggleFlash() -> Bool {
        return false
    }
    
    func supportFlash() -> Bool {
        return false
    }
    
    func flashOn() -> Bool {
        return false
    }
    
    internal func toggleFlash(camera: AVCaptureDevice?) -> Bool {
        var torchOn = false
        if let camera = camera {
            do {
                if !(camera.hasTorch && camera.isTorchAvailable) {
                    return false
                }
                torchOn = camera.torchMode != .on
                let newMode = torchOn ? AVCaptureDevice.TorchMode.on : AVCaptureDevice.TorchMode.off
                try camera.lockForConfiguration()
                camera.torchMode = newMode
                camera.unlockForConfiguration()
            } catch {
                DDLogError("can't set flash: \(error)")
            }
        }
        return torchOn
    }

}
