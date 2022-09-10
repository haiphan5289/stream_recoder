import Foundation
import AVFoundation
import CocoaLumberjackSwift

@available(iOS 13.0, *)
class StreamerMultiCam: Streamer {
    
    public var pipDevicePosition: MultiCamPicturePosition = .off

    // video
    private weak var backCameraVideoPreviewLayer: AVCaptureVideoPreviewLayer?
    private weak var frontCameraVideoPreviewLayer: AVCaptureVideoPreviewLayer?
    private var backCamera: AVCaptureDevice?
    private var frontCamera: AVCaptureDevice?
    private var backCameraDeviceInput: AVCaptureDeviceInput?
    private var frontCameraDeviceInput: AVCaptureDeviceInput?
    private let backCameraVideoDataOutput = AVCaptureVideoDataOutput()
    private let frontCameraVideoDataOutput = AVCaptureVideoDataOutput()
    private var frontCameraVideoPort: AVCaptureInput.Port?
    private var backCameraVideoPort: AVCaptureInput.Port?
    private var currentPiPSampleBuffer: CMSampleBuffer?
    private var mainTransform: ImageTransform?
    private var pipTransform: ImageTransform?
    private var multiCamMode: Settings.MultiCamMode = .off
    
    // jpeg capture
    private var imageOutFront: AVCaptureOutput?
    private var imageOutBack: AVCaptureOutput?
    private var imageOutFrontConnection: AVCaptureConnection?
    private var imageOutBackConnection: AVCaptureConnection?
    private var savedImage: CIImage?

    private let previewToggleMap: [MultiCamPicturePosition: MultiCamPicturePosition] =
        [.off: .off,
         .pip_front: .pip_back,
         .pip_back: .pip_front,
         .left_front: .left_back,
         .left_back: .left_front]

    override var postprocess: Bool {
        return true
    }

    override var previewPositionPip: MultiCamPicturePosition {
        return pipDevicePosition
    }
    
    class func isSupported() -> Bool {
        return Settings.sharedInstance.multiCamMode != .off
    }

    override func createSession() -> AVCaptureSession? {
        return AVCaptureMultiCamSession()
    }
    
    override func setupVideoIn() throws {
        guard AVCaptureMultiCamSession.isMultiCamSupported else {
            print("MultiCam not supported on this device")
            throw StreamerError.MultiCamNotSupported
        }
        let cameraPos = Settings.sharedInstance.cameraPosition
        multiCamMode = Settings.sharedInstance.multiCamMode
        switch multiCamMode {
        case .pip:
            pipDevicePosition = cameraPos == .back ? .pip_front : .pip_back
        case .sideBySide:
            pipDevicePosition = cameraPos == .back ? .left_back : .left_front
        default:
            pipDevicePosition = .off
        }
        
        guard configureBackCameraIn() else {
           throw StreamerError.SetupFailed
        }
        
        guard configureFrontCameraIn() else {
            throw StreamerError.SetupFailed
        }
    }
    
    override func setupVideoOut() throws {
        guard configureBackCameraOut() else {
           throw StreamerError.SetupFailed
        }
        
        guard configureFrontCameraOut() else {
            throw StreamerError.SetupFailed
        }
    }
    
    private func configureBackCameraIn() -> Bool {
        guard let session = session as? AVCaptureMultiCamSession else {return false}

        // Find the back camera
        guard let backCamera = Settings.sharedInstance.getDefaultBackCamera(probe: probeMultiCam) else {
            DDLogError("Could not find the back camera")
            return false
        }
        
        self.backCamera = backCamera
        
        // Add the back camera input to the session
        do {
            backCameraDeviceInput = try AVCaptureDeviceInput(device: backCamera)
            
            guard let backCameraDeviceInput = backCameraDeviceInput,
                session.canAddInput(backCameraDeviceInput) else {
                    print("Could not add back camera device input")
                    return false
            }
            session.addInputWithNoConnections(backCameraDeviceInput)
        } catch {
            print("Could not create back camera device input: \(error)")
            return false
        }
        
        // Find the back camera device input's video port
        guard let backCameraDeviceInput = backCameraDeviceInput,
            let backCameraVideoPort = backCameraDeviceInput.ports(for: .video,
                                                              sourceDeviceType: backCamera.deviceType,
                                                              sourceDevicePosition: backCamera.position).first else {
                                                                DDLogError("Could not find the back camera device input's video port")
                                                                return false
        }
        
        // Add the back camera video data output
        guard session.canAddOutput(backCameraVideoDataOutput) else {
            print("Could not add the back camera video data output")
            return false
        }
        session.addOutputWithNoConnections(backCameraVideoDataOutput)
        backCameraVideoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(PixelFormat_RGB)]
        backCameraVideoDataOutput.alwaysDiscardsLateVideoFrames = true
        backCameraVideoDataOutput.setSampleBufferDelegate(self, queue: workQueue)
        
