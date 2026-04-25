import UIKit
import FirebaseAuth
import FirebaseFirestore
import UserNotifications

class ImposterGameViewController: HeaderViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var roundLabel: UILabel!
    @IBOutlet weak var promptLabel: UILabel!
    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var playersTableView: UITableView!

    var gameCode: String!

    private let db = Firestore.firestore()
    private var gameListener: ListenerRegistration?
    private var playersListener: ListenerRegistration?

    private var players: [(id: String, name: String)] = []
    private var gameData: [String: Any] = [:]
    private var selectedVotePlayerId: String?
    private var lastKnownPhase: String?
    private var lifecycleObserverTokens: [NSObjectProtocol] = []
    private var backgroundMonitoringTask: UIBackgroundTaskIdentifier = .invalid

    private var turnReminderNotificationIdentifier: String {
        let code = gameCode ?? "unknown"
        return "imposter-turn-reminder-\(code)"
    }

    private var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }

    private var currentPhase: String {
        gameData["imposterPhase"] as? String ?? "clue"
    }

    private var activePlayerIds: [String] {
        if let ids = gameData["activePlayerIds"] as? [String], !ids.isEmpty {
            return ids
        }
        return players.map { $0.id }
    }

    private var voteCandidates: [(id: String, name: String)] {
        let activeIds = Set(activePlayerIds)
        return players.filter { activeIds.contains($0.id) }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        playersTableView.dataSource = self
        playersTableView.delegate = self
        playersTableView.isHidden = true
        playersTableView.alpha = 1.0
        playersTableView.backgroundColor = .clear

        navigationItem.hidesBackButton = true
        title = ""
        navigationItem.title = ""

        doneButton.layer.cornerRadius = 16
        doneButton.setTitle("Waiting...", for: .normal)

        categoryLabel.text = "IMPOSTER"
        roundLabel.text = "Loading..."
        promptLabel.text = "Setting up game..."
        wordLabel.text = ""
        statusLabel.text = "Please wait"

        requestNotificationPermissionIfNeeded()
        observePlayers()
        observeGame()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startObservingAppLifecycle()
        cancelTurnReminderNotification()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopObservingAppLifecycle()
        endBackgroundTurnMonitoringWindow()
        cancelTurnReminderNotification()

        gameListener?.remove()
        gameListener = nil
        playersListener?.remove()
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
                    print("Error loading imposter players in game screen: \(error.localizedDescription)")
                    return
                }

                guard let docs = snapshot?.documents else { return }

                let sortedDocs = docs.sorted {
                    let lhs = ($0.data()["joinedAt"] as? Timestamp)?.dateValue() ?? .distantPast
                    let rhs = ($1.data()["joinedAt"] as? Timestamp)?.dateValue() ?? .distantPast
                    return lhs < rhs
                }

                self.players = sortedDocs.map { doc in
                    let name = doc.data()["name"] as? String ?? "Player"
                    return (id: doc.documentID, name: name)
                }

                DispatchQueue.main.async {
                    self.playersTableView.reloadData()
                    self.renderUI()
                }
            }
    }

    func observeGame() {
        guard let gameCode = gameCode else { return }

        gameListener = db.collection("games").document(gameCode).addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            if let error = error {
                print("Error observing imposter game: \(error.localizedDescription)")
                return
            }

            guard let data = snapshot?.data() else { return }
            self.gameData = data

            DispatchQueue.main.async {
                self.renderUI()
            }
        }
    }

    func renderUI() {
        guard let currentUserId = currentUserId else { return }

        let phase = currentPhase
        if lastKnownPhase != phase {
            if phase != "voting" {
                selectedVotePlayerId = nil
            }
            lastKnownPhase = phase
        }

        switch phase {
        case "clue":
            renderCluePhase(for: currentUserId)
        case "voting":
            renderVotingPhase(for: currentUserId)
        case "result":
            renderResultPhase(for: currentUserId)
        default:
            categoryLabel.text = "IMPOSTER"
            roundLabel.text = "Loading..."
            promptLabel.text = "Setting up game..."
            wordLabel.text = ""
            statusLabel.text = "Please wait"
            playersTableView.isHidden = true
            doneButton.isEnabled = false
        }
        reconcileTurnReminderSchedulingForCurrentAppState()
    }

    func renderCluePhase(for userId: String) {
        let imposterId = gameData["imposterId"] as? String ?? ""
        let isImposter = userId == imposterId
        let word = gameData["imposterWord"] as? String ?? ""
        let category = gameData["imposterCategory"] as? String ?? "Category"
        let roundNumber = gameData["roundNumber"] as? Int ?? 1

        let readyIds = Set(gameData["clueReadyPlayerIds"] as? [String] ?? [])
        let hasMarkedReady = readyIds.contains(userId)
        let speakerOrder = gameData["speakerOrder"] as? [String] ?? activePlayerIds
        let currentSpeakerId = nextUnreadyPlayerId(
            activeIds: activePlayerIds,
            speakerOrder: speakerOrder,
            readyIds: readyIds
        )
        let isCurrentSpeakersTurn = currentSpeakerId == userId
        let everyoneReady = !activePlayerIds.isEmpty && activePlayerIds.allSatisfy { readyIds.contains($0) }

        categoryLabel.text = "Category: \(category)"
        roundLabel.text = "Round \(roundNumber)"
        promptLabel.text = isImposter ? "You are the imposter" : "Your word is"
        wordLabel.text = isImposter ? "???" : word
        statusLabel.font = UIFont.systemFont(ofSize: 17)
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0

        if everyoneReady {
            statusLabel.text = "Moving to voting..."
        } else if hasMarkedReady {
            statusLabel.text = "Clue submitted. Waiting for everyone else..."
        } else if isCurrentSpeakersTurn {
            statusLabel.text = "It's your turn. Give a clue, then tap I'm Ready."
        } else if let currentSpeakerId = currentSpeakerId {
            statusLabel.text = "Waiting for \(name(for: currentSpeakerId)) to give a clue..."
        } else {
            statusLabel.text = "Describe it without saying it!"
        }

        playersTableView.isHidden = true
        doneButton.isHidden = false
        doneButton.setTitle((hasMarkedReady || !isCurrentSpeakersTurn) ? "Waiting..." : "I'm Ready", for: .normal)
        doneButton.isEnabled = !hasMarkedReady && isCurrentSpeakersTurn
    }

    func renderVotingPhase(for userId: String) {
        let votes = parseVoteMap(gameData["imposterVotes"])
        let hasVoted = votes[userId] != nil
        let submittedVote = votes[userId]

        if let submittedVote = submittedVote {
            selectedVotePlayerId = submittedVote
        }

        categoryLabel.text = "IMPOSTER"
        roundLabel.text = "Voting Time"
        promptLabel.text = "Who is the imposter?"
        wordLabel.text = ""
        statusLabel.font = UIFont.systemFont(ofSize: 17)
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.text = hasVoted ? "Vote submitted. Waiting for everyone else..." : "It's your turn to vote"

        playersTableView.isHidden = false
        playersTableView.reloadData()

        doneButton.isHidden = false
        doneButton.setTitle(hasVoted ? "Waiting..." : "Submit Vote", for: .normal)
        doneButton.isEnabled = !hasVoted
    }

    func renderResultPhase(for userId: String) {
        let imposterId = gameData["imposterId"] as? String ?? ""
        let imposterName = name(for: imposterId)
        let imposterCaught = gameData["imposterCaught"] as? Bool ?? false
        let topSuspectIds = gameData["roundTopSuspectIds"] as? [String] ?? []

        categoryLabel.text = imposterCaught ? "IMPOSTER CAUGHT!" : "IMPOSTER NOT CAUGHT!"
        roundLabel.text = ""
        promptLabel.text = "The imposter was"
        wordLabel.text = imposterName
        statusLabel.font = UIFont.boldSystemFont(ofSize: 18)
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0

        if imposterCaught {
            statusLabel.text = "\(imposterName) was caught!\n\(imposterName) takes a shot!"
        } else if topSuspectIds.count > 1 {
            let tiedNames = topSuspectIds.map { name(for: $0) }.joined(separator: ", ")
            statusLabel.text = "Tie vote: \(tiedNames).\n\(imposterName) escapes.\nEveryone else bottoms up!"
        } else if let votedOutId = topSuspectIds.first {
            let votedOutName = name(for: votedOutId)
            statusLabel.text = "\(votedOutName) was voted out.\n\(imposterName) escapes.\nEveryone else bottoms up!"
        } else {
            statusLabel.text = "\(imposterName) escapes.\nEveryone else bottoms up!"
        }

        playersTableView.isHidden = true
        doneButton.isHidden = false

        if isCurrentUserHost(userId: userId) {
            doneButton.setTitle("Next Round", for: .normal)
            doneButton.isEnabled = true
        } else {
            doneButton.setTitle("Waiting for host...", for: .normal)
            doneButton.isEnabled = false
        }
    }

    func isCurrentUserHost(userId: String) -> Bool {
        let hostId = gameData["hostId"] as? String
        return hostId == userId
    }

    func name(for playerId: String) -> String {
        players.first(where: { $0.id == playerId })?.name ?? "Player"
    }

    func parseVoteMap(_ rawVotes: Any?) -> [String: String] {
        if let typedVotes = rawVotes as? [String: String] {
            return typedVotes
        }

        guard let votes = rawVotes as? [String: Any] else { return [:] }

        var mappedVotes: [String: String] = [:]
        for (voterId, targetAny) in votes {
            if let targetId = targetAny as? String {
                mappedVotes[voterId] = targetId
            }
        }
        return mappedVotes
    }

    func nextUnreadyPlayerId(activeIds: [String], speakerOrder: [String], readyIds: Set<String>) -> String? {
        let activeSet = Set(activeIds)
        let orderedActiveIds = speakerOrder.filter { activeSet.contains($0) }
        let turnOrder = orderedActiveIds.isEmpty ? activeIds : orderedActiveIds
        return turnOrder.first(where: { !readyIds.contains($0) })
    }

    func shouldScheduleTurnReminder() -> Bool {
        guard let currentUserId = currentUserId else { return false }

        switch currentPhase {
        case "clue":
            let readyIds = Set(gameData["clueReadyPlayerIds"] as? [String] ?? [])
            if readyIds.contains(currentUserId) {
                return false
            }

            let speakerOrder = gameData["speakerOrder"] as? [String] ?? activePlayerIds
            let computedCurrentSpeakerId = nextUnreadyPlayerId(
                activeIds: activePlayerIds,
                speakerOrder: speakerOrder,
                readyIds: readyIds
            )
            let currentSpeakerId = (gameData["currentPlayerId"] as? String) ?? computedCurrentSpeakerId
            return currentSpeakerId == currentUserId
        case "voting":
            let votes = parseVoteMap(gameData["imposterVotes"])
            return votes[currentUserId] == nil
        default:
            return false
        }
    }

    func requestNotificationPermissionIfNeeded() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, error in
            if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
        }
    }

    func startObservingAppLifecycle() {
        guard lifecycleObserverTokens.isEmpty else { return }

        let notificationCenter = NotificationCenter.default
        let willResignActiveToken = notificationCenter.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.beginBackgroundTurnMonitoringWindow()
            self?.reconcileTurnReminderSchedulingForCurrentAppState()
        }

        let didEnterBackgroundToken = notificationCenter.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.beginBackgroundTurnMonitoringWindow()
            self?.reconcileTurnReminderSchedulingForCurrentAppState()
        }

        let didBecomeActiveToken = notificationCenter.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.endBackgroundTurnMonitoringWindow()
            self?.reconcileTurnReminderSchedulingForCurrentAppState()
        }

        let willEnterForegroundToken = notificationCenter.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.endBackgroundTurnMonitoringWindow()
            self?.reconcileTurnReminderSchedulingForCurrentAppState()
        }

        lifecycleObserverTokens = [
            willResignActiveToken,
            didEnterBackgroundToken,
            didBecomeActiveToken,
            willEnterForegroundToken
        ]
    }

    func stopObservingAppLifecycle() {
        let notificationCenter = NotificationCenter.default
        lifecycleObserverTokens.forEach { notificationCenter.removeObserver($0) }
        lifecycleObserverTokens.removeAll()
    }

    func reconcileTurnReminderSchedulingForCurrentAppState() {
        let applicationState = UIApplication.shared.applicationState
        if applicationState == .active {
            cancelTurnReminderNotification()
            return
        }

        if shouldScheduleTurnReminder() {
            scheduleTurnReminderNotificationIfNeeded()
        } else {
            cancelTurnReminderNotification()
        }
    }

    func beginBackgroundTurnMonitoringWindow() {
        guard backgroundMonitoringTask == .invalid else { return }

        backgroundMonitoringTask = UIApplication.shared.beginBackgroundTask(withName: "ImposterTurnMonitoring") { [weak self] in
            self?.endBackgroundTurnMonitoringWindow()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 25) { [weak self] in
            self?.endBackgroundTurnMonitoringWindow()
        }
    }

    func endBackgroundTurnMonitoringWindow() {
        guard backgroundMonitoringTask != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundMonitoringTask)
        backgroundMonitoringTask = .invalid
    }

    func scheduleTurnReminderNotificationIfNeeded() {
        guard shouldScheduleTurnReminder() else {
            cancelTurnReminderNotification()
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "It's your turn in Imposter"
        content.body = "Jump back into Bevoholic so your group can keep the round moving."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let request = UNNotificationRequest(
            identifier: turnReminderNotificationIdentifier,
            content: content,
            trigger: trigger
        )

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [turnReminderNotificationIdentifier])
        center.add(request) { error in
            if let error = error {
                print("Error scheduling imposter turn reminder notification: \(error.localizedDescription)")
            }
        }
    }

    func cancelTurnReminderNotification() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [turnReminderNotificationIdentifier])
        center.removeDeliveredNotifications(withIdentifiers: [turnReminderNotificationIdentifier])
    }

    func setupNextRound() {
        guard
            let gameCode = gameCode,
            let currentUserId = currentUserId,
            isCurrentUserHost(userId: currentUserId)
        else {
            return
        }

        let activeIds = activePlayerIds
        guard !activeIds.isEmpty else { return }

        let nextImposterId = activeIds.randomElement() ?? activeIds[0]
        let speakerOrder = activeIds.shuffled()
        let randomContent = ImposterGameManager.shared.randomCategoryAndWord()
        let nextRoundNumber = (gameData["roundNumber"] as? Int ?? 1) + 1

        db.collection("games").document(gameCode).setData([
            "imposterPhase": "clue",
            "imposterCategory": randomContent.category,
            "imposterWord": randomContent.word,
            "imposterId": nextImposterId,
            "clueReadyPlayerIds": [],
            "imposterVotes": [String: String](),
            "roundTopSuspectIds": [String](),
            "roundVoteCounts": [String: Int](),
            "speakerOrder": speakerOrder,
            "currentPlayerId": speakerOrder.first ?? activeIds[0],
            "roundNumber": nextRoundNumber,
            "updatedAt": Timestamp()
        ], merge: true)
    }

    func markClueReady() {
        guard let gameCode = gameCode, let currentUserId = currentUserId else { return }

        let gameRef = db.collection("games").document(gameCode)

        db.runTransaction({ transaction, errorPointer -> Any? in
            let snapshot: DocumentSnapshot
            do {
                snapshot = try transaction.getDocument(gameRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            guard let data = snapshot.data() else { return nil }

            let phase = data["imposterPhase"] as? String ?? "clue"
            guard phase == "clue" else { return nil }

            let activeIds = data["activePlayerIds"] as? [String] ?? []
            let speakerOrder = data["speakerOrder"] as? [String] ?? activeIds
            let readyIdsBeforeUpdate = Set(data["clueReadyPlayerIds"] as? [String] ?? [])
            let expectedCurrentSpeakerId = self.nextUnreadyPlayerId(
                activeIds: activeIds,
                speakerOrder: speakerOrder,
                readyIds: readyIdsBeforeUpdate
            )

            // Only the active speaker can complete the clue step.
            guard expectedCurrentSpeakerId == currentUserId else { return nil }

            var readyIds = readyIdsBeforeUpdate
            readyIds.insert(currentUserId)

            var updates: [String: Any] = [
                "clueReadyPlayerIds": Array(readyIds),
                "updatedAt": Timestamp()
            ]

            let everyoneReady = !activeIds.isEmpty && activeIds.allSatisfy { readyIds.contains($0) }
            if everyoneReady {
                updates["imposterPhase"] = "voting"
                updates["imposterVotes"] = [String: String]()
                updates["roundTopSuspectIds"] = [String]()
                updates["roundVoteCounts"] = [String: Int]()
                updates["currentPlayerId"] = FieldValue.delete()
            } else {
                let nextSpeakerId = self.nextUnreadyPlayerId(
                    activeIds: activeIds,
                    speakerOrder: speakerOrder,
                    readyIds: readyIds
                )
                if let nextSpeakerId = nextSpeakerId {
                    updates["currentPlayerId"] = nextSpeakerId
                }
            }

            transaction.setData(updates, forDocument: gameRef, merge: true)
            return nil
        }) { _, error in
            if let error = error {
                print("Error marking ready for imposter clue phase: \(error.localizedDescription)")
            }
        }
    }

    func submitVote() {
        guard let gameCode = gameCode, let currentUserId = currentUserId else { return }

        guard let selectedVotePlayerId = selectedVotePlayerId else {
            statusLabel.text = "Please select a player first"
            return
        }

        let gameRef = db.collection("games").document(gameCode)

        db.runTransaction({ transaction, errorPointer -> Any? in
            let snapshot: DocumentSnapshot
            do {
                snapshot = try transaction.getDocument(gameRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            guard let data = snapshot.data() else { return nil }

            let phase = data["imposterPhase"] as? String ?? ""
            guard phase == "voting" else { return nil }

            let activeIds = data["activePlayerIds"] as? [String] ?? []
            guard activeIds.contains(selectedVotePlayerId) else { return nil }

            var votes = self.parseVoteMap(data["imposterVotes"])

            // Prevent re-voting from overriding existing ballot.
            if votes[currentUserId] != nil {
                return nil
            }

            votes[currentUserId] = selectedVotePlayerId

            var updates: [String: Any] = [
                "imposterVotes": votes,
                "updatedAt": Timestamp()
            ]

            let everyoneVoted = !activeIds.isEmpty && activeIds.allSatisfy { votes[$0] != nil }
            if everyoneVoted {
                var voteCounts: [String: Int] = [:]
                for votedId in votes.values {
                    voteCounts[votedId, default: 0] += 1
                }

                let maxVotes = voteCounts.values.max() ?? 0
                let topSuspectIds = voteCounts
                    .filter { $0.value == maxVotes }
                    .map { $0.key }
                let imposterId = data["imposterId"] as? String ?? ""
                let imposterCaught = topSuspectIds.count == 1 && topSuspectIds.first == imposterId

                updates["imposterPhase"] = "result"
                updates["imposterCaught"] = imposterCaught
                updates["roundTopSuspectIds"] = topSuspectIds
                updates["roundVoteCounts"] = voteCounts
            }

            transaction.setData(updates, forDocument: gameRef, merge: true)
            return nil
        }) { _, error in
            if let error = error {
                print("Error submitting imposter vote: \(error.localizedDescription)")
            }
        }
    }


    @IBAction func donePressed(_ sender: UIButton) {
        switch currentPhase {
        case "clue":
            markClueReady()
        case "voting":
            submitVote()
        case "result":
            setupNextRound()
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return voteCandidates.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "VoteCell") ??
            UITableViewCell(style: .default, reuseIdentifier: "VoteCell")
        let player = voteCandidates[indexPath.row]
        let votes = parseVoteMap(gameData["imposterVotes"])
        let submittedVote = currentUserId.flatMap { votes[$0] }
        let activeSelection = submittedVote ?? selectedVotePlayerId

        cell.textLabel?.text = player.name
        cell.accessoryType = (activeSelection == player.id) ? .checkmark : .none

        if submittedVote != nil {
            cell.selectionStyle = .none
        } else {
            cell.selectionStyle = .default
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard currentPhase == "voting" else { return }
        let votes = parseVoteMap(gameData["imposterVotes"])
        if let currentUserId = currentUserId, votes[currentUserId] != nil {
            return
        }

        selectedVotePlayerId = voteCandidates[indexPath.row].id
        tableView.reloadData()
    }
}
