//
//  VideoPlayerView.swift
//  SMessenger
//
//  Created by Rum on 14/01/2021.
//  Copyright © 2021 SMessenger. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

private func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

private var VideoPlayerViewContext = 0

class VideoPlayerView: UIView {
    var asset: AVAsset? {
        didSet {
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback)
            } catch(let error) {
                print(error.localizedDescription)
            }
            
            if self.asset == oldValue {
                return
            }
            
            if let oldAsset = oldValue {
                oldAsset.cancelLoading()
            }
            
            self.playerItem = nil
            
            if let newValue = self.asset {
                self.activityIndicator.startAnimating()
                newValue.loadValuesAsynchronously(forKeys: ["duration", "tracks"], completionHandler: {
                    if newValue == self.asset {
                        var error: NSError?
                        let loadStatus = newValue.statusOfValue(forKey: "duration", error: &error)
                        var item: AVPlayerItem?
                        if loadStatus == .loaded {
                            item = AVPlayerItem(asset: newValue)
                        } else if loadStatus == .failed {
                            self.error = error
                        }
                        
                        DispatchQueue.main.async {
                            if newValue == self.asset {
                                self.activityIndicator.stopAnimating()
                                
                                if let item = item {
                                    self.playerItem = item
                                } else if let error = self.error, self.autoPlayOrShowErrorOnce {
                                    self.showPlayError(error.localizedDescription)
                                }
                            }
                        }
                    }
                })
            }
        }
    }
    
    public var playerItem: AVPlayerItem? {

        willSet {
            if self.playerItem == newValue {
                return
            }
            
            if let oldPlayerItem = self.playerItem {
                self.removeObservers(for: oldPlayerItem)
                self.player.pause()

                self.player.replaceCurrentItem(with: nil)
            }

            if let newPlayerItem = newValue {
                self.player.replaceCurrentItem(with: newPlayerItem)
                self.addObservers(for: newPlayerItem)
            }
        }
    }
    
    public var beginPlayBlock: (() -> Void)?
    
    public var isControlHidden: Bool {
        get { return self.vControl.isHidden }
        
        set { self.vControl.isHidden = newValue }
    }
    
    public var isPlaying: Bool {
        get { return self.player.rate == 1.0 }
    }
        
    private var mediaPlaying: Bool = false
    
    public var autoHidesControlView = true
    
    public var tapToToggleControlView = true {
        willSet {
            self.tapGesture.isEnabled = newValue
        }
    }
    
    public var isFinishedPlaying = false
    
    lazy var btnPlay: UIButton = {
        let btn = UIButton()
        btn.setTitle("􀊄", for: .normal)
        btn.setTitle("􀊆", for: .selected)
        btn.titleLabel?.font = UIFont.sfProTextRegular(size: 24)
        btn.setTitleColor(UIColor(hex: "75b9f2"), for: .normal)
        btn.setTitleColor(UIColor(hex: "75b9f2"), for: .selected)
        btn.isSelected = false
        btn.alpha = 1
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(playAndHidesControlView), for: .touchUpInside)
        
        return btn
    }()
    
    lazy var lblDuration: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.workSansMedium(size: 13)
        lbl.textColor = UIColor.black
        lbl.translatesAutoresizingMaskIntoConstraints = false
        
        return lbl
    }()
    
    lazy var trackSlider: UISlider = {
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.thumbTintColor = .black
        slider.maximumTrackTintColor = UIColor.black.withAlphaComponent(0.11)
        slider.minimumTrackTintColor = UIColor.black
        let customThumb = Utilities.shared.makeCircleWith(size: CGSize(width: 16, height: 16), backgroundColor: .black)
        slider.setThumbImage(customThumb, for: .normal)
        slider.setThumbImage(customThumb, for: .highlighted)
        slider.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(sliderTappedAction(tapGesture:))))
        slider.addTarget(self, action: #selector(timeSliderDidChange(sender:event:)), for: .valueChanged)
        return slider
    }()
    
    lazy var vControl: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addShadowDecorate(radius: 0, maskCorner: [.layerMaxXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMinXMinYCorner], shadowColor: UIColor.black.withAlphaComponent(0.1), shadowOffset: CGSize(width: 0, height: -0.5), shadowRadius: 0, shadowOpacity: 10)
        view.layer.borderColor = UIColor.black.withAlphaComponent(0.1).cgColor
        view.layer.borderWidth = 0.5
        
        return view
    }()
    
    private let playPauseButton = UIButton(type: .custom)
    private var tapGesture: UITapGestureRecognizer!
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.isUserInteractionEnabled = false
        indicator.center = self.center
        indicator.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin, .flexibleBottomMargin, .flexibleRightMargin]
        
        return indicator
    }()
    
    private var playerLayer: AVPlayerLayer {
        return self.layer as! AVPlayerLayer
    }
    
    private let player = AVPlayer()
    
    private var currentTime: Double {
        get {
            return CMTimeGetSeconds(player.currentTime())
        }
        
        set {
            guard let _ = self.player.currentItem else { return }
            let newTime = CMTimeMakeWithSeconds(Double(Int64(newValue)), preferredTimescale: 1)
            self.player.seek(to: newTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        }
    }
        
    private var autoPlayOrShowErrorOnce = false
    
    private var _error: NSError?
    private var error: NSError? {
        get {
            return _error ?? self.player.currentItem?.error as NSError?
        }
        
        set {
            _error = newValue
        }
    }
    
    private let timeRemainingFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = [.minute, .second]
        
        return formatter
    }()

    private var timeObserverToken: Any?
    
    open override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    var autoPlay: Bool = true
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setupUI()
    }
    
    deinit {
        guard let currentItem = self.player.currentItem, currentItem.observationInfo != nil else { return }
        
        self.removeObservers(for: currentItem)
    }
    
    @objc public func playAndHidesControlView() {
        UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseInOut, animations: {
            self.btnPlay.isSelected = !self.btnPlay.isSelected
            if self.isPlaying {
                self.btnPlay.isHidden = false
            } else {
                self.btnPlay.isHidden = self.isControlHidden
            }
            self.btnPlay.alpha = self.btnPlay.isSelected ? 0.5 : 1
        }, completion: nil)
        
        if !self.isPlaying {
            self.play()
        } else {
            self.pause()
        }
        
        self.beginPlayBlock?()
    }
    
    public func play() {
        guard !self.isPlaying else { return }
        
        if let error = self.error {
            if let avAsset = self.asset ?? self.playerItem?.asset, self.isTriableError(error) {
                self.autoPlayOrShowErrorOnce = true
                
                if avAsset is AVURLAsset {
                    self.asset = nil
                } else {
                    self.asset = avAsset
                }
                self.error = nil
            } else {
                self.showPlayError(error.localizedDescription)
            }
            
            return
        }
        
        if let currentItem = self.playerItem {
            if currentItem.status == .readyToPlay {
                if self.isFinishedPlaying {
                    self.isFinishedPlaying = false
                    self.currentTime = 0.0
                }
                
                self.player.play()
                
                self.updateactivityIndicatorStateIfNeeded()
            } else if currentItem.status == .unknown {
                self.player.play()
            }
        }
    }
    
    @objc public func pause() {
        guard let _ = self.player.currentItem, self.isPlaying else { return }
        
        self.player.pause()
    }
    
    public func stop() {
        self.asset?.cancelLoading()
        self.pause()
    }
    
    public func reset() {
        self.asset?.cancelLoading()
        
        self.asset = nil
        self.playerItem = nil
        self.error = nil
        
        self.autoPlayOrShowErrorOnce = false
        self.isFinishedPlaying = false
        self.activityIndicator.stopAnimating()
        
        self.btnPlay.isHidden = false
        
        self.playPauseButton.isEnabled = false
        self.trackSlider.isEnabled = false
        self.trackSlider.value = 0
        
        self.lblDuration.isEnabled = false
        self.lblDuration.text = "00:00"
    }
    
    // MARK: - Private
    private func setupUI() {
        self.playerLayer.player = self.player
        
        self.addSubview(self.activityIndicator)
        self.addSubview(vControl)
        vControl.addSubview(btnPlay)
        vControl.addSubview(lblDuration)
        vControl.addSubview(trackSlider)

        NSLayoutConstraint.activate([
            vControl.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor, constant: -60),
            vControl.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0),
            vControl.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0),
            vControl.heightAnchor.constraint(equalToConstant: 38),

            btnPlay.widthAnchor.constraint(equalToConstant: 30),
            btnPlay.heightAnchor.constraint(equalToConstant: 30),
            btnPlay.centerYAnchor.constraint(equalTo: vControl.centerYAnchor, constant: 0),
            btnPlay.leadingAnchor.constraint(equalTo: vControl.leadingAnchor, constant: 7),
            
            trackSlider.leadingAnchor.constraint(equalTo: btnPlay.trailingAnchor, constant: 7),
            trackSlider.trailingAnchor.constraint(equalTo: lblDuration.leadingAnchor, constant: -12),
            trackSlider.centerYAnchor.constraint(equalTo: vControl.centerYAnchor, constant: 0),

            lblDuration.centerYAnchor.constraint(equalTo: vControl.centerYAnchor, constant: 0),
            lblDuration.trailingAnchor.constraint(equalTo: vControl.trailingAnchor, constant: -12)
        ])
        vControl.isHidden = self.isControlHidden
    }
    
    @objc private func timeSliderDidChange(sender: UISlider, event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began:
                mediaPlaying = self.isPlaying
                if mediaPlaying {
                    self.pause()
                }
                break
            case .moved:
                self.currentTime = Double(self.trackSlider.value)
            case .ended,
                 .cancelled:
                if mediaPlaying {
                    self.play()
                }
            default:
                break
            }
        } else {
            self.currentTime = Double(self.trackSlider.value)
            self.play()
        }
    }
    
    @objc private func sliderTappedAction(tapGesture: UITapGestureRecognizer) {
        if let slider = tapGesture.view as? UISlider {
            if slider.isHighlighted { return }
            
            let point = tapGesture.location(in: slider)
            let percentage = Float(point.x / slider.bounds.width)
            let delta = percentage * Float(slider.maximumValue - slider.minimumValue)
            let value = slider.minimumValue + delta
            slider.setValue(value, animated: false)
            slider.sendActions(for: .valueChanged)
        }
    }
    
    @objc public func toggleControlView(tapGesture: UITapGestureRecognizer) {
        
        UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseInOut, animations: {
            self.isControlHidden = !self.isControlHidden
            if self.isPlaying {
                self.btnPlay.isHidden = self.isControlHidden
            } else {
                self.btnPlay.isHidden = false
            }
            self.btnPlay.alpha = self.btnPlay.isSelected ? 0.5 : 1
        }, completion: nil)
        
