//
//  LeaderboardViewController.swift
//  Bevoholic
//
//  Created by Srishti Jain on 3/9/26.
//

import UIKit

class LeaderboardViewController: UIViewController, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!

    var leaderboardPlayers: [Player] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
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

        let cell = tableView.dequeueReusableCell(withIdentifier: "playerCell", for: indexPath)

        let player = leaderboardPlayers[indexPath.row]

        cell.textLabel?.text = player.name
        cell.detailTextLabel?.text = "\(player.points) pts"
        
        // Highlight the winner (first row)
           if indexPath.row == 0 {
               cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 18)
           }

        return cell
    }

    @IBAction func playAgainPressed(_ sender: UIButton) {

        // Reset game state
        DrinkOrDareGameManager.shared.currentPlayerIndex = 0
        DrinkOrDareGameManager.shared.turnsPlayed = 0

        // Return to home screen
        navigationController?.popToRootViewController(animated: true)
    }
}
