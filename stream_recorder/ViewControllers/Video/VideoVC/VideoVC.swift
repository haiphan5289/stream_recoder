//
//  VideoVC.swift
//  stream_recorder
//
//  Created by HHumorous on 03/04/2022.
//

import UIKit
import AVFoundation

struct VideoModel: Equatable {
    var path: URL
    var name: String
    var thumb: UIImage
    var duration: Double
    var createAt: Date
}

class VideoVC: UIViewController {
    
    @IBOutlet weak var clvContent: UICollectionView!
    
    var listVideos: [VideoModel] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(getListVideos), name: NSNotification.Name("did_record_video"), object: nil)
        // Do any additional setup after loading the view.
        setupCollectionView()
        getListVideos()
    }
    
    func setupCollectionView() {
        clvContent.delegate = self
        clvContent.dataSource = self
        clvContent.register(UINib(nibName: VideoCell.identifierCell, bundle: nil), forCellWithReuseIdentifier: VideoCell.identifierCell)
        clvContent.collectionViewLayout = createLayout()
    }
    
    func createLayout() -> UICollectionViewLayout {
        let sectionProvider = { (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
                                    
            let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1/3), heightDimension: .fractionalHeight(1.0)))
            item.contentInsets = NSDirectionalEdgeInsets(top: 1, leading: 1, bottom: 1, trailing: 1)
            
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalWidth(1/3)), subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 7, leading: 16, bottom: 16, trailing: 16)
            
            return section
        }
                
        let layout = UICollectionViewCompositionalLayout(sectionProvider: sectionProvider)
        
        return layout
    }
    
    @objc func getListVideos() {
        // Should create a folder with name to save video

        let files = FileManager.default.urls(in: nil, for: .documentDirectory) ?? []
        listVideos = files.map { (file) -> VideoModel in
            return getDataFile(file: file)
        }.sorted(by: {$0.createAt.compare($1.createAt) == .orderedDescending})

        clvContent.reloadData()
    }
    
    func getDataFile(file: URL) -> VideoModel {
        let asset = AVAsset(url: file)
        let createAt = asset.creationDate?.value as? Date ?? Date()

        return VideoModel(path: file, name: file.lastPathComponent, thumb: UIImage(), duration: asset.duration.seconds, createAt: createAt)
    }
}

extension VideoVC: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return listVideos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: VideoCell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoCell.identifierCell, for: indexPath) as! VideoCell
        
        let video = listVideos[indexPath.row]
        cell.configura(video: video)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let video = listVideos[indexPath.row]
        
        let vc: VideoPreviewerVC = .load(SB: .Main)
        vc.photo = video
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let context = UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { (action) -> UIMenu? in
            let delete = UIAction(title: "Delete", image: UIImage(systemName: "trash"), identifier: nil, discoverabilityTitle: nil, attributes: .destructive, state: .off) { (_) in
                
                self.removeVideo(at: indexPath)
            }
            
            
            return UIMenu(title: "", image: nil, identifier: nil, options: UIMenu.Options.displayInline, children: [delete])
            
        }
        return context
    }
    
    func removeVideo(at indexPath: IndexPath) {
        let video = self.listVideos[indexPath.row]
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: video.path.path) {
            try? fileManager.removeItem(at: video.path)
            
            self.getListVideos()
        }
        
    }
}

extension FileManager {
    func urls(in path: String? = nil, for directory: FileManager.SearchPathDirectory, skipsHiddenFiles: Bool = true) -> [URL]? {
        let documentsURL = path == nil ? urls(for: directory, in: .userDomainMask)[0] : urls(for: directory, in: .userDomainMask)[0].appendingPathComponent(path!)
        let fileURLs = try? contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil, options: skipsHiddenFiles ? .skipsHiddenFiles : [] )
        return fileURLs
    }
}

