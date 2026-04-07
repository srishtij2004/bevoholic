import UIKit

class ImposterGameViewController: HeaderViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var roundLabel: UILabel!
    @IBOutlet weak var promptLabel: UILabel!
    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var playersTableView: UITableView!

    var gameCode: String!
    
    var players = ["Srishti", "Sri", "John", "Likhita"]
    var actualImposter = "John"
    var selectedPlayer: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        playersTableView.dataSource = self
        playersTableView.delegate = self
        playersTableView.isHidden = true

        navigationItem.hidesBackButton = true
        title = ""
        navigationItem.title = ""

        doneButton.layer.cornerRadius = 16
        doneButton.setTitle("I'm Ready", for: .normal)

        setupClueUI()
    }

    func setupClueUI() {
        let result = ImposterGameManager.shared.randomCategoryAndWord()

        categoryLabel.text = "IMPOSTER"
        roundLabel.text = "Round 1"
        promptLabel.text = "Your word is"
        wordLabel.text = result.word
        statusLabel.text = "Describe it without saying it!"
    }

    @IBAction func donePressed(_ sender: UIButton) {
        if doneButton.title(for: .normal) == "Play Again" {
            navigationController?.popViewController(animated: true)
            return
        }
        if doneButton.title(for: .normal) == "I'm Ready" {
                roundLabel.text = "Voting Time"
                promptLabel.text = "Who is the imposter?"
                wordLabel.text = " "
                statusLabel.text = "Tap a name to vote"
                playersTableView.isHidden = false
                doneButton.setTitle("Submit Vote", for: .normal)
            }
        else {
            if let selectedPlayer = selectedPlayer {
                categoryLabel.text = Bool.random() ? "IMPOSTER CAUGHT!" : "IMPOSTER NOT CAUGHT!"
                roundLabel.text = ""
                promptLabel.text = "The imposter was"
                wordLabel.text = actualImposter
                if selectedPlayer == actualImposter {
                    categoryLabel.text = "IMPOSTER CAUGHT!"
                    statusLabel.font = UIFont.boldSystemFont(ofSize: 18)
                    statusLabel.textAlignment = .center
                    statusLabel.numberOfLines = 0
                    statusLabel.text = "\(actualImposter) takes a shot"
                    doneButton.isHidden = false
                    doneButton.setTitle("Play Again", for: .normal)
                } else {
                    categoryLabel.text = "IMPOSTER NOT CAUGHT!"
                    statusLabel.font = UIFont.boldSystemFont(ofSize: 18)
                    statusLabel.textAlignment = .center
                    statusLabel.numberOfLines = 0
                    statusLabel.text = "\(actualImposter) wins! Everyone else bottoms up!"
                    doneButton.isHidden = false
                    doneButton.setTitle("Play Again", for: .normal)
                }
                playersTableView.isHidden = true
                //doneButton.isHidden = true
            } else {
                statusLabel.text = "Please select a player first"
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return players.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        cell.textLabel?.text = players[indexPath.row]

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedPlayer = players[indexPath.row]
    }
}
