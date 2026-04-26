//
//  DrinkOrDareGameManager.swift
//  Bevoholic
//
//  Created by Srishti Jain on 3/9/26.
//
//
//
//import Foundation
//
struct Player {
    var name: String
    var points: Int
    var avatar: String?
}

enum DareMode {
    case onCampus
    case westCampus
    case kickback
}

enum GameMode {
    case buzzedBevo
    case bevoHolic
    case buzzkillBevo
}

struct MapDestination {
    let name: String
    let latitude: Double
    let longitude: Double
}

class DrinkOrDareGameManager {

    static let shared = DrinkOrDareGameManager()

    var players: [Player] = []
    var currentPlayerIndex: Int = 0

    // total turns played across the whole game
    var turnsPlayed: Int = 0

    // each player gets 2 turns
    let totalRounds: Int = 2

    // selected settings
    var selectedDareMode: DareMode = .onCampus
    var selectedGameMode: GameMode = .buzzedBevo

    // current dare text shown on dare screen
    var currentDare: String = ""

    // dare banks
    private let onCampusDares = [
        "Take a selfie with Bevo statue",
        "Sing Texas Fight near the Tower",
        "Ask someone on Speedway for a restaurant recommendation",
        "Take a group photo on the South Mall",
        "Find someone wearing burnt orange and get a Hook 'Em photo",
        "Do your best runway walk down Speedway",
        "Take a picture with the Littlefield Fountain",
        "High-five someone near the PCL",
        "Pose like a statue outside the Blanton",
        "Get a stranger to rate your Texas Fight performance",
        "Compliment someone's outfit near the Union",
        "Take a dramatic album-cover photo by the Turtle Pond"
    ]

    private let westCampusDares = [
        "Knock on a friend's door and yell Hook 'Em",
        "Do a dance outside your apartment",
        "Order food for the group",
        "Take a selfie outside Cain and Abel's",
        "Ask someone on Rio Grande for their best late-night food pick",
        "Start a tiny sidewalk chant for Texas",
        "Take a photo with the weirdest apartment sign you can find",
        "Convince someone to join a group Hook 'Em",
        "Find a food truck and ask what the best order is",
        "Do a victory lap around your block",
        "Get someone to teach you their favorite party pose",
        "Record a 5-second hype video outside Pluckers",
        "Take a group picture at 26th and Rio Grande"
    ]

    private let kickbackDares = [
        "Tell an embarrassing story",
        "Let the group pick your next drink",
        "Text someone 'Hook 'Em' with no context"
    ]

    private let mapDestinations = [
        "Take a selfie with Bevo statue": MapDestination(
            name: "Bevo Statue",
            latitude: 30.283732,
            longitude: -97.732635
        ),
        "Sing Texas Fight near the Tower": MapDestination(
            name: "UT Tower",
            latitude: 30.286100,
            longitude: -97.739321
        ),
        "Ask someone on Speedway for a restaurant recommendation": MapDestination(
            name: "Speedway",
            latitude: 30.287015,
            longitude: -97.736734
        ),
        "Take a group photo on the South Mall": MapDestination(
            name: "South Mall",
            latitude: 30.284782,
            longitude: -97.739336
        ),
        "Find someone wearing burnt orange and get a Hook 'Em photo": MapDestination(
            name: "University of Texas at Austin",
            latitude: 30.285231,
            longitude: -97.733994
        ),
        "Do your best runway walk down Speedway": MapDestination(
            name: "Speedway",
            latitude: 30.287015,
            longitude: -97.736734
        ),
        "Take a picture with the Littlefield Fountain": MapDestination(
            name: "Littlefield Fountain",
            latitude: 30.283124,
            longitude: -97.739394
        ),
        "High-five someone near the PCL": MapDestination(
            name: "Perry-Castaneda Library",
            latitude: 30.283496,
            longitude: -97.737278
        ),
        "Pose like a statue outside the Blanton": MapDestination(
            name: "Blanton Museum of Art",
            latitude: 30.280918,
            longitude: -97.737619
        ),
        "Get a stranger to rate your Texas Fight performance": MapDestination(
            name: "UT Tower",
            latitude: 30.286100,
            longitude: -97.739321
        ),
        "Compliment someone's outfit near the Union": MapDestination(
            name: "Texas Union",
            latitude: 30.286337,
            longitude: -97.741052
        ),
        "Take a dramatic album-cover photo by the Turtle Pond": MapDestination(
            name: "Turtle Pond",
            latitude: 30.286397,
            longitude: -97.737829
        ),
        "Knock on a friend's door and yell Hook 'Em": MapDestination(
            name: "West Campus",
            latitude: 30.286920,
            longitude: -97.747402
        ),
        "Do a dance outside your apartment": MapDestination(
            name: "West Campus",
            latitude: 30.286920,
            longitude: -97.747402
        ),
        "Order food for the group": MapDestination(
            name: "West Campus Restaurants",
            latitude: 30.286145,
            longitude: -97.744539
        ),
        "Take a selfie outside Cain and Abel's": MapDestination(
            name: "Cain and Abel's",
            latitude: 30.290003,
            longitude: -97.742019
        ),
        "Ask someone on Rio Grande for their best late-night food pick": MapDestination(
            name: "Rio Grande Street",
            latitude: 30.286561,
            longitude: -97.744927
        ),
        "Start a tiny sidewalk chant for Texas": MapDestination(
            name: "West Campus",
            latitude: 30.286920,
            longitude: -97.747402
        ),
        "Take a photo with the weirdest apartment sign you can find": MapDestination(
            name: "West Campus",
            latitude: 30.286920,
            longitude: -97.747402
        ),
        "Convince someone to join a group Hook 'Em": MapDestination(
            name: "West Campus",
            latitude: 30.286920,
            longitude: -97.747402
        ),
        "Find a food truck and ask what the best order is": MapDestination(
            name: "West Campus Food Trucks",
            latitude: 30.286145,
            longitude: -97.744539
        ),
        "Do a victory lap around your block": MapDestination(
            name: "West Campus",
            latitude: 30.286920,
            longitude: -97.747402
        ),
        "Get someone to teach you their favorite party pose": MapDestination(
            name: "West Campus",
            latitude: 30.286920,
            longitude: -97.747402
        ),
        "Record a 5-second hype video outside Pluckers": MapDestination(
            name: "Pluckers Wing Bar",
            latitude: 30.287459,
            longitude: -97.741896
        ),
        "Take a group picture at 26th and Rio Grande": MapDestination(
            name: "26th and Rio Grande",
            latitude: 30.290055,
            longitude: -97.744738
        )
    ]

