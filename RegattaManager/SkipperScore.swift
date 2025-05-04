// SkipperScore.swift
// RegattaManager
//
// Created by Neil Fulcher on 18/04/2025.
//

import Foundation
import SwiftData

struct Score {
    let skipperName: String
    let sailNumber: String
    let totalPoints: Int
    let positionsPerRace: [Int] // Position for each race (or penalty for DNS/DNF)
    let discardedRaceIndices: [Int] // Changed to an array to store multiple discards
    let hasDNSorDNF: Bool // New property to indicate if the total includes DNS/DNF penalties
}

struct ScoreCalculator {
    static func computeScores(for races: [Race], using context: ModelContext) -> (scores: [Score], uncompletedRaces: [Int]) {
        // Fetch all skippers
        let fetchDescriptor = FetchDescriptor<Skipper>()
        guard let allSkippers = try? context.fetch(fetchDescriptor) else {
            return (scores: [], uncompletedRaces: [])
        }
        
        // Map to hold scores for each skipper
        var scoresBySkipper: [String: (points: [Int], sailNumber: String, hasDNSorDNF: Bool)] = [:]
        
        for skipper in allSkippers {
            scoresBySkipper[skipper.id] = (points: [], sailNumber: "", hasDNSorDNF: false)
        }
        
        // Track races with no finishing positions
        var uncompletedRaces: [Int] = []
        
        // Calculate points for each race
        for (index, race) in races.enumerated() {
            let finishingPositions = race.fetchFinishingPositions(using: context)
            let totalBoats = allSkippers.count
            
            // Check if the race has no finishing positions
            if finishingPositions.isEmpty {
                uncompletedRaces.append(index)
            }
            
            // Map positions for this race
            var positionMap: [String: Int] = [:]
            
            // Assign positions to boats that finished
            for (index, skipper) in finishingPositions.enumerated() {
                let status = race.getStatus(for: skipper)
                if status == .finished {
                    positionMap[skipper.id] = index + 1 // 1st place = 1 point, 2nd place = 2 points, etc.
                }
            }
            
            // Assign points to all skippers for this race
            for skipper in allSkippers {
                var points: Int
                let status = race.getStatus(for: skipper)
                
                if status == .dns || status == .dnf {
                    // DNS/DNF boats get a penalty score (number of boats + 1)
                    points = totalBoats + 1
                    scoresBySkipper[skipper.id]?.hasDNSorDNF = true
                } else if let position = positionMap[skipper.id] {
                    points = position
                } else {
                    // Boats that didn't participate in this race (not in finishingPositions) are treated as DNS
                    points = totalBoats + 1
                    scoresBySkipper[skipper.id]?.hasDNSorDNF = true
                }
                
                scoresBySkipper[skipper.id]?.points.append(points)
                scoresBySkipper[skipper.id]?.sailNumber = skipper.sailNumber
            }
        }
        
        // Calculate number of discards (1 discard per 5 or more races)
        let numberOfDiscards = races.count >= 5 ? races.count / 5 : 0
        
        // Compute total scores with multiple discards
        var scores: [Score] = []
        for skipper in allSkippers {
            guard let scoreData = scoresBySkipper[skipper.id] else { continue }
            
            let points = scoreData.points
            guard !points.isEmpty else { continue }
            
            // Find the indices of the worst races to discard (highest points)
            let sortedIndices = points.indices.sorted { points[$0] > points[$1] }
            let discardedIndices = sortedIndices.prefix(numberOfDiscards).sorted() // Sort for consistent display
            
            // Calculate total points, excluding discarded races
            let totalPoints = points.enumerated().reduce(0) { sum, element in
                discardedIndices.contains(element.offset) ? sum : sum + element.element
            }
            
            scores.append(Score(
                skipperName: skipper.name,
                sailNumber: scoreData.sailNumber,
                totalPoints: totalPoints,
                positionsPerRace: points,
                discardedRaceIndices: Array(discardedIndices), // Store all discarded indices
                hasDNSorDNF: scoreData.hasDNSorDNF
            ))
        }
        
        return (scores: scores.sorted { $0.totalPoints < $1.totalPoints }, uncompletedRaces: uncompletedRaces)
    }
}
