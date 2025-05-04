// ScoresView.swift
// RegattaManager
//
// Created by Neil Fulcher on 18/04/2025.
//

import SwiftUI
import SwiftData

struct HeaderRow: View {
    let raceCount: Int
    let uncompletedRaces: [Int] // Race indices (0-based) with no finishing positions
    
    var body: some View {
        HStack(spacing: 0) {
            Text("Skipper")
                .font(StyleGuide.bodyFont)
                .bold()
                .foregroundColor(StyleGuide.textColor)
                .frame(minWidth: 120, alignment: .leading)
                .padding(.horizontal, 1)
            Text("Sail")
                .font(StyleGuide.bodyFont)
                .bold()
                .foregroundColor(StyleGuide.textColor)
                .frame(minWidth: 50, alignment: .center)
                .padding(.horizontal, 6)
            Text("Total")
                .font(StyleGuide.bodyFont)
                .bold()
                .foregroundColor(StyleGuide.textColor)
                .frame(minWidth: 50, alignment: .center)
                .padding(.horizontal, 6)
            ForEach(1...raceCount, id: \.self) { raceNum in
                let raceIndex = raceNum - 1
                Text("R\(raceNum)")
                    .font(StyleGuide.bodyFont)
                    .bold()
                    .foregroundColor(StyleGuide.textColor)
                    .italic(uncompletedRaces.contains(raceIndex)) // Italicize uncompleted races
                    .frame(minWidth: 40, alignment: .center)
                    .padding(.horizontal, 4)
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Score table headers: Skipper, Sail Number, Total Points, and Race positions")
    }
}

struct RacePositionCell: View {
    let position: Int
    let isDiscarded: Bool
    let race: Race
    let skipper: Skipper
    
    var body: some View {
        let status = race.getStatus(for: skipper)
        ZStack {
            if isDiscarded {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 32, height: 20)
            }
            Text(status == .finished ? "\(position)" : "\(status.rawValue.uppercased()) (\(position))")
                .font(StyleGuide.bodyFont)
                .foregroundColor(status == .finished ? StyleGuide.textColor : .red)
                .frame(minWidth: 40, alignment: .center)
                .padding(.horizontal, 4)
        }
    }
}

struct ScoreRow: View {
    let score: Score
    let races: [Race]
    let modelContext: ModelContext
    
    var body: some View {
        HStack(spacing: 0) {
            Text(score.skipperName)
                .font(StyleGuide.bodyFont)
                .foregroundColor(StyleGuide.textColor)
                .frame(minWidth: 120, alignment: .leading)
                .padding(.horizontal, 6)
            Text(score.sailNumber)
                .font(StyleGuide.bodyFont)
                .foregroundColor(StyleGuide.secondaryTextColor)
                .frame(minWidth: 40, alignment: .center)
                .padding(.horizontal, 8)
            Text(score.hasDNSorDNF ? "\(score.totalPoints)*" : "\(score.totalPoints)")
                .font(StyleGuide.bodyFont)
                .foregroundColor(StyleGuide.textColor)
                .frame(minWidth: 40, alignment: .center)
                .padding(.horizontal, 8)
            // Fetch the skipper for this score once
            let fetchDescriptor = FetchDescriptor<Skipper>()
            let allSkippers = (try? modelContext.fetch(fetchDescriptor)) ?? []
            let skipper = allSkippers.first(where: { $0.sailNumber == score.sailNumber && $0.name == score.skipperName })
            
            if let skipper = skipper {
                ForEach(Array(score.positionsPerRace.indices), id: \.self) { index in
                    let position = score.positionsPerRace[index]
                    let isDiscarded = score.discardedRaceIndices.contains(index)
                    let race = races[index]
                    RacePositionCell(
                        position: position,
                        isDiscarded: isDiscarded,
                        race: race,
                        skipper: skipper
                    )
                }
            } else {
                ForEach(Array(score.positionsPerRace.indices), id: \.self) { _ in
                    Text("-")
                        .font(StyleGuide.bodyFont)
                        .foregroundColor(StyleGuide.textColor)
                        .frame(minWidth: 40, alignment: .center)
                        .padding(.horizontal, 4)
                }
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Skipper: \(score.skipperName), Sail: \(score.sailNumber), Total Points: \(score.totalPoints), Race Positions: \(score.positionsPerRace.map { String($0) }.joined(separator: ", "))"
        )
    }
}

struct ScoresView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RaceEvent.date, order: .reverse) private var events: [RaceEvent]

