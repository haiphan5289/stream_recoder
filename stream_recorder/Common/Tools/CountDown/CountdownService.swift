//
//  CountdownService.swift
//  ScoreCam
//
//  Created by Rum on 21/03/2022.
//

import UIKit

protocol CountdownServiceDelegate: AnyObject {
    func timerDidUpdateCounterValue(newValue: Int)
    func timerDidUpdateCounterValue(newValueString: String)
    func timerDidStart()
    func timerDidPause()
    func timerDidResume()
    func timerDidEnd()
}

extension CountdownServiceDelegate {
    func timerDidUpdateCounterValue(newValue: Int) {}
    func timerDidUpdateCounterValue(newValueString: String) {}
    func timerDidStart() {}
    func timerDidPause() {}
    func timerDidResume() {}
    func timerDidEnd() {}
}

class CountdownService {
    weak var delegate: CountdownServiceDelegate?
    
    // use minutes and seconds for presentation
    public var useMinutesAndSecondsRepresentation = true
    
    private var timer: Timer?
    private var beginingValue: Int = 1
    private var totalTime: TimeInterval = 1
    private var elapsedTime: TimeInterval = 0
    private var interval: TimeInterval = 1 // Interval which is set by a user
    private let fireInterval: TimeInterval = 0.01 // ~60
    var isCountDown: Bool = true

    private var currentCounterValue: Int = 0 {
        didSet {
            delegate?.timerDidUpdateCounterValue(newValueString: currentCounterValue.durationTimeToShortString())
            delegate?.timerDidUpdateCounterValue(newValue: currentCounterValue)
        }
    }
    
    public func start(beginingValue: Int, interval: TimeInterval = 1, countDown: Bool = true) {
        self.beginingValue = beginingValue
        self.interval = interval
        self.isCountDown = countDown
        
        totalTime = TimeInterval(beginingValue) * interval
        elapsedTime = 0
        currentCounterValue = beginingValue
        
        timer?.invalidate()
        timer = Timer(timeInterval: fireInterval, target: self, selector: #selector(CountdownService.timerFired(_:)), userInfo: nil, repeats: true)
        
        RunLoop.main.add(timer!, forMode: .common)
        
        delegate?.timerDidStart()
    }
    
    /**
     * Pauses the timer with saving the current state
     */
    public func pause() {
        timer?.fireDate = Date.distantFuture
        
        delegate?.timerDidPause()
    }
    
    /**
     * Resumes the timer from the current state
     */
    public func resume() {
        timer?.fireDate = Date()
        
        delegate?.timerDidResume()
    }
    
    /**
     * End the timer
     */
    public func end() {
        self.currentCounterValue = 0
        timer?.invalidate()
        
        delegate?.timerDidEnd()
    }
    
    public func invalidate() {
        timer?.invalidate()
    }

    private func getMinutesAndSeconds(remainingSeconds: Int) -> (String) {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds - minutes * 60
        let secondString = seconds < 10 ? "0" + seconds.description : seconds.description
        return minutes.description + ":" + secondString
    }
    
    
    public func getSeconds() -> String {
        return String(format: "%i", currentCounterValue)
    }
    
    // MARK: Private methods
    @objc private func timerFired(_ timer: Timer) {
        if isCountDown {
            elapsedTime += fireInterval
            
            if elapsedTime < totalTime {
                let computedCounterValue = beginingValue - Int(elapsedTime / interval)
                if computedCounterValue != currentCounterValue {
                    currentCounterValue = computedCounterValue
                }
            } else {
                end()
            }
        } else {
            elapsedTime += fireInterval
            let computedCounterValue = beginingValue + Int(elapsedTime / interval)
            currentCounterValue = computedCounterValue
        }
        
    }
}
