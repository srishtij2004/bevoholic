//
//  LobbyViewController.swift
//  Bevoholic
//
//  Created by Poluchalla, Srilekha on 3/8/26.
//

import UIKit
import FirebaseFirestore

class LobbyViewController: HeaderViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!

    @IBOutlet weak var gameCodeLabel: UILabel!
    
    var gameCode: String!
    let db = Firestore.firestore()
    var listener: ListenerRegistration?

    // Store usernames for table view
    var usernames: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        gameCodeLabel.text = "Code: \(gameCode ?? "")"
        tableView.rowHeight = 60
        fetchPlayers()
    }


    func fetchPlayers() {
        guard let gameCode = gameCode else { return }

        // Listen to the players subcollection
        listener = db.collection("games")
            .document(gameCode)
            .collection("players")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching players: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else { return }

                self.usernames = []

                let group = DispatchGroup()

                for doc in documents {
                    let data = doc.data()
                    let name = data["name"] as? String ?? "Player"
                    self.usernames.append(name)
                }
                group.notify(queue: .main) {
                    self.tableView.reloadData()
                }
            }
    }

    @IBAction func startButtonPressed(_ sender: Any) {
        // load players into game manager
            DrinkOrDareGameManager.shared.setPlayers(usernames)

            // go to dare screen
            performSegue(withIdentifier: "startSegue", sender: self)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usernames.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "PlayerCell", for: indexPath) as! PlayerCell

        let username = usernames[indexPath.row]

        cell.usernameLabel.text = username
        cell.avatarImageView.image = UIImage(systemName: "person.circle.fill")

        return cell
    }

    deinit {
        listener?.remove()
    }
}
