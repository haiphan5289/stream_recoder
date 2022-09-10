import AVFoundation
import CocoaLumberjackSwift

// Generate empty audio and video frames during pause
class SilenceGenerator {
    var active: Bool = false
    var engine: StreamerEngineProxy

    private var currentAudioFormat: AudioStreamBasicDescription?
    private var lastAudioSampleNum: Int = 0
    private var lastAudioFrameTime: Double = 0.0
    private var realtimeOffset: Double = 0.0
    private var audioFrameTimer: Timer?
    private let audioFrameInterval: TimeInterval = 1.0/50.0
    
    private var lastVideorameTime: Double = 0.0
    private var blackFrameTimer: Timer?
    private var blackFrameTime:CFTimeInterval = 0
    private var blackFrameOffset:CFTimeInterval = 0
    private var blackFrame: CVPixelBuffer?

    private var streamWidth: Int = 1920
    private var streamHeight: Int = 1080
    
    init() {
        self.engine = StreamerSingleton.sharedEngine
    }
    
    func setStreamSize(width: Int, height: Int) {
        streamWidth = width
        streamHeight = height
    }
    
    // Store active audio details to generate silence in same format
    func handleAudioSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        if audioFrameTimer != nil || blackFrameTimer != nil {
            audioFrameTimer?.invalidate()
            fillGap(to: sampleBuffer, minPeriod: 0.05)
            audioFrameTimer = nil
        }

