//
//  LeaderboardViewController.swift
//  Bevoholic
//
//  Created by Srishti Jain on 3/9/26.
//

import UIKit
import FirebaseFirestore

class LeaderboardViewController: HeaderViewController, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!

    var gameCode: String!
    var leaderboardPlayers: [Player] = []

    private let db = Firestore.firestore()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        tableView.dataSource = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadLeaderboard()
    }

    func loadLeaderboard() {
        guard let gameCode = gameCode else { return }

        db.collection("games")
            .document(gameCode)
            .collection("players")
            .order(by: "points", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error loading leaderboard: \(error.localizedDescription)")
                    return
                }

                self.leaderboardPlayers = snapshot?.documents.map { document in
                    let data = document.data()
                    return Player(
                        name: data["name"] as? String ?? "Player",
                        points: data["points"] as? Int ?? 0,
                        avatar: nil
                    )
                } ?? []

                self.tableView.reloadData()
            }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        leaderboardPlayers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "playerCell", for: indexPath)
        let player = leaderboardPlayers[indexPath.row]

        cell.textLabel?.text = player.name
        cell.detailTextLabel?.text = "\(player.points) pts"

        if indexPath.row == 0 {
            cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        }

        return cell
    }

    @IBAction func playAgainPressed(_ sender: UIButton) {
        navigationController?.popToRootViewController(animated: true)
    }
}
