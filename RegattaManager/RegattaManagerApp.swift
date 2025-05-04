// RegattaManagerApp.swift
// RegattaManager
//
// Created by Neil Fulcher on 15/04/2025.
//

import SwiftUI
import SwiftData

@main
struct RegattaManagerApp: App {
    let container: ModelContainer
    
    init() {
        do {
            let schema = Schema([RaceEvent.self, Skipper.self, Race.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            container = try ModelContainer(for: schema, configurations: config)
            
            // Pre-populate test data in the test environment
            if config.isStoredInMemoryOnly {
                prepopulateTestData()
            }
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .environmentObject(ClearDataManager(modelContainer: container))
        }
    }
    
    @MainActor
    private func prepopulateTestData() {
        let context = container.mainContext
        
        // Check if data already exists to avoid duplicates on app restart
        let fetchDescriptor = FetchDescriptor<Skipper>()
        let existingSkippers = (try? context.fetch(fetchDescriptor)) ?? []
        guard existingSkippers.isEmpty else {
            print("Test data already exists, skipping pre-population")
            return
        }
        
        // Create 15 Skippers with surnames; first 3 with 2-digit sail numbers
        let skippers = [
            Skipper(id: UUID().uuidString, name: "John Smith", sailNumber: "47"),
            Skipper(id: UUID().uuidString, name: "Neil Johnson", sailNumber: "01"),
            Skipper(id: UUID().uuidString, name: "Trevor Brown", sailNumber: "31"),
            Skipper(id: UUID().uuidString, name: "Alice Davis", sailNumber: "102"),
            Skipper(id: UUID().uuidString, name: "Bob Wilson", sailNumber: "103"),
            Skipper(id: UUID().uuidString, name: "Charlie Harris", sailNumber: "104"),
            Skipper(id: UUID().uuidString, name: "Diana Clark", sailNumber: "105"),
            Skipper(id: UUID().uuidString, name: "Eve Lewis", sailNumber: "106"),
            Skipper(id: UUID().uuidString, name: "Frank Walker", sailNumber: "107"),
            Skipper(id: UUID().uuidString, name: "Grace Hall", sailNumber: "108"),
            Skipper(id: UUID().uuidString, name: "Henry Allen", sailNumber: "109"),
            Skipper(id: UUID().uuidString, name: "Ivy King", sailNumber: "110"),
            Skipper(id: UUID().uuidString, name: "Jack Scott", sailNumber: "111"),
            Skipper(id: UUID().uuidString, name: "Kelly Green", sailNumber: "112"),
            Skipper(id: UUID().uuidString, name: "Liam White", sailNumber: "113")
        ]
        
        skippers.forEach { context.insert($0) }
        
        // Create Regatta
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMMM yyyy"
        guard let date = dateFormatter.date(from: "19 April 2025") else {
            print("Failed to parse date for test regatta")
            return
        }
        
        let regatta = RaceEvent(date: date, location: "Filby", name: "Test Regatta")
        context.insert(regatta)
        
        // Create 12 Races with all 15 skippers
        for i in 1...12 {
            let race = Race(finishingPositions: skippers.shuffled())
            race.event = regatta
            regatta.races.append(race)
            context.insert(race)
        }
        
        do {
            try context.save()
            print("Successfully pre-populated test data")
        } catch {
            print("Failed to pre-populate test data: \(error)")
        }
    }
}

class ClearDataManager: ObservableObject {
    let modelContainer: ModelContainer
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    
    @MainActor
    func clearData() {
        let context = modelContainer.mainContext
        do {
            try context.delete(model: RaceEvent.self)
            try context.delete(model: Skipper.self)
            try context.delete(model: Race.self)
            try context.save()
            print("Cleared all data from SwiftData store")
        } catch {
            print("Failed to clear data: \(error)")
        }
    }
}
