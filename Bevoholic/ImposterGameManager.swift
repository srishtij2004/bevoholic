import Foundation

final class ImposterGameManager {
    static let shared = ImposterGameManager()

    private init() {}

    private let categories: [String: [String]] = [
        
        "UT Places": [
            "PCL", "Gregory Gym", "UT Tower", "DKR Stadium", "Moody Center",
            "West Campus", "Speedway", "FAC", "Jester", "Littlefield Fountain"
        ],
        
        "UT Athletes": [
            "Arch Manning", "Quinn Ewers", "Bijan Robinson", "Vince Young",
            "Kevin Durant", "Colt McCoy", "Jordan Whittington"
        ],
        
        "UT Culture": [
            "Hook 'em", "Burnt Orange", "Bevo", "Longhorn Band",
            "Sixth Street", "Tailgate", "Game Day", "Texas Fight"
        ],
        
        "UT Food & Spots": [
            "Cabo Bob's", "Pluckers", "Torchy's",
            "Kerbey Lane", "In-N-Out", "Chick-fil-A"
        ],
        
        "UT Classes & Majors": [
            "CS Major", "Business Major", "Pre-Med",
            "Engineering"
        ]
    ]

    func randomCategoryAndWord() -> (category: String, word: String) {
        let category = categories.keys.randomElement() ?? "Fruits"
        let words = categories[category] ?? ["Apple"]
        let word = words.randomElement() ?? "Apple"
        return (category, word)
    }
}
