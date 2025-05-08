// RegattaDetailView.swift
// RegattaManager
//
// Created by Neil Fulcher on 18/04/2025.
//

import SwiftUI
import SwiftData

struct RegattaDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showEditRaceView: Bool = false
    @State private var selectedRace: Race?
    @State private var refreshID = UUID() // To force UI refresh
    
    let event: RaceEvent
    
    var races: [Race] {
        event.races.sorted(by: { $0.creationDate < $1.creationDate })
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Event Details
                VStack(alignment: .leading, spacing: 1) {
                    Text(event.name)
                        .font(StyleGuide.headlineFont)
                        .foregroundColor(StyleGuide.textColor)
                    Text("LOC: \(event.location)")
                        .font(StyleGuide.bodyFont)
                        .foregroundColor(StyleGuide.textColor)
                    Text("Date: \(event.date, style: .date)")
                        .font(StyleGuide.bodyFont)
                        .foregroundColor(StyleGuide.textColor)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Event Details: Name \(event.name), Location \(event.location), Date \(event.date, style: .date)")
                
                // Completed Races
                ForEach(races.filter { $0.isCompleted }, id: \.self) { race in
                    Button(action: {
                        selectedRace = race
                        showEditRaceView = true
                    }) {
                        Text("Race \(raceNumber(for: race))")
                            .font(StyleGuide.bodyFont)
                            .bold()
                            .foregroundColor(StyleGuide.textColor)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                    .accessibilityLabel("Race \(raceNumber(for: race))")
                    .accessibilityHint("Tap to view and edit finishing positions")
                    
                    Divider()
                }
                
                // Add bottom padding
                Spacer()
                    .frame(height: 8)
            }
        }
        .id(refreshID)
        .navigationTitle("Regatta Details")
        .background(StyleGuide.nauticalGradient)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    do {
                        let newRace = Race(finishingPositions: [])
                        newRace.event = event
                        event.races.append(newRace)
                        modelContext.insert(newRace)
                        try modelContext.save()
                        refreshID = UUID()
                        selectedRace = newRace
                        showEditRaceView = true
                        print("Successfully added new race and opened EditRaceView")
                    } catch {
                        print("Failed to add new race: \(error)")
                    }
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(StyleGuide.nauticalBlueAccent)
                        .accessibilityLabel("Add new race")
                }
            }
        }
        .sheet(isPresented: $showEditRaceView) {
            if let race = selectedRace {
                EditRaceView(race: race) { updatedSkippers in
                    race.setFinishingPositions(updatedSkippers)
                    do {
                        try modelContext.save()
                        refreshID = UUID()
                        print("Successfully saved race updates")
                    } catch {
                        print("Failed to save race updates: \(error)")
                    }
                }
            }
        }
    }
    
    private func raceNumber(for race: Race) -> Int {
        guard let index = races.firstIndex(of: race) else {
            return 0
        }
        return index + 1
    }
    
    private func positionSuffix(for position: Int) -> String {
        switch position {
        case 1:
            return "1st"
        case 2:
            return "2nd"
        case 3:
            return "3rd"
        default:
            return "\(position)th"
        }
    }
}

#Preview {
    let schema = Schema([RaceEvent.self, Skipper.self, Race.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: RaceEvent.self, Skipper.self, Race.self, configurations: config)
    
    let context = container.mainContext
    
    // Create Test Skippers
    let skippers = [
        Skipper(id: UUID().uuidString, name: "Neil Johnson", sailNumber: "01"),
        Skipper(id: UUID().uuidString, name: "Ivy King", sailNumber: "110"),
        Skipper(id: UUID().uuidString, name: "Diana Clark", sailNumber: "105"),
        Skipper(id: UUID().uuidString, name: "Frank Walker", sailNumber: "107"),
        Skipper(id: UUID().uuidString, name: "Charlie Harris", sailNumber: "104"),
        Skipper(id: UUID().uuidString, name: "Trevor Brown", sailNumber: "31"),
        Skipper(id: UUID().uuidString, name: "Eve Lewis", sailNumber: "106"),
        Skipper(id: UUID().uuidString, name: "Alice Davis", sailNumber: "102"),
        Skipper(id: UUID().uuidString, name: "John Smith", sailNumber: "47"),
        Skipper(id: UUID().uuidString, name: "Jane Doe", sailNumber: "111"),
        Skipper(id: UUID().uuidString, name: "Bob Smith", sailNumber: "112"),
        Skipper(id: UUID().uuidString, name: "Alice Brown", sailNumber: "103"),
        Skipper(id: UUID().uuidString, name: "Tom Jones", sailNumber: "108"),
        Skipper(id: UUID().uuidString, name: "Sarah Lee", sailNumber: "109"),
        Skipper(id: UUID().uuidString, name: "Mike Wilson", sailNumber: "113")
    ]
    
    skippers.forEach { context.insert($0) }
    
    // Create Test Event and Races
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd MMMM yyyy"
    guard let date = dateFormatter.date(from: "19 April 2025") else {
        fatalError("Failed to parse date for test regatta in preview")
    }
    
    let event = RaceEvent(date: date, location: "Filby", name: "Test Regatta")
    
    // Race 1: Some finishers, DNS, and DNF
    let race1Finishers = Array(skippers[0..<5]) // First 5 skippers
    let race1 = Race(finishingPositions: race1Finishers)
    race1.setStatus(.dns, for: skippers[0]) // Neil Johnson DNS
    race1.setStatus(.dnf, for: skippers[1]) // Ivy King DNF
    
    // Race 2: Different finishers
    let race2Finishers = Array(skippers[5..<10]) // Next 5 skippers
    let race2 = Race(finishingPositions: race2Finishers)
    race2.setStatus(.dns, for: skippers[5]) // Trevor Brown DNS
    
    // Race 3: Empty (not completed)
    let race3 = Race(finishingPositions: [])
    
    race1.event = event
    race2.event = event
    race3.event = event
    event.races.append(contentsOf: [race1, race2, race3])
    
    context.insert(event)
    context.insert(race1)
    context.insert(race2)
    context.insert(race3)
    
    do {
        try context.save()
        print("Successfully loaded test data for RegattaDetailView preview")
    } catch {
        print("Failed to load test data for RegattaDetailView preview: \(error)")
    }
    
    return NavigationStack {
        RegattaDetailView(event: event)
            .modelContainer(container)
    }
}
