import UIKit
import FirebaseAuth
import FirebaseFirestore

class ImposterGameViewController: HeaderViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var roundLabel: UILabel!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var roleLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!

    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var votingTableView: UITableView!

    var gameCode: String!

    private let db = Firestore.firestore()
    private var gameListener: ListenerRegistration?
    private var playersListener: ListenerRegistration?

    private var gameData: [String: Any] = [:]
    private var allPlayers: [(id: String, name: String)] = []
    private var voteCandidates: [(id: String, name: String)] = []
    private var selectedVoteTargetId: String?
    private var hasShownEndAlert = false

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true

        votingTableView.delegate = self
        votingTableView.dataSource = self

        doneButton.layer.cornerRadius = 12
        doneButton.setTitle("I'm Ready", for: .normal)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hasShownEndAlert = false
        observePlayers()
        observeGame()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        gameListener?.remove()
        playersListener?.remove()
        gameListener = nil
        playersListener = nil
    }

    func observePlayers() {
        guard let gameCode = gameCode else { return }

        playersListener = db.collection("games")
            .document(gameCode)
            .collection("players")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("Error observing imposter players: \(error.localizedDescription)")
                    return
                }

                guard let docs = snapshot?.documents else { return }
                self.allPlayers = docs.map { doc in
                    let name = doc.data()["name"] as? String ?? "Player"
                    return (id: doc.documentID, name: name)
                }

                self.refreshVoteCandidates()
                self.votingTableView.reloadData()
            }
    }

    func observeGame() {
        guard let gameCode = gameCode else { return }

        gameListener = db.collection("games").document(gameCode).addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                print("Error observing imposter game state: \(error.localizedDescription)")
                return
            }

            guard let data = snapshot?.data() else { return }
            self.gameData = data
            self.updateUI(with: data)
        }
    }

    func updateUI(with data: [String: Any]) {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let gameState = data["gameState"] as? String ?? "lobby"
        let phase = data["imposterPhase"] as? String ?? "clue"
        let round = data["roundNumber"] as? Int ?? 1

        let imposterWord = data["imposterWord"] as? String ?? "-"
        let imposterId = data["imposterId"] as? String ?? ""
        let currentPlayerId = data["currentPlayerId"] as? String

        let activePlayers = data["activePlayerIds"] as? [String] ?? []
        let isActive = activePlayers.contains(userId)

        let votes = extractVotes(from: data)
        let hasVoted = votes[userId] != nil

        roleLabel.isHidden = false
        roundLabel.text = "Round \(round)"
        categoryLabel.text = "IMPOSTOR"

        roleLabel.text = (userId == imposterId) ? "Imposter" : imposterWord

        if gameState == "finished" {
            doneButton.isHidden = true
            votingTableView.isHidden = true
            statusLabel.text = data["imposterResultMessage"] as? String ?? "Game over"
            roundLabel.text = statusLabel.text?.contains("imposter was voted out") == true ? "IMPOSTOR CAUGHT!" : "IMPOSTOR NOT CAUGHT!"

            if !hasShownEndAlert {
                hasShownEndAlert = true
                showEndGameAlert(message: statusLabel.text ?? "Game over")
            }
            return
        }

        if !isActive {
            doneButton.isHidden = true
            votingTableView.isHidden = true
            statusLabel.text = "You were voted out. Watch the rest of the round."
            return
        }

        if phase == "clue" {
            votingTableView.isHidden = true
            doneButton.setTitle("I'm Ready", for: .normal)

            let isCurrentSpeaker = (currentPlayerId == userId)
            doneButton.isHidden = !isCurrentSpeaker
            doneButton.isEnabled = isCurrentSpeaker

            if isCurrentSpeaker {
                statusLabel.text = (userId == imposterId) ? "Act like you know the word!" : "Describe it without saying it!"
            } else {
                let currentSpeakerName = allPlayers.first(where: { $0.id == currentPlayerId })?.name ?? "Next Player"
                statusLabel.text = "\(currentSpeakerName) is giving a clue."
            }
            return
        }

        if phase == "voting" {
            roleLabel.isHidden = true
            doneButton.isHidden = false
            votingTableView.isHidden = false
            roundLabel.text = "Voting Time"
            refreshVoteCandidates()
            votingTableView.reloadData()

            if hasVoted {
                doneButton.isEnabled = false
                doneButton.setTitle("Voted", for: .normal)
                let votedPlayerName = allPlayers.first(where: { $0.id == votes[userId] })?.name ?? "a player"
                statusLabel.text = "Vote submitted: \(votedPlayerName). Waiting for others..."
            } else {
                doneButton.isEnabled = selectedVoteTargetId != nil
                statusLabel.text = "Vote who you think is the imposter."
                if let selectedId = selectedVoteTargetId,
                   let selectedName = allPlayers.first(where: { $0.id == selectedId })?.name {
                    doneButton.setTitle("Vote for \(selectedName)", for: .normal)
                } else {
                    doneButton.setTitle("Vote", for: .normal)
                }
            }
            return
        }
    }

    func extractVotes(from data: [String: Any]) -> [String: String] {
        let rawVotes = data["imposterVotes"] as? [String: Any] ?? [:]
        var votes: [String: String] = [:]
        for (voter, target) in rawVotes {
            if let targetId = target as? String {
                votes[voter] = targetId
            }
        }
        return votes
    }

    func refreshVoteCandidates() {
        let activePlayers = gameData["activePlayerIds"] as? [String] ?? []
        voteCandidates = allPlayers.filter { activePlayers.contains($0.id) }
    }

    @IBAction func donePressed(_ sender: UIButton) {
        let phase = gameData["imposterPhase"] as? String ?? "clue"
        if phase == "voting" {
            submitVote()
            return
        }
        
        guard
            let gameCode = gameCode,
            let userId = Auth.auth().currentUser?.uid
        else {
            return
        }

        let gameRef = db.collection("games").document(gameCode)

        db.runTransaction({ transaction, errorPointer in
            let snapshot: DocumentSnapshot
            do {
                try snapshot = transaction.getDocument(gameRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            guard let data = snapshot.data() else { return nil }
            let phase = data["imposterPhase"] as? String ?? "clue"
            let currentPlayerId = data["currentPlayerId"] as? String ?? ""
            if phase != "clue" || currentPlayerId != userId {
                return nil
            }

            let active = data["activePlayerIds"] as? [String] ?? []
            let speakerOrder = data["speakerOrder"] as? [String] ?? active
            var spoken = data["roundSpokenPlayerIds"] as? [String] ?? []

            if !spoken.contains(userId) {
                spoken.append(userId)
            }

            let allActiveSpoken = Set(active).isSubset(of: Set(spoken))

            if allActiveSpoken {
                transaction.setData([
                    "imposterPhase": "voting",
                    "imposterVotes": [:],
                    "roundSpokenPlayerIds": spoken,
                    "updatedAt": Timestamp()
                ], forDocument: gameRef, merge: true)
                return nil
            }

            let nextPlayerId = speakerOrder.first { id in
                active.contains(id) && !spoken.contains(id)
            } ?? active.first ?? ""

            transaction.setData([
                "currentPlayerId": nextPlayerId,
                "roundSpokenPlayerIds": spoken,
                "updatedAt": Timestamp()
            ], forDocument: gameRef, merge: true)

            return nil
        }) { _, error in
            if let error = error {
                print("Error marking clue done: \(error.localizedDescription)")
            }
        }
    }

//    @IBAction func votePressed(_ sender: UIButton) {
//        submitVote()
//    }

    func submitVote() {
        guard
            let gameCode = gameCode,
            let voterId = Auth.auth().currentUser?.uid,
            let targetId = selectedVoteTargetId
        else {
            return
        }

        let gameRef = db.collection("games").document(gameCode)

        db.runTransaction({ transaction, errorPointer in
            let snapshot: DocumentSnapshot
            do {
                try snapshot = transaction.getDocument(gameRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            guard let data = snapshot.data() else { return nil }
            let gameState = data["gameState"] as? String ?? ""
            let phase = data["imposterPhase"] as? String ?? ""
            if gameState != "inProgress" || phase != "voting" {
                return nil
            }

            let active = data["activePlayerIds"] as? [String] ?? []
            if !active.contains(voterId) || !active.contains(targetId) {
                return nil
            }

            var votes = self.extractVotes(from: data)
            if votes[voterId] != nil {
                return nil
            }

            votes[voterId] = targetId

            if votes.count < active.count {
                transaction.setData([
                    "imposterVotes": votes,
                    "updatedAt": Timestamp()
                ], forDocument: gameRef, merge: true)
                return nil
            }

            let voteCounts = Dictionary(grouping: votes.values, by: { $0 }).mapValues { $0.count }
            let maxVotes = voteCounts.values.max() ?? 0
            let topTargets = voteCounts.filter { $0.value == maxVotes }.map { $0.key }

            let imposterId = data["imposterId"] as? String ?? ""
            let oldEliminated = data["eliminatedPlayerIds"] as? [String] ?? []
            var updatedEliminated = oldEliminated
            var updatedActive = active

            if topTargets.count > 1 {
                let nextOrder = updatedActive.shuffled()
                let nextContent = ImposterGameManager.shared.randomCategoryAndWord()
                let nextRound = (data["roundNumber"] as? Int ?? 1) + 1

                transaction.setData([
                    "imposterPhase": "clue",
                    "imposterVotes": [:],
                    "speakerOrder": nextOrder,
                    "currentPlayerId": nextOrder.first ?? "",
                    "roundSpokenPlayerIds": [],
                    "roundNumber": nextRound,
                    "imposterCategory": nextContent.category,
                    "imposterWord": nextContent.word,
                    "updatedAt": Timestamp()
                ], forDocument: gameRef, merge: true)
                return nil
            }

            let votedOutId = topTargets[0]
            if votedOutId == imposterId {
                transaction.setData([
                    "gameState": "finished",
                    "imposterPhase": "finished",
                    "imposterVotes": votes,
                    "imposterResultMessage": "Game Over. The imposter was voted out.",
                    "updatedAt": Timestamp()
                ], forDocument: gameRef, merge: true)
                return nil
            }

            if !updatedEliminated.contains(votedOutId) {
                updatedEliminated.append(votedOutId)
            }
            updatedActive.removeAll { $0 == votedOutId }

            if updatedActive.count == 2 && updatedActive.contains(imposterId) {
                transaction.setData([
                    "gameState": "finished",
                    "imposterPhase": "finished",
                    "imposterVotes": votes,
                    "activePlayerIds": updatedActive,
                    "eliminatedPlayerIds": updatedEliminated,
                    "imposterResultMessage": "Imposter wins! Final two reached.",
                    "updatedAt": Timestamp()
                ], forDocument: gameRef, merge: true)
                return nil
            }

            let nextOrder = updatedActive.shuffled()
            let nextContent = ImposterGameManager.shared.randomCategoryAndWord()
            let nextRound = (data["roundNumber"] as? Int ?? 1) + 1

            transaction.setData([
                "imposterPhase": "clue",
                "imposterVotes": [:],
                "activePlayerIds": updatedActive,
                "eliminatedPlayerIds": updatedEliminated,
                "speakerOrder": nextOrder,
                "currentPlayerId": nextOrder.first ?? "",
                "roundSpokenPlayerIds": [],
                "roundNumber": nextRound,
                "imposterCategory": nextContent.category,
                "imposterWord": nextContent.word,
                "updatedAt": Timestamp()
            ], forDocument: gameRef, merge: true)

            return nil
        }) { _, error in
            if let error = error {
                print("Error submitting imposter vote: \(error.localizedDescription)")
            } else {
                self.selectedVoteTargetId = nil
                self.doneButton.isEnabled = false
                self.doneButton.setTitle("Voted", for: .normal)
            }
        }
    }

    func showEndGameAlert(message: String) {
        let alert = UIAlertController(title: "Game Over", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Back to Menu", style: .default) { _ in
            self.navigationController?.popToRootViewController(animated: true)
        })
        present(alert, animated: true)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        voteCandidates.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ImposterVoteCell", for: indexPath)
        let candidate = voteCandidates[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = candidate.name
        cell.contentConfiguration = content

        if candidate.id == selectedVoteTargetId {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedPlayer = voteCandidates[indexPath.row]
        selectedVoteTargetId = selectedPlayer.id
        doneButton.isEnabled = true
        doneButton.setTitle("Vote for \(selectedPlayer.name)", for: .normal)
        tableView.reloadData()
    }
}