//        self.startHidesControlTimerIfNeeded()
    }

    private var hidesControlViewTimer: Timer?
    private func startHidesControlTimerIfNeeded() {
        guard self.autoHidesControlView else { return }
        
        self.stopHidesControlTimer()
        if !self.isControlHidden && self.isPlaying {
            self.hidesControlViewTimer = Timer.scheduledTimer(timeInterval: 5,
                                                              target: self,
                                                              selector: #selector(hidesControlViewIfNeeded),
                                                              userInfo: nil,
                                                              repeats: false)
        }
    }
    
    private func stopHidesControlTimer() {
        guard self.autoHidesControlView else { return }
        
        self.hidesControlViewTimer?.invalidate()
        self.hidesControlViewTimer = nil
    }
    
    @objc private func hidesControlViewIfNeeded() {
        if self.isPlaying {
            self.isControlHidden = true
        }
    }
    
    private func createTimeString(time: Float) -> String {
        let components = NSDateComponents()
        components.second = Int(max(0.0, time))
        
        return timeRemainingFormatter.string(from: components as DateComponents)!
    }
    
    private func showPlayError(_ message: String) {
        // Show toast message
        print(message)
    }
    
    private func isTriableError(_ error: NSError) -> Bool {
        let untriableCodes: Set<Int> = [
            URLError.badURL.rawValue,
            URLError.fileDoesNotExist.rawValue,
            URLError.unsupportedURL.rawValue,
        ]
        
        return !untriableCodes.contains(error.code)
    }
    
    private func updateactivityIndicatorStateIfNeeded() {
        if self.isPlaying, let currentItem = self.player.currentItem {
            if currentItem.isPlaybackBufferEmpty {
                self.activityIndicator.startAnimating()
            } else if currentItem.isPlaybackLikelyToKeepUp {
                self.activityIndicator.stopAnimating()
            } else {
                self.activityIndicator.stopAnimating()
            }
        }
    }
    
    // MARK: - Observer
    
    private func addObservers(for playerItem: AVPlayerItem) {
        playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.duration), options: [.new, .initial], context: &VideoPlayerViewContext)
        playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.new, .initial], context: &VideoPlayerViewContext)
        playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp), options: [.new, .initial], context: &VideoPlayerViewContext)
        playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackBufferEmpty), options: [.new, .initial], context: &VideoPlayerViewContext)
        player.addObserver(self, forKeyPath: #keyPath(AVPlayer.rate), options: [.new, .initial], context: &VideoPlayerViewContext)
        
        NotificationCenter.default.addObserver(self, selector: #selector(itemDidPlayToEndTime), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        
        let interval = CMTime(value: 1, timescale: 1)
        self.timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main, using: { [weak self] (time) in
            guard let strongSelf = self else { return }
            
            let timeElapsed = Float(CMTimeGetSeconds(time))
            
            if strongSelf.isPlaying {
                strongSelf.trackSlider.value = timeElapsed
            }
        })
    }
    
    private func removeObservers(for playerItem: AVPlayerItem) {
        playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.duration), context: &VideoPlayerViewContext)
        playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: &VideoPlayerViewContext)
        playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp), context: &VideoPlayerViewContext)
        playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackBufferEmpty), context: &VideoPlayerViewContext)
        self.player.removeObserver(self, forKeyPath: #keyPath(AVPlayer.rate), context: &VideoPlayerViewContext)
        
        NotificationCenter.default.removeObserver(self)
        
        if let timeObserverToken = self.timeObserverToken {
            self.player.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
    }
    
    @objc func itemDidPlayToEndTime(notification: Notification) {
        if (notification.object as? AVPlayerItem) == self.player.currentItem {
            self.isFinishedPlaying = true
            UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseInOut, animations: {
                self.btnPlay.isHidden = false
                self.btnPlay.alpha = 1
                self.btnPlay.isSelected = false
            }, completion: nil)
        }
    }
    
    // Update our UI when player or `player.currentItem` changes.
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &VideoPlayerViewContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        if keyPath == #keyPath(AVPlayerItem.duration) {
            let newDuration: CMTime
            if let newDurationAsValue = change?[NSKeyValueChangeKey.newKey] as? NSValue {
                newDuration = newDurationAsValue.timeValue
            } else {
                newDuration = CMTime.zero
            }
            
            let hasValidDuration = newDuration.isNumeric && newDuration.value != 0
            let newDurationSeconds = hasValidDuration ? CMTimeGetSeconds(newDuration) : 0.0
            let currentTime = hasValidDuration ? Float(CMTimeGetSeconds(player.currentTime())) : 0.0
            
            self.trackSlider.maximumValue = Float(newDurationSeconds)
            self.trackSlider.value = currentTime
            
            self.playPauseButton.isEnabled = hasValidDuration
            self.trackSlider.isEnabled = hasValidDuration
            
            self.lblDuration.isEnabled = hasValidDuration
            self.lblDuration.text = self.createTimeString(time: Float(newDurationSeconds))
        } else if keyPath == #keyPath(AVPlayerItem.status) {
            guard let currentItem = object as? AVPlayerItem else { return }
            guard self.autoPlayOrShowErrorOnce else { return }
            
            let newStatus: AVPlayerItem.Status
            
            if let newStatusAsNumber = change?[NSKeyValueChangeKey.newKey] as? NSNumber {
                newStatus = AVPlayerItem.Status(rawValue: newStatusAsNumber.intValue)!
            } else {
                newStatus = .unknown
            }
            
            if newStatus == .readyToPlay {
                self.play()
                
                self.autoPlayOrShowErrorOnce = false
            } else if newStatus == .failed {
                if let error = currentItem.error {
                    self.showPlayError(error.localizedDescription)
                } else {
                    self.showPlayError("Unknown")
                }
                
                self.autoPlayOrShowErrorOnce = false
            }
        } else if keyPath == #keyPath(AVPlayer.rate) {
            // Update UI status.
            let newRate = (change?[NSKeyValueChangeKey.newKey] as! NSNumber).doubleValue
            
            if newRate == 1.0 {
//                self.startHidesControlTimerIfNeeded()
                self.playPauseButton.isSelected = true
            } else {
//                self.stopHidesControlTimer()
                self.playPauseButton.isSelected = false
            }
        } else if keyPath == #keyPath(AVPlayerItem.isPlaybackLikelyToKeepUp) {
            self.updateactivityIndicatorStateIfNeeded()
        } else if keyPath == #keyPath(AVPlayerItem.isPlaybackBufferEmpty) {
            self.updateactivityIndicatorStateIfNeeded()
        }
    }
}
