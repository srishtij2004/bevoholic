//based on drink or dare and imposter view controllers

import UIKit
import PhotosUI
import FirebaseAuth
import FirebaseFirestore

class CALViewController: HeaderViewController, PHPickerViewControllerDelegate {
    
    @IBOutlet weak var calTitleLabel: UILabel!
    @IBOutlet weak var calPromptLabel: UILabel!
    @IBOutlet weak var uploadButton: UIButton!
    
    @IBOutlet weak var cardView: UIView!
    
    var gameCode: String!
    var selectedImage: UIImage?
    private let db = Firestore.firestore()
    var promptListener: ListenerRegistration?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        cardView.layer.cornerRadius = 20
        cardView.clipsToBounds = true
        fetchSyncedPrompt()
        setUploadIconSize()
        addDashedBorder()
    }
    
    func fetchSyncedPrompt() {
        guard let gameCode = gameCode else {
            return
        }
        
        promptListener = db.collection("games").document(gameCode).addSnapshotListener { snapshot, error in
            if let data = snapshot?.data(), let prompt = data["currentPrompt"] as? String {
                DispatchQueue.main.async {
                    self.calPromptLabel.text = prompt
                }
            }
            else {
                DispatchQueue.main.async {
                    self.calPromptLabel.text = "Waiting for prompt..."
                }
            }
        }
    }
    
    func addDashedBorder() {
        let dashedBorder = CAShapeLayer()
        dashedBorder.strokeColor = UIColor.black.cgColor
        dashedBorder.lineDashPattern = [6, 4]
        dashedBorder.fillColor = nil
        dashedBorder.frame = uploadButton.bounds
        
        dashedBorder.path = UIBezierPath(
            roundedRect: uploadButton.bounds,
            cornerRadius: 20
        ).cgPath
        uploadButton.layer.addSublayer(dashedBorder)
    }
    
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
    
    @IBAction func uploadPressed(_ sender: UIButton) {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else {
            return
        }
        
        provider.loadObject(ofClass: UIImage.self) { image, _ in
            DispatchQueue.main.async {
                guard let selected = image as? UIImage else {
                    return
                }
                self.selectedImage = self.resizeImage(selected, targetSize: CGSize(width: 400, height: 400))
                self.updateUploadButtonPreview()
                self.uploadButton.isEnabled = true
            }
        }
    }
    
    func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
    func updateUploadButtonPreview() {
        guard let image = selectedImage else {
            return
        }
        let preview = image.preparingThumbnail(of: CGSize(width: 50, height: 50))
        var config = uploadButton.configuration
        config?.image = preview
        uploadButton.configuration = config
    }
    
    @IBAction func submitPressed(_ sender: UIButton) {
        guard let image = selectedImage, let gameCode = gameCode else {
            return
        }
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }
        
        sender.isEnabled = false
        
        guard let imageData = image.jpegData(compressionQuality: 0.3) else {
            sender.isEnabled = true
            return
        }
        let base64String = imageData.base64EncodedString()
        
        let gameRef = db.collection("games").document(gameCode)
        
        let submissionData: [String: Any] = [
            "image": base64String,
            "submittedAt": Timestamp(),
            "userId": userId
        ]
        
        gameRef.collection("submissions").document(userId).setData(submissionData) { error in
            if error != nil {
                sender.isEnabled = true
                return
            }
            
            gameRef.getDocument { (document, error) in
                if let document = document, let data = document.data() {
                    let totalPlayers = (data["playerOrder"] as? [String])?.count ?? 0
                    
                    gameRef.collection("submissions").getDocuments { (snapshot, error) in
                        let submissionCount = snapshot?.documents.count ?? 0
                        
                        if submissionCount >= totalPlayers && totalPlayers > 0 {
                            gameRef.updateData(["gameState": "voting"])
                        } else {
                            gameRef.updateData(["gameState": "submitting"])
                        }
                        
                        DispatchQueue.main.async {
                            self.selectedImage = nil
                            self.setUploadIconSize()
                            sender.isEnabled = true
                            self.showWaitingScreen()
                        }
                    }
                }
            }
        }
    }
    
    func showWaitingScreen() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let waitingVC = storyboard.instantiateViewController(withIdentifier: "WaitingViewController") as? WaitingViewController else {
            return
        }
        waitingVC.gameCode = gameCode
        navigationController?.pushViewController(waitingVC, animated: true)
    }
    
    deinit {
        promptListener?.remove()
    }
}
