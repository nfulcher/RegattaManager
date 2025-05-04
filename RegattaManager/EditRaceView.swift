// EditRaceView.swift
// RegattaManager
//
// Created by Neil Fulcher on 18/04/2025.
//

import SwiftUI
import SwiftData

struct SkipperStatus {
    let skipper: Skipper
    let status: RaceStatus
}

struct UnfinishedBoatTile: View {
    let skipper: Skipper
    let onFinish: () -> Void
    let onMarkDNS: () -> Void
    let onMarkDNF: () -> Void
    
    var body: some View {
        Button(action: onFinish) {
            Text(skipper.sailNumber)
                .font(StyleGuide.bodyFont)
                .bold()
                .foregroundColor(StyleGuide.textColor)
                .frame(minWidth: 60, minHeight: 60)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .contextMenu {
            contextMenuContent()
        }
        .accessibilityLabel("Sail number \(skipper.sailNumber), yet to finish")
        .accessibilityHint("Tap to mark this boat as finished, or long press to mark as DNS or DNF")
    }
    
    @ViewBuilder
    private func contextMenuContent() -> some View {
        Button(action: onMarkDNS) {
            Text("Mark as DNS")
        }
        Button(action: onMarkDNF) {
            Text("Mark as DNF")
        }
    }
}

struct EditRaceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Skipper.name, order: .forward) private var allSkippers: [Skipper]
    
    @State private var unfinishedSkippers: [Skipper] = []
    @State private var finishedSkippers: [Skipper] = []
    @State private var dnsDnfSkippers: [SkipperStatus] = []
    let race: Race
    let onSave: ([Skipper]) -> Void
    
    private let gridColumns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    private var canSave: Bool {
        unfinishedSkippers.isEmpty // All boats must be either finished or DNS/DNF
    }
    
    init(race: Race, onSave: @escaping ([Skipper]) -> Void) {
        self.race = race
        self.onSave = onSave
    }
    
    // Extracted action methods
    private func markAsFinished(_ skipper: Skipper) {
        withAnimation {
            unfinishedSkippers.removeAll { $0.id == skipper.id }
            finishedSkippers.append(skipper)
        }
    }
    
    private func markAsDNS(_ skipper: Skipper) {
        withAnimation {
            unfinishedSkippers.removeAll { $0.id == skipper.id }
            dnsDnfSkippers.append(SkipperStatus(skipper: skipper, status: .dns))
        }
    }
    
    private func markAsDNF(_ skipper: Skipper) {
        withAnimation {
            unfinishedSkippers.removeAll { $0.id == skipper.id }
            dnsDnfSkippers.append(SkipperStatus(skipper: skipper, status: .dnf))
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Unfinished Boats Section
                VStack(alignment: .leading) {
                    Text("Boats Yet to Finish")
                        .font(StyleGuide.headlineFont)
                        .foregroundColor(StyleGuide.textColor)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    if unfinishedSkippers.isEmpty {
                        Text("All boats have finished or are marked as DNS/DNF")
                            .font(StyleGuide.bodyFont)
                            .foregroundColor(StyleGuide.secondaryTextColor)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        ScrollView {
                            LazyVGrid(columns: gridColumns, spacing: 8) {
                                ForEach(unfinishedSkippers, id: \.id) { skipper in
                                    UnfinishedBoatTile(
                                        skipper: skipper,
                                        onFinish: { markAsFinished(skipper) },
                                        onMarkDNS: { markAsDNS(skipper) },
                                        onMarkDNF: { markAsDNF(skipper) }
                                    )
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom)
                        }
                    }
                }
                
                // Finishing Positions Section
                VStack(alignment: .leading) {
                    Text("Finishing Positions")
                        .font(StyleGuide.headlineFont)
                        .foregroundColor(StyleGuide.textColor)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    if finishedSkippers.isEmpty {
                        Text("No boats have finished yet")
                            .font(StyleGuide.bodyFont)
                            .foregroundColor(StyleGuide.secondaryTextColor)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        ScrollView {
                            VStack(spacing: 8) {
                                ForEach(finishedSkippers.indices, id: \.self) { index in
                                    let skipper = finishedSkippers[index]
                                    Button(action: {
                                        withAnimation {
                                            finishedSkippers.removeAll { $0.id == skipper.id }
                                            unfinishedSkippers.append(skipper)
                                            unfinishedSkippers.sort { $0.sailNumber < $1.sailNumber }
                                        }
                                    }) {
                                        HStack {
                                            Text("\(positionSuffix(for: index + 1)): \(skipper.sailNumber)")
                                                .font(StyleGuide.bodyFont)
                                                .foregroundColor(StyleGuide.textColor)
                                            Spacer()
                                        }
                                        .padding()
                                        .background(Color.green.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    .accessibilityLabel("Position \(positionSuffix(for: index + 1)), Sail number \(skipper.sailNumber)")
                                    .accessibilityHint("Tap to move this boat back to unfinished")
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom)
                        }
                    }
                }
                
                // DNS/DNF Boats Section
                VStack(alignment: .leading) {
                    Text("DNS/DNF Boats")
                        .font(StyleGuide.headlineFont)
                        .foregroundColor(StyleGuide.textColor)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    if dnsDnfSkippers.isEmpty {
                        Text("No boats marked as DNS or DNF")
                            .font(StyleGuide.bodyFont)
                            .foregroundColor(StyleGuide.secondaryTextColor)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        ScrollView {
                            VStack(spacing: 8) {
                                ForEach(dnsDnfSkippers, id: \.skipper.id) { skipperStatus in
                                    let skipper = skipperStatus.skipper
                                    let status = skipperStatus.status
                                    Button(action: {
                                        withAnimation {
                                            dnsDnfSkippers.removeAll { $0.skipper.id == skipper.id }
                                            unfinishedSkippers.append(skipper)
                                            unfinishedSkippers.sort { $0.sailNumber < $1.sailNumber }
                                        }
                                    }) {
                                        HStack {
                                            Text("\(skipper.sailNumber): \(status.rawValue.uppercased())")
                                                .font(StyleGuide.bodyFont)
                                                .foregroundColor(StyleGuide.textColor)
                                            Spacer()
                                        }
                                        .padding()
                                        .background(Color.orange.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    .accessibilityLabel("Sail number \(skipper.sailNumber), marked as \(status.rawValue.uppercased())")
                                    .accessibilityHint("Tap to move this boat back to unfinished")
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom)
                        }
                    }
                }
            }
            .background(StyleGuide.nauticalGradient)
            .navigationTitle("Record Race Finishes")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(StyleGuide.nauticalBlueAccent)
                    .accessibilityLabel("Cancel editing race")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        // Set DNS/DNF statuses in the Race object
                        for skipperStatus in dnsDnfSkippers {
                            race.setStatus(skipperStatus.status, for: skipperStatus.skipper)
                        }
                        // Combine finished skippers and DNS/DNF skippers for saving
                        let allSkippers = finishedSkippers + dnsDnfSkippers.map { $0.skipper }
                        onSave(allSkippers)
                        dismiss()
                    }
                    .foregroundColor(canSave ? StyleGuide.nauticalBlueAccent : StyleGuide.secondaryTextColor)
                    .disabled(!canSave)
                    .accessibilityLabel("Save race finishes")
                    .accessibilityHint(canSave ? "Tap to save the race results" : "Cannot save until all boats are finished or marked as DNS/DNF")
                }
            }
            .onAppear {
                // Initialize the lists
                let currentFinishingPositions = race.fetchFinishingPositions(using: modelContext)
                finishedSkippers = currentFinishingPositions.filter { race.getStatus(for: $0) == .finished }
                dnsDnfSkippers = currentFinishingPositions.compactMap { skipper in
                    let status = race.getStatus(for: skipper)
                    return status != .finished ? SkipperStatus(skipper: skipper, status: status) : nil
                }
                unfinishedSkippers = allSkippers.filter { skipper in
                    !currentFinishingPositions.contains { $0.id == skipper.id }
                }
                unfinishedSkippers.sort { $0.sailNumber < $1.sailNumber }
            }
        }
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
        Skipper(id: UUID().uuidString, name: "Frank Walker", sailNumber: "107")
    ]
    
    skippers.forEach { context.insert($0) }
    
    // Create a Race with some initial finishing positions
    let race = Race(finishingPositions: [skippers[0], skippers[1]])
    
    return NavigationStack {
        EditRaceView(race: race) { _ in }
            .modelContainer(container)
    }
}
