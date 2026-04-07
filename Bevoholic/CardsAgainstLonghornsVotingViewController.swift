import UIKit
import FirebaseAuth
import FirebaseFirestore

class CardsAgainstLonghornsVotingViewController: HeaderViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var submitVoteButton: UIButton!
    
    var gameCode: String!
    private let db = Firestore.firestore()
    
    var submissions: [(userId: String, image: UIImage)] = []
    var selectedUserId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 300
        
        loadSubmissions()
    }
    
    func loadSubmissions() {
        guard let gameCode = gameCode else { return }
        print("Fetching submissions for game: \(gameCode)")
        
        db.collection("games").document(gameCode).collection("submissions").getDocuments { snapshot, error in
            if let error = error {
                print("Firestore Error: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No submissions found in DB.")
                return
            }
            
            print("Found \(documents.count) documents.")

            self.submissions = documents.compactMap { doc in
                guard let base64String = doc.data()["image"] as? String else {
                    print("Document \(doc.documentID) missing 'image' field.")
                    return nil
                }
                
                guard let imageData = Data(base64Encoded: base64String) else {
                    print("Failed to decode Base64 for \(doc.documentID)")
                    return nil
                }
                
                guard let image = UIImage(data: imageData) else {
                    print("Data was not a valid image for \(doc.documentID)")
                    return nil
                }
                
                return (userId: doc.documentID, image: image)
            }
            
            print("Successfully loaded \(self.submissions.count) images.")
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return submissions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlayerImageTableViewCell", for: indexPath) as! PlayerImageTableViewCell
        
        let submission = submissions[indexPath.row]
        cell.playerImageView.image = submission.image
        
        if submission.userId == selectedUserId {
            cell.contentView.layer.borderWidth = 4
            cell.contentView.layer.borderColor = UIColor.systemGreen.cgColor
        } else {
            cell.contentView.layer.borderWidth = 0
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedUserId = submissions[indexPath.row].userId
        tableView.reloadData()
    }
    
    @IBAction func submitVotePressed(_ sender: Any) {
        guard let selected = selectedUserId, let gameCode = gameCode else {
            print("Please select an image first!")
            return
        }
        
        db.collection("games").document(gameCode).collection("votes")
            .document(selected)
            .setData([
                "votes": FieldValue.increment(Int64(1))
            ], merge: true) { error in
                if let error = error {
                    print("Error voting: \(error.localizedDescription)")
                } else {
                    print("Vote cast for \(selected)")
                }
            }
    }
}
