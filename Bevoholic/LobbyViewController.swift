//
//  LobbyViewController.swift
//  Bevoholic
//
//  Created by Poluchalla, Srilekha on 3/8/26.
//

import UIKit
import FirebaseFirestore

class LobbyViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!

    var gameCode: String!
    let db = Firestore.firestore()
    var listener: ListenerRegistration?

    // Store usernames for table view
    var usernames: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self

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
                    let uid = doc.documentID // player UID

                    group.enter()

                    // Fetch username from users collection
                    self.db.collection("users").document(uid).getDocument { userDoc, error in
                        defer { group.leave() }

                        if let data = userDoc?.data(), let username = data["username"] as? String {
                            self.usernames.append(username)
                        } else {
                            self.usernames.append("Player") // fallback
                        }
                    }
                }

                group.notify(queue: .main) {
                    self.tableView.reloadData()
                }
            }
    }


    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usernames.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "PlayerCell", for: indexPath)

        let username = usernames[indexPath.row]

        // Configure player icon
        cell.imageView?.image = UIImage(systemName: "person.circle.fill")
        cell.imageView?.tintColor = .systemBlue
        cell.imageView?.layer.cornerRadius = 25
        cell.imageView?.clipsToBounds = true
        cell.imageView?.contentMode = .scaleAspectFit

        cell.textLabel?.text = username

        return cell
    }

    deinit {
        listener?.remove()
    }
}