        let ts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let duration = CMSampleBufferGetDuration(sampleBuffer)
        let num = CMSampleBufferGetNumSamples(sampleBuffer)
        //DDLogVerbose("audioSampleBuffer PTS \(ts.seconds) duration \(duration.seconds)")
        realtimeOffset = ts.seconds - CACurrentMediaTime()
        lastAudioFrameTime = ts.seconds + duration.seconds
        lastAudioSampleNum = num
        if let format = CMSampleBufferGetFormatDescription(sampleBuffer),
           let audioDesc = CMAudioFormatDescriptionGetStreamBasicDescription(format)?.pointee {
            currentAudioFormat = audioDesc
        }
    }
    
    func handleVideoSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> Bool {
        let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        lastVideorameTime = pts.seconds
        if !active {
            let seconds = CACurrentMediaTime()
            blackFrameOffset = pts.seconds - seconds
        }
        
        if blackFrameTime > 0 {
            if pts.seconds < blackFrameTime + 0.001 {
                DDLogInfo("Skip frame after black frame")
                return false
            } else {
                blackFrameTime = 0
            }
        }
        return true
    }
    
    func start(fps: Double, withAudio: Bool) {
        DDLogInfo("SilenceGenerator start")
        
        if fps > 0 {
            startBlackFrameTimer(fps: fps)
        }
        if withAudio {
            if audioFrameTimer != nil {
                audioFrameTimer?.invalidate()
            }
            audioFrameTimer = Timer.scheduledTimer(withTimeInterval: audioFrameInterval, repeats: true) { (_) in
                StreamerSingleton.sharedQueue.async {
                    self.generateByTimer()
                }
            }
            active = true
        }
    }
    
    func stop() {
        audioFrameTimer?.invalidate()
        stopBlackFrameTimer()
        active = false
    }
    
    func outputBlackFrame(withPresentationTime time: CMTime) {
        if (blackFrame == nil) {
            
            CVPixelBufferCreate(kCFAllocatorDefault,
                                streamWidth, streamHeight,
                                kCVPixelFormatType_32BGRA,
                                nil,
                                &blackFrame)
        }
        if let blackFrame = blackFrame {
            engine.didOutputVideoPixelBuffer(blackFrame, withPresentationTime: time)
        } else {
            DDLogError("Failed to create pixel buffer")
        }
    }
    
    private func fillGap(to sampleBuffer: CMSampleBuffer, minPeriod: Double) {
        let ts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

        let ts_time = ts.seconds
        let dt = ts_time - lastAudioFrameTime
        if dt > minPeriod { return }
        let count = CMSampleBufferGetNumSamples(sampleBuffer)
        guard let format = CMSampleBufferGetFormatDescription(sampleBuffer),
            let audioDesc = CMAudioFormatDescriptionGetStreamBasicDescription(format)?.pointee else {
            return
        }

        var deltaSamples = Int(ceil((ts.seconds - lastAudioFrameTime) * audioDesc.mSampleRate))
        deltaSamples -= deltaSamples % 2
        var pts_val = Int64(lastAudioFrameTime * audioDesc.mSampleRate)
        while deltaSamples > 0 {
            let samples = deltaSamples > count * 3 / 2 ? count : deltaSamples //Generate block with at most 1.5x of input block length
            DDLogInfo("black frame: generatng \(samples) empty samples @ \(audioDesc.mSampleRate)")
            let pts = CMTime(value: pts_val, timescale: CMTimeScale(audioDesc.mSampleRate))
            if let buf = generatePCM(pts: pts, frameCount: samples, audioDesc: audioDesc) {
                engine.didOutputAudioSampleBuffer(buf)
            }
            pts_val += Int64(samples)
            deltaSamples -= samples
        }
    }
    
    private func generateByTimer() {
        guard let format = currentAudioFormat else { return }
        let sampleRate = format.mSampleRate
        let adjustedTime = realtimeOffset + CACurrentMediaTime()
        let duration = adjustedTime - lastAudioFrameTime
        var frameCount = Int(floor(duration * format.mSampleRate))
        var frameTime = lastAudioFrameTime
        let chunkDuration = Double(lastAudioSampleNum) / sampleRate
        while frameCount >= lastAudioSampleNum {
            //DDLogInfo("Generating \(lastAudioSampleNum) empty audio samples at \(frameTime)")
            let pts = CMTime(seconds: frameTime, preferredTimescale: CMTimeScale(sampleRate))
            if let buf = generatePCM(pts: pts, frameCount: lastAudioSampleNum, audioDesc: format) {
                engine.didOutputAudioSampleBuffer(buf)
            }
            frameTime += chunkDuration
            frameCount -= lastAudioSampleNum
        }
        lastAudioFrameTime = frameTime
    }
    
    private func generatePCM(pts: CMTime, frameCount: CMItemCount, audioDesc: AudioStreamBasicDescription) -> CMSampleBuffer? {
        var sampleBuffer: CMSampleBuffer? = nil
        
        let dataLen:Int = Int(frameCount) * Int(audioDesc.mChannelsPerFrame) * 2
        var bbuf: CMBlockBuffer? = nil

        var status = CMBlockBufferCreateWithMemoryBlock(allocator: kCFAllocatorDefault,
                                                        memoryBlock: nil,
                                                        blockLength: dataLen,
                                                        blockAllocator: nil,
                                                        customBlockSource: nil,
                                                        offsetToData: 0,
                                                        dataLength: dataLen,
                                                        flags: 0,
                                                        blockBufferOut: &bbuf)
        
        guard status == kCMBlockBufferNoErr, bbuf != nil else {
            DDLogError("Failed to create memory block")
            return nil
        }

        status = CMBlockBufferFillDataBytes(with: 0, blockBuffer: bbuf!, offsetIntoDestination: 0, dataLength: dataLen)
        guard status == kCMBlockBufferNoErr else {
            DDLogError("Failed to fill memory block")
            return nil
        }
        
        var formatDesc: CMAudioFormatDescription?
        var descVar = audioDesc
        status = CMAudioFormatDescriptionCreate(allocator: kCFAllocatorDefault,
                                                asbd: &descVar,
                                                layoutSize: 0,
                                                layout: nil,
                                                magicCookieSize: 0,
                                                magicCookie: nil,
                                                extensions: nil,
                                                formatDescriptionOut: &formatDesc)
        guard status == noErr, formatDesc != nil else {
            DDLogError("Failed to create format description")
            return nil
        }

        status = CMAudioSampleBufferCreateReadyWithPacketDescriptions(allocator: kCFAllocatorDefault,
                                                                      dataBuffer: bbuf!,
                                                                      formatDescription: formatDesc!,
                                                                      sampleCount: frameCount,
                                                                      presentationTimeStamp: pts,
                                                                      packetDescriptions: nil,
                                                                      sampleBufferOut: &sampleBuffer)

        guard  status == noErr, sampleBuffer != nil else {
            DDLogError("Failed to create sampleBuffer")
            return nil
        }
        return sampleBuffer
    }
    

    
    private func startBlackFrameTimer(fps: Double) {
        let interval:TimeInterval = fps < 1.0 ? 1.0/30.0 : 1.0 / fps
        
        if let timer = blackFrameTimer {
            timer.invalidate()
        }
        blackFrameTime = 0
        DDLogVerbose("Start black frame timer at \(fps) FPS  offset \(blackFrameOffset)")
        DispatchQueue.main.async {
            self.blackFrameTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block: { (_) in
                let seconds = CACurrentMediaTime() + self.blackFrameOffset
                self.drawBlackFrame(ts: seconds)
            })
            let seconds = CACurrentMediaTime() + self.blackFrameOffset
            if seconds - self.lastVideorameTime > 1.5/fps {
                //Add itermediate frames
                var curTs = self.lastVideorameTime + 1.0/fps
                while curTs < seconds {
                    self.drawBlackFrame(ts: curTs)
                    curTs += 1.0/fps
                }
            }
        }
    }
    
    private func stopBlackFrameTimer() {
        if let timer = blackFrameTimer {
            timer.invalidate()
            DDLogVerbose("Stop black frame timer")
        }
        blackFrameTimer = nil
    }
    
    private func drawBlackFrame(ts: CFTimeInterval) {
        blackFrameTime = ts
        //DDLogVerbose("Draw black frame at \(ts)")
        let time = CMTime(seconds: ts, preferredTimescale: 1000)
        outputBlackFrame(withPresentationTime: time)
    }
}
