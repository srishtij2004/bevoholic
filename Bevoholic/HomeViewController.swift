import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore

class HomeViewController: HeaderViewController {

    let db = Firestore.firestore()
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func profileTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "SettingsViewController")
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func drinkOrDareTapped(_ sender: UIButton) {
        showGameOptions()
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
            guard let code = alert.textFields?.first?.text, !code.isEmpty else { return }
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
            self.db.collection("games").document(code)
                .collection("players").document(userId)
                .setData([
                    "name": Auth.auth().currentUser?.displayName ?? "Player",
                    "isHost": true
                ]) { error in
                    if let error = error { print(error); return }
                    self.showGameCodeAlert(code: code, location: location)
                }
        }
    }
    
    func joinGame(gameCode: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let playerData: [String: Any] = [
            "name": Auth.auth().currentUser?.displayName ?? "Player",
            "isHost": false
        ]

        db.collection("games").document(gameCode)
            .collection("players").document(userId)
            .setData(playerData) { error in
                if let error = error { print("Error joining game: \(error)"); return }
                print("Joined game \(gameCode)")

                self.goToLobby(with: gameCode)
            }
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
}
