// RegattaListView.swift
// RegattaManager
//
// Created by Neil Fulcher on 15/04/2025.
//

import SwiftUI
import SwiftData

struct RegattaListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RaceEvent.date, order: .reverse) private var events: [RaceEvent]
    @State private var showingAddEventSheet = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(events) { event in
                    NavigationLink(destination: RegattaDetailView(event: event)) {
                        VStack(alignment: .leading) {
                            Text(event.name.isEmpty ? "Unnamed Regatta" : event.name)
                                .font(StyleGuide.titleFont)
                                .foregroundColor(StyleGuide.textColor)
                            Text("Location: \(event.location.isEmpty ? "Unknown" : event.location)")
                                .font(StyleGuide.bodyFont)
                                .foregroundColor(StyleGuide.secondaryTextColor)
                            Text("Date: \(event.date, style: .date)")
                                .font(StyleGuide.captionFont)
                                .foregroundColor(StyleGuide.secondaryTextColor)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(StyleGuide.sailWhite)
                        )
                        .padding(.vertical, 2)
                        .accessibilityLabel("\(event.name.isEmpty ? "Unnamed Regatta" : event.name), Location: \(event.location.isEmpty ? "Unknown" : event.location), Date: \(event.date, style: .date)")
                        .accessibilityHint("Tap to view regatta details")
                        .transition(.opacity) // Fade-in animation for list items
                    }
                }
                .onDelete { indexSet in
                    withAnimation {
                        indexSet.forEach { index in
                            let event = events[index]
                            modelContext.delete(event)
                        }
                        do {
                            try modelContext.save()
                        } catch {
                            print("Failed to delete event: \(error)")
                        }
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        // Swipe action handled in onDelete
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Regattas")
            .navigationBarItems(trailing: Button(action: {
                showingAddEventSheet = true
            }) {
                Image(systemName: "plus")
                    .foregroundColor(StyleGuide.nauticalBlueAccent) // Updated to nautical blue
            }
            .accessibilityLabel("Add new regatta"))
            .sheet(isPresented: $showingAddEventSheet) {
                AddEventView()
            }
            .background(StyleGuide.nauticalGradient)
            .animation(.easeInOut, value: showingAddEventSheet) // Sheet animation
        }
    }
}

struct AddEventView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var name: String = ""
    @State private var location: String = ""
    @State private var date: Date = Date()

    var body: some View {
        NavigationStack {
            Form {
                TextField("Regatta Name", text: $name)
                    .font(StyleGuide.bodyFont)
                    .accessibilityLabel("Regatta name")
                TextField("Location", text: $location)
                    .font(StyleGuide.bodyFont)
                    .accessibilityLabel("Regatta location")
                DatePicker("Date", selection: $date, displayedComponents: .date)
                    .font(StyleGuide.bodyFont)
                    .accessibilityLabel("Regatta date")
            }
            .background(StyleGuide.sailWhite)
            .navigationTitle("Add Regatta")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
                .font(StyleGuide.bodyFont)
                .foregroundColor(StyleGuide.nauticalBlueAccent) // Updated to nautical blue
                .accessibilityLabel("Cancel adding regatta"),
                trailing: Button("Save") {
                    let newEvent = RaceEvent(date: date, location: location, name: name)
                    modelContext.insert(newEvent)
                    do {
                        try modelContext.save()
                    } catch {
                        print("Failed to save event: \(error)")
                    }
                    dismiss()
                }
                .font(StyleGuide.bodyFont)
                .foregroundColor(StyleGuide.nauticalBlueAccent) // Updated to nautical blue
                .disabled(name.isEmpty || location.isEmpty)
                .accessibilityLabel("Save regatta")
            )
            .background(StyleGuide.nauticalGradient)
        }
    }
}

#Preview {
    let schema = Schema([RaceEvent.self, Skipper.self, Race.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: RaceEvent.self, Skipper.self, Race.self, configurations: config)
    
    return RegattaListView()
        .modelContainer(container)
}
