import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore

class HomeViewController: HeaderViewController {

    @IBOutlet weak var calButton: UIButton!
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        calButton.titleLabel?.textAlignment = .center
    }

    @IBAction func profileTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "SettingsViewController")
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func drinkOrDareTapped(_ sender: UIButton) {
        showOptions(for: "Drink or Dare")
    }

    @IBAction func imposterTapped(_ sender: UIButton) {
        showOptions(for: "Imposter")
    }

    @IBAction func cardsAgainstLonghornsTapped(_ sender: UIButton) {
        showOptions(for: "Cards Against Longhorns")
    }
    
    func showOptions(for gameType: String) {
        let actionSheet = UIAlertController(
            title: gameType,
            message: "Do you want to join or create a game?",
            preferredStyle: .actionSheet
        )

        actionSheet.addAction(UIAlertAction(title: "Join Game", style: .default) { _ in
            self.showJoinAlert(for: gameType)
        })

        actionSheet.addAction(UIAlertAction(title: "Create Game", style: .default) { _ in
            if gameType == "Drink or Dare" {
                self.showCreateGameOptions()
            } else {
                self.createGenericGame(type: gameType)
            }
        })

        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(actionSheet, animated: true)
    }
    
    func showJoinAlert(for gameType: String) {
        let alert = UIAlertController(title: "Join \(gameType)", message: "Enter Game Code", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Game Code" }
        
        alert.addAction(UIAlertAction(title: "Join", style: .default) { _ in
            guard let code = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(), !code.isEmpty else { return }
            self.validateAndJoin(code: code, expectedType: gameType)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    func validateAndJoin(code: String, expectedType: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("games").document(code).getDocument { snapshot, error in
            guard let snapshot = snapshot, snapshot.exists,
                  let actualType = snapshot.data()?["gameType"] as? String else {
                self.showJoinGameError(message: "Game not found.")
                return
            }

            if actualType == expectedType {
                self.addCurrentUserToGame(gameCode: code, userId: userId, isHost: false) { success in
                    if success { self.routeToCorrectLobby(type: actualType, code: code) }
                }
            } else {
                self.showJoinGameError(message: "This code is for \(actualType), not \(expectedType).")
            }
        }
    }

    func routeToCorrectLobby(type: String, code: String) {
        switch type {
        case "Drink or Dare": goToLobby(with: code)
        case "Imposter": goToImposterLobby(with: code)
        //case "Cards Against Longhorns": goToCALLobby(with: code)
        default: break
        }
    }
    
    func createGenericGame(type: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let code = generateGameCode()

        // Matches your existing Imposter gameData exactly
        let gameData: [String: Any] = [
            "hostId": userId,
            "gameType": type,
            "gameState": "lobby",
            "createdAt": Timestamp()
        ]

        db.collection("games").document(code).setData(gameData) { error in
            if let error = error { print(error); return }

            self.addCurrentUserToGame(gameCode: code, userId: userId, isHost: true) { success in
                guard success else { return }
                
                if type == "Imposter" {
                    self.showImposterCodeAlert(code: code)
                }
            }
        }
    }
    
    func showGameOptions() {
        let actionSheet = UIAlertController(
            title: "Drink or Dare",
            message: "Do you want to join or create a game?",
            preferredStyle: .actionSheet
        )

        actionSheet.addAction(UIAlertAction(title: "Join Game", style: .default) { _ in
            self.showJoinGameAlert()
        })

        actionSheet.addAction(UIAlertAction(title: "Create Game", style: .default) { _ in
            self.showCreateGameOptions()
        })

        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(actionSheet, animated: true)
    }

    func showJoinGameAlert() {
        let alert = UIAlertController(title: "Join Game", message: "Enter Game Code", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Game Code" }
        alert.addAction(UIAlertAction(title: "Join", style: .default) { _ in
            guard let code = alert.textFields?.first?.text?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased(),
                  !code.isEmpty else { return }
            self.joinGame(gameCode: code)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    func showCreateGameOptions() {
        let sheet = UIAlertController(title: "Select Location", message: nil, preferredStyle: .actionSheet)
        let locations = ["On Campus", "West Campus", "Kickback"]
        locations.forEach { location in
            sheet.addAction(UIAlertAction(title: location, style: .default) { _ in
                self.createGame(location: location)
            })
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(sheet, animated: true)
    }

    func generateGameCode() -> String {
        let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<6).compactMap { _ in chars.randomElement() })
    }

    func createGame(location: String) {
        
        // Set dare mode in the game manager
        switch location {
        case "On Campus":
            DrinkOrDareGameManager.shared.selectedDareMode = .onCampus
        case "West Campus":
            DrinkOrDareGameManager.shared.selectedDareMode = .westCampus
        case "Kickback":
            DrinkOrDareGameManager.shared.selectedDareMode = .kickback
        default:
            DrinkOrDareGameManager.shared.selectedDareMode = .onCampus
        }
        
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let code = generateGameCode()

        let gameData: [String: Any] = [
            "hostId": userId,
            "location": location,
            "gameType": "Drink or Dare",
            "createdAt": Timestamp()
        ]

        // Store game
        db.collection("games").document(code).setData(gameData) { error in
            if let error = error { print(error); return }

            // Add host as player
            self.addCurrentUserToGame(gameCode: code, userId: userId, isHost: true) { success in
                guard success else { return }
                self.showGameCodeAlert(code: code, location: location)
            }
        }
    }
    
    func joinGame(gameCode: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let gameDocument = db.collection("games").document(gameCode)

        gameDocument.getDocument { snapshot, error in
            if let error = error {
                print("Error looking up game: \(error)")
                self.showJoinGameError(message: "We couldn't verify that game code. Please try again.")
                return
            }

            guard let snapshot = snapshot, snapshot.exists else {
                self.showJoinGameError(message: "That game lobby doesn't exist. Check the code and try again.")
                return
            }

            self.addCurrentUserToGame(gameCode: gameCode, userId: userId, isHost: false) { success in
                guard success else {
                    self.showJoinGameError(message: "Unable to join this game right now. Please try again.")
                    return
                }

                print("Joined game \(gameCode)")
                self.goToLobby(with: gameCode)
            }
        }
    }

    func addCurrentUserToGame(gameCode: String, userId: String, isHost: Bool, completion: @escaping (Bool) -> Void) {
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                print("Error loading user profile: \(error)")
                completion(false)
                return
            }

            let username = (snapshot?.data()?["username"] as? String)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let playerName = (username?.isEmpty == false) ? username! : "Player"

            self.db.collection("games").document(gameCode)
                .collection("players").document(userId)
                .setData([
                    "name": playerName,
                    "isHost": isHost,
                    "points": 0,
                    "joinedAt": Timestamp()
                ]) { error in
                    if let error = error {
                        print("Error saving player to game: \(error)")
                        completion(false)
                        return
                    }

                    completion(true)
                }
        }
    }

    func showJoinGameError(message: String) {
        let alert = UIAlertController(title: "Unable to Join Game", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    func showGameCodeAlert(code: String, location: String) {
        let alert = UIAlertController(
            title: "Game Created",
            message: "Location: \(location)\n\nShare this code:\n\(code)",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            // Navigate to lobby AFTER the user taps OK
            self.goToLobby(with: code)
        })

        present(alert, animated: true)
    }

    func goToLobby(with gameCode: String) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let lobbyVC = storyboard.instantiateViewController(withIdentifier: "LobbyViewController") as? LobbyViewController {
            lobbyVC.gameCode = gameCode
            navigationController?.pushViewController(lobbyVC, animated: true)
        }
    }

    func showImposterOptions() {
        let actionSheet = UIAlertController(
            title: "Imposter",
            message: "Do you want to join or create a game?",
            preferredStyle: .actionSheet
        )

        actionSheet.addAction(UIAlertAction(title: "Join Game", style: .default) { _ in
            self.showJoinImposterAlert()
        })

        actionSheet.addAction(UIAlertAction(title: "Create Game", style: .default) { _ in
            self.createImposterGame()
        })

        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(actionSheet, animated: true)
    }

    func showJoinImposterAlert() {
        let alert = UIAlertController(title: "Join Imposter Game", message: "Enter Game Code", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Game Code" }
        alert.addAction(UIAlertAction(title: "Join", style: .default) { _ in
            guard
                let code = alert.textFields?.first?.text?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .uppercased(),
                !code.isEmpty
            else {
                return
            }
            self.joinImposterGame(gameCode: code)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    func createImposterGame() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let code = generateGameCode()

        let gameData: [String: Any] = [
            "hostId": userId,
            "gameType": "Imposter",
            "gameState": "lobby",
            "createdAt": Timestamp()
        ]

        db.collection("games").document(code).setData(gameData) { error in
            if let error = error {
                print("Error creating imposter game: \(error.localizedDescription)")
                return
            }

            self.addCurrentUserToGame(gameCode: code, userId: userId, isHost: true) { success in
                guard success else { return }
                self.showImposterCodeAlert(code: code)
            }
        }
    }

    func joinImposterGame(gameCode: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let gameDocument = db.collection("games").document(gameCode)

        gameDocument.getDocument { snapshot, error in
            if let error = error {
                print("Error looking up imposter game: \(error)")
                self.showJoinGameError(message: "We couldn't verify that game code. Please try again.")
                return
            }

            guard let snapshot = snapshot, snapshot.exists else {
                self.showJoinGameError(message: "That game lobby doesn't exist. Check the code and try again.")
                return
            }

            let gameType = snapshot.data()?["gameType"] as? String ?? ""
            guard gameType == "Imposter" else {
                self.showJoinGameError(message: "That code is not for an Imposter game.")
                return
            }

            self.addCurrentUserToGame(gameCode: gameCode, userId: userId, isHost: false) { success in
                guard success else {
                    self.showJoinGameError(message: "Unable to join this game right now. Please try again.")
                    return
                }
                self.goToImposterLobby(with: gameCode)
            }
        }
    }

    func showImposterCodeAlert(code: String) {
        let alert = UIAlertController(
            title: "Imposter Game Created",
            message: "Share this code:\n\(code)",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.goToImposterLobby(with: code)
        })

        present(alert, animated: true)
    }

    func goToImposterLobby(with gameCode: String) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let lobbyVC = storyboard.instantiateViewController(withIdentifier: "ImposterLobbyViewController") as? ImposterLobbyViewController else {
            return
        }
        lobbyVC.gameCode = gameCode
        navigationController?.pushViewController(lobbyVC, animated: true)
    }
}
