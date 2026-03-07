import UIKit

class HomeViewController: UIViewController {

    @IBAction func profileTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "SettingsViewController")
        navigationController?.pushViewController(vc, animated: true)
    }
}
