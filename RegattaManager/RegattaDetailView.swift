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
            VStack(alignment: .leading, spacing: 0) { // No spacing between rows
                // Event Details
                VStack(alignment: .leading, spacing: 1) { // Minimal internal spacing
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
                .padding(.horizontal, 16) // Match List's default horizontal padding
                .padding(.top, 8) // Add space above "Test Regatta"
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Event Details: Name \(event.name), Location \(event.location), Date \(event.date, style: .date)")
                
                // Races (without a "Races" section header)
                ForEach(races, id: \.self) { race in
                    // Race Title
                    Text("Race \(raceNumber(for: race))")
                        .font(StyleGuide.bodyFont)
                        .bold()
                        .foregroundColor(StyleGuide.textColor)
                        .padding(.horizontal, 16) // Match List's default horizontal padding
                        .padding(.top, 8) // was 8 Space above race title for hierarchy
                        .padding(.bottom, 8) // was 8 Space above race title for hierarchy
                    
                    Divider() // Thin line beneath the race title
                    
                    let finishingPositions = race.fetchFinishingPositions(using: modelContext)
                    if finishingPositions.isEmpty {
                        Text("No finishing positions recorded")
                            .font(StyleGuide.bodyFont)
                            .foregroundColor(StyleGuide.secondaryTextColor)
                            .padding(.horizontal, 16) // Match List's default horizontal padding
                            .accessibilityLabel("No finishing positions recorded for Race \(raceNumber(for: race))")
                        
                        Divider() // Thin line after "No finishing positions recorded"
                    } else {
                        ForEach(finishingPositions.indices, id: \.self) { index in
                            let skipper = finishingPositions[index]
                            let status = race.getStatus(for: skipper)
                            let positionText = status == .finished ? "\(index + 1)" : status.rawValue.uppercased()
                            let statusText = status == .finished ? "" : " (\(status.rawValue.uppercased()))"
                            let positionSuffix = status == .finished ? positionSuffix(for: index + 1) : ""
                            
                            HStack {
                                Text("\(positionSuffix)\(status == .finished ? "" : positionText)")
                                    .font(StyleGuide.bodyFont)
                                    .foregroundColor(status == .finished ? StyleGuide.textColor : .red)
                                
                                Spacer() // Push sail number to the right
                                
                                Text("\(skipper.sailNumber)\(statusText)")
                                    .font(StyleGuide.bodyFont)
                                    .foregroundColor(status == .finished ? StyleGuide.textColor : .red)
                                    .multilineTextAlignment(.trailing)
                                    .padding(.vertical, 8) // Line spacing NMF
                               
                            }
                            .padding(.horizontal, 16) // Match List's default horizontal padding
                            .accessibilityLabel("Position \(positionText), Sail number \(skipper.sailNumber), Status \(status.rawValue.uppercased())")
                            
                            Divider() // Thin line between each finishing position
                        }
                    }
                }
                .onTapGesture {
                    if let race = races.first(where: { $0 == selectedRace }) {
                        selectedRace = race
                        showEditRaceView = true
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Race List")
                .accessibilityHint("Tap to edit finishing positions")
                
                // Add bottom padding to ensure the last row isn't cut off
                Spacer()
                    .frame(height: 8)
            }
        }
        .id(refreshID) // Force refresh when refreshID changes
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
                        refreshID = UUID() // Trigger UI refresh
                        // Present EditRaceView for the new race
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
                        refreshID = UUID() // Trigger UI refresh
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
    
    var raceSkippers1 = skippers
    raceSkippers1.removeAll { $0.sailNumber == "01" } // Exclude Neil Johnson (DNS)
    let race1 = Race(finishingPositions: raceSkippers1)
    
    var raceSkippers2 = skippers
    raceSkippers2.removeAll { $0.sailNumber == "110" } // Exclude Ivy King (DNF)
    let race2 = Race(finishingPositions: raceSkippers2)
    
    race1.event = event
    race2.event = event
    event.races.append(contentsOf: [race1, race2])
    
    // Mark some boats as DNS/DNF for testing
    race1.setStatus(.dns, for: skippers[0]) // Neil Johnson DNS in Race 1
    race2.setStatus(.dnf, for: skippers[1]) // Ivy King DNF in Race 2
    
    context.insert(event)
    context.insert(race1)
    context.insert(race2)
    
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
