// SkipperListView.swift
// RegattaManager
//
// Created by Neil Fulcher on 18/04/2025.
//

import SwiftUI
import SwiftData

struct SkipperListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Skipper.name, order: .forward) private var skippers: [Skipper]
    @State private var selection: Set<Skipper> = []
    var onSave: ([Skipper]) -> Void

    var body: some View {
        NavigationStack {
            if skippers.isEmpty {
                Text("No skippers available")
                    .font(StyleGuide.headlineFont)
                    .foregroundColor(StyleGuide.secondaryTextColor)
                    .padding()
                    .accessibilityLabel("No skippers available")
            } else {
                List {
                    Section(header: Text("Select Skippers")
                                .font(StyleGuide.headlineFont)
                                .foregroundColor(StyleGuide.textColor)) {
                        ForEach(skippers) { skipper in
                            HStack {
                                Text(skipper.name)
                                    .font(StyleGuide.bodyFont)
                                    .foregroundColor(StyleGuide.textColor)
                                Spacer()
                                Text("Sail: \(skipper.sailNumber)")
                                    .font(StyleGuide.captionFont)
                                    .foregroundColor(StyleGuide.secondaryTextColor)
                                if selection.contains(skipper) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(StyleGuide.nauticalBlueAccent) // Updated to nautical blue
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.easeInOut) {
                                    if selection.contains(skipper) {
                                        selection.remove(skipper)
                                    } else {
                                        selection.insert(skipper)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selection.contains(skipper) ? StyleGuide.oceanBlue.opacity(0.1) : StyleGuide.sailWhite)
                            )
                            .padding(.horizontal, 2)
                            .accessibilityLabel("Skipper: \(skipper.name), Sail: \(skipper.sailNumber)")
                            .accessibilityHint(selection.contains(skipper) ? "Selected, tap to deselect" : "Tap to select")
                        }
                    }
                    .headerProminence(.increased)
                }
                .navigationTitle("Select Skippers")
                .navigationBarItems(
                    leading: Button("Cancel") {
                        dismiss()
                    }
                    .font(StyleGuide.bodyFont)
                    .foregroundColor(StyleGuide.nauticalBlueAccent) // Updated to nautical blue
                    .accessibilityLabel("Cancel selecting skippers"),
                    trailing: Button("Save") {
                        onSave(Array(selection))
                        dismiss()
                    }
                    .font(StyleGuide.bodyFont)
                    .foregroundColor(StyleGuide.nauticalBlueAccent) // Updated to nautical blue
                    .disabled(selection.isEmpty)
                    .accessibilityLabel("Save selected skippers")
                )
                .background(StyleGuide.nauticalGradient)
            }
        }
    }
}

#Preview {
    let schema = Schema([RaceEvent.self, Skipper.self, Race.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: RaceEvent.self, Skipper.self, Race.self, configurations: config)
    
    return SkipperListView { _ in }
        .modelContainer(container)
}
