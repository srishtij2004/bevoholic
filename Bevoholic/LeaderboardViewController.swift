//
//  LeaderboardViewController.swift
//  Bevoholic
//
//  Created by Srishti Jain on 3/9/26.
//

import UIKit
import FirebaseFirestore

class LeaderboardViewController: HeaderViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!

    var gameCode: String!
    var leaderboardPlayers: [(id: String, name: String, points: Int)] = []

    private let db = Firestore.firestore()

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.hidesBackButton = true
        tableView.dataSource = self
        tableView.delegate = self
        tableView.layer.cornerRadius = 20
        tableView.clipsToBounds = true
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

                guard let documents = snapshot?.documents else { return }

                self.leaderboardPlayers = documents.map { doc in
                    let data = doc.data()
                    let name = data["name"] as? String ?? "Player"
                    let points = data["points"] as? Int ?? 0
                    return (id: doc.documentID, name: name, points: points)
                }

                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
    }

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return leaderboardPlayers.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: "LeaderboardCell",
            for: indexPath
        ) as! LeaderboardCell

        let player = leaderboardPlayers[indexPath.row]

        cell.usernameLabel.text = player.name
        cell.pointsLabel.text = "\(player.points)"
        cell.usernameLabel.font = UIFont.systemFont(ofSize: 17)
        cell.pointsLabel.font = UIFont.systemFont(ofSize: 17)
        cell.usernameLabel.textColor = .label
        cell.pointsLabel.textColor = .label
        
        if indexPath.row == 0 {
                cell.usernameLabel.font = UIFont.boldSystemFont(ofSize: 23)
                cell.pointsLabel.font = UIFont.boldSystemFont(ofSize: 23)
                cell.usernameLabel.textColor = .systemGreen
                cell.pointsLabel.textColor = .systemGreen
        }
        db.collection("users").document(player.id).getDocument { snapshot, error in
            if let data = snapshot?.data(),
               let avatarName = data["selectedAvatar"] as? String {

                DispatchQueue.main.async {
                    cell.avatarImageView.image = UIImage(named: avatarName)
                }
            } else {
                DispatchQueue.main.async {
                    cell.avatarImageView.image = UIImage(named: "longhornHead")
                    cell.avatarImageView.backgroundColor = UIColor(
                        red: 250/255,
                        green: 193/255,
                        blue: 145/255,
                        alpha: 1.0
                    )
                }
            }
        }

        return cell
    }

    // Bigger first place row
    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {

        if indexPath.row == 0 {
            return 110
        }
        return 70
    }

    @IBAction func playAgainPressed(_ sender: UIButton) {
        navigationController?.popToRootViewController(animated: true)
    }
}
