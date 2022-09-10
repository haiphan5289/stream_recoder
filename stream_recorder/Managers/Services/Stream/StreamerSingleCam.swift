import CoreImage
import CocoaLumberjackSwift
import AVFoundation
import FaceCamFW

class StreamerSingleCam: Streamer {
    
    enum CameraSwitchingState {
        case none
        case preparing
        case switching
    }
    
    // video
    private var captureDevice: AVCaptureDevice?
    private var videoIn: AVCaptureDeviceInput?
    private var videoOut: AVCaptureVideoDataOutput?
    private var videoConnection: AVCaptureConnection?
    private var transform: ImageTransform?
    private var cameraSwitching: CameraSwitchingState = .none
    
    // jpeg capture
    private var imageOut: AVCaptureOutput?

    override var postprocess: Bool {
        return Settings.sharedInstance.postprocess
    }

    override func createSession() -> AVCaptureSession? {
        return AVCaptureSession()
    }
   
    override func setupVideoIn() throws {
        // start video input configuration
        guard let session = session else {
            throw StreamerError.SetupFailed
        }
        var position = Settings.sharedInstance.cameraPosition
        if #available(iOS 10.0, *) {
            if position == .back {
                captureDevice = Settings.sharedInstance.getDefaultBackCamera(probe: self.probeCam)
            } else {
                captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
            }
        } else {
            let cameras: [AVCaptureDevice] = AVCaptureDevice.devices(for: .video)
            for camera in cameras {
                if camera.position == position {
                    captureDevice = camera
                }
            }
        }
        
        if captureDevice == nil {
            // wrong cameraID? ok, pick default one
            captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        }
        
        guard let captureDevice = captureDevice else {
            DDLogError("streamer fail: can't open camera device")
            throw StreamerError.SetupFailed
        }
        
        position = captureDevice.position
        
        do {
            videoIn = try AVCaptureDeviceInput(device: captureDevice)
        } catch {
            DDLogError("streamer fail: can't allocate video input: \(error)")
            throw StreamerError.SetupFailed
        }
        
