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
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(petStore)
                .environmentObject(authManager)
                .environmentObject(coachViewModel)
        }
    }
}
