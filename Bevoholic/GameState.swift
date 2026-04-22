//
//  GameState.swift
//  Bevoholic
//
//  Created by Poluchalla, Srilekha on 4/1/26.
//


import Foundation

struct GameState {
    //prompts for Cards Against Longhorns
    static let allPrompts: [String] = [
        "When you see an org giving out free food on campus…",
        "When your friend says 'Let’s skip class'…",
        "When you realize your group project is due tomorrow…",
        "When someone steals your favorite spot in the library…",
        "When it’s 2 AM and you just remembered your homework…",
        "When the RA says 'Quiet hours start now'…",
        "When you see someone eating your leftovers…",
        "When the professor says the exam is cumulative…",
        "When it’s Taco Tuesday and you see the line at the food truck…",
        "When you finally get your grade back and it’s better than expected…"
    ]
    
    static var unusedPrompts: [String] = allPrompts
    
    static func getNextPrompt() -> String {
        if unusedPrompts.isEmpty {
            unusedPrompts = allPrompts
        }
        
        let randomIndex = Int.random(in: 0..<unusedPrompts.count)
        return unusedPrompts.remove(at: randomIndex)
    }
}
