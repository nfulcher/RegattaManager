// ContentView.swift
// RegattaManager
//
// Created by Neil Fulcher on 15/04/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject private var clearDataManager: ClearDataManager
    @State private var showDebugButtons = false

    var body: some View {
        TabView {
            RegattaListView()
                .tabItem {
                    Label("Regattas", systemImage: "sailboat")
                        .foregroundColor(StyleGuide.nauticalBlueAccent)
                }
            
            SkipperManagementView()
                .tabItem {
                    Label("Skippers", systemImage: "person.2")
                        .foregroundColor(StyleGuide.nauticalBlueAccent)
                }
            
            ScoresView()
                .tabItem {
                    Label("Scores", systemImage: "list.number")
                        .foregroundColor(StyleGuide.nauticalBlueAccent)
                }
        }
        .accentColor(StyleGuide.nauticalBlueAccent)
        .overlay(
            Group {
                if showDebugButtons {
                    VStack(spacing: 10) {
                        Button(action: {
                            clearDataManager.clearData()
                            prepopulateTestData()
                        }) {
                            Text("Load Test Data")
                                .font(StyleGuide.bodyFont)
                                .padding()
                                .background(StyleGuide.buttonGradient)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .accessibilityLabel("Load test data")
                        .accessibilityHint("Clears existing data and loads predefined test data")
                        
                        Button(action: {
                            clearDataManager.clearData()
                        }) {
                            Text("Clear Data")
                                .font(StyleGuide.bodyFont)
                                .padding()
                                .background(StyleGuide.buttonGradient)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .accessibilityLabel("Clear all app data")
                        .accessibilityHint("Deletes all regattas, skippers, and races")
                    }
                    .padding(.bottom, 60) // Adjusted to avoid tab bar
                    .padding(.trailing)
                    .transition(.opacity) // Fade-in/out animation for debug buttons
                }
            },
            alignment: .bottomTrailing
        )
        .background(StyleGuide.nauticalGradient)
        .gesture(
            LongPressGesture(minimumDuration: 2)
                .onEnded { _ in
                    withAnimation {
                        showDebugButtons.toggle()
                    }
                }
        )
        .accessibilityLabel("Long press to toggle debug buttons")
    }
    
    @MainActor
    private func prepopulateTestData() {
        let context = clearDataManager.modelContainer.mainContext
        
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
        
        // Create 11 Races with all 15 skippers
        for i in 1...11 {
            let race = Race(finishingPositions: skippers.shuffled())
            race.event = regatta
            regatta.races.append(race)
            context.insert(race)
        }
        
        do {
            try context.save()
            print("Successfully loaded test data via button")
        } catch {
            print("Failed to load test data via button: \(error)")
        }
    }
}

struct SkipperManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Skipper.name, order: .forward) private var skippers: [Skipper]
    @State private var showingAddSkipperSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if skippers.isEmpty {
                    Text("No skippers available")
                        .font(StyleGuide.headlineFont)
                        .foregroundColor(StyleGuide.secondaryTextColor)
                        .padding()
                        .accessibilityLabel("No skippers available")
                } else {
                    List {
                        ForEach(skippers) { skipper in
                            HStack {
                                Text(skipper.name)
                                    .font(StyleGuide.bodyFont)
                                    .foregroundColor(StyleGuide.textColor)
                                Spacer()
                                Text("Sail: \(skipper.sailNumber)")
                                    .font(StyleGuide.captionFont)
                                    .foregroundColor(StyleGuide.secondaryTextColor)
                            }
                            .padding(.vertical, 4) // Reduced padding for less white space
                            .padding(.horizontal, 8)
                            .accessibilityLabel("Skipper: \(skipper.name), Sail Number: \(skipper.sailNumber)")
                            .accessibilityHint("Swipe to delete")
                            .transition(.opacity) // Fade-in animation for list items
                        }
                        .onDelete { indexSet in
                            withAnimation {
                                indexSet.forEach { index in
                                    let skipper = skippers[index]
                                    modelContext.delete(skipper)
                                }
                                do {
                                    try modelContext.save()
                                    print("Deleted skipper, remaining skippers: \(skippers.map { $0.name })")
                                } catch {
                                    print("Failed to delete skipper: \(error)")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Skippers")
            .navigationBarItems(trailing: Button(action: {
                showingAddSkipperSheet = true
            }) {
                Image(systemName: "plus")
                    .foregroundColor(StyleGuide.nauticalBlueAccent)
            }
            .accessibilityLabel("Add new skipper"))
            .sheet(isPresented: $showingAddSkipperSheet) {
                AddSkipperView()
            }
            .background(StyleGuide.nauticalGradient)
            .animation(.easeInOut, value: showingAddSkipperSheet) // Sheet animation
        }
        .onAppear {
            print("SkipperManagementView appeared with \(skippers.count) skippers: \(skippers.map { $0.name })")
        }
    }
}

struct AddSkipperView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var name: String = ""
    @State private var sailNumber: String = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                    .font(StyleGuide.bodyFont)
                    .accessibilityLabel("Skipper name")
                TextField("Sail Number", text: $sailNumber)
                    .font(StyleGuide.bodyFont)
                    .accessibilityLabel("Sail number")
            }
            .background(StyleGuide.sailWhite)
            .navigationTitle("Add Skipper")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
                .font(StyleGuide.bodyFont)
                .foregroundColor(StyleGuide.nauticalBlueAccent)
                .accessibilityLabel("Cancel adding skipper"),
                trailing: Button("Save") {
                    let newSkipper = Skipper(id: UUID().uuidString, name: name, sailNumber: sailNumber)
                    modelContext.insert(newSkipper)
                    do {
                        try modelContext.save()
                        print("Saved new skipper: \(newSkipper.name)")
                    } catch {
                        print("Failed to save skipper: \(error)")
                    }
                    dismiss()
                }
                .font(StyleGuide.bodyFont)
                .foregroundColor(StyleGuide.nauticalBlueAccent)
                .disabled(name.isEmpty || sailNumber.isEmpty)
                .accessibilityLabel("Save skipper")
            )
            .background(StyleGuide.nauticalGradient)
        }
    }
}

#Preview {
    let schema = Schema([RaceEvent.self, Skipper.self, Race.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: RaceEvent.self, Skipper.self, Race.self, configurations: config)
    
    return ContentView()
        .modelContainer(container)
        .environmentObject(ClearDataManager(modelContainer: container))
}
