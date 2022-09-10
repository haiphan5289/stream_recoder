//
//  VideoPreviewerVC.swift
//  stream_recorder
//
//  Created by HHumorous on 09/04/2022.
//

import UIKit
import AVKit
import AVFoundation
import Photos
import PixelSDK

enum VideoPreviewTool: Int, CaseIterable {
    case p2p = 0
    case music
    case edit
    case gif
    case record
    
    var title: String {
        switch self {
        case .p2p:
            return "Pic in Pic"
        case .music:
            return "Add Music"
        case .edit:
            return "Edit"
        case .gif:
            return "To GIF"
        case .record:
            return "Record Audio"
        }
    }
    
    var icon: UIImage {
        switch self {
        case .p2p:
            return #imageLiteral(resourceName: "icPicInPic")
        case .music:
            return #imageLiteral(resourceName: "icMusic")
        case .edit:
            return #imageLiteral(resourceName: "icEdit")
        case .gif:
            return #imageLiteral(resourceName: "icGif")
        case .record:
            return #imageLiteral(resourceName: "icRecordAudio")
        }
    }
}

class VideoPreviewerVC: UIViewController {
    @IBOutlet weak var vFooter: UIView!
    @IBOutlet weak var clvContent: UICollectionView!
    @IBOutlet weak var vHeader: UIView!
    @IBOutlet weak var vPlayer: VideoPlayerView!
    
    lazy private(set) var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.startAnimating()
        return activityIndicator
    }()
    
    var autoPlay: Bool = true
    
    var photo: VideoModel!
    var isHiddenStatusBar: Bool = false
    
    override open var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait, .landscapeLeft, .landscapeRight]
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent
    }
    
    override var prefersStatusBarHidden: Bool {
        return isHiddenStatusBar
    }
    
    deinit {
        self.vPlayer.stop()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCollectionView()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.vPlayer.asset == nil {
            view.addSubview(activityIndicator)
            activityIndicator.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
            activityIndicator.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin, .flexibleRightMargin, .flexibleBottomMargin]
            activityIndicator.sizeToFit()
            activityIndicator.startAnimating()

            getItemPlayer(file: self.photo) { (item) in
                self.vPlayer.asset = item
                self.activityIndicator.stopAnimating()
                self.setupGesture()
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.vPlayer.asset = nil
        self.vPlayer.btnPlay.isHidden = false
        self.vPlayer.btnPlay.alpha = 1
        self.vPlayer.btnPlay.isSelected = false
        clearTempFolder()
    }
    
    func setupCollectionView() {
        clvContent.delegate = self
        clvContent.dataSource = self
        clvContent.register(UINib(nibName: VideoPreviewToolCell.identifierCell, bundle: nil), forCellWithReuseIdentifier: VideoPreviewToolCell.identifierCell)
        clvContent.collectionViewLayout = createLayout()
    }
    
    func createLayout() -> UICollectionViewLayout {
        let sectionProvider = { (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
                                    
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .estimated(80), heightDimension: .fractionalHeight(1.0)))
            
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(60)), subitems: [item])
            group.interItemSpacing = .fixed(16)

            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
            section.orthogonalScrollingBehavior = .continuous

            return section
        }
                
        let layout = UICollectionViewCompositionalLayout(sectionProvider: sectionProvider)
        
        return layout
    }
    
    func setupGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        vPlayer.addGestureRecognizer(tapGesture)
    }
    
    @objc func handleTapGesture(_ gesture: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseInOut]) {
            if self.vFooter.alpha == 0 {
                self.vFooter.alpha = 1
                self.vHeader.alpha = 1
                self.isHiddenStatusBar = false
            } else {
                self.vFooter.alpha = 0
                self.vHeader.alpha = 0
                self.isHiddenStatusBar = true
            }
            self.vPlayer.toggleControlView(tapGesture: gesture)
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.temporaryDirectory
        return paths
    }
    
    func clearTempFolder() {
        let fileManager = FileManager.default
        let tempFolderPath = NSTemporaryDirectory()
        do {
            let filePaths = try fileManager.contentsOfDirectory(atPath: tempFolderPath)
            for filePath in filePaths {
                try fileManager.removeItem(atPath: tempFolderPath + filePath)
            }
        } catch {
            print("Could not clear temp folder: \(error)")
        }
    }
    
    func getItemPlayer(file: VideoModel, completion: ((AVAsset?) -> Void)?) {
        let item = AVAsset(url: file.path)
        completion?(item)
    }
    
    @IBAction func onPressClose(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func onPressShare(_ sender: UIButton) {
        let activity = UIActivityViewController(activityItems: [photo.path], applicationActivities: nil)
        present(activity, animated: true)
    }
    
    @IBAction func onPressSave(_ sender: UIButton) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.photo.path)
        }) { saved, error in
            if saved {
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "Video saved", message: nil, preferredStyle: .alert)
                    let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alertController.addAction(defaultAction)
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }
}

extension VideoPreviewerVC: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return VideoPreviewTool.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: VideoPreviewToolCell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoPreviewToolCell.identifierCell, for: indexPath) as! VideoPreviewToolCell
        let item = VideoPreviewTool.allCases[indexPath.row]
        
        cell.lblTitle.text = item.title
        cell.imgIcon.image = item.icon
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let asset = AVAsset(url: photo.path)
        let _ = Session(assets: [asset], sessionReady: { (session, error) in
            guard let session = session,
                let video = session.video else {
                print("Unable to create session: \(error!)")
                return
            }
            
            // Set the initial primary filter to Sepulveda
            video.primaryFilter = SessionFilterSepulveda()

            let editController = EditController(session: session)
            editController.delegate = self

            let nav = UINavigationController(rootViewController: editController)
            nav.modalPresentationStyle = .fullScreen
            self.present(nav, animated: true, completion: nil)
        })
    }
}

extension VideoPreviewerVC: EditControllerDelegate {
    func editController(_ editController: EditController, didFinishEditing session: Session) {
        let view = ProgressVideoAlert()
        view.configureWith(sdkSession: session)
        view.callback = { action, _session in
            if action {
                if let videoUrl = _session?.video?.exportedVideoURL {
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoUrl)
                    }) { saved, error in
                        if saved {
                            DispatchQueue.main.async {
                                editController.dismiss(animated: true) {
                                    let alertController = UIAlertController(title: "Video saved", message: nil, preferredStyle: .alert)
                                    let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                                    alertController.addAction(defaultAction)
                                    self.present(alertController, animated: true, completion: nil)
                                }
                            }
                        }
                    }
                }
            } else {
                editController.dismiss(animated: true)
            }
        }
        view.show(animated: true)
    }
}
