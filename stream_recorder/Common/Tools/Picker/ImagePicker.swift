
import UIKit

public protocol ImagePickerDelegate: AnyObject {
    func didSelect(image: UIImage?)
    func didSelectVideo(url: URL)
}

open class ImagePicker: NSObject {

    private let pickerController: UIImagePickerController
    private weak var presentationController: UIViewController?
    private weak var delegate: ImagePickerDelegate?

    public init(presentationController: UIViewController, delegate: ImagePickerDelegate) {
        self.pickerController = UIImagePickerController()

        super.init()

        self.presentationController = presentationController
        self.delegate = delegate

        self.pickerController.delegate = self
        self.pickerController.allowsEditing = false
        self.pickerController.mediaTypes = ["public.image"]
        if #available(iOS 13.0, *) {
            self.pickerController.overrideUserInterfaceStyle = .light
        } else {
            // Fallback on earlier versions
        }
    }

    private func action(for type: UIImagePickerController.SourceType, title: String) -> UIAlertAction? {
        guard UIImagePickerController.isSourceTypeAvailable(type) else {
            return nil
        }

        return UIAlertAction(title: title, style: .default) { [unowned self] _ in
            self.pickerController.sourceType = type
            self.presentationController?.present(self.pickerController, animated: true)
        }
    }
    
    public func presentGallery(type: [String]) {
        pickerController.sourceType = .photoLibrary
        pickerController.mediaTypes = type
        self.presentationController?.present(self.pickerController, animated: true)
    }
    
    public func presentCamera() {
        pickerController.sourceType = .camera
        pickerController.allowsEditing = false
        self.presentationController?.present(self.pickerController, animated: true)
    }

    public func present(from sourceView: UIView) {

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        if let action = self.action(for: .camera, title: "Take photo") {
            alertController.addAction(action)
        }
        if let action = self.action(for: .savedPhotosAlbum, title: "Camera roll") {
            alertController.addAction(action)
        }
        if let action = self.action(for: .photoLibrary, title: "Photo library") {
            alertController.addAction(action)
        }

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        if #available(iOS 13.0, *) {
            alertController.overrideUserInterfaceStyle = .light
        } else {
            // Fallback on earlier versions
        }

        if UIDevice.current.userInterfaceIdiom == .pad {
            alertController.popoverPresentationController?.sourceView = sourceView
            alertController.popoverPresentationController?.sourceRect = sourceView.bounds
            alertController.popoverPresentationController?.permittedArrowDirections = [.down, .up]
        }

        self.presentationController?.present(alertController, animated: true)
    }

    private func pickerController(_ controller: UIImagePickerController, didSelect image: UIImage?) {
        controller.dismiss(animated: true, completion: nil)

        self.delegate?.didSelect(image: image)
    }
    
    private func pickerController(_ controller: UIImagePickerController, didSelect url: URL) {
        controller.dismiss(animated: true, completion: nil)

        self.delegate?.didSelectVideo(url: url)
    }
}

extension ImagePicker: UIImagePickerControllerDelegate {

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

    public func imagePickerController(_ picker: UIImagePickerController,
                                      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let url = info[.mediaURL] as? URL {
            self.pickerController(picker, didSelect: url)
        } else if let image = info[.editedImage] as? UIImage {
            self.pickerController(picker, didSelect: image)
        } else if let image = info[.originalImage] as? UIImage {
            self.pickerController(picker, didSelect: image)
        } else {
            self.pickerController(picker, didSelect: nil)
        }
    }
}

extension ImagePicker: UINavigationControllerDelegate {

}