    var body: some View {
        NavigationStack {
            List {
                ForEach(events) { event in
                    Section(
                        header: Text("\(event.name) - \(event.location) - \(event.date, style: .date)")
                            .font(StyleGuide.headlineFont)
                            .foregroundColor(StyleGuide.textColor)
                            .padding(.vertical, 4)
                    ) {
                        if event.races.isEmpty {
                            Text("No races available")
                                .font(StyleGuide.bodyFont)
                                .foregroundColor(StyleGuide.secondaryTextColor)
                                .padding()
                                .accessibilityLabel("No races available for \(event.name)")
                        } else {
                            let races = event.races.sorted(by: { $0.creationDate < $1.creationDate })
                            let (scores, uncompletedRaces) = ScoreCalculator.computeScores(for: races, using: modelContext)
                            if scores.isEmpty {
                                Text("No scores available")
                                .font(StyleGuide.bodyFont)
                                .foregroundColor(StyleGuide.secondaryTextColor)
                                .padding()
                                .accessibilityLabel("No scores available for \(event.name)")
                            } else {
                                // Table Container with Horizontal Scrolling
                                ScrollView(.horizontal, showsIndicators: true) {
                                    VStack(alignment: .leading, spacing: 0) {
                                        ZStack(alignment: .topLeading) {
                                            // Table Content
                                            VStack(alignment: .leading, spacing: 0) {
                                                HeaderRow(raceCount: event.races.count, uncompletedRaces: uncompletedRaces)
                                                
                                                // Data Rows
                                                ForEach(scores, id: \.skipperName) { score in
                                                    ScoreRow(score: score, races: races, modelContext: modelContext)
                                                        .accessibilityHint("Row in score table for \(event.name)")
                                                }
                                            }

                                            // Continuous Vertical Lines
                                            GeometryReader { geometry in
                                                let columnWidths: [CGFloat] = [120, 50, 50] + Array(repeating: 40, count: event.races.count)
                                                let offsets = columnWidths.reduce(into: [CGFloat]()) { result, width in
                                                    result.append((result.last ?? 0) + width + 8)
                                                }
                                                ForEach(0..<offsets.count, id: \.self) { index in
                                                    Rectangle()
                                                        .fill(Color.gray.opacity(0.3))
                                                        .frame(width: 1, height: geometry.size.height)
                                                        .offset(x: offsets[index] - 4, y: 0)
                                                }
                                            }
                                        }
                                        
                                        // Legend for DNS/DNF, uncompleted races, and discards
                                        if scores.contains(where: { $0.hasDNSorDNF }) || !uncompletedRaces.isEmpty || event.races.count >= 5 {
                                            HStack {
                                                if scores.contains(where: { $0.hasDNSorDNF }) {
                                                    Text("* Includes DNS/DNF penalties")
                                                        .font(StyleGuide.bodyFont)
                                                        .foregroundColor(StyleGuide.secondaryTextColor)
                                                }
                                                if !uncompletedRaces.isEmpty {
                                                    Text("Italicized races have no finishing positions")
                                                        .font(StyleGuide.bodyFont)
                                                        .foregroundColor(StyleGuide.secondaryTextColor)
                                                }
                                                if event.races.count >= 5 {
                                                    let numberOfDiscards = event.races.count / 5
                                                    Text("\(numberOfDiscards) race\(numberOfDiscards == 1 ? "" : "s") discarded")
                                                        .font(StyleGuide.bodyFont)
                                                        .foregroundColor(StyleGuide.secondaryTextColor)
                                                }
                                                Spacer()
                                            }
                                            .padding(.vertical, 4)
                                            .padding(.horizontal)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .headerProminence(.increased)
                }
            }
            .navigationTitle("Scores")
            .background(StyleGuide.nauticalGradient)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Image(systemName: "trophy")
                        .foregroundColor(StyleGuide.nauticalBlueAccent)
                        .accessibilityLabel("Scores view")
                }
            }
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
        Skipper(id: UUID().uuidString, name: "John Smith", sailNumber: "47")
    ]
    
    skippers.forEach { context.insert($0) }
    
    // Create Regatta
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd MMMM yyyy"
    guard let date = dateFormatter.date(from: "19 April 2025") else {
        fatalError("Failed to parse date for test regatta in preview")
    }
    
    let regatta = RaceEvent(date: date, location: "Filby", name: "Test Regatta")
    context.insert(regatta)
    
    // Create 9 Races with all skippers
    for i in 1...9 {
        // Exclude Neil Johnson (DNS in Race 1) and Ivy King (DNF in Race 2) from finishing positions
        var raceSkippers = skippers.shuffled()
        if i == 1 {
            raceSkippers.removeAll { $0.sailNumber == "01" } // Exclude Neil Johnson
        }
        if i == 2 {
            raceSkippers.removeAll { $0.sailNumber == "110" } // Exclude Ivy King
        }
        let race = Race(finishingPositions: raceSkippers)
        race.event = regatta
        regatta.races.append(race)
        context.insert(race)
        // Mark some boats as DNS/DNF for testing
        if i == 1 {
            race.setStatus(.dns, for: skippers[0]) // Neil Johnson DNS in Race 1
        }
        if i == 2 {
            race.setStatus(.dnf, for: skippers[1]) // Ivy King DNF in Race 2
        }
    }
    
    do {
        try context.save()
        print("Successfully loaded test data for ScoresView preview")
    } catch {
        print("Failed to load test data for ScoresView preview: \(error)")
    }
    
    return ScoresView()
        .modelContainer(container)
}
