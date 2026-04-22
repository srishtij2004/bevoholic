//
//CALVotingVC.swift
//Bevoholic
//
//Created by Likhita Velmurugan on 3/9/26.

import UIKit
import FirebaseAuth
import FirebaseFirestore

class CALVotingVC: HeaderViewController {

    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var voteSubmittedLabel: UILabel!

    var gameCode: String!
    let db = Firestore.firestore()

    var submissions: [(userId: String, image: UIImage)] = []
    var currentIndex = 0

    private var gameStateListener: ListenerRegistration?
    private var hasRouted = false

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.hidesBackButton = true
        voteSubmittedLabel.isHidden = true
        cardView.layer.cornerRadius = 20
        cardView.clipsToBounds = true
        setupCard()
        loadSubmissions()
        listenForResults()
    }

    func setupCard() {
        cardView.layer.cornerRadius = 20
        cardView.clipsToBounds = true

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        cardView.addGestureRecognizer(pan)
    }

    func loadSubmissions() {
        db.collection("games").document(gameCode).collection("submissions").getDocuments { snapshot, error in

            guard let docs = snapshot?.documents else { return }

            self.submissions.removeAll()

            for doc in docs {
                let data = doc.data()

                if let base64 = data["image"] as? String,
                   let imageData = Data(base64Encoded: base64),
                   let image = UIImage(data: imageData) {

                    self.submissions.append((doc.documentID, image))
                }
            }

            DispatchQueue.main.async {
                self.showCurrentCard()
            }
        }
    }

    func showCurrentCard() {
        if currentIndex >= submissions.count {
            finishedVoting()
            return
        }

        imageView.image = submissions[currentIndex].image
        cardView.transform = .identity
        cardView.center = view.center
    }

    @objc func handleSwipe(_ gesture: UIPanGestureRecognizer) {

        let translation = gesture.translation(in: view)

        switch gesture.state {

        case .changed:
            cardView.center = CGPoint(
                x: view.center.x + translation.x,
                y: view.center.y + translation.y
            )

            cardView.transform = CGAffineTransform(rotationAngle: translation.x / 500)

        case .ended:

            if translation.x > 120 {
                swipeRight()
            }
            else if translation.x < -120 {
                swipeLeft()
            }
            else {
                UIView.animate(withDuration: 0.2) {
                    self.cardView.center = self.view.center
                    self.cardView.transform = .identity
                }
            }

        default:
            break
        }
    }

    func swipeRight() {
        let votedUser = submissions[currentIndex].userId

        castVote(for: votedUser)

        UIView.animate(withDuration: 0.25, animations: {
            self.cardView.center.x += 500
        }) { _ in
            self.currentIndex += 1
            self.showCurrentCard()
        }
    }

    func swipeLeft() {
        UIView.animate(withDuration: 0.25, animations: {
            self.cardView.center.x -= 500
        }) { _ in
            self.currentIndex += 1
            self.showCurrentCard()
        }
    }

    func castVote(for userId: String) {

        let voteRef = db.collection("games")
            .document(gameCode)
            .collection("votes")
            .document(userId)

        voteRef.getDocument { doc, error in

            let currentVotes = doc?.data()?["votes"] as? Int ?? 0

            voteRef.setData([
                "votes": currentVotes + 1
            ], merge: true)
        }
    }

    func finishedVoting() {
        voteSubmittedLabel.isHidden = false
        cardView.isHidden = true
        guard let uid = Auth.auth().currentUser?.uid else { return }

            let playerRef = db.collection("games")
                .document(gameCode)
                .collection("players")
                .document(uid)

            playerRef.setData([
                "didFinishVoting": true
            ], merge: true)

            checkAllPlayersFinished()
    }

    func checkAllPlayersFinished() {

        let playersRef = db.collection("games")
            .document(gameCode)
            .collection("players")

        playersRef.getDocuments { snapshot, error in

            guard let docs = snapshot?.documents else { return }

            let totalPlayers = docs.count

            let finishedPlayers = docs.filter {
                ($0.data()["didFinishVoting"] as? Bool) == true
            }.count

            if totalPlayers > 0 && finishedPlayers == totalPlayers {

                self.db.collection("games")
                    .document(self.gameCode)
                    .updateData([
                        "gameState": "results"
                    ])
            }
        }
    }

    func listenForResults() {
        db.collection("games").document(gameCode)
            .addSnapshotListener { snapshot, error in

                let state = snapshot?.data()?["gameState"] as? String ?? ""

                if state == "results" {
                    self.routeToWinnerScreen()
                }
            }
    }

    func routeToWinnerScreen() {
        guard !hasRouted else { return }
        hasRouted = true

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CALWinnerVC") as! CALWinnerVC

        vc.gameCode = gameCode
        navigationController?.pushViewController(vc, animated: true)
    }
}
