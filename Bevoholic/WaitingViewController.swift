//
//  WaitingViewController.swift
//  Bevoholic
//
//  Created by Srishti Jain on 3/9/26.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class WaitingViewController: HeaderViewController {

    var gameCode: String!

    private let db = Firestore.firestore()
    private var gameListener: ListenerRegistration?
    private var hasNavigated = false

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hasNavigated = false
        observeGame()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        gameListener?.remove()
        gameListener = nil
    }

    func observeGame() {
        guard let gameCode = gameCode else { return }

        gameListener = db.collection("games").document(gameCode).addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                print("Error observing waiting state: \(error.localizedDescription)")
                return
            }

            guard
                !self.hasNavigated,
                let currentUserId = Auth.auth().currentUser?.uid,
                let gameData = snapshot?.data(),
                let gameState = gameData["gameState"] as? String
            else {
                return
            }

            if gameState == "finished" {
                self.hasNavigated = true
                self.showLeaderboardScreen()
                return
            }

            guard let currentPlayerId = gameData["currentPlayerId"] as? String else { return }

            if currentPlayerId == currentUserId {
                self.hasNavigated = true
                self.showDareScreen()
            }
        }
    }

    func showDareScreen() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let dareViewController = storyboard.instantiateViewController(withIdentifier: "DareScreenViewController") as? DareScreenViewController else {
            return
        }

        dareViewController.gameCode = gameCode
        dareViewController.navigationItem.hidesBackButton = true
        navigationController?.pushViewController(dareViewController, animated: true)
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
