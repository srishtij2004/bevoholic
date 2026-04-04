import Foundation

final class ImposterGameManager {
    static let shared = ImposterGameManager()

    private init() {}

    private let categories: [String: [String]] = [
        "Fruits": ["Apple", "Banana", "Orange", "Mango", "Pineapple", "Strawberry", "Grape"],
        "Movies": ["Titanic", "Inception", "Terminator", "Avatar", "Jaws", "Gladiator", "Rocky"],
        "Animals": ["Lion", "Elephant", "Dolphin", "Tiger", "Giraffe", "Penguin", "Kangaroo"],
        "Countries": ["Brazil", "Canada", "Japan", "Italy", "India", "Mexico", "Spain"],
        "Sports": ["Soccer", "Basketball", "Baseball", "Tennis", "Golf", "Hockey", "Volleyball"]
    ]

    func randomCategoryAndWord() -> (category: String, word: String) {
        let category = categories.keys.randomElement() ?? "Fruits"
        let words = categories[category] ?? ["Apple"]
        let word = words.randomElement() ?? "Apple"
        return (category, word)
    }
}
