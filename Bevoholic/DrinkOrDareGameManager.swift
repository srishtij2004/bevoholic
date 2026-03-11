//
//  DrinkOrDareGameManager.swift
//  Bevoholic
//
//  Created by Srishti Jain on 3/9/26.
//


import Foundation

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
        "Ask someone on Speedway for a restaurant recommendation"
    ]

    private let westCampusDares = [
        "Knock on a friend's door and yell Hook 'Em",
        "Do a dance outside your apartment",
        "Order food for the group"
    ]

    private let kickbackDares = [
        "Tell an embarrassing story",
        "Let the group pick your next drink",
        "Text someone 'Hook 'Em' with no context"
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

    func dareModeText() -> String {
        switch selectedDareMode {
        case .onCampus:
            return "On Campus"
        case .westCampus:
            return "West Campus"
        case .kickback:
            return "Kickback"
        }
    }

    func gameModeText() -> String {
        switch selectedGameMode {
        case .buzzedBevo:
            return "Buzzed Bevo"
        case .bevoHolic:
            return "BevoHolic"
        case .buzzkillBevo:
            return "Buzzkill Bevo"
        }
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
}
