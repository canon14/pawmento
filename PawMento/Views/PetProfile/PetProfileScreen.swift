import SwiftUI

struct PetProfileScreen: View {
    @EnvironmentObject var petStore: PetStore
    @EnvironmentObject var logStore: LogStore
    @EnvironmentObject var medicationStore: MedicationStore
    @StateObject private var viewModel = PetProfileViewModel()
    
    // Top app bar components
    var body: some View {
        VStack(spacing: 0) {
            // Top App Bar
            PetProfileTopBar(petName: petStore.activePet?.name ?? "Pets")
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    if let pet = petStore.activePet {
                        HeroCardView(pet: pet, viewModel: viewModel)
                        
                        AICoachCardView(pet: pet, viewModel: viewModel)
                        
                        HealthStatsSection()
                        
                        RecentActivityPreview(logs: logStore.logs, petName: pet.name)
                        
                        CareTeamCard()
                        
                        // Vet PDF CTA
                        VetPDFCTACard(logCount: logStore.logs.count)
                        
                        MedicationsCard(medications: viewModel.medications)
                        
                        VitalRecordsList()
                        
                        ArchiveButton(pet: pet)
                    } else {
                        // Empty state (🟡 11.1 — was plain text)
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                                    .frame(width: 100, height: 100)
                                
                                Circle()
                                    .fill(Color.primary.opacity(0.1))
                                    .frame(width: 72, height: 72)
                                
                                Image(systemName: "pawprint.fill")
                                    .font(.system(size: 28, weight: .medium))
                                    .foregroundColor(.primary)
                            }
                            .padding(.bottom, 4)
                            
                            Text("No pet selected")
                                .font(.headlineMD)
                                .foregroundColor(.primaryText)
                            
                            Text("Select a pet from the tab bar or add your first pet to get started.")
                                .font(.bodyMD)
                                .foregroundColor(.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .padding(.vertical, 80)
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 120) // Extra padding for bottom nav
            }
            .refreshable {
                if let pet = petStore.activePet {
                    await medicationStore.fetchMedications(for: pet.id)
                    await viewModel.refreshProfile(for: pet, logs: logStore.logs, fetchedMedications: medicationStore.medications, forceRefresh: true)
                }
            }
        }
        .background(Color.background.ignoresSafeArea())
        .onAppear {
            if let pet = petStore.activePet {
                Task {
                    await medicationStore.fetchMedications(for: pet.id)
                    await viewModel.refreshProfile(for: pet, logs: logStore.logs, fetchedMedications: medicationStore.medications)
                }
            }
        }
    }
}
