// https://developer.apple.com/library/ios/documentation/NetworkingInternet/Conceptual/StreamingMediaGuide/FrequentlyAskedQuestions/FrequentlyAskedQuestions.html

// Although the protocol specification does not limit the video and audio formats, the current Apple implementation supports the following video formats:
// H.264 Baseline Level 3.0, Baseline Level 3.1, Main Level 3.1, and High Profile Level 4.1.

// kVTProfileLevel_H264_Baseline_AutoLevel
// kVTProfileLevel_H264_Main_AutoLevel
// kVTProfileLevel_H264_High_AutoLevel

import AVFoundation
import VideoToolbox

struct VideoConfig {
    var cameraID: String
    var videoSize: CMVideoDimensions
    var fps: Double // AVFrameRateRange
    var keyFrameIntervalDuration: Double
    var bitrate: Int
    var portrait: Bool
    var type: CMVideoCodecType
    var profileLevel: CFString
    
    init(cameraID: String, videoSize: CMVideoDimensions, fps: Double, keyFrameIntervalDuration: Double, bitrate: Int, portrait: Bool, type: CMVideoCodecType, profileLevel: CFString) {
        self.cameraID = cameraID
        self.videoSize = videoSize
        self.fps = fps
        self.keyFrameIntervalDuration = keyFrameIntervalDuration
        self.bitrate = bitrate
        self.portrait = portrait
        self.type = type
        self.profileLevel = profileLevel
    }
}

struct AudioConfig {
    var sampleRate: Double // AVAudioSession.sharedInstance().sampleRate
    var channelCount: Int
    var bitrate: Int
    
    init(sampleRate: Double, channelCount: Int, bitrate: Int) {
        self.sampleRate = sampleRate
        self.channelCount = channelCount
        self.bitrate = bitrate
    }
}
