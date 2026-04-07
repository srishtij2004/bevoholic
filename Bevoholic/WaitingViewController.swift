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
    
    @IBOutlet weak var startVotingButton: UIButton!
    private let db = Firestore.firestore()
    private var gameListener: ListenerRegistration?
    private var hasNavigated = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        startVotingButton.isHidden = true
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
                print("Error: \(error.localizedDescription)")
                return
            }
            
            guard
                !self.hasNavigated,
                let currentUserId = Auth.auth().currentUser?.uid,
                let gameData = snapshot?.data(),
                let gameState = gameData["gameState"] as? String
            else { return }
            
            if gameState == "voting" {
                self.hasNavigated = true
                self.showVotingScreen()
                return
            }
            
            if gameState == "submitting" {
                // Check for Host button
                if let playerOrder = gameData["playerOrder"] as? [String], playerOrder.first == currentUserId {
                    self.startVotingButton.isHidden = false
                }
                return // Exit early so the turn-based logic below doesn't fire
            }
            
            if gameState == "finished" {
                self.hasNavigated = true
                self.showLeaderboardScreen()
                return
            }
            
            if let currentPlayerId = gameData["currentPlayerId"] as? String, currentPlayerId == currentUserId {
                self.hasNavigated = true
                self.showDareScreen()
            }
        }
    }
    @IBAction func startVotingPressed(_ sender: UIButton) {
        guard let gameCode = gameCode else { return }

        db.collection("games").document(gameCode).updateData([
            "gameState": "voting"
        ]) { error in
            if let error = error {
                print("Error starting vote: \(error.localizedDescription)")
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
    func showVotingScreen() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let votingVC = storyboard.instantiateViewController(withIdentifier: "CardsAgainstLonghornsVotingViewController") as? CardsAgainstLonghornsVotingViewController else { return }
        votingVC.gameCode = gameCode
        navigationController?.pushViewController(votingVC, animated: true)
    }
}
