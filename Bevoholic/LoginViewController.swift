import UIKit
import FirebaseAuth
import FirebaseFirestore

class LoginViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        errorLabel.text = ""
    }

    @IBAction func loginTapped(_ sender: UIButton) {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            errorLabel.text = "Please enter email and password."
            return
        }

        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                self?.errorLabel.text = error.localizedDescription
                return
            }

            self?.goToHome()
        }
    }

    @IBAction func signUpTapped(_ sender: UIButton) {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            errorLabel.text = "Please enter email and password."
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                self?.errorLabel.text = error.localizedDescription
                return
            }

            guard let user = result?.user else { return }

            let db = Firestore.firestore()
            db.collection("users").document(user.uid).setData([
                "email": email,
                "username": email.components(separatedBy: "@").first ?? "Player",
                "difficulty": "Bevoholic"
            ]) { err in
                if let err = err {
                    self?.errorLabel.text = "Account created, but profile save failed: \(err.localizedDescription)"
                    return
                }

                self?.goToHome()
            }
        }
    }

    private func goToHome() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "MainNavigationController")
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
}
