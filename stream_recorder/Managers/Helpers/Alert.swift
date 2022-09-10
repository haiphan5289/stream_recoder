//
//  Alert.swift
//  stream_recorder
//
//  Created by Huy on 14/03/2022.
//

import Foundation
import UIKit

class Alert: NSObject {
    
    var popupWindow : UIWindow!

    class var sharedInstance: Alert {
        struct SingletonWrapper {
            static let sharedInstance = Alert()
        }
        
        return SingletonWrapper.sharedInstance;
    }
    
    class var shared: Alert {
        return Alert()
    }
    
    fileprivate override init() {
        super.init()
    }
    
    func centerErrorMessage(text: String, rootVC: UIViewController? = nil) {
        if let rootVC = rootVC {
            DispatchQueue.main.async {
                let view = UIAlertController(title: "Error", message: text, preferredStyle: .alert)
                view.addAction(UIAlertAction(title: "OK", style: .default))
                rootVC.present(view, animated: true)
            }
        }
    }
    
    func errorMessage(message: String, rootVC: UIViewController? = nil) {
        if let rootVC = rootVC {
            DispatchQueue.main.async {
                let view = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
                view.addAction(UIAlertAction(title: "OK", style: .default))
                rootVC.present(view, animated: true)
            }
        }
        
    }
    
    func warningMessage(message: String, rootVC: UIViewController? = nil) {
        if let rootVC = rootVC {
            DispatchQueue.main.async {
                let view = UIAlertController(title: "Warning", message: message, preferredStyle: .alert)
                view.addAction(UIAlertAction(title: "OK", style: .default))
                rootVC.present(view, animated: true)
            }
        }
    }
    
    func successMessage(message: String, rootVC: UIViewController? = nil) {
        if let rootVC = rootVC {
            DispatchQueue.main.async {
                let view = UIAlertController(title: "Success", message: message, preferredStyle: .alert)
                view.addAction(UIAlertAction(title: "OK", style: .default))
                rootVC.present(view, animated: true)
            }
        }
    }
    
}

class StatusBarShowingViewController: UIViewController {

    override var prefersStatusBarHidden : Bool {
        return false
    }

}
