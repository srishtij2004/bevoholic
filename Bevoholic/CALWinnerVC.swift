//
//  CALWinnerVC.swift
//  Bevoholic
//
//  Created by Poluchalla, Srilekha on 4/1/26.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class CALWinnerVC: HeaderViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var newRoundButton: UIButton!
    
    var gameCode: String!
    private let db = Firestore.firestore()
    private var stateListener: ListenerRegistration?
    private var hasRoutedToPrompt = false
    
    var winners: [(username: String, avatar: String)] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        
        newRoundButton.isHidden = false
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 200
        
        calculateWinners()
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
    
    //in case of a tie, display all winners
    func calculateWinners() {
        guard let gameCode = gameCode else { return }
        
        db.collection("games").document(gameCode).collection("votes").getDocuments { snapshot, error in
            guard let documents = snapshot?.documents, !documents.isEmpty else { return }
            
            var maxVotes = 0
            for doc in documents {
                let votes = doc.data()["votes"] as? Int ?? 0
                if votes > maxVotes {
                    maxVotes = votes
                }
            }
            
            var winningUserIds: [String] = []
            for doc in documents {
                let votes = doc.data()["votes"] as? Int ?? 0
                if votes == maxVotes {
                    winningUserIds.append(doc.documentID)
                }
            }
            
            self.fetchWinnerDetails(userIds: winningUserIds)
        }
    }
    
    //get from AvatarCell class
    func fetchWinnerDetails(userIds: [String]) {
        let group = DispatchGroup()
        var fetchedWinners: [(username: String, avatar: String)] = []
        
        for userId in userIds {
            group.enter()
            var username = "Player"
            var avatar = "longhornHead"
            
            db.collection("games").document(self.gameCode).collection("players").document(userId).getDocument { playerSnap, _ in
                if let playerData = playerSnap?.data() {
                    if let name = playerData["name"] as? String {
                        username = name
                    } else if let name = playerData["username"] as? String {
                        username = name
                    }
                }
                
                self.db.collection("users").document(userId).getDocument { userSnap, _ in
                    if let userData = userSnap?.data() {
                        avatar = userData["selectedAvatar"] as? String ?? "longhornHead"
                        if username == "Player" {
                            if let name = userData["name"] as? String {
                                username = name
                            } else if let name = userData["username"] as? String {
                                username = name
                            }
                        }
                    }
                    
                    fetchedWinners.append((username: username, avatar: avatar))
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            self.winners = fetchedWinners
            self.tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return winners.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WinnerCell", for: indexPath) as! WinnerCell
        let winner = winners[indexPath.row]
        
        cell.usernameLabel.text = winner.username
        cell.avatarImageView.image = UIImage(named: winner.avatar)
        
        return cell
    }
    
    func listenForNewRound() {
        guard let gameCode = gameCode else { return }
        
        stateListener = db.collection("games").document(gameCode).addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            if let error = error { return }
            
            guard
                !self.hasRoutedToPrompt,
                let data = snapshot?.data(),
                let gameState = data["gameState"] as? String,
                gameState == "inProgress"
            else { return }
            
            self.hasRoutedToPrompt = true
            self.routeBackToPromptScreen()
        }
    }
    
    @IBAction func startNewRoundPressed(_ sender: UIButton) {
        guard let gameCode = gameCode else { return }
        
        sender.isEnabled = false
        
        let gameRef = self.db.collection("games").document(gameCode)
        let group = DispatchGroup()
        
        group.enter()
        gameRef.collection("submissions").getDocuments { snap, _ in
            for doc in snap?.documents ?? [] {
                doc.reference.delete()
            }
            group.leave()
        }
        
        group.enter()
        gameRef.collection("votes").getDocuments { snap, _ in
            for doc in snap?.documents ?? [] {
                doc.reference.delete()
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            let selectedPrompt = GameState.getNextPrompt()
            gameRef.setData([
                "gameState": "inProgress",
                "currentPrompt": selectedPrompt,
                "updatedAt": Timestamp()
            ], merge: true) { _ in
                DispatchQueue.main.async {
                    sender.isEnabled = true
                }
            }
        }
    }
    
    func routeBackToPromptScreen() {
        if let viewControllers = self.navigationController?.viewControllers {
            for vc in viewControllers {
                if vc is CALViewController {
                    self.navigationController?.popToViewController(vc, animated: true)
                    return
                }
            }
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let promptVC = storyboard.instantiateViewController(withIdentifier: "CALViewController") as? CALViewController {
            promptVC.gameCode = self.gameCode
            self.navigationController?.pushViewController(promptVC, animated: true)
        }
    }
}