        if session.canAddInput(videoIn!) {
            session.addInput(videoIn!)
        } else {
            DDLogError("streamer fail: can't add video input")
            throw StreamerError.SetupFailed
        }
        // video input configuration completed
    }
    
    override func setupVideoOut() throws {
        guard let captureDevice = captureDevice,
              let format = setCameraParams(camera: captureDevice),
              let session = session else {
            throw StreamerError.SetupFailed
        }
        maxZoomFactor = findMaxZoom(camera: captureDevice, format: format)

        let videoOut = AVCaptureVideoDataOutput()
        videoOut.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as String) : NSNumber(value: PixelFormat_YUV)]
        videoOut.alwaysDiscardsLateVideoFrames = true
        videoOut.setSampleBufferDelegate(self, queue: workQueue)
        
        if session.canAddOutput(videoOut) {
            session.addOutput(videoOut)
        } else {
            DDLogError("streamer fail: can't add video output")
            throw StreamerError.SetupFailed
        }
        
        guard let videoConnection = videoOut.connection(with: AVMediaType.video) else {
            DDLogError("streamer fail: can't allocate video connection")
            throw StreamerError.SetupFailed
        }
        videoConnection.videoOrientation = self.videoOrientation
        videoConnection.automaticallyAdjustsVideoMirroring = false
        videoConnection.isVideoMirrored = false
        setVideoStabilizationMode(connection: videoConnection, camera: captureDevice)
        
        self.videoOut = videoOut
        self.videoConnection = videoConnection
        
        if postprocess {
            let videoSize = CMVideoDimensions(width: Int32(streamWidth), height: Int32(streamHeight))
            transform = ImageTransform(size: videoSize)
            transform?.portraitVideo = videoConfig?.portrait ?? false
            self.transform?.postion = captureDevice.position

        }
        // video output configuration completed
    }
    

    override func isValidFormat(_ format: AVCaptureDevice.Format) -> Bool {
        return CMFormatDescriptionGetMediaType(format.formatDescription) == kCMMediaType_Video &&
            CMFormatDescriptionGetMediaSubType(format.formatDescription) == PixelFormat_YUV
    }

    override func setupStillImage() throws {
        guard let session = session else {
            throw StreamerError.SetupFailed
        }

        if #available(iOS 11.0,*) {
            imageOut = AVCapturePhotoOutput()
        } else {
            let stillPhotoOut = AVCaptureStillImageOutput()
            stillPhotoOut.outputSettings = [AVVideoCodecKey:AVVideoCodecJPEG, AVVideoQualityKey:0.85] as [String : Any]
            imageOut = stillPhotoOut
        }
        if session.canAddOutput(imageOut!) {
            session.addOutput(imageOut!)
        } else {
            DDLogError("streamer fail: can't add still image output")
            throw StreamerError.SetupFailed
        }
    }
    
    override func stopCapture() {
        silenceGenerator.stop()
        super.stopCapture()
    }
    
    override func releaseCapture() {
        // detach compression sessions and mp4 recorder
        videoOut?.setSampleBufferDelegate(nil, queue: nil)

        super.releaseCapture()
        
        videoConnection = nil
        videoIn = nil
        videoOut = nil
        imageOut = nil
        captureDevice = nil
        recordDevice = nil
        ciContext = nil
        session = nil
        transform = nil
    }
    
    override func changeCamera() {
        
        let discovery = AVCaptureDevice.DiscoverySession.init(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .unspecified)
        let cameras = discovery.devices
        
        if cameras.count < 2 {
            DDLogError("device has only one camera, this is impossible")
            return
        }
        guard cameraSwitching == .none else {
            return
        }
        cameraSwitching = .preparing
        
        workQueue.async {
            guard let session = self.session, let captureDevice = self.captureDevice, let videoConfig = self.videoConfig,
                  self.videoIn != nil, self.videoOut != nil else {
                return
            }
            
            var preferredPosition: AVCaptureDevice.Position = .front
            let currentPosition: AVCaptureDevice.Position = captureDevice.position
            
            // find next camera
            switch (currentPosition) {
            case .unspecified, .front:
                preferredPosition = .back
            case .back:
                preferredPosition = .front
            @unknown default: break
            }
            var videoDevice: AVCaptureDevice?
            if #available(iOS 10.0, *) {
                if preferredPosition == .back {
                    videoDevice = Settings.sharedInstance.getDefaultBackCamera(probe: self.probeCam)
                } else {
                    videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: preferredPosition)
                }
            } else {
                for camera in cameras {
                    if camera.position == preferredPosition {
                        videoDevice = camera
                    }
                }
            }
            guard let newDevice = videoDevice else {
                DDLogError("next camera not found, this is impossible")
                return
            }
            
            // check that next camera can produce same resolution and fps as active camera
            var newFormat: AVCaptureDevice.Format?
            for format in newDevice.formats {
                
                if CMFormatDescriptionGetMediaType(format.formatDescription) != kCMMediaType_Video {
                    continue
                }
                if CMFormatDescriptionGetMediaSubType(format.formatDescription) != self.PixelFormat_YUV {
                    continue
                }
                
                let resolution = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
                if resolution.width == videoConfig.videoSize.width, resolution.height == videoConfig.videoSize.height {
                    if format.videoSupportedFrameRateRanges.contains(where: { $0.maxFrameRate >= videoConfig.fps && $0.minFrameRate <= videoConfig.fps }) {
                        newFormat = format
                        break
                    }
                }
            }
            guard newFormat != nil else {
                self.delegate?.notification(notification: StreamerNotification.ChangeCameraFailed)
                self.cameraSwitching = .none
                return
            }
            self.cameraSwitching = .switching
            self.silenceGenerator.start(fps: videoConfig.fps, withAudio: false)
            DDLogInfo("cameraSwitching start")

            do {
                try newDevice.lockForConfiguration()
                newDevice.activeFormat = newFormat!
                
                // https://developer.apple.com/library/content/documentation/AudioVideo/Conceptual/AVFoundationPG/Articles/04_MediaCapture.html
                // If you change the focus mode settings, you can return them to the default configuration as follows:
                if newDevice.isFocusModeSupported(.continuousAutoFocus) {
                    if newDevice.isFocusPointOfInterestSupported {
                        //DDLogVerbose("reset focusPointOfInterest")
                        newDevice.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
                    }
                    //DDLogVerbose("reset focusMode")
                    newDevice.focusMode = .continuousAutoFocus
                }
                let initZoom: CGFloat
                self.baseZoomFactor = self.getInitZoomFactor(forDevice: newDevice)
                if newDevice.position == .back && Settings.sharedInstance.backCameraZoom > 0 {
                    initZoom = Settings.sharedInstance.backCameraZoom
                } else {
                    initZoom = self.baseZoomFactor
                }
                newDevice.videoZoomFactor = initZoom
                self.maxZoomFactor = self.findMaxZoom(camera: newDevice, format: newFormat!)
                
                newDevice.unlockForConfiguration()
                
                session.beginConfiguration()
                session.removeInput(self.videoIn!)
                
                self.captureDevice = newDevice
                self.position = newDevice.position
                self.transform?.postion = self.position
                self.videoIn = try AVCaptureDeviceInput(device: self.captureDevice!)
                
                if session.canAddInput(self.videoIn!) {
                    session.addInput(self.videoIn!)
                } else {
                    throw StreamerError.SetupFailed
                }
                
                guard let videoConnection = self.videoOut?.connection(with: AVMediaType.video) else {
                    DDLogError("streamer fail: can't allocate video connection")
                    throw StreamerError.SetupFailed
                }
                videoConnection.videoOrientation = self.videoOrientation
                self.videoConnection = videoConnection
                self.setVideoStabilizationMode(connection: self.videoConnection!, camera: self.captureDevice!)
                
                // On iOS, the receiver's activeVideoMinFrameDuration resets to its default value if receiver's activeFormat changes; Should first change activeFormat, then set fps
                try newDevice.lockForConfiguration()
                newDevice.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(videoConfig.fps))
                newDevice.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(videoConfig.fps))
                newDevice.videoZoomFactor = initZoom
                newDevice.unlockForConfiguration()
                session.commitConfiguration()
                self.cameraSwitching = .none
                DDLogInfo("cameraSwitching done")
                
            } catch {
                DDLogError("can't change camera: \(error)")
                self.delegate?.captureStateDidChange(state: CaptureState.CaptureStateFailed, status: error)
            }
            
            self.delegate?.notification(notification: StreamerNotification.ActiveCameraDidChange)
        }
    }
    
    func probeCam(camera: AVCaptureDevice, size: CMVideoDimensions, fps: Double) -> Bool {
        let supported = camera.formats.contains { (format) in
            let camResolution = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            let camFps = format.videoSupportedFrameRateRanges
            return CMFormatDescriptionGetMediaType(format.formatDescription) == kCMMediaType_Video &&
                camResolution.width >= size.width && camResolution.height >= size.height &&
                camFps.contains{ (range) in
                    range.minFrameRate <= fps && fps <= range.maxFrameRate }
        }
        return supported
    }
    
    override func processVideoSampleBuffer(_ sampleBuffer: CMSampleBuffer, fromOutput videoDataOutput: AVCaptureVideoDataOutput) {
        if videoDataOutput != videoOut {
            return
        }
        let sampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        //DDLogVerbose("didOutput sampleBuffer: video \(sampleTime.seconds)")
        if isPaused {
            silenceGenerator.outputBlackFrame(withPresentationTime: sampleTime)
            return
        }
        if self.cameraSwitching != .switching {
            self.silenceGenerator.stop()
        }
        if silenceGenerator.handleVideoSampleBuffer(sampleBuffer) == false {
            return
        }
        
        // apply CoreImage filters to video; if postprocessing is not required, then just pass buffer directly to encoder and mp4 writer
        if postprocess {
            // rotateAndEncode will also send frame to mp4 writer
            rotateAndEncode(sampleBuffer: sampleBuffer)
        } else {
            engine.didOutputVideoSampleBuffer(sampleBuffer)
        }
    }

    // MARK: jpeg capture
    override func captureStillImage() {
        guard cameraSwitching == .none else {
            return
        }
        let df = DateFormatter()
        df.dateFormat = "yyyyMMddHHmmss"
        photoFileName = "IMG_" + df.string(from: Date())
        if #available(iOS 11.0,*) {
            if let out = self.imageOut as? AVCapturePhotoOutput{
                var codecs: [AVVideoCodecType] = []
                if Settings.sharedInstance.snapshotFormat == .heic {
                    codecs = out.supportedPhotoCodecTypes(for: .heic)
                    if codecs.isEmpty {
                        DDLogWarn("HEIC is not available, fallback to JPEG")
                    } else {
                        photoFileName?.append(".heic")
                    }
                }
                if codecs.isEmpty {
                    codecs = out.supportedPhotoCodecTypes(for: .jpg)
                    photoFileName?.append(".jpg")
                }
                if let codec = codecs.first {
                    let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey:codec])
                    let videoConnection = out.connection(with: .video)
                    videoConnection?.videoOrientation = self.orientation

                    out.capturePhoto(with: settings, delegate: self)
                }
            }
        } else {
            photoFileName?.append(".jpg")
            guard let out = self.imageOut as? AVCaptureStillImageOutput else {return}
            workQueue.async {
                search: for connection in out.connections {
                    for port in connection.inputPorts {
                        if port.mediaType == AVMediaType.video {
                            connection.videoOrientation = self.orientation
                            out.captureStillImageAsynchronously(from: connection, completionHandler: self.saveStillImage)
                            break search
                        }
                    }
                }
            }
        }
    }
    
    private func saveStillImage(imageBuffer: CMSampleBuffer?, error: Error?) {
        if error == nil, let buffer = imageBuffer {
            do {
                if let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer) {
                    let documents = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                    let fileUrl = documents.appendingPathComponent(photoFileName!)
                    try imageData.write(to: fileUrl, options: .atomic)
                    self.delegate?.photoSaved(fileUrl: fileUrl)
                    DDLogVerbose("save jpeg to \(fileUrl.absoluteString)")
                }
            } catch {
                DDLogError("failed to save jpeg: \(error)")
            }
        }
    }

    @available(iOS 11.0,*)
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if error == nil, let imageData = photo.fileDataRepresentation() {
            do {
                let documents = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                let fileUrl = documents.appendingPathComponent(photoFileName!)
                
                try imageData.write(to: fileUrl, options: .atomic)
                self.delegate?.photoSaved(fileUrl: fileUrl)
                DDLogVerbose("save photo to \(fileUrl.absoluteString)")
            } catch {
                DDLogError("failed to photo jpeg: \(error)")
            }
        }
    }

    // MARK: Live rotation
    private func rotateAndEncode(sampleBuffer: CMSampleBuffer) {
        guard let videoConfig = videoConfig else {
            DDLogError("No videoConfig provided")
            return
        }
        let outputOptions = [kCVPixelBufferOpenGLESCompatibilityKey as String: NSNumber(value: true),
                             kCVPixelBufferIOSurfacePropertiesKey as String: [:]] as [String : Any]
        
        var outputBuffer: CVPixelBuffer? = nil
        
        let status: CVReturn = CVPixelBufferCreate(kCFAllocatorDefault,
                                                   streamWidth, streamHeight,
                                                   PixelFormat_RGB,
                                                   outputOptions as CFDictionary?,
                                                   &outputBuffer)
        
        guard status == kCVReturnSuccess, outputBuffer != nil else {
            DDLogError("error in CVPixelBufferCreate")
            return
        }
        
        let sampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        let sourceBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        
        transform?.orientation = orientation
       
        let sourceImage = CIImage(cvPixelBuffer: sourceBuffer, options: [CIImageOption.colorSpace: NSNull()])
        
        var outputImage: CIImage = sourceImage
        let bounds = CGRect(x: 0, y: 0, width: streamWidth, height: streamHeight)

        guard let transformMatrix = transform?.getMatrix(extent: bounds) else {
            DDLogError("Failed to get transformation")
            return
        }
        let wCam: Float = Float(videoConfig.videoSize.width)  // 1920
        let hCam: Float = Float(videoConfig.videoSize.height) // 1080

        // "overlay" is demo function, it is not used in stock Larix application
        func overlay() {
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let alphaInfo = CGImageAlphaInfo.premultipliedLast.rawValue
            
            let bitmapContext = CGContext(
                data: nil,
                width: Int(wCam),
                height: Int(hCam),
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: alphaInfo)!
            
            bitmapContext.setAlpha(0.5)
            bitmapContext.setTextDrawingMode(CGTextDrawingMode.fill)
            bitmapContext.textPosition = CGPoint(x: 20, y: 20)
            
            let displayLineTextWhite = CTLineCreateWithAttributedString(NSAttributedString(string: todayString(), attributes: [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 50)]))
            CTLineDraw(displayLineTextWhite, bitmapContext)
            
            let textCGImage = bitmapContext.makeImage()!
            let textImage = CIImage(cgImage: textCGImage)
            
            let combinedFilter = CIFilter(name: "CISourceOverCompositing")!
            combinedFilter.setValue(textImage, forKey: "inputImage")
            combinedFilter.setValue(outputImage, forKey: "inputBackgroundImage")
            
            outputImage = combinedFilter.outputImage!
        }
        outputImage = outputImage.transformed(by: transformMatrix)

        // Demo of additional CoreImage filter: "overlay" text on top of stream using "CISourceOverCompositing"
        //overlay()
        
        if let context = ciContext {
            context.render(outputImage, to: outputBuffer!, bounds: outputImage.extent, colorSpace: nil)
            engine.didOutputVideoPixelBuffer(outputBuffer!, withPresentationTime:sampleTime)
        }
    }
    
    func todayString() -> String {
        let date = Date()
        let calender = Calendar.current
        let components = calender.dateComponents([.year,.month,.day,.hour,.minute,.second], from: date)
        
        let year = components.year
        let month = components.month
        let day = components.day
        let hour = components.hour
        let minute = components.minute
        let second = components.second
        
        return String(year!) + "-" + String(month!) + "-" + String(day!) + " " + String(hour!)  + ":" + String(minute!) + ":" +  String(second!)
    }
    
    // MARK: Autofocus
    override func continuousFocus(at focusPoint: CGPoint, position _: AVCaptureDevice.Position = .unspecified) {
        focus(at: focusPoint, mode: .continuousAutoFocus, camera: captureDevice)
    }
    
    override func autoFocus(at focusPoint: CGPoint, position _: AVCaptureDevice.Position = .unspecified) {
        focus(at: focusPoint, mode: .autoFocus, camera: captureDevice)
    }
    
    override func canFocus(position: AVCaptureDevice.Position = .unspecified) -> Bool {
        return focusSupported(camera: captureDevice)
    }

    
    override func resetFocus() {
        workQueue.async {
            if let camera = self.captureDevice {
                do {
                    try camera.lockForConfiguration()
                    self.defaultFocus(camera: camera)
                    camera.unlockForConfiguration()
                } catch {
                    DDLogError("can't lock video device for configuration: \(error)")
                }
            }
        }
    }

    override func zoomTo(factor: CGFloat) {
        workQueue.async {
            if let camera = self.captureDevice {
                do {
                    if factor > camera.activeFormat.videoMaxZoomFactor || factor < 1.0 {
                        return
                    }
                    try camera.lockForConfiguration()
                    camera.videoZoomFactor = factor
                    camera.unlockForConfiguration()
                    if camera.position == .back {
                        Settings.sharedInstance.backCameraZoom = factor
                    }
                } catch {
                    DDLogError("can't lock video device for configuration: \(error)")
                }
            } else {
                DDLogError("No camera")
            }
        }
    }
    
    override func getCurrentZoom() -> CGFloat {
        return self.captureDevice?.videoZoomFactor ?? 1.0
    }
    
    override func updateFps(newBitrate: Int32) {
        guard let videoConfig = videoConfig, videoConfig.bitrate != 0, let camera = captureDevice else {
            return
        }
        let bitrateRel:Double = Double(newBitrate) / Double(videoConfig.bitrate)
        var relFps = videoConfig.fps
        if bitrateRel < 0.5 {
            relFps = max(15.0, floor(videoConfig.fps * bitrateRel * 2.0 / 5.0) * 5.0)
        }
        if abs(relFps - currentFps) < 1.0 {
            return
        }
        let format = camera.activeFormat
        let ranges = format.videoSupportedFrameRateRanges
        var newFormat: AVCaptureDevice.Format?
//        for range in ranges {
//            NSLog("Range \(range.minFrameRate) - \(range.maxFrameRate) FPS")
//        }
        if ranges.first(where:{ $0.maxFrameRate >= relFps && $0.minFrameRate <= relFps } ) == nil {
            //Need to switch to another format
            newFormat = findFormat(fps: &relFps, camera: camera)
        }
        do {
            try camera.lockForConfiguration()
            if let format = newFormat {
                camera.activeFormat = format
            }
            camera.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(relFps))
            camera.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(relFps))
            camera.unlockForConfiguration()
            currentFps = relFps
        } catch {
            DDLogError("can't lock video device for configuration: \(error)")
        }
    }
    
    override func toggleFlash() -> Bool {
        guard cameraSwitching == .none else {
            return false
        }
        return toggleFlash(camera: captureDevice)
    }
    
    override func setExposureCompensation(_ ev: Float, position: AVCaptureDevice.Position = .unspecified) {
        guard let camera = captureDevice else { return }
        do {
            try camera.lockForConfiguration()
            camera.setExposureTargetBias(ev)
            camera.unlockForConfiguration()
        } catch {
            DDLogError("can't lock video device for configuration: \(error)")
        }
    }
    
    override func getExposureCompensation(position: AVCaptureDevice.Position = .unspecified) -> Float {
        return captureDevice?.exposureTargetBias ??  0.0
    }

    override func supportFlash() -> Bool {
        guard let camera = captureDevice else { return false}
        return camera.hasTorch && camera.isTorchAvailable
    }
    
    override func flashOn() -> Bool {
        guard let camera = captureDevice else { return false}
        return camera.hasTorch && camera.isTorchAvailable && camera.torchMode == .on
    }
    
    override func getSwitchZoomFactors() -> [CGFloat] {
        guard let camera = captureDevice else { return []}
        return getSwitchZoomFactors(forDevice: camera)
    }


    
}
