import SwiftUI

struct OnboardingCarouselView: View {
    @EnvironmentObject var authManager: AuthManager
    
    @State private var currentIndex = 0
    @State private var showingSkipConfirmation = false
    @State private var showingAddPetSheet = false
    
    var body: some View {
        ZStack {
            Color.warmCream.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with Skip Button
                HStack {
                    Spacer()
                    Button(action: {
                        showingSkipConfirmation = true
                    }) {
                        Text("Skip")
                            .font(.skipOnboarding)
                            .foregroundColor(.tertiaryText)
                    }
                    .padding(.top, 20)
                    .padding(.trailing, 20)
                }
                
                // Carousel
                TabView(selection: $currentIndex) {
                    OnboardingSlideView(
                        illustration: Slide1Illustration(),
                        headline: "Notice the\nlittle things.",
                        bodyText: "Pets can't tell us when something feels off. PawMento helps you catch it before it becomes a problem."
                    ).tag(0)
                    
                    OnboardingSlideView(
                        illustration: Slide2Illustration(),
                        headline: "Log anything\nin under 10 seconds.",
                        bodyText: "Snap a photo. Pick a tag. Done. No forms. No typing. No friction."
                    ).tag(1)
                    
                    OnboardingSlideView(
                        illustration: Slide3Illustration(),
                        headline: "Patterns your vet\nwill want to see.",
                        bodyText: "PawMento connects your logs into insights — and formats them into a report your vet can actually use."
                    ).tag(2)
                    
                    OnboardingSlideView(
                        illustration: Slide4Illustration(),
                        headline: "Your pet deserves\nthis kind of care.",
                        bodyText: "Take 30 seconds to set up your pet's profile. Everything else follows from there."
                    ).tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: currentIndex)
                
                // Footer (Dots + CTA)
                VStack(spacing: 24) {
                    // Custom Progress Dots
                    HStack(spacing: 8) {
                        ForEach(0..<4) { index in
                            Circle()
                                .fill(Color.primary.opacity(currentIndex == index ? 1.0 : 0.2))
                                .frame(width: currentIndex == index ? 8 : 6, height: currentIndex == index ? 8 : 6)
                                .animation(.easeInOut(duration: 0.2), value: currentIndex)
                                .onTapGesture {
                                    withAnimation {
                                        currentIndex = index
                                    }
                                }
                        }
                    }
                    
                    // Primary CTA
                    Button(action: {
                        if currentIndex < 3 {
                            withAnimation {
                                currentIndex += 1
                            }
                        } else {
                            // Show Add Pet Sheet
                            showingAddPetSheet = true
                        }
                    }) {
                        Text(currentIndex == 3 ? "Get started" : "Continue")
                            .font(.ctaOnboarding)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.primary)
                            .cornerRadius(14)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
        }
        .confirmationDialog("Skip onboarding?", isPresented: $showingSkipConfirmation, titleVisibility: .visible) {
            Button("Skip — I know what I'm doing", role: .destructive) {
                showingAddPetSheet = true
            }
            Button("Keep going — almost there", role: .cancel) { }
        }
        .sheet(isPresented: $showingAddPetSheet) {
            AddFirstPetScreen {
                Task {
                    await authManager.completeOnboarding()
                }
            }
        }
    }
}

#Preview {
    OnboardingCarouselView()
}
