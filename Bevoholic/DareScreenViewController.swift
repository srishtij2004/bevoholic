//
//  DareScreenViewController.swift
//  Bevoholic
//
//  Created by Likhita Velmurugan on 3/9/26.
//

import UIKit
import PhotosUI
import FirebaseAuth
import FirebaseFirestore

class DareScreenViewController: HeaderViewController, PHPickerViewControllerDelegate {

    @IBOutlet weak var gameModeLabel: UILabel!
    @IBOutlet weak var dareModeLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var playerPoints: UILabel!

    @IBOutlet weak var dare: UILabel!
    @IBOutlet weak var locationButton: UIButton!

    @IBOutlet weak var uploadButton: UIButton!
    @IBOutlet weak var completeButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!

    @IBOutlet weak var avatarImageView: PlayerProfile!
    
    @IBOutlet weak var cardView: UIView!
    
    var gameCode: String!

    private let db = Firestore.firestore()
    private var gameListener: ListenerRegistration?
    private var playerListener: ListenerRegistration?
    private var hasRoutedAway = false
    
    var playerDifficulty = "Buzzed Bevo"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        setUploadIconSize()
        addDashedBorder()
        uploadButton.layer.cornerRadius = 20
        uploadButton.clipsToBounds = true
        loadPlayerDifficulty()

