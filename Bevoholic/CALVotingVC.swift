//
//  CALVotingVC.swift
//  Bevoholic
//
//  Created by Likhita Velmurugan on 3/9/26.

import UIKit
import FirebaseAuth
import FirebaseFirestore

class CALVotingVC: HeaderViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var submitVoteButton: UIButton!
    @IBOutlet weak var voteSubmittedLabel: UILabel!
    
    var gameCode: String!
    private let db = Firestore.firestore()
    private var gameStateListener: ListenerRegistration?
    private var hasRouted = false
    
    var submissions: [(userId: String, image: UIImage)] = []
    var selectedUserId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        
        voteSubmittedLabel.isHidden = true
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 300
        
        loadSubmissions()
        listenForResults()
    }
    
    func loadSubmissions() {
        guard let gameCode = gameCode else {
            return
        }
        
        db.collection("games").document(gameCode).collection("submissions").getDocuments { snapshot, error in
            if let error = error {
                return
            }
            
            guard let documents = snapshot?.documents else {
                return
            }

            self.submissions = []
            
            for doc in documents {
                let data = doc.data()
                
                if let base64String = data["image"] as? String {
                    if let imageData = Data(base64Encoded: base64String) {
                        if let realImage = UIImage(data: imageData) {
                            self.submissions.append((userId: doc.documentID, image: realImage))
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return submissions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlayerImageTableViewCell", for: indexPath) as! PlayerImageTableViewCell
        
        let submission = submissions[indexPath.row]
        cell.playerImageView.image = submission.image
        
        if submission.userId == selectedUserId {
            cell.contentView.layer.borderWidth = 4
            cell.contentView.layer.borderColor = UIColor.systemGreen.cgColor
        }
        else {
            cell.contentView.layer.borderWidth = 0
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if voteSubmittedLabel.isHidden == false {
            return
        }
        
        selectedUserId = submissions[indexPath.row].userId
        tableView.reloadData()
    }
    
    @IBAction func submitVotePressed(_ sender: UIButton) {
        guard let selected = selectedUserId, let gameCode = gameCode else {
            return
        }
        
        submitVoteButton.isHidden = true
        voteSubmittedLabel.isHidden = false
        
        let gameRef = db.collection("games").document(gameCode)
        let voteDocRef = gameRef.collection("votes").document(selected)
        
        voteDocRef.getDocument { document, error in
            var currentVotes = 0
            
            if let data = document?.data(), let votes = data["votes"] as? Int {
                currentVotes = votes
            }
            
            let newVoteTotal = currentVotes + 1
            
            voteDocRef.setData(["votes": newVoteTotal], merge: true) { error in
                if let error = error {
                    self.submitVoteButton.isHidden = false
                    self.voteSubmittedLabel.isHidden = true
                    return
                }
                
                gameRef.getDocument { document, error in
                    if let document = document, let data = document.data() {
                        let totalPlayers = (data["playerOrder"] as? [String])?.count ?? 0
                        
                        gameRef.collection("votes").getDocuments { snapshot, error in
                            var totalVotesCast = 0
                            
                            if let documents = snapshot?.documents {
                                for doc in documents {
                                    let votes = doc.data()["votes"] as? Int ?? 0
                                    totalVotesCast += votes
                                }
                            }
                            
                            if totalVotesCast >= totalPlayers && totalPlayers > 0 {
                                gameRef.updateData(["gameState": "results"])
                            }
                        }
                    }
                }
            }
        }
    }
    
    func listenForResults() {
        guard let gameCode = gameCode else {
            return
        }
        
        gameStateListener = db.collection("games").document(gameCode).addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else {
                return
            }
            
            if let data = snapshot?.data(), let gameState = data["gameState"] as? String {
                if gameState == "results" {
                    self.routeToWinnerScreen()
                }
            }
        }
    }
    
    func routeToWinnerScreen() {
        guard !hasRouted else {
            return
        }
        
        hasRouted = true
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let winnerVC = storyboard.instantiateViewController(withIdentifier: "CALWinnerVC") as? CALWinnerVC else {
            return
        }
        
        winnerVC.gameCode = self.gameCode
        self.navigationController?.pushViewController(winnerVC, animated: true)
    }
    
    deinit {
        gameStateListener?.remove()
    }
}
