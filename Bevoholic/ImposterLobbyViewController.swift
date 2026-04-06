import UIKit
import FirebaseAuth
import FirebaseFirestore

class ImposterLobbyViewController: HeaderViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var gameCodeLabel: UILabel!

    var gameCode: String!
    private let db = Firestore.firestore()
    private var playersListener: ListenerRegistration?
    private var gameListener: ListenerRegistration?
    private var hasRoutedToGame = false
    private var players: [(id: String, name: String)] = []
    private var usernames: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true

        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 60

        gameCodeLabel.text = "Code: \(gameCode ?? "")"

        observePlayers()
        observeGameState()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        playersListener?.remove()
        gameListener?.remove()
    }

    func observePlayers() {
        guard let gameCode = gameCode else { return }

        playersListener = db.collection("games")
            .document(gameCode)
            .collection("players")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("Error loading imposter players: \(error.localizedDescription)")
                    return
                }

                guard let docs = snapshot?.documents else { return }

                let sorted = docs.sorted {
                    let lhs = ($0.data()["joinedAt"] as? Timestamp)?.dateValue() ?? .distantPast
                    let rhs = ($1.data()["joinedAt"] as? Timestamp)?.dateValue() ?? .distantPast
                    return lhs < rhs
                }

                self.players = sorted.map { doc in
                    let name = doc.data()["name"] as? String ?? "Player"
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

        gameListener = db.collection("games").document(gameCode).addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            if let error = error { return }

            guard
                !self.hasRoutedToGame,
                let data = snapshot?.data(),
                let gameState = data["gameState"] as? String,
                gameState == "inProgress"
            else { return }

            self.hasRoutedToGame = true
            self.showImposterGameScreen()
        }
    }

    @IBAction func startButtonPressed(_ sender: Any) {
        guard let gameCode = gameCode else { return }
    
        guard players.count >= 3 else {
            showAlert(title: "Need More Players", message: "Imposter needs at least 3 players to start.")
            return
        }

        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        db.collection("games").document(gameCode).getDocument { snapshot, error in
            let hostId = snapshot?.data()?["hostId"] as? String
            guard hostId == currentUserId else {
                self.showAlert(title: "Host Only", message: "Only the host can start the game.")
                return
            }

            let activePlayerIds = self.players.map { $0.id }
            let imposterId = activePlayerIds.randomElement() ?? activePlayerIds[0]
            let speakerOrder = activePlayerIds.shuffled()
            let randomContent = ImposterGameManager.shared.randomCategoryAndWord()

            self.db.collection("games").document(gameCode).setData([
                "gameState": "inProgress",
                "imposterPhase": "clue",
                "imposterCategory": randomContent.category,
                "imposterWord": randomContent.word,
                "imposterId": imposterId,
                "activePlayerIds": activePlayerIds,
                "eliminatedPlayerIds": [],
                "speakerOrder": speakerOrder,
                "currentPlayerId": speakerOrder[0],
                "roundNumber": 1,
                "updatedAt": Timestamp()
            ], merge: true)
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

    func showImposterGameScreen() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "ImposterGameViewController") as? ImposterGameViewController {
            vc.gameCode = gameCode
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