        completeButton.isEnabled = false
        completeButton.alpha = 0.5
        completeButton.backgroundColor = .systemGreen
        completeButton.layer.cornerRadius = 25
        cardView.layer.cornerRadius = 20
        cardView.clipsToBounds = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        observeGame()
        observeCurrentPlayer()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        gameListener?.remove()
        gameListener = nil
        playerListener?.remove()
        playerListener = nil
    }

    func observeGame() {
        guard let gameCode = gameCode else { return }

        gameListener = db.collection("games").document(gameCode).addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                print("Error observing active turn: \(error.localizedDescription)")
                return
            }

            guard let data = snapshot?.data() else { return }
            self.updateUI(with: data)
            self.routeIfNeeded(using: data)
        }
    }
    
    func loadPlayerDifficulty() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("Error loading difficulty: \(error.localizedDescription)")
                return
            }

            let difficulty = snapshot?.data()?["difficulty"] as? String ?? "Buzzed Bevo"
            self.playerDifficulty = difficulty

            DispatchQueue.main.async {
                self.updateDifficultyUI()
            }
        }
    }
    
    func updateDifficultyUI() {
        gameModeLabel.text = " Game Mode: \(playerDifficulty)"

        switch playerDifficulty {
            
        case "Buzzkill Bevo":
            skipButton.setTitle("Skip -5 pts", for: .normal)

        case "Buzzed Bevo":
            skipButton.setTitle("Skip! Take a shot! -5 pts", for: .normal)

        case "Bevoholic":

            let shotText = Bool.random()
            ? "Skip! Take 2 shots! -5 pts"
            : "Skip! Take 1 shot! -5 pts"

            skipButton.setTitle(shotText, for: .normal)

        default:
            skipButton.setTitle("Skip -5 pts", for: .normal)
        }
    }

    func observeCurrentPlayer() {
        guard
            let gameCode = gameCode,
            let userId = Auth.auth().currentUser?.uid
        else {
            return
        }

        playerListener = db.collection("games")
            .document(gameCode)
            .collection("players")
            .document(userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("Error observing player score: \(error.localizedDescription)")
                    return
                }

                let points = snapshot?.data()?["points"] as? Int ?? 0
                self.playerPoints.text = "\(points)"
            }
    }

    func updateUI(with gameData: [String: Any]) {
        if let currentPlayerId = gameData["currentPlayerId"] as? String {
                
                db.collection("users").document(currentPlayerId).getDocument { [weak self] snapshot, error in
                    guard let self = self,
                          let data = snapshot?.data(),
                          let avatarName = data["selectedAvatar"] as? String else { return }
                    
                    DispatchQueue.main.async {
                        self.avatarImageView.image = UIImage(named: avatarName)
                    }
                }
        }
        usernameLabel.text = gameData["currentPlayerName"] as? String ?? "Player"

        let location = gameData["location"] as? String ?? "On Campus"
        dareModeLabel.text = " Dare Mode: \(location)"

        dare.text = gameData["currentDare"] as? String ?? ""

        locationButton.isHidden = location == "Kickback"
    }

    func routeIfNeeded(using gameData: [String: Any]) {
        guard !hasRoutedAway else { return }
        
        guard
            let currentUserId = Auth.auth().currentUser?.uid,
            let gameState = gameData["gameState"] as? String
        else {
            return
        }

        if gameState == "finished" {
            hasRoutedAway = true
            showLeaderboardScreen()
            return
        }

        guard let currentPlayerId = gameData["currentPlayerId"] as? String else { return }

        if currentUserId != currentPlayerId {
            hasRoutedAway = true
            showWaitingScreen()
        }
    }

    func addDashedBorder() {
        uploadButton.layer.sublayers?.removeAll(where: { $0 is CAShapeLayer })

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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        addDashedBorder()
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

    @IBAction func completePressed(_ sender: UIButton) {
        submitTurn(pointsDelta: 20)
    }

    @IBAction func skipPressed(_ sender: UIButton) {
        submitTurn(pointsDelta: -5)
    }

    func submitTurn(pointsDelta: Int) {
        guard
            let gameCode = gameCode,
            let userId = Auth.auth().currentUser?.uid
        else {
            return
        }

        completeButton.isEnabled = false
        skipButton.isEnabled = false

        let gameRef = db.collection("games").document(gameCode)
        let playerRef = gameRef.collection("players").document(userId)

        gameRef.getDocument { snapshot, error in
            if let error = error {
                print("Error loading game for turn submission: \(error.localizedDescription)")
                return
            }

            guard
                let gameData = snapshot?.data(),
                let currentPlayerId = gameData["currentPlayerId"] as? String,
                currentPlayerId == userId
            else {
                return
            }

            playerRef.getDocument { playerSnapshot, error in
                if let error = error {
                    print("Error loading player score: \(error.localizedDescription)")
                    return
                }

                let currentPoints = playerSnapshot?.data()?["points"] as? Int ?? 0
                let updatedPoints = currentPoints + pointsDelta

                playerRef.setData(["points": updatedPoints], merge: true) { error in
                    if let error = error {
                        print("Error updating player score: \(error.localizedDescription)")
                        return
                    }

                    self.advanceGame(using: gameData)
                }
            }
        }
    }

    func advanceGame(using gameData: [String: Any]) {
        guard let gameCode = gameCode else { return }

        let gameRef = db.collection("games").document(gameCode)
        let playerOrder = gameData["playerOrder"] as? [String] ?? []
        guard !playerOrder.isEmpty else { return }

        let currentTurnIndex = gameData["currentTurnIndex"] as? Int ?? 0
        let turnsPlayed = gameData["turnsPlayed"] as? Int ?? 0
        let totalRounds = gameData["totalRounds"] as? Int ?? DrinkOrDareGameManager.shared.totalRounds
        let nextTurnsPlayed = turnsPlayed + 1

        if nextTurnsPlayed >= playerOrder.count * totalRounds {
            gameRef.setData([
                "gameState": "finished",
                "turnsPlayed": nextTurnsPlayed
            ], merge: true) { error in
                if let error = error {
                    print("Error finishing game: \(error.localizedDescription)")
                }
            }
            return
        }

        let nextTurnIndex = (currentTurnIndex + 1) % playerOrder.count
        let nextPlayerId = playerOrder[nextTurnIndex]
        let location = gameData["location"] as? String ?? "On Campus"
        let nextDare = DrinkOrDareGameManager.shared.randomDare(for: location)

        gameRef.collection("players").document(nextPlayerId).getDocument { snapshot, error in
            if let error = error {
                print("Error loading next player: \(error.localizedDescription)")
                return
            }

            let nextPlayerName = snapshot?.data()?["name"] as? String ?? "Player"

            gameRef.setData([
                "currentTurnIndex": nextTurnIndex,
                "currentPlayerId": nextPlayerId,
                "currentPlayerName": nextPlayerName,
                "currentDare": nextDare,
                "turnsPlayed": nextTurnsPlayed
            ], merge: true) { error in
                if let error = error {
                    print("Error advancing game: \(error.localizedDescription)")
                }
            }
        }
    }

    func showWaitingScreen() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let waitingViewController = storyboard.instantiateViewController(withIdentifier: "WaitingViewController") as? WaitingViewController else {
            return
        }

        waitingViewController.gameCode = gameCode
        waitingViewController.navigationItem.hidesBackButton = true
        navigationController?.pushViewController(waitingViewController, animated: true)
    }

    func showLeaderboardScreen() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let leaderboardViewController = storyboard.instantiateViewController(withIdentifier: "LeaderboardViewController") as? LeaderboardViewController else {
            return
        }

        leaderboardViewController.gameCode = gameCode
        leaderboardViewController.navigationItem.hidesBackButton = true
        navigationController?.pushViewController(leaderboardViewController, animated: true)
    }
    
}
