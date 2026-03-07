import UIKit
import FirebaseAuth
import FirebaseFirestore

class SettingsViewController: UIViewController {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var statusLabel: UILabel!

    @IBOutlet weak var bevoholicButton: UIButton!
    @IBOutlet weak var buzzedButton: UIButton!
    @IBOutlet weak var buzzkillButton: UIButton!

    let db = Firestore.firestore()

    var selectedDifficulty = "Bevoholic"

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        loadUserSettings()
    }

    func setupUI() {
        statusLabel.text = ""

        avatarImageView.layer.cornerRadius = avatarImageView.frame.size.width / 2
        avatarImageView.clipsToBounds = true

        styleDifficultyButton(bevoholicButton)
        styleDifficultyButton(buzzedButton)
        styleDifficultyButton(buzzkillButton)

        updateDifficultyUI()
    }

    func styleDifficultyButton(_ button: UIButton) {
        button.layer.cornerRadius = 10
        button.clipsToBounds = true
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemGray4
    }

    func updateDifficultyUI() {
        bevoholicButton.tintColor = .systemGray4
        buzzedButton.tintColor = .systemGray4
        buzzkillButton.tintColor = .systemGray4

        switch selectedDifficulty {
        case "Bevoholic":
            bevoholicButton.tintColor = .systemOrange
        case "Buzzed Bevo":
            buzzedButton.tintColor = .systemOrange
        case "Buzzkill Bevo":
            buzzkillButton.tintColor = .systemOrange
        default:
            bevoholicButton.tintColor = .systemOrange
        }
    }

    func loadUserSettings() {
        guard let uid = Auth.auth().currentUser?.uid else {
            statusLabel.text = "No logged in user."
            return
        }

        db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                self.statusLabel.text = "Failed to load settings: \(error.localizedDescription)"
                return
            }

            guard let data = snapshot?.data() else {
                self.statusLabel.text = "No settings found."
                return
            }

            self.usernameTextField.text = data["username"] as? String ?? ""

            let savedDifficulty = data["difficulty"] as? String ?? "Bevoholic"
            self.selectedDifficulty = savedDifficulty
            self.updateDifficultyUI()
        }
    }

    @IBAction func bevoholicTapped(_ sender: UIButton) {
        selectedDifficulty = "Bevoholic"
        updateDifficultyUI()
    }

    @IBAction func buzzedTapped(_ sender: UIButton) {
        selectedDifficulty = "Buzzed Bevo"
        updateDifficultyUI()
    }

    @IBAction func buzzkillTapped(_ sender: UIButton) {
        selectedDifficulty = "Buzzkill Bevo"
        updateDifficultyUI()
    }

    @IBAction func saveTapped(_ sender: UIButton) {
        guard let uid = Auth.auth().currentUser?.uid else {
            statusLabel.text = "No logged in user."
            return
        }

        guard let username = usernameTextField.text, !username.trimmingCharacters(in: .whitespaces).isEmpty else {
            statusLabel.text = "Username cannot be empty."
            return
        }

        db.collection("users").document(uid).setData([
            "username": username,
            "difficulty": selectedDifficulty
        ], merge: true) { [weak self] error in
            if let error = error {
                self?.statusLabel.text = "Save failed: \(error.localizedDescription)"
            } else {
                self?.statusLabel.text = "Settings saved."
            }
        }
    }

    @IBAction func logoutTapped(_ sender: UIButton) {
        do {
            try Auth.auth().signOut()

            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "LoginViewController")
            vc.modalPresentationStyle = .fullScreen
            present(vc, animated: true)
        } catch {
            statusLabel.text = "Logout failed: \(error.localizedDescription)"
        }
    }
}
