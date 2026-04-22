//copy of drink or dare lobby code

import UIKit
import FirebaseAuth
import FirebaseFirestore

class CALLobbyVC: HeaderViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var gameCodeLabel: UILabel!
    @IBOutlet weak var gameLabel: UILabel!

    var gameCode: String!
    let db = Firestore.firestore()
    var playersListener: ListenerRegistration?
    var gameListener: ListenerRegistration?
    var players: [(id: String, name: String)] = []
    var usernames: [String] = []
    var hasRoutedToGameScreen = false

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 80
        tableView.layer.cornerRadius = 20
        tableView.clipsToBounds = true
        gameLabel.text = "Cards Against Longhorns"
        gameCodeLabel.text = "Code: \(gameCode ?? "")"
        fetchPlayers()
        observeGameState()
    }

    func fetchPlayers() {
        guard let gameCode = gameCode else {
            return
        }
        
        playersListener = db.collection("games")
            .document(gameCode)
            .collection("players")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    return
                }

                guard let documents = snapshot?.documents else {
                    return
                }
                
                let sortedDocuments = documents.sorted {
                    let lhsTimestamp = ($0.data()["joinedAt"] as? Timestamp)?.dateValue() ?? .distantPast
                    let rhsTimestamp = ($1.data()["joinedAt"] as? Timestamp)?.dateValue() ?? .distantPast
                    return lhsTimestamp < rhsTimestamp
                }

                self.players = sortedDocuments.map { doc in
                    let data = doc.data()
                    let name = data["name"] as? String ?? "Player"
                    return (id: doc.documentID, name: name)
                }
                
                self.usernames = self.players.map { $0.name }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
    }

    func observeGameState() {
        guard let gameCode = gameCode else {
            return
        }
        
        gameListener = db.collection("games")
            .document(gameCode)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else {
                    return
                }
                
                if let error = error {
                    return
                }

                guard
                    let data = snapshot?.data(),
                    let gameState = data["gameState"] as? String,
                    gameState == "inProgress"
                else {
                    return
                }

                self.routeToPromptScreen()
            }
    }

    func routeToPromptScreen() {
        guard !hasRoutedToGameScreen else {
            return
        }
        
        hasRoutedToGameScreen = true
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        guard let promptVC = storyboard.instantiateViewController(withIdentifier: "CALViewController") as? CALViewController else {
            return
        }
        
        promptVC.gameCode = gameCode
        navigationController?.pushViewController(promptVC, animated: true)
    }

    @IBAction func startButtonPressed(_ sender: Any) {
        guard let gameCode = gameCode, !players.isEmpty else {
            return
        }
            
        let firstPlayer = players[0]
        let selectedPrompt = GameState.getNextPrompt()
            
        db.collection("games").document(gameCode).setData([
            "gameState": "inProgress",
            "currentPrompt": selectedPrompt,
            "playerOrder": players.map { $0.id },
            "currentTurnIndex": 0,
            "currentPlayerId": firstPlayer.id,
            "currentPlayerName": firstPlayer.name,
            "turnsPlayed": 0
        ], merge: true) { error in
            if let error = error {
                return
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usernames.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlayerCell", for: indexPath) as! PlayerCell
        let username = usernames[indexPath.row]
        let playerId = players[indexPath.row].id
        cell.usernameLabel.text = username

        db.collection("users").document(playerId).getDocument { snapshot, _ in
            if let data = snapshot?.data(), let avatarName = data["selectedAvatar"] as? String {
                DispatchQueue.main.async {
                    cell.avatarImageView.image = UIImage(named: avatarName)
                }
            } else {
                DispatchQueue.main.async {
                    cell.avatarImageView.image = UIImage(named: "longhornHead")
                }
            }
        }

        return cell
    }

    deinit {
        playersListener?.remove()
        gameListener?.remove()
    }
}
