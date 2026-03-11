//
//  LeaderboardViewController.swift
//  Bevoholic
//
//  Created by Srishti Jain on 3/9/26.
//

import UIKit

class LeaderboardViewController: HeaderViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!

    var leaderboardPlayers: [Player] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
    }

    // Reload leaderboard whenever this screen appears
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        leaderboardPlayers = DrinkOrDareGameManager.shared.leaderboard()
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
        cell.scoreLabel.text = "\(player.points) pts"
        cell.avatarImageView.image = UIImage(systemName: "person.circle.fill")

        // Highlight winner
        if indexPath.row == 0 {
            cell.usernameLabel.font = UIFont.boldSystemFont(ofSize: 18)
        }

        return cell
    }

    @IBAction func playAgainPressed(_ sender: UIButton) {

        // Reset game state
        DrinkOrDareGameManager.shared.resetGame()
        // Return to home screen
        navigationController?.popToRootViewController(animated: true)
    }
}
