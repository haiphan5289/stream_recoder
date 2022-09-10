//
//  HomeVC.swift
//  stream_recorder
//
//  Created by HHumorous on 03/04/2022.
//

import UIKit
import PixelSDK
import Photos
import PhotosUI

class HomeVC: UIViewController {
    
    enum HomeRow: Int, CaseIterable {
        case stream = 0
        case record
        case edit
        case cam
    }
    
    @IBOutlet weak var clvContent: UICollectionView!
    
    var imagePicker: ImagePicker!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupCollectionView()
        imagePicker = ImagePicker(presentationController: self, delegate: self)
    }
    
    func setupCollectionView() {
        clvContent.delegate = self
        clvContent.dataSource = self
        clvContent.register(UINib(nibName: HomeEditCell.identifierCell, bundle: nil), forCellWithReuseIdentifier: HomeEditCell.identifierCell)
        clvContent.register(UINib(nibName: HomeRecordCell.identifierCell, bundle: nil), forCellWithReuseIdentifier: HomeRecordCell.identifierCell)
        clvContent.register(UINib(nibName: HomeStreamCell.identifierCell, bundle: nil), forCellWithReuseIdentifier: HomeStreamCell.identifierCell)
        clvContent.register(UINib(nibName: HomeFaceCamCell.identifierCell, bundle: nil), forCellWithReuseIdentifier: HomeFaceCamCell.identifierCell)
        clvContent.collectionViewLayout = createLayout()
    }
    
    func createLayout() -> UICollectionViewLayout {
        let sectionProvider = { [self] (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
                                    
            let streamItem = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(186.0)))
            streamItem.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 8, trailing: 16)
            
            let recordItem = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(140.0)))
            recordItem.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
            
            let editItem = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(3/5), heightDimension: .absolute(140.0)))
            editItem.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 16, trailing: 8)
            
            let faceItem = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(2/5), heightDimension: .absolute(140.0)))
            faceItem.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 16, trailing: 16)

            let groupEditFace = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(140.0)), subitems: [editItem, faceItem])
            
            let containerGroup = NSCollectionLayoutGroup.vertical(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1)), subitems: [streamItem, recordItem, groupEditFace])
            
            let section = NSCollectionLayoutSection(group: containerGroup)
            
            return section
        }
                
        let layout = UICollectionViewCompositionalLayout(sectionProvider: sectionProvider)
        
        return layout
    }
}

extension HomeVC: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return HomeRow.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let row = HomeRow(rawValue: indexPath.row) else { return UICollectionViewCell() }
        switch row {
        case .stream:
            let cell: HomeStreamCell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeStreamCell.identifierCell, for: indexPath) as! HomeStreamCell
            
            return cell
        case .record:
            let cell: HomeRecordCell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeRecordCell.identifierCell, for: indexPath) as! HomeRecordCell
            
            return cell
        case .edit:
            let cell: HomeEditCell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeEditCell.identifierCell, for: indexPath) as! HomeEditCell
            
            return cell
        case .cam:
            let cell: HomeFaceCamCell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeFaceCamCell.identifierCell, for: indexPath) as! HomeFaceCamCell
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let row = HomeRow(rawValue: indexPath.row) else { return }
        switch row {
        case .stream:
            let vc: StreamVC = .load(SB: .Home)
            present(vc, animated: true, completion: nil)
        case .record:
            let vc: RecordVC = .load(SB: .Home)
            present(vc, animated: true, completion: nil)
        case .edit:
            let container = ContainerController(modes: [.library, .video])
            container.editControllerDelegate = self
            container.libraryController.fetchPredicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
            container.libraryController.draftMediaTypes = []

            let nav = UINavigationController(rootViewController: container)
            nav.modalPresentationStyle = .fullScreen

            self.present(nav, animated: true, completion: nil)
        case .cam:
            
            imagePicker.presentGallery(type: ["public.movie"])
        }

    }
}

extension HomeVC: ImagePickerDelegate {
    func didSelect(image: UIImage?) {
        //
    }
    
    func didSelectVideo(url: URL) {
        let vc: FacecamVC = .load(SB: .Home)
        vc.modalPresentationStyle = .fullScreen
        vc.videoURL = url
        self.present(vc, animated: true, completion: nil)
    }
}

extension HomeVC: EditControllerDelegate {
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
