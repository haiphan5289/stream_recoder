//
//  RecordVC.swift
//  stream_recorder
//
//  Created by HHumorous on 04/04/2022.
//

import UIKit
import AVFoundation
import AVKit
import ReplayKit

class RecordVC: UIViewController {
    
    enum RecordState: Int {
        case ready
        case recording
        case stop
        
        var color: UIColor? {
            switch self {
            case .ready, .stop:
                return UIColor(hex: "75b9f2")
            case .recording:
                return UIColor(hex: "f3736c")
            }
        }
        
        var titleButton: String {
            switch self {
            case .ready, .stop:
                return "Start Recording"
            case .recording:
                return "Stop"
            }
        }
        
        var titleStatus: String {
            switch self {
            case .ready:
                return "Press To Start Recordings"
            case .recording:
                return "Recording"
            case .stop:
                return "Saved!"
            }
        }
        
        var iconRecordShow: Bool {
            switch self {
            case .ready, .stop:
                return false
            case .recording:
                return true
            }
        }
    }
    
    @IBOutlet weak var vContent: UIView!
    @IBOutlet weak var vRecord: UIView!
    @IBOutlet weak var btnRecord: UIButton!
    @IBOutlet weak var imgRecord: UIImageView!
    @IBOutlet weak var vConfig: UIView!
    @IBOutlet weak var lblRecordTime: UILabel!
    @IBOutlet weak var lblStatus: UILabel!
    
    var stateRecording: RecordState = .ready
    
    var timer: CountdownService?
    
    lazy var broadcastView: RPSystemBroadcastPickerView = {
        let view = RPSystemBroadcastPickerView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.preferredExtension = "beelab.stream.xrecorder.broadcase-stream-recorder"
        view.backgroundColor = .clear
        
        if let button = view.subviews.first as? UIButton {
            button.fillSuperview()
            button.setImage(nil, for: .normal)
            button.setImage(nil, for: .selected)
        }
        
        return view
    }()
    
    var observations: [ NSObjectProtocol] = []
    var observer: NSKeyValueObservation?
    lazy var notificationCenter: NotificationCenter = .default
    let userDefault = UserDefaults(suiteName: "group.beelab.stream.xrecorder.broadcast")
    
    deinit {
        observer?.invalidate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupUI()
        updateUI()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.setupBroadcast()
        }
        observer = userDefault?.observe(\.broadcastState, options: [.initial, .new], changeHandler: { defaults, change in
            if let newValue = change.newValue {
                if newValue == 1 {
                    self.startRecordSetup()
                } else {
                    self.endRecordingSetup()
                }
            }
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.setupBroadcast()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        observations.append(
            notificationCenter.addObserver(
                forName: UIApplication.willEnterForegroundNotification,
                object: nil,
                queue: nil
            ) { [weak self] _ in
                self?.read()
            }
        )
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        observations.forEach(notificationCenter.removeObserver(_:))
    }
    
    func setupBroadcast() {
        
        if Cache.shared.is_premium == false && RemoteConfigManager.sharedInstance.boolValue(forKey: .lockSreenRecording) {
           
            return
        }
        
        view.addSubview(broadcastView)
        NSLayoutConstraint.activate([
            broadcastView.leadingAnchor.constraint(equalTo: btnRecord.leadingAnchor),
            broadcastView.topAnchor.constraint(equalTo: btnRecord.topAnchor),
            broadcastView.trailingAnchor.constraint(equalTo: btnRecord.trailingAnchor),
            broadcastView.bottomAnchor.constraint(equalTo: btnRecord.bottomAnchor)
        ])
    }
    
    func setupUI() {
        vRecord.layer.cornerRadius = 30
        vRecord.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        vContent.layer.cornerRadius = 30
        vContent.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }
    
    func updateUI() {
        UIView.animate(withDuration: 0.25, delay: 0, options: [.layoutSubviews]) {
            self.btnRecord.setTitle(self.stateRecording.titleButton, for: .normal)
            self.btnRecord.backgroundColor = self.stateRecording.color
            self.imgRecord.isHidden = !self.stateRecording.iconRecordShow
            self.lblStatus.text = self.stateRecording.titleStatus
            self.vConfig.isHidden = self.stateRecording.iconRecordShow
        }
    }
    
    func read() {
        let fileManager = FileManager.default
        if let container = fileManager
                .containerURL(
                    forSecurityApplicationGroupIdentifier: "group.beelab.stream.xrecorder.broadcast"
                )?.appendingPathComponent("Library/Documents/") {

            let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            do {
                let contents = try fileManager.contentsOfDirectory(atPath: container.path)
                for path in contents {
                    guard !path.hasSuffix(".plist") else {
                        print("file at path \(path) is plist, exiting")
                        return
                    }
                    let fileURL = container.appendingPathComponent(path)
                    var isDirectory: ObjCBool = false
                    guard fileManager.fileExists(atPath: fileURL.path, isDirectory: &isDirectory) else {
                        return
                    }
                    guard !isDirectory.boolValue else {
                        return
                    }
                    let destinationURL = documentsDirectory.appendingPathComponent(path)
                    do {
                        try fileManager.copyItem(at: fileURL, to: destinationURL)
                        print("Successfully copied \(fileURL)", "to: ", destinationURL)
                        NotificationCenter.default.post(name: NSNotification.Name("did_record_video"), object: nil, userInfo: nil)
                    } catch {
                        print("error copying \(fileURL) to \(destinationURL)", error)
                    }
                }
            } catch {
                print("contents, \(error)")
            }
        }
    }

    @IBAction func onPressClose(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func onPressConfig(_ sender: UIButton) {
        let vc: RecordConfigVC = .load(SB: .Home)
        present(vc, animated: true, completion: nil)
    }
    
    @IBAction func onPressRecord(_ sender: UIButton) {
        
        if Cache.shared.is_premium == false && RemoteConfigManager.sharedInstance.boolValue(forKey: .lockSreenRecording) {
            let vc: InappPremiumVC = .load(SB: .More)
            vc.pageMode = 2
            present(vc, animated: true, completion: nil)
            return
        }
        
        if stateRecording == .recording {
            if let button = broadcastView.subviews.first as? UIButton {
                button.sendActions(for: .touchUpInside)
            }
        }
    }
    
    func startRecordSetup() {
        if stateRecording == .ready {
            if timer == nil {
                timer = CountdownService()
                timer?.start(beginingValue: 0, interval: 1, countDown: false)
                timer?.delegate = self
            }
            stateRecording = .recording
            broadcastView.isHidden = true
            updateUI()
        }
    }
    
    func endRecordingSetup() {
        if stateRecording != .ready {
            if timer != nil {
                timer?.pause()
            }
            stateRecording = .stop
            broadcastView.isHidden = false
            updateUI()
            read()
        }
    }
}

extension RecordVC: CountdownServiceDelegate {
    func timerDidUpdateCounterValue(newValueString: String) {
        lblRecordTime.text = newValueString
    }
    
    func timerDidPause() {
        let alert = RecordingSavedAlert()
        alert.callback = { action in
            if action {
                
            }
            if self.timer != nil {
                self.timer?.end()
            }
            self.stateRecording = .ready
            self.updateUI()
        }
        alert.show(animated: true)
    }
    
    func timerDidEnd() {
        timer = nil
    }
    
    func timerDidStart() {
        //
    }
}
