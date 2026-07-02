//
//  PawMentoApp.swift
//  PawMento
//
//  Created by max_ladmin on 5/23/26.
//

import SwiftUI

@main
struct PawMentoApp: App {
    @StateObject private var petStore = PetStore()
    @StateObject private var authManager = AuthManager()
    @StateObject private var coachViewModel = CoachViewModel()
    @StateObject private var logStore = LogStore()
    @StateObject private var medicationStore = MedicationStore()
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var toastManager = ToastManager.shared
    
    init() {
        // Initialize early to ensure UNUserNotificationCenter delegate is registered
        _ = NotificationManager.shared
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(petStore)
                .environmentObject(authManager)
                .environmentObject(coachViewModel)
                .environmentObject(logStore)
                .environmentObject(medicationStore)
                .environmentObject(subscriptionManager)
                .environmentObject(toastManager)
        }

    }
}
