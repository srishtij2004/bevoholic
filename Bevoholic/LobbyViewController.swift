//
//  LobbyViewController.swift
//  Bevoholic
//
//  Created by Poluchalla, Srilekha on 3/8/26.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class LobbyViewController: HeaderViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!

    @IBOutlet weak var gameCodeLabel: UILabel!
    
    @IBOutlet weak var gameLabel: UILabel!
    
    var gameCode: String!
    let db = Firestore.firestore()
    var playersListener: ListenerRegistration?
    var gameListener: ListenerRegistration?
    var players: [(id: String, name: String)] = []
    var hasRoutedToGameScreen = false

    // Store usernames for table view
    var usernames: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        gameCodeLabel.text = "Code: \(gameCode ?? "")"
        tableView.rowHeight = 80
        fetchPlayers()
        observeGameState()
        tableView.layer.cornerRadius = 20
        tableView.clipsToBounds = true
    }


    func fetchPlayers() {
        guard let gameCode = gameCode else { return }

        // Listen to the players subcollection
        playersListener = db.collection("games")
            .document(gameCode)
            .collection("players")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching players: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else { return }

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
        guard let gameCode = gameCode else { return }

        gameListener = db.collection("games")
            .document(gameCode)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("Error observing game state: \(error.localizedDescription)")
                    return
                }

                guard
                    let data = snapshot?.data(),
                    let gameState = data["gameState"] as? String,
                    gameState == "inProgress"
                else {
                    return
                }

                self.routeToCurrentTurn(using: data)
            }
    }

    func routeToCurrentTurn(using gameData: [String: Any]) {
        guard
            !hasRoutedToGameScreen,
            let currentUserId = Auth.auth().currentUser?.uid,
            let currentPlayerId = gameData["currentPlayerId"] as? String
        else {
            return
        }

        hasRoutedToGameScreen = true

        if currentUserId == currentPlayerId {
            showDareScreen()
        } else {
            showWaitingScreen()
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

    func showWaitingScreen() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let waitingViewController = storyboard.instantiateViewController(withIdentifier: "WaitingViewController") as? WaitingViewController else {
            return
        }

        waitingViewController.gameCode = gameCode
        waitingViewController.navigationItem.hidesBackButton = true
        navigationController?.pushViewController(waitingViewController, animated: true)
    }

    @IBAction func startButtonPressed(_ sender: Any) {
        guard let gameCode = gameCode else { return }
        guard !players.isEmpty else { return }

        db.collection("games").document(gameCode).getDocument { snapshot, error in
            if let error = error {
                print("Error loading game for start: \(error.localizedDescription)")
                return
            }

            let gameData = snapshot?.data() ?? [:]
            let location = gameData["location"] as? String ?? "On Campus"
            let firstPlayer = self.players[0]
            let currentDare = DrinkOrDareGameManager.shared.randomDare(for: location)

            self.db.collection("games").document(gameCode).setData([
                "gameState": "inProgress",
                "playerOrder": self.players.map { $0.id },
                "currentTurnIndex": 0,
                "currentPlayerId": firstPlayer.id,
                "currentPlayerName": firstPlayer.name,
                "currentDare": currentDare,
                "turnsPlayed": 0,
                "totalRounds": DrinkOrDareGameManager.shared.totalRounds
            ], merge: true) { error in
                if let error = error {
                    print("Error starting game: \(error.localizedDescription)")
                }
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

        //get selected avatar from firestore
        db.collection("users").document(playerId).getDocument { snapshot, error in
            if let data = snapshot?.data(), let avatarName = data["selectedAvatar"] as? String {
                DispatchQueue.main.async {
                    cell.avatarImageView.image = UIImage(named: avatarName)
                }
            } else {
                DispatchQueue.main.async {
                    cell.avatarImageView.image = UIImage(named: "longhornHead")
                    cell.avatarImageView.backgroundColor = UIColor(red: 250/255, green: 193/255, blue: 145/255, alpha: 1.0)

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