    func setPlayers(_ names: [String]) {
        players = names.map { Player(name: $0, points: 0, avatar: nil) }
        currentPlayerIndex = 0
        turnsPlayed = 0
        currentDare = nextDare()
    }

    func setModes(dareMode: DareMode, gameMode: GameMode) {
        selectedDareMode = dareMode
        selectedGameMode = gameMode
    }

    func currentPlayer() -> Player? {
        guard currentPlayerIndex < players.count else { return nil }
        return players[currentPlayerIndex]
    }

    func nextDare() -> String {
        switch selectedDareMode {
        case .onCampus:
            return onCampusDares.randomElement() ?? "Take a selfie on campus"
        case .westCampus:
            return westCampusDares.randomElement() ?? "Do a dare in West Campus"
        case .kickback:
            return kickbackDares.randomElement() ?? "Tell a funny story"
        }
    }

    func completeTurn() {
        guard currentPlayerIndex < players.count else { return }

        players[currentPlayerIndex].points += 20
        advanceTurn()
    }

    func skipTurn() {
        guard currentPlayerIndex < players.count else { return }

        players[currentPlayerIndex].points -= 5
        advanceTurn()
    }

    private func advanceTurn() {
        guard !players.isEmpty else { return }

        turnsPlayed += 1
        currentPlayerIndex = (currentPlayerIndex + 1) % players.count
        currentDare = nextDare()
    }

    func isGameFinished() -> Bool {
        return turnsPlayed >= players.count * totalRounds
    }

    func leaderboard() -> [Player] {
        return players.sorted { $0.points > $1.points }
    }

    func resetGame() {
        currentPlayerIndex = 0
        turnsPlayed = 0

        for i in players.indices {
            players[i].points = 0
        }

        currentDare = nextDare()
    }

    func randomDare(for location: String) -> String {
        let previousMode = selectedDareMode
        selectedDareMode = dareMode(for: location)
        let selectedDare = nextDare()
        selectedDareMode = previousMode
        return selectedDare
    }

    func dareMode(for location: String) -> DareMode {
        switch location {
        case "West Campus":
            return .westCampus
        case "Kickback":
            return .kickback
        default:
            return .onCampus
        }
    }

    func mapDestination(for dare: String, location: String) -> MapDestination? {
        if let destination = mapDestinations[dare] {
            return destination
        }

        switch dareMode(for: location) {
        case .onCampus:
            return MapDestination(
                name: "University of Texas at Austin",
                latitude: 30.285231,
                longitude: -97.733994
            )
        case .westCampus:
            return MapDestination(
                name: "West Campus",
                latitude: 30.286920,
                longitude: -97.747402
            )
        case .kickback:
            return nil
        }
    }
}
