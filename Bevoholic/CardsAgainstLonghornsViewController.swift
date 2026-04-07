import UIKit
import PhotosUI
import FirebaseAuth
import FirebaseFirestore

class CardsAgainstLonghornsViewController: HeaderViewController, PHPickerViewControllerDelegate {
    
    @IBOutlet weak var calTitleLabel: UILabel!
    @IBOutlet weak var calPromptLabel: UILabel!
    @IBOutlet weak var uploadButton: UIButton!
    
    var gameCode: String!
    var selectedImage: UIImage?
    private let db = Firestore.firestore()
    
    let calPrompts: [String] = [
        "When you see an org giving out free food on campus…",
        "When your friend says 'Let’s skip class'…",
        "When you realize your group project is due tomorrow…",
        "When someone steals your favorite spot in the library…",
        "When it’s 2 AM and you just remembered your homework…",
        "When the RA says 'Quiet hours start now'…",
        "When you see someone eating your leftovers…",
        "When the professor says the exam is cumulative…",
        "When it’s Taco Tuesday and you see the line at the food truck…",
        "When you finally get your grade back and it’s better than expected…"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        setRandomPrompt()
        setUploadIconSize()
        addDashedBorder()
    }
    
    func setRandomPrompt() {
        calPromptLabel.text = calPrompts.randomElement() ?? "Be creative!"
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
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
        
        provider.loadObject(ofClass: UIImage.self) { image, _ in
            DispatchQueue.main.async {
                guard let selected = image as? UIImage else { return }
                self.selectedImage = self.resizeImage(selected, targetSize: CGSize(width: 400, height: 400))
                self.updateUploadButtonPreview()
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
        guard let image = selectedImage else { return }
        let preview = image.preparingThumbnail(of: CGSize(width: 50, height: 50))
        var config = uploadButton.configuration
        config?.image = preview
        uploadButton.configuration = config
    }
    
    @IBAction func submitPressed(_ sender: UIButton){
        guard let image = selectedImage, let gameCode = gameCode else {
            print("No image selected or game code missing")
            return
        }
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        sender.isEnabled = false
        
        guard let imageData = image.jpegData(compressionQuality: 0.3) else { return }
        let base64String = imageData.base64EncodedString()
        
        let gameRef = db.collection("games").document(gameCode)
        
        gameRef.collection("submissions").document(userId).setData([
            "image": base64String,
            "submittedAt": Timestamp(),
            "userId": userId
        ]) { error in
            if let error = error {
                print("Error uploading submission: \(error.localizedDescription)")
                sender.isEnabled = true
                return
            }

            gameRef.updateData(["gameState": "submitting"]) { error in
                if let error = error {
                    print("Error updating game state: \(error.localizedDescription)")
                }
                
                self.showWaitingScreen()
            }
        }
    }
    
    func showWaitingScreen() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let waitingVC = storyboard.instantiateViewController(withIdentifier: "WaitingViewController") as? WaitingViewController else { return }
        waitingVC.gameCode = gameCode
        navigationController?.pushViewController(waitingVC, animated: true)
    }
}
