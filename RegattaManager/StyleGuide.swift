// StyleGuide.swift
// RegattaManager
//
// Created by Neil Fulcher on 15/04/2025.
//

import SwiftUI

enum StyleGuide {
    // Colors
    static let oceanBlue = Color.blue.opacity(0.7)
    static let sailWhite = Color.white.opacity(0.9)
    static let textColor = Color.black
    static let secondaryTextColor = Color.gray
    static let nauticalBlueAccent = Color.blue.opacity(0.5) // New nautical blue accent

    // Gradients
    static let nauticalGradient = LinearGradient(
        gradient: Gradient(colors: [oceanBlue.opacity(0.3), sailWhite]),
        startPoint: .top,
        endPoint: .bottom
    )
    static let buttonGradient = LinearGradient(
        gradient: Gradient(colors: [oceanBlue, oceanBlue.opacity(0.6)]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Fonts
    static let titleFont = Font.system(size: 24, weight: .bold, design: .default)
    static let headlineFont = Font.system(size: 18, weight: .semibold, design: .default)
    static let bodyFont = Font.system(size: 16, weight: .regular, design: .default)
    static let captionFont = Font.system(size: 14, weight: .regular, design: .default)
}