        self.backCameraVideoPort = backCameraVideoPort
        return true
    }
    
    func probeMultiCam(camera: AVCaptureDevice, size: CMVideoDimensions, fps: Double) -> Bool {
        let discovery = AVCaptureDevice.DiscoverySession.init(deviceTypes: [.builtInWideAngleCamera, camera.deviceType], mediaType: .video, position: .unspecified)
        let multicam = discovery.supportedMultiCamDeviceSets
        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            return false
        }
        var supported = multicam.contains { (devices) -> Bool in
            devices.contains(frontCamera) && devices.contains(camera)
        }
        if !supported {
            return false
        }
        supported = camera.formats.contains { (format) in
            let camResolution = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            let camFps = format.videoSupportedFrameRateRanges
            return CMFormatDescriptionGetMediaType(format.formatDescription) == kCMMediaType_Video &&
                format.isMultiCamSupported &&
                camResolution.width >= size.width && camResolution.height >= size.height &&
                camFps.contains{ (range) in
                    range.minFrameRate <= fps && fps <= range.maxFrameRate }
        }
        return supported
    }
    
    private func configureBackCameraOut() -> Bool {

        guard let session = session as? AVCaptureMultiCamSession,
            let backCamera = self.backCamera,
            let backCameraVideoPort = self.backCameraVideoPort else {return false}

        // Connect the back camera device input to the back camera video data output
        let backCameraVideoDataOutputConnection = AVCaptureConnection(inputPorts: [backCameraVideoPort], output: backCameraVideoDataOutput)
        guard session.canAddConnection(backCameraVideoDataOutputConnection) else {
            print("Could not add a connection to the back camera video data output")
            return false
        }
        session.addConnection(backCameraVideoDataOutputConnection)
        backCameraVideoDataOutputConnection.videoOrientation = orientation
        backCameraVideoDataOutputConnection.automaticallyAdjustsVideoMirroring = false
        backCameraVideoDataOutputConnection.isVideoMirrored = false

        guard let format = setCameraParams(camera: backCamera) else {
            return false
        }
        setVideoStabilizationMode(connection: backCameraVideoDataOutputConnection, camera: backCamera)

        self.maxZoomFactor = findMaxZoom(camera: backCamera, format: format)
        
        return true
    }
    
    private func configureFrontCameraIn() -> Bool {
        guard let session = session as? AVCaptureMultiCamSession else {return false}
        
        // Find the front camera
        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("Could not find the front camera")
            return false
        }
        self.frontCamera = frontCamera
        
        // Add the front camera input to the session
        do {
            frontCameraDeviceInput = try AVCaptureDeviceInput(device: frontCamera)
            
            guard let frontCameraDeviceInput = frontCameraDeviceInput,
                session.canAddInput(frontCameraDeviceInput) else {
                    print("Could not add front camera device input")
                    return false
            }
            session.addInputWithNoConnections(frontCameraDeviceInput)
        } catch {
            DDLogError("Could not create front camera device input: \(error)")
            return false
        }
        
        // Find the front camera device input's video port
        guard let frontCameraDeviceInput = frontCameraDeviceInput,
            let frontCameraVideoPort = frontCameraDeviceInput.ports(for: .video,
                                                                    sourceDeviceType: frontCamera.deviceType,
                                                                    sourceDevicePosition: frontCamera.position).first else {
            DDLogError("Could not find the front camera device input's video port")
            return false
        }
        self.frontCameraVideoPort = frontCameraVideoPort
        
        return true
    }
        
    private func configureFrontCameraOut() -> Bool {
        guard let session = session as? AVCaptureMultiCamSession,
        let frontCamera = self.frontCamera,
        let frontCameraVideoPort = self.frontCameraVideoPort else {return false}

        // Add the front camera video data output
        guard session.canAddOutput(frontCameraVideoDataOutput) else {
            DDLogError("Could not add the front camera video data output")
            return false
        }
        session.addOutputWithNoConnections(frontCameraVideoDataOutput)
        frontCameraVideoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(PixelFormat_RGB)]
        frontCameraVideoDataOutput.alwaysDiscardsLateVideoFrames = true
        frontCameraVideoDataOutput.setSampleBufferDelegate(self, queue: workQueue)
        
        // Connect the front camera device input to the front camera video data output
        let frontCameraVideoDataOutputConnection = AVCaptureConnection(inputPorts: [frontCameraVideoPort], output: frontCameraVideoDataOutput)
        guard session.canAddConnection(frontCameraVideoDataOutputConnection) else {
            print("Could not add a connection to the front camera video data output")
            return false
        }
        self.frontCameraVideoPort = frontCameraVideoPort
        session.addConnection(frontCameraVideoDataOutputConnection)
        frontCameraVideoDataOutputConnection.videoOrientation = orientation
        frontCameraVideoDataOutputConnection.automaticallyAdjustsVideoMirroring = false
        frontCameraVideoDataOutputConnection.isVideoMirrored = false

        guard setCameraParams(camera: frontCamera) != nil else {
            return false
        }
        setVideoStabilizationMode(connection: frontCameraVideoDataOutputConnection, camera: frontCamera)

        return true
    }
    
    
    override func isValidFormat(_ format: AVCaptureDevice.Format) -> Bool {
        return CMFormatDescriptionGetMediaType(format.formatDescription) == kCMMediaType_Video && format.isMultiCamSupported
    }

    override func setupStillImage() throws {
        guard let session = self.session else {
            return
        }
        let imageOutFront = AVCapturePhotoOutput()
        session.addOutputWithNoConnections(imageOutFront)
        
        // Connect the front camera device input to the front camera photo output
        let imageOutFrontConnection = AVCaptureConnection(inputPorts: [frontCameraVideoPort!], output: imageOutFront)
        imageOutFrontConnection.videoOrientation = orientation
        imageOutFrontConnection.automaticallyAdjustsVideoMirroring = false
        imageOutFrontConnection.isVideoMirrored = false

        guard session.canAddConnection(imageOutFrontConnection) else {
            DDLogError("Could not add a connection to the front camera video data output")
            throw StreamerError.SetupFailed
        }
        session.addConnection(imageOutFrontConnection)
        self.imageOutFront = imageOutFront
        self.imageOutFrontConnection = imageOutFrontConnection
        
        let imageOutBack = AVCapturePhotoOutput()
        session.addOutputWithNoConnections(imageOutBack)
        
        // Connect the back camera device input to the front camera photo output
        let imageOutBackConnection = AVCaptureConnection(inputPorts: [backCameraVideoPort!], output: imageOutBack)
        imageOutBackConnection.videoOrientation = orientation
        imageOutBackConnection.automaticallyAdjustsVideoMirroring = false
        imageOutBackConnection.isVideoMirrored = false

        guard session.canAddConnection(imageOutBackConnection) else {
            DDLogError("Could not add a connection to the back camera photo data output")
            throw StreamerError.SetupFailed
        }
        session.addConnection(imageOutBackConnection)
        self.imageOutBack = imageOutBack
        self.imageOutBackConnection = imageOutBackConnection

    }
    
    override func connectPreview(back: AVCaptureVideoPreviewLayer, front: AVCaptureVideoPreviewLayer) -> Bool {
        guard let session = self.session, let frontCamPort = self.frontCameraVideoPort, let backCamPort = self.backCameraVideoPort else {
            return false
        }
        
        // Connect the front camera device input to the front camera video preview layer
        frontCameraVideoPreviewLayer = front
        let frontCameraVideoPreviewLayerConnection = AVCaptureConnection(inputPort: frontCamPort, videoPreviewLayer: front)
        guard session.canAddConnection(frontCameraVideoPreviewLayerConnection) else {
            print("Could not add a connection to the front camera video preview layer")
            return false
        }
        session.addConnection(frontCameraVideoPreviewLayerConnection)
        frontCameraVideoPreviewLayerConnection.automaticallyAdjustsVideoMirroring = false
        frontCameraVideoPreviewLayerConnection.isVideoMirrored = true
        
        // Connect the back camera device input to the back camera video preview layer
        backCameraVideoPreviewLayer = back
        let backCameraVideoPreviewLayerConnection = AVCaptureConnection(inputPort: backCamPort, videoPreviewLayer: back)
        guard session.canAddConnection(backCameraVideoPreviewLayerConnection) else {
            print("Could not add a connection to the back camera video preview layer")
            return false
        }
        session.addConnection(backCameraVideoPreviewLayerConnection)
        backCameraVideoPreviewLayerConnection.automaticallyAdjustsVideoMirroring = false
        backCameraVideoPreviewLayerConnection.isVideoMirrored = false
        return true
    }

    override func releaseCapture() {
        // detach compression sessions and mp4 recorder
        frontCameraVideoDataOutput.setSampleBufferDelegate(nil, queue: nil)
        backCameraVideoDataOutput.setSampleBufferDelegate(nil, queue: nil)

        super.releaseCapture()
        backCameraDeviceInput = nil
        frontCameraDeviceInput = nil
        frontCameraVideoPort = nil
        backCameraVideoPort = nil
        backCamera = nil
        frontCamera = nil

        currentPiPSampleBuffer = nil
        mainTransform = nil
        pipTransform = nil
    }

    override func changeCamera() {
        pipDevicePosition = previewToggleMap[pipDevicePosition] ?? .off
        currentPiPSampleBuffer = nil
    }
    
    override func processVideoSampleBuffer(_ sampleBuffer: CMSampleBuffer, fromOutput videoDataOutput: AVCaptureVideoDataOutput) {
        if videoDataOutput != frontCameraVideoDataOutput && videoDataOutput != backCameraVideoDataOutput {
            return
        }
        
        // will be true either if PiP is front and got back camera sample, or PiP is back and got front camera sample
        let isFullScreenBuffer = (pipDevicePosition == .pip_front || pipDevicePosition == .left_back) == (videoDataOutput == backCameraVideoDataOutput)
        if isPaused {
            if isFullScreenBuffer {
                let sampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                silenceGenerator.outputBlackFrame(withPresentationTime: sampleTime)
            }
            return
        }
        if isFullScreenBuffer {
            processFullScreenSampleBuffer(sampleBuffer)
        } else {
            processPiPSampleBuffer(sampleBuffer)
        }
    }
    
    private func processFullScreenSampleBuffer(_ fullScreenSampleBuffer: CMSampleBuffer) {
        
        guard let fullScreenPixelBuffer = CMSampleBufferGetImageBuffer(fullScreenSampleBuffer) else {
            return
        }

        if mainTransform == nil {
            var videoSize = videoConfig!.videoSize
            if videoConfig!.portrait {
                videoSize = CMVideoDimensions(width: videoSize.height, height: videoSize.width)
            }
            mainTransform = ImageTransform(size: videoSize)
        }
        mainTransform?.orientation = orientation
        mainTransform?.portraitVideo = videoConfig!.portrait
        mainTransform?.postion = (pipDevicePosition == .pip_front || pipDevicePosition == .left_back) ? .back : .front

        guard let pipSampleBuffer = currentPiPSampleBuffer,
            let pipPixelBuffer = CMSampleBufferGetImageBuffer(pipSampleBuffer) else {
                return
        }
        
        let sampleTime = CMSampleBufferGetPresentationTimeStamp(fullScreenSampleBuffer)
        
        guard let outputImage = rotateAndEncode(fullScreenPixelBuffer: fullScreenPixelBuffer,
                                             pipPixelBuffer: pipPixelBuffer) else {
            DDLogError("Unable to combine video")
            return
        }
        engine.didOutputVideoPixelBuffer(outputImage, withPresentationTime:sampleTime)
    }
    
    private func processPiPSampleBuffer(_ pipSampleBuffer: CMSampleBuffer) {

        if pipTransform == nil {

            var videoSize = videoConfig!.videoSize
            if videoConfig!.portrait {
                videoSize = CMVideoDimensions(width: videoSize.height, height: videoSize.width)
            }
            pipTransform = ImageTransform(size: videoSize, scale: 0.5)
            pipTransform?.alignX = 1.0
            pipTransform?.alignY = 0.0
            pipTransform?.portraitVideo = videoConfig!.portrait
        }
        pipTransform?.orientation = orientation
        pipTransform?.postion = (pipDevicePosition == .pip_front || pipDevicePosition == .left_back) ? .front : .back

        currentPiPSampleBuffer = pipSampleBuffer
    }
    
    // MARK: jpeg capture
    override func captureStillImage() {
        let df = DateFormatter()
        df.dateFormat = "yyyyMMddHHmmss"
        photoFileName = "IMG_" + df.string(from: Date())
        guard let outFront = self.imageOutFront as? AVCapturePhotoOutput,
            let outBack = self.imageOutBack as? AVCapturePhotoOutput else { return }

        if Settings.sharedInstance.snapshotFormat == .heic {
            photoFileName?.append(".heic")
        } else {
            photoFileName?.append(".jpg")

        }
        let settings = AVCapturePhotoSettings(format: [String(kCVPixelBufferPixelFormatTypeKey):PixelFormat_RGB])
        outFront.capturePhoto(with: settings, delegate: self)
        outBack.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if error == nil, let imageData = photo.cgImageRepresentation() {
            let srcImage = CIImage(cgImage: imageData)
            if savedImage == nil {
                savedImage = srcImage
                return
            }
            defer {
                savedImage = nil
            }
            let isFullScreenBuffer = (pipDevicePosition == .pip_front || pipDevicePosition == .left_back) == (output == imageOutBack)
            var mainImage: CIImage? = isFullScreenBuffer ? srcImage : savedImage
            var pipImage: CIImage? = isFullScreenBuffer ? savedImage : srcImage
            
            let bounds = CGRect(x: 0, y: 0, width: streamWidth, height: streamHeight)
            
            let mainMirror = !(pipDevicePosition == .pip_front || pipDevicePosition == .left_back)
            let pipMirror = (pipDevicePosition == .pip_front || pipDevicePosition == .left_back)
            guard let transformMatrix = mainTransform?.getMatrix(extent: bounds, flipped: mainMirror),
                let pipMatrix = pipTransform?.getMatrix(extent: bounds, flipped: pipMirror) else {
                return
            }
            mainImage = mainImage?.transformed(by: transformMatrix)
            pipImage = pipImage?.transformed(by: pipMatrix)

            if let context = ciContext {
                if let outImage = pipImage?.composited(over: mainImage!) {
                    let color = mainImage!.colorSpace
                    let options: [CIImageRepresentationOption: Any] = [:]
                    do {
                        let documents = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                        let fileUrl = documents.appendingPathComponent(photoFileName!)
                        if Settings.sharedInstance.snapshotFormat == .heic {
                            if let tmpImage = context.createCGImage(outImage, from: bounds) {
                                // Do some magic with image conversion - writeHEIF fails with saving outImage directly
                                let fixedImage = CIImage(cgImage: tmpImage)
                                try context.writeHEIFRepresentation(of: fixedImage, to: fileUrl, format: .BGRA8, colorSpace: color!, options: options)
                            }
                        } else {
                            try context.writeJPEGRepresentation(of: outImage, to: fileUrl, colorSpace: color!, options: options)
                        }
                        self.delegate?.photoSaved(fileUrl: fileUrl)
                    } catch {
                        DDLogError("failed to save jpeg: \(error)")
                    }
                }
            }
            
        }
    }
    
    // MARK: Live rotation
    private func rotateAndEncode(fullScreenPixelBuffer: CVPixelBuffer, pipPixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        
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
            return nil
        }
        let w = CGFloat(streamWidth)
        let h = CGFloat(streamHeight)
        if multiCamMode == .pip {
            if videoConfig?.portrait == false && (orientation == .portrait || orientation == .portraitUpsideDown) {
                pipTransform?.alignX = (1.0 + CGFloat(streamHeight)/CGFloat(streamWidth) / 3.0) / 2.0
            } else if videoConfig?.portrait == true && (orientation == .landscapeLeft || orientation == .landscapeRight) {
                pipTransform?.alignY = (1.0 - CGFloat(streamWidth)/CGFloat(streamHeight) / 3.0) / 2.0
            } else {
                pipTransform?.alignX = 1.0
                pipTransform?.alignY = 0.0
            }
        } else if multiCamMode == .sideBySide {
            if videoConfig?.portrait == true {
                mainTransform?.alignX = 0.5
                pipTransform?.alignX = 0.5
                if orientation == .landscapeLeft || orientation == .landscapeRight {
                    pipTransform?.scalePip = 1.0
                    mainTransform?.scalePip = 1.0
                    let Ω = (w * w)/(h * h)
                    let y = (0.5 - Ω)/(1.0 - Ω)
                    mainTransform?.alignY = 1 - y
                    pipTransform?.alignY = y
                } else {
                    pipTransform?.scalePip = 0.5
                    mainTransform?.scalePip = 0.5
                    mainTransform?.alignY = 1.0
                    pipTransform?.alignY = 0.0
                }
            } else if videoConfig?.portrait == false {
                mainTransform?.alignY = 0.5
                pipTransform?.alignY = 0.5
                if orientation == .portrait || orientation == .portraitUpsideDown {
                    pipTransform?.scalePip = 1.0
                    mainTransform?.scalePip = 1.0
                    mainTransform?.alignX = CGFloat(streamHeight)/CGFloat(streamWidth) * 0.5
                    pipTransform?.alignX = 1 - CGFloat(streamHeight)/CGFloat(streamWidth) * 0.5
                } else {
                    mainTransform?.scalePip = 0.5
                    pipTransform?.scalePip = 0.5
                    mainTransform?.alignX = 0.0
                    pipTransform?.alignX = 1.0
                }
            }
        }
        
        let sourceImage = CIImage(cvPixelBuffer: fullScreenPixelBuffer, options: [CIImageOption.colorSpace: NSNull()])
        var outputImage: CIImage = sourceImage
        var pipImage = CIImage(cvPixelBuffer: pipPixelBuffer, options: [CIImageOption.colorSpace: NSNull()])
        let bounds = CGRect(x: 0, y: 0, width: streamWidth, height: streamHeight)

        guard let transformMatrix = mainTransform?.getMatrix(extent: bounds, flipped: true), let pipMatrix = pipTransform?.getMatrix(extent: bounds, flipped: true) else {
            return nil
        }

        outputImage = outputImage.transformed(by: transformMatrix)
        pipImage = pipImage.transformed(by: pipMatrix)

        if let context = ciContext {
            context.render(outputImage, to: outputBuffer!, bounds: bounds, colorSpace: nil)
            context.render(pipImage, to: outputBuffer!, bounds: bounds, colorSpace: nil)
        }
        return outputBuffer
        
    }
    
    // MARK: Autofocus
    override func continuousFocus(at focusPoint: CGPoint, position: AVCaptureDevice.Position = .unspecified) {
        guard let camera = position == .front ? frontCamera: backCamera else {return}
        focus(at: focusPoint, mode: .continuousAutoFocus, camera: camera)

    }

    override func autoFocus(at focusPoint: CGPoint, position: AVCaptureDevice.Position = .unspecified) {
        guard let camera = position == .front ? frontCamera: backCamera else {return}
        focus(at: focusPoint, mode: .autoFocus, camera: camera)
    }
    
    
    override func canFocus(position: AVCaptureDevice.Position = .unspecified) -> Bool {
        guard let camera = position == .front ? frontCamera: backCamera else {return false }
        return focusSupported(camera: camera)
    }

    override func resetFocus() {
        workQueue.async {
            do {
                if let camera = self.frontCamera {
                    try camera.lockForConfiguration()
                    self.defaultFocus(camera: camera)
                    camera.unlockForConfiguration()
                }
                if let camera = self.backCamera {
                    try camera.lockForConfiguration()
                    self.defaultFocus(camera: camera)
                    camera.unlockForConfiguration()
                }
            }
            catch {
                DDLogError("can't lock video device for configuration: \(error)")
            }
        }
    }
    
    override func zoomTo(factor: CGFloat) {
        workQueue.async {
            if let camera = self.backCamera {
                do {
                    if factor > camera.activeFormat.videoMaxZoomFactor || factor < 1.0 {
                        return
                    }
                    try camera.lockForConfiguration()
                    camera.videoZoomFactor = factor
                    camera.unlockForConfiguration()
                    Settings.sharedInstance.backCameraZoom = factor
                } catch {
                    DDLogError("can't lock video device for configuration: \(error)")
                }
            }
        }
    }
    
    override func getCurrentZoom() -> CGFloat {
        return backCamera?.videoZoomFactor ?? 1.0
    }

    
    override func updateFps(newBitrate: Int32) {
        guard videoConfig != nil && videoConfig!.bitrate != 0 else {
            return
        }

        let bitrateRel:Double = Double(newBitrate) / Double(videoConfig!.bitrate)
        var relFps = videoConfig!.fps
        if bitrateRel < 0.75 {
            relFps = max(10.0, floor(videoConfig!.fps * bitrateRel * 1.33 / 5.0) * 5.0)
        }
        if abs(relFps - currentFps) < 1.0 {
            return
        }
        guard frontCamera != nil && backCamera != nil else { return }
        let cameras = [frontCamera!, backCamera!]
        for camera in cameras {
            let format = camera.activeFormat
            let ranges = format.videoSupportedFrameRateRanges
            var newFormat: AVCaptureDevice.Format?
            if ranges.first(where:{ $0.maxFrameRate >= relFps && $0.minFrameRate <= relFps } ) == nil {
                //Need to switch to another format
                newFormat = findFormat(fps: &relFps, camera: camera)
            }
            do {
                try camera.lockForConfiguration()
                if newFormat != nil {
                    camera.activeFormat = newFormat!
                }
                camera.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(relFps))
                camera.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(relFps))
                camera.unlockForConfiguration()
                currentFps = relFps
            } catch {
                DDLogError("can't lock video device for configuration: \(error)")
            }
        }
    }
        
    
    override func toggleFlash() -> Bool {
        return toggleFlash(camera: backCamera)
    }
    
    override func supportFlash() -> Bool {
        guard let camera = backCamera else { return false}
        return camera.hasTorch && camera.isTorchAvailable
    }
    
    override func flashOn() -> Bool {
        guard let camera = backCamera else { return false}
        return camera.hasTorch && camera.isTorchAvailable && camera.torchMode == .on
    }
    
    override func setExposureCompensation(_ ev: Float, position: AVCaptureDevice.Position = .unspecified) {
        guard let camera = position == .front ? frontCamera : backCamera else { return }
        do {
            try camera.lockForConfiguration()
            camera.setExposureTargetBias(ev)
            camera.unlockForConfiguration()
        } catch {
            DDLogError("can't lock video device for configuration: \(error)")
        }
    }
    
    override func getExposureCompensation(position: AVCaptureDevice.Position = .unspecified) -> Float {
        guard let camera = position == .front ? frontCamera: backCamera else {return 0.0}
        return camera.exposureTargetBias
    }

    override func getSwitchZoomFactors() -> [CGFloat] {
        guard let camera = backCamera else { return []}
        return getSwitchZoomFactors(forDevice: camera)
    }

    
}
