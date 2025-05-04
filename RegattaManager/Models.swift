//
//  Models.swift
//  RegattaManager
//
//  Created by Neil Fulcher on 15/04/2025.
//

import Foundation
import SwiftData

enum RaceStatus: String, Codable {
    case finished
    case dns
    case dnf
}

@Model
class RaceEvent {
    var date: Date
    var location: String
    var name: String
    var races: [Race]

    init(date: Date, location: String, name: String) {
        self.date = date
        self.location = location
        self.name = name
        self.races = []
    }
}

@Model
class Skipper {
    var id: String
    var name: String
    var sailNumber: String

    init(id: String, name: String, sailNumber: String) {
        self.id = id
        self.name = name
        self.sailNumber = sailNumber
    }
}

@Model
class Race {
    var creationDate: Date
    var event: RaceEvent?
    private var finishingPositionsNames: [String]
    private var statuses: [String: String] // Maps skipper ID to RaceStatus rawValue

    init(finishingPositions: [Skipper]) {
        self.creationDate = Date()
        self.finishingPositionsNames = finishingPositions.map { $0.id }
        self.statuses = Dictionary(uniqueKeysWithValues: finishingPositions.map { ($0.id, RaceStatus.finished.rawValue) })
    }
    
    func setFinishingPositions(_ skippers: [Skipper]) {
        self.finishingPositionsNames = skippers.map { $0.id }
        // Preserve existing statuses for skippers that are still in the list
        var newStatuses: [String: String] = [:]
        for skipper in skippers {
            newStatuses[skipper.id] = statuses[skipper.id] ?? RaceStatus.finished.rawValue
        }
        self.statuses = newStatuses
    }
    
    func fetchFinishingPositions(using context: ModelContext) -> [Skipper] {
        let skipperIds = finishingPositionsNames
        let predicate = #Predicate<Skipper> { skipper in
            skipperIds.contains(skipper.id)
        }
        let fetchDescriptor = FetchDescriptor<Skipper>(predicate: predicate)
        do {
            let allSkippers = try context.fetch(fetchDescriptor)
            return skipperIds.compactMap { id in
                allSkippers.first { $0.id == id }
            }
        } catch {
            print("Failed to fetch skippers: \(error)")
            return []
        }
    }
    
    func setStatus(_ status: RaceStatus, for skipper: Skipper) {
        statuses[skipper.id] = status.rawValue
    }
    
    func getStatus(for skipper: Skipper) -> RaceStatus {
        guard let statusRawValue = statuses[skipper.id],
              let status = RaceStatus(rawValue: statusRawValue) else {
            return .finished
        }
        return status
    }
}
