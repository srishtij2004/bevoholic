//
//  WaitingViewController.swift
//  Bevoholic
//
//  Created by Srishti Jain on 3/9/26.
//

import UIKit

class WaitingViewController: UIViewController {

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {

            if DrinkOrDareGameManager.shared.isGameFinished() {
                self.performSegue(withIdentifier: "showLeaderboard", sender: self)
            } else {
                self.performSegue(withIdentifier: "showNextTurn", sender: self)
            }

        }
    }
}
