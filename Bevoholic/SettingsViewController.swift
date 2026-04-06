import UIKit
import FirebaseAuth
import FirebaseFirestore

class SettingsViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    @IBOutlet weak var avatarImageView: PlayerProfile!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var statusLabel: UILabel!

    @IBOutlet weak var bevoholicButton: UIButton!
    @IBOutlet weak var buzzedButton: UIButton!
    @IBOutlet weak var buzzkillButton: UIButton!

    @IBOutlet weak var avatarCollectionView: UICollectionView!
    let db = Firestore.firestore()
    let avatars = [
        "longhornHead_sunglasses",
        "longhornHead_sunHat",
        "longhornHead_baseballHat",
        "longhornHead_partyHat",
        "longhornHead_jesterHat",
        "longhornHead_beanieHat",
        "longhornHead_flowerHat",
        "longhornHead_cowboyHat",
        "longhornHead_topHat"
    ]
    
    var selectedDifficulty = "Buzzed Bevo"
    var selectedAvatar = "longhornHead"
    let darkBrown = UIColor(red: 120/255, green: 50/255, blue: 1/255, alpha: 1.0)


    override func viewDidLoad() {
        super.viewDidLoad()
        avatarCollectionView.backgroundColor = .clear
        setupUI()
        loadUserSettings()
        avatarCollectionView.delegate = self
        avatarCollectionView.dataSource = self

        if let layout = avatarCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.itemSize = CGSize(width: 100, height: 100)
            layout.minimumLineSpacing = 2
            layout.minimumInteritemSpacing = 2
            layout.sectionInset = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        }
    }
    
    //num avatars
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return avatars.count
    }

    //set up each avatar
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AvatarCell", for: indexPath) as! AvatarCell
        let avatarName = avatars[indexPath.row]
        cell.configure(with: avatarName, selected: avatarName == selectedAvatar)
        return cell
    }

    //user select
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedAvatar = avatars[indexPath.row]
        avatarImageView.image = UIImage(named: selectedAvatar)
        avatarCollectionView.reloadData()
    }

    func setupUI() {
        statusLabel.text = ""

        styleDifficultyButton(bevoholicButton)
        styleDifficultyButton(buzzedButton)
        styleDifficultyButton(buzzkillButton)

        updateDifficultyUI()
        avatarImageView.backgroundColor = darkBrown

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
            bevoholicButton.tintColor = darkBrown
        case "Buzzed Bevo":
            buzzedButton.tintColor = darkBrown
        case "Buzzkill Bevo":
            buzzkillButton.tintColor = darkBrown
        default:
            buzzedButton.tintColor = darkBrown
        }
    }
    func updateAvatar(_ avatarName: String) {
        selectedAvatar = avatarName
        avatarImageView.image = UIImage(named: avatarName)
        avatarImageView.backgroundColor = darkBrown
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

            let savedDifficulty = data["difficulty"] as? String ?? "Buzzed Bevo"
            self.selectedDifficulty = savedDifficulty
            self.updateDifficultyUI()
            
            let savedAvatar = data["selectedAvatar"] as? String ?? "longhornHead"
            self.updateAvatar(savedAvatar)
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
            "difficulty": selectedDifficulty,
            "selectedAvatar": selectedAvatar
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
