//
//  CALWinnerVC.swift
//  Bevoholic
//
//  Created by Poluchalla, Srilekha on 4/1/26.
//

import UIKit
import FirebaseFirestore

class CALWinnerVC: HeaderViewController {

    @IBOutlet weak var winnerCardView: UIView!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var winnerMessageLabel: UILabel!
    @IBOutlet weak var newRoundButton: UIButton!

    @IBOutlet weak var winnerMessageView: UIView!
    
    var gameCode: String!

    private let db = Firestore.firestore()
    private var stateListener: ListenerRegistration?
    private var hasRoutedToPrompt = false

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.hidesBackButton = true

        styleUI()
        calculateWinner()
        listenForNewRound()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hasRoutedToPrompt = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stateListener?.remove()
    }

    func styleUI() {
        winnerCardView.layer.cornerRadius = 20
        winnerCardView.clipsToBounds = true
        winnerMessageView.layer.cornerRadius = 20
        winnerMessageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = avatarImageView.frame.width / 2
        avatarImageView.clipsToBounds = true

        newRoundButton.layer.cornerRadius = 18
    }

    func calculateWinner() {
        guard let gameCode = gameCode else { return }

        db.collection("games")
            .document(gameCode)
            .collection("votes")
            .getDocuments { snapshot, error in

                guard let docs = snapshot?.documents,
                      !docs.isEmpty else { return }

                var maxVotes = 0
                var winnerId = ""

                for doc in docs {
                    let votes = doc.data()["votes"] as? Int ?? 0

                    if votes > maxVotes {
                        maxVotes = votes
                        winnerId = doc.documentID
                    }
                }

                self.loadWinnerDetails(userId: winnerId)
            }
    }

    func loadWinnerDetails(userId: String) {

        var username = "@player"
        var avatarName = "longhornHead"

        db.collection("games")
            .document(gameCode)
            .collection("players")
            .document(userId)
            .getDocument { snap, error in

                if let data = snap?.data() {
                    username = data["name"] as? String ??
                               data["username"] as? String ??
                               "@player"
                }

                self.db.collection("users")
                    .document(userId)
                    .getDocument { userSnap, error in

                        if let data = userSnap?.data() {
                            avatarName = data["selectedAvatar"] as? String ?? "longhornHead"
                        }

                        DispatchQueue.main.async {

                            self.usernameLabel.text = "@\(username)"
                            self.avatarImageView.image = UIImage(named: avatarName)

                            self.winnerMessageLabel.text =
                            "@\(username) wins!\nEveryone else bottoms up!"
                        }
                    }
            }
    }

    func listenForNewRound() {
        guard let gameCode = gameCode else { return }

        stateListener = db.collection("games")
            .document(gameCode)
            .addSnapshotListener { snapshot, error in

                guard let data = snapshot?.data(),
                      let state = data["gameState"] as? String else { return }

                if state == "inProgress" && !self.hasRoutedToPrompt {
                    self.hasRoutedToPrompt = true
                    self.routeBackToPromptScreen()
                }
            }
    }

    @IBAction func startNewRoundPressed(_ sender: UIButton) {

        guard let gameCode = gameCode else { return }

        sender.isEnabled = false

        let gameRef = db.collection("games").document(gameCode)
        let group = DispatchGroup()

        group.enter()
        gameRef.collection("submissions").getDocuments { snap, _ in
            snap?.documents.forEach { $0.reference.delete() }
            group.leave()
        }

        group.enter()
        gameRef.collection("votes").getDocuments { snap, _ in
            snap?.documents.forEach { $0.reference.delete() }
            group.leave()
        }
        gameRef.collection("players").getDocuments { snap, _ in
            for doc in snap?.documents ?? [] {
                doc.reference.updateData([
                    "didFinishVoting": false
                ])
            }
        }
        group.notify(queue: .main) {

            let prompt = GameState.getNextPrompt()

            gameRef.setData([
                "gameState": "inProgress",
                "currentPrompt": prompt,
                "updatedAt": Timestamp()
            ], merge: true)

            sender.isEnabled = true
        }
    }

    func routeBackToPromptScreen() {

        if let vcs = navigationController?.viewControllers {
            for vc in vcs {
                if vc is CALViewController {
                    navigationController?.popToViewController(vc, animated: true)
                    return
                }
            }
        }
    }
}
