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

struct SkipperTile: View {
    let skipper: Skipper
    let position: Int?
    let status: String?
    let onTap: () -> Void
    
    init(skipper: Skipper, position: Int? = nil, status: String? = nil, onTap: @escaping () -> Void) {
        self.skipper = skipper
        self.position = position
        self.status = status
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: onTap) {
            Text(displayText)
                .font(StyleGuide.bodyFont)
                .bold()
                .foregroundColor(StyleGuide.textColor)
                .frame(minWidth: 60, minHeight: 60)
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Tap to move this boat back to unfinished")
    }
    
    private var displayText: String {
        if let position = position {
            return "\(skipper.sailNumber) (\(positionSuffix(for: position)))"
        } else if let status = status {
            return "\(skipper.sailNumber) (\(status))"
        } else {
            return skipper.sailNumber
        }
    }
    
    private var backgroundColor: Color {
        if status == "DNS" {
            return Color.gray.opacity(0.1)
        } else if status == "DNF" {
            return Color.orange.opacity(0.1)
        } else {
            return Color.green.opacity(0.1)
        }
    }
    
    private var accessibilityLabel: String {
        if let position = position {
            return "Position \(positionSuffix(for: position)), Sail number \(skipper.sailNumber)"
        } else if let status = status {
            return "Sail number \(skipper.sailNumber), marked as \(status)"
        } else {
            return "Sail number \(skipper.sailNumber)"
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

struct SkipperDropDelegate: DropDelegate {
    let skipper: Skipper
    @Binding var finishers: [Skipper]
    @Binding var draggedSkipper: Skipper?
    
    func performDrop(info: DropInfo) -> Bool {
        guard let draggedSkipper = draggedSkipper,
              draggedSkipper.id != skipper.id,
              let fromIndex = finishers.firstIndex(where: { $0.id == draggedSkipper.id }),
              let toIndex = finishers.firstIndex(where: { $0.id == skipper.id }) else {
            print("Drop failed: draggedSkipper=\(draggedSkipper?.sailNumber ?? "nil"), skipper=\(skipper.sailNumber)")
            return false
        }
        
        print("Dropping \(draggedSkipper.sailNumber) from index \(fromIndex) to index \(toIndex)")
        finishers.remove(at: fromIndex)
        finishers.insert(draggedSkipper, at: toIndex)
        self.draggedSkipper = nil
        print("New order: \(finishers.map { $0.sailNumber }.joined(separator: ", "))")
        return true
    }
    
    func dropEntered(info: DropInfo) {
        print("Drop entered for skipper \(skipper.sailNumber)")
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        print("Drop updated for skipper \(skipper.sailNumber)")
        return DropProposal(operation: .move)
    }
}

// Extracted Unfinished Boats Section
struct UnfinishedBoatsSection: View {
    let unfinishedSkippers: [Skipper]
    let gridColumns: [GridItem]
    let markAsFinished: (Skipper) -> Void
    let markAsDNS: (Skipper) -> Void
    let markAsDNF: (Skipper) -> Void
    
    var body: some View {
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
    }
}

// Extracted Finishing Positions Section
struct FinishingPositionsSection: View {
    @Binding var finishedSkippers: [Skipper]
    @Binding var unfinishedSkippers: [Skipper]
    @Binding var dnsDnfSkippers: [SkipperStatus]
    @Binding var draggedSkipper: Skipper?
    let gridColumns: [GridItem]
    
    var body: some View {
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
                    LazyVGrid(columns: gridColumns, spacing: 8) {
                        ForEach(finishedSkippers.indices, id: \.self) { index in
                            let skipper = finishedSkippers[index]
                            HStack {
                                SkipperTile(
                                    skipper: skipper,
                                    position: index + 1,
                                    onTap: {
                                        withAnimation {
                                            finishedSkippers.removeAll { $0.id == skipper.id }
                                            unfinishedSkippers.append(skipper)
                                            unfinishedSkippers.sort { $0.sailNumber < $1.sailNumber }
                                        }
                                    }
                                )
                                Image(systemName: "line.3.horizontal")
                                    .foregroundColor(StyleGuide.secondaryTextColor)
                                    .padding(.trailing, 8)
                                    .accessibilityLabel("Drag to reorder")
                            }
                            .onDrag({
                                self.draggedSkipper = skipper
                                return NSItemProvider(object: skipper.id as NSString)
                            }, preview: {
                                SkipperTile(skipper: skipper, position: index + 1, onTap: {})
                                    .opacity(0.8)
                            })
                            .onDrop(of: [.text], delegate: SkipperDropDelegate(
                                skipper: skipper,
                                finishers: $finishedSkippers,
                                draggedSkipper: $draggedSkipper
                            ))
                            .contextMenu {
                                Button(action: {
                                    withAnimation {
                                        finishedSkippers.removeAll { $0.id == skipper.id }
                                        dnsDnfSkippers.append(SkipperStatus(skipper: skipper, status: .dns))
                                    }
                                }) {
                                    Text("Mark as DNS")
                                }
                                Button(action: {
                                    withAnimation {
                                        finishedSkippers.removeAll { $0.id == skipper.id }
                                        dnsDnfSkippers.append(SkipperStatus(skipper: skipper, status: .dnf))
                                    }
                                }) {
                                    Text("Mark as DNF")
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
        }
    }
}

// Extracted DNS/DNF Boats Section
struct DNSDNFBoatsSection: View {
    @Binding var dnsDnfSkippers: [SkipperStatus]
    @Binding var unfinishedSkippers: [Skipper]
    @Binding var finishedSkippers: [Skipper]
    let gridColumns: [GridItem]
    
    var body: some View {
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
                    LazyVGrid(columns: gridColumns, spacing: 8) {
                        ForEach(dnsDnfSkippers, id: \.skipper.id) { skipperStatus in
                            let skipper = skipperStatus.skipper
                            let status = skipperStatus.status
                            let tile = SkipperTile(
                                skipper: skipper,
                                status: status.rawValue.uppercased(),
                                onTap: {
                                    withAnimation {
                                        dnsDnfSkippers.removeAll { $0.skipper.id == skipper.id }
                                        unfinishedSkippers.append(skipper)
                                        unfinishedSkippers.sort { $0.sailNumber < $1.sailNumber }
                                    }
                                }
                            )
                            tile
                                .contextMenu {
                                    if status != .dns {
                                        Button(action: {
                                            withAnimation {
                                                dnsDnfSkippers.removeAll { $0.skipper.id == skipper.id }
                                                dnsDnfSkippers.append(SkipperStatus(skipper: skipper, status: .dns))
                                            }
                                        }) {
                                            Text("Mark as DNS")
                                        }
                                    }
                                    if status != .dnf {
                                        Button(action: {
                                            withAnimation {
                                                dnsDnfSkippers.removeAll { $0.skipper.id == skipper.id }
                                                dnsDnfSkippers.append(SkipperStatus(skipper: skipper, status: .dnf))
                                            }
                                        }) {
                                            Text("Mark as DNF")
                                        }
                                    }
                                    Button(action: {
                                        withAnimation {
                                            dnsDnfSkippers.removeAll { $0.skipper.id == skipper.id }
                                            finishedSkippers.append(skipper)
                                        }
                                    }) {
                                        Text("Mark as Finished")
                                    }
                                }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
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
    @State private var draggedSkipper: Skipper?
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
                UnfinishedBoatsSection(
                    unfinishedSkippers: unfinishedSkippers,
                    gridColumns: gridColumns,
                    markAsFinished: markAsFinished,
                    markAsDNS: markAsDNS,
                    markAsDNF: markAsDNF
                )
                
                FinishingPositionsSection(
                    finishedSkippers: $finishedSkippers,
                    unfinishedSkippers: $unfinishedSkippers,
                    dnsDnfSkippers: $dnsDnfSkippers,
                    draggedSkipper: $draggedSkipper,
                    gridColumns: gridColumns
                )
                
                DNSDNFBoatsSection(
                    dnsDnfSkippers: $dnsDnfSkippers,
                    unfinishedSkippers: $unfinishedSkippers,
                    finishedSkippers: $finishedSkippers,
                    gridColumns: gridColumns
                )
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
                
                // Reset lists
                finishedSkippers = []
                dnsDnfSkippers = []
                unfinishedSkippers = []
                
                // First, categorize skippers that have recorded positions
                for skipper in currentFinishingPositions {
                    let status = race.getStatus(for: skipper)
                    if status == .finished {
                        finishedSkippers.append(skipper)
                    } else {
                        dnsDnfSkippers.append(SkipperStatus(skipper: skipper, status: status))
                    }
                }
                
                // Then, add skippers that are not in the finishing positions to unfinished
                unfinishedSkippers = allSkippers.filter { skipper in
                    !currentFinishingPositions.contains { $0.id == skipper.id }
                }
                
                // Sort for consistent display
                finishedSkippers.sort { $0.sailNumber < $1.sailNumber }
                dnsDnfSkippers.sort { $0.skipper.sailNumber < $1.skipper.sailNumber }
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
        Skipper(id: UUID().uuidString, name: "Frank Walker", sailNumber: "107"),
        Skipper(id: UUID().uuidString, name: "Charlie Harris", sailNumber: "104"),
        Skipper(id: UUID().uuidString, name: "Eve Lewis", sailNumber: "106")
    ]
    
    skippers.forEach { context.insert($0) }
    
    // Create a Race with some initial finishing positions
    let race = Race(finishingPositions: skippers)
    race.setStatus(.dns, for: skippers[4])
    race.setStatus(.dnf, for: skippers[5])
    
    return NavigationStack {
        EditRaceView(race: race) { _ in }
            .modelContainer(container)
    }
}
