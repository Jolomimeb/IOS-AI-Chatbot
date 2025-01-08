//
//  MebAssistantIOSApp.swift
//  MebAssistantIOS
//
//  Created by Jolomi Mebaghanje on 1/1/25.
//

import SwiftUI
import Firebase

@main
struct MebAssistantIOSApp: App {
    @StateObject var authManager = AuthenticationManager()

    init() {
        // Configure Firebase as soon as the app starts
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
        }
    }
}

