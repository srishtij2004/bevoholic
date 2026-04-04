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

                self.tableView.reloadData()
            }
    }

    func observeGameState() {
        guard let gameCode = gameCode else { return }

        gameListener = db.collection("games").document(gameCode).addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                print("Error observing imposter game: \(error.localizedDescription)")
                return
            }

            guard
                !self.hasRoutedToGame,
                let data = snapshot?.data(),
                let gameState = data["gameState"] as? String,
                gameState == "inProgress"
            else {
                return
            }

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

        let gameRef = db.collection("games").document(gameCode)

        gameRef.getDocument { snapshot, error in
            if let error = error {
                print("Error loading imposter game start data: \(error.localizedDescription)")
                return
            }

            let hostId = snapshot?.data()?["hostId"] as? String
            guard hostId == currentUserId else {
                self.showAlert(title: "Host Only", message: "Only the host can start the game.")
                return
            }

            let activePlayerIds = self.players.map { $0.id }
            let imposterId = activePlayerIds.randomElement() ?? activePlayerIds[0]
            let speakerOrder = activePlayerIds.shuffled()

            let randomContent = ImposterGameManager.shared.randomCategoryAndWord()

            gameRef.setData([
                "gameType": "Imposter",
                "gameState": "inProgress",
                "imposterPhase": "clue",
                "imposterCategory": randomContent.category,
                "imposterWord": randomContent.word,
                "imposterId": imposterId,
                "activePlayerIds": activePlayerIds,
                "eliminatedPlayerIds": [],
                "speakerOrder": speakerOrder,
                "roundSpokenPlayerIds": [],
                "currentPlayerId": speakerOrder[0],
                "roundNumber": 1,
                "imposterVotes": [:],
                "updatedAt": Timestamp()
            ], merge: true) { error in
                if let error = error {
                    print("Error starting imposter game: \(error.localizedDescription)")
                }
            }
        }
    }

    func showImposterGameScreen() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let vc = storyboard.instantiateViewController(withIdentifier: "ImposterGameViewController") as? ImposterGameViewController else {
            return
        }

        vc.gameCode = gameCode
        vc.navigationItem.hidesBackButton = true
        navigationController?.pushViewController(vc, animated: true)
    }

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        players.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlayerCell", for: indexPath) as! PlayerCell
        let player = players[indexPath.row]
        cell.usernameLabel.text = player.name
        cell.avatarImageView.image = UIImage(systemName: "person.circle.fill")
        return cell
    }
}
