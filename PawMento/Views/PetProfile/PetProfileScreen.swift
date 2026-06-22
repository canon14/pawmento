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
                        Text("No pet selected")
                            .padding(.top, 40)
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
