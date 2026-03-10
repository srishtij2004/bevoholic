
//  DareScreenViewController.swift
//  Bevoholic
//
//  Created by Likhita Velmurugan on 3/9/26.
//

import UIKit
import PhotosUI

class DareScreenViewController: HeaderViewController, PHPickerViewControllerDelegate {

    @IBOutlet weak var uploadButton: UIButton!
    @IBOutlet weak var completeButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        setUploadIconSize()
        addDashedBorder()
        
        completeButton.isEnabled = false
        completeButton.alpha = 0.5
        completeButton.backgroundColor = .systemGreen
        completeButton.layer.cornerRadius = 25
    }
    
    func addDashedBorder() {
        let dashedBorder = CAShapeLayer()
        dashedBorder.strokeColor = UIColor.black.cgColor
        dashedBorder.lineDashPattern = [6,4]
        dashedBorder.fillColor = nil
        dashedBorder.frame = uploadButton.bounds

        dashedBorder.path = UIBezierPath(
            roundedRect: uploadButton.bounds,
            cornerRadius: 20
        ).cgPath

        uploadButton.layer.addSublayer(dashedBorder)
    }

    // For icon inside the upload button
    func setUploadIconSize() {
        var config = uploadButton.configuration
        config?.image = UIImage(
            systemName: "square.and.arrow.up.circle.fill",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 50, weight: .bold)
        )
        config?.imagePlacement = .leading
        config?.imagePadding = 12
        uploadButton.configuration = config
    }


    //Upload pressed -> choose from gallery -> shpw pic preview
    @IBAction func uploadPressed(_ sender: UIButton) {
        showPhotoPicker()
    }

    func showPhotoPicker() {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)

        guard
            let provider = results.first?.itemProvider,
            provider.canLoadObject(ofClass: UIImage.self)
        else { return }

        provider.loadObject(ofClass: UIImage.self) { image, _ in

            DispatchQueue.main.async {
                guard let selectedImage = image as? UIImage else { return }
                self.updateUploadButtonPreview(image: selectedImage)
                self.enableCompleteButton()
            }
        }
    }

    func updateUploadButtonPreview(image: UIImage) {

        let preview = image.preparingThumbnail(of: CGSize(width: 50, height: 50))
        var config = uploadButton.configuration
        config?.image = preview
        config?.imagePlacement = .leading
        uploadButton.configuration = config
    }

    func enableCompleteButton() {
        completeButton.isEnabled = true
        completeButton.alpha = 1
    }
}
