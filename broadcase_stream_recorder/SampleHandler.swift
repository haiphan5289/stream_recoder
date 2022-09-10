//
//  SampleHandler.swift
//  broadcase_stream_recorder
//
//  Created by HHumorous on 06/04/2022.
//

import ReplayKit
import UserNotifications
import BroadcastWriter

class SampleHandler: RPBroadcastSampleHandler {
    
    private var writer: BroadcastWriter?
    private let fileManager: FileManager = .default
    private let notificationCenter = UNUserNotificationCenter.current()
    private let nodeURL: URL
    
    let userDefault = UserDefaults(suiteName: "group.beelab.stream.xrecorder.broadcast")
    
    var isBroadcast = false
    let streamer: ScreenStreamer

    override init() {
        streamer = ScreenStreamer.sharedInstance

        if #available(iOSApplicationExtension 14.0, *) {
            nodeURL = fileManager.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(for: .mpeg4Movie)
        } else {
            nodeURL = fileManager.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mp4")
        }

        fileManager.removeFileIfExists(url: nodeURL)

        super.init()
    }
    
    func checkStreamIfNeed() {
        guard let stream_url = userDefault?.string(forKey: "stream_url"),
              let stream_key = userDefault?.string(forKey: "stream_key") else { return }
        
        let stream_full_url = stream_url + "/" + stream_key
        
        let config = ConnectionConfig()
        config.uri = URL(string: stream_full_url)!
        config.mode = .videoAudio
        isBroadcast = true
        let id = ScreenStreamer.sharedInstance.createConnection(config: config)
        
        streamer.delegate = self
        let status = streamer.startCapture()
        print("status: %@, id: %@, streamUrl: %@", status, id, stream_full_url)
    }
    
    func startWriter() {
        let screen: UIScreen = .main
        do {
            writer = try .init(
                outputURL: nodeURL,
                screenSize: screen.bounds.size,
                screenScale: screen.scale
            )
        } catch {
            assertionFailure(error.localizedDescription)
            finishBroadcastWithError(error)
            return
        }
        do {
            try writer?.start()
            userDefault?.set(1, forKey: "broadcastState")
            if isBroadcast {
                userDefault?.set(1, forKey: "streamingState")
            }
        } catch {
            finishBroadcastWithError(error)
        }
    }

    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        // User has requested to start the broadcast. Setup info from the UI extension can be supplied but optional.
        checkStreamIfNeed()

        startWriter()
    }
    
    override func broadcastPaused() {
        // User has requested to pause the broadcast. Samples will stop being delivered.
        if isBroadcast {
            streamer.pause()
        }
        
        writer?.pause()
    }
    
    override func broadcastResumed() {
        // User has requested to resume the broadcast. Samples delivery will resume.
        if isBroadcast {
            streamer.resume()
        }
        
        writer?.resume()
    }
    
    override func broadcastFinished() {
        // User has requested to finish the broadcast.
        finishWriter()
        
        if isBroadcast {
            streamer.stopCapture()
            streamer.releaseAllConnections()
        }
    }
    
    func finishWriter() {
        guard let writer = writer else {
            return
        }

        let outputURL: URL
        do {
            outputURL = try writer.finish()
        } catch {
            debugPrint("writer failure", error)
            return
        }

        guard let containerURL = fileManager.containerURL(
                    forSecurityApplicationGroupIdentifier: "group.beelab.stream.xrecorder.broadcast"
        )?.appendingPathComponent("Library/Documents/") else {
            fatalError("no container directory")
        }
        do {
            try fileManager.createDirectory(
                at: containerURL,
                withIntermediateDirectories: true,
                attributes: nil
            )
        } catch {
            debugPrint("error creating", containerURL, error)
        }

        let destination = containerURL.appendingPathComponent(outputURL.lastPathComponent)
        do {
            debugPrint("Moving", outputURL, "to:", destination)
            try self.fileManager.moveItem(
                at: outputURL,
                to: destination
            )
            userDefault?.set(0, forKey: "broadcastState")
            if isBroadcast {
                userDefault?.set(0, forKey: "streamingState")
            }
        } catch {
            debugPrint("ERROR", error)
        }

        debugPrint("FINISHED")
    }
    
    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        guard let writer = writer else {
            debugPrint("processSampleBuffer: Writer is nil")
            return
        }

        do {
            let captured = try writer.processSampleBuffer(sampleBuffer, with: sampleBufferType)
            debugPrint("processSampleBuffer captured", captured)
        } catch {
            debugPrint("processSampleBuffer error:", error.localizedDescription)
        }
        
        if isBroadcast {
            streamer.processSampleBuffer(sampleBuffer, with: sampleBufferType)
        }
    }
    
    private func scheduleNotification() {
        print("scheduleNotification")
        let content: UNMutableNotificationContent = .init()
        content.title = "broadcastStarted"
        content.subtitle = Date().description

        let trigger: UNNotificationTrigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 5, repeats: false)
        let notificationRequest: UNNotificationRequest = .init(
            identifier: "group.beelab.stream.xrecorder.notification",
            content: content,
            trigger: trigger
        )
        notificationCenter.add(notificationRequest) { (error) in
            print("add", notificationRequest, "with ", error?.localizedDescription ?? "no error")
        }
    }
}

extension SampleHandler: ScreencasterDelegate {
    func connectionStateDidChange(id: Int32, state: ConnectionState, status: ConnectionStatus, info: [AnyHashable : Any]!) {
        print("connectionStateDidChange \(id) state: \(state.rawValue) status: \(status.rawValue)")
    }
}

extension FileManager {

    func removeFileIfExists(url: URL) {
        guard fileExists(atPath: url.path) else { return }
        do {
            try removeItem(at: url)
        } catch {
            print("error removing item \(url)", error)
        }
    }
}
