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

class DrinkOrDareGameManager {
    
    static let shared = DrinkOrDareGameManager()
    
    var players: [Player] = []
    
    // tracks whose turn visually
    var currentPlayerIndex: Int = 0
    
    // tracks total turns played
    var turnsPlayed: Int = 0
    
    // each player gets 2 turns
    let rounds = 2
    
    func setPlayers(_ names: [String]) {
        players = names.map { Player(name: $0, points: 0, avatar: nil) }
        currentPlayerIndex = 0
        turnsPlayed = 0
    }
    
    func currentPlayer() -> Player? {
        guard players.count > 0 else { return nil }
        return players[currentPlayerIndex]
    }
    
    func completeTurn() {
        guard players.count > 0 else { return }
        
        players[currentPlayerIndex].points += 20
        advanceTurn()
    }
    
    func skipTurn() {
        guard players.count > 0 else { return }
        
        players[currentPlayerIndex].points -= 5
        advanceTurn()
    }
    
    private func advanceTurn() {
        turnsPlayed += 1
        
        // rotate to next player
        currentPlayerIndex = (currentPlayerIndex + 1) % players.count
    }
    
    func isGameFinished() -> Bool {
        return turnsPlayed >= players.count * rounds
    }
    
    func leaderboard() -> [Player] {
        return players.sorted { $0.points > $1.points }
    }
}
