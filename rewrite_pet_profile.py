import os

screen_path = "/Users/max_ladmin/Desktop/antigravity_pawmento/pawmento/PawMento/Views/PetProfile/PetProfileScreen.swift"
comp_path = "/Users/max_ladmin/Desktop/antigravity_pawmento/pawmento/PawMento/Views/PetProfile/Components/PetProfileComponents.swift"

# 1. PetProfileScreen.swift
with open(screen_path, 'r') as f:
    screen_content = f.read()

screen_content = screen_content.replace(".background(Color.warmCream.ignoresSafeArea())", ".background(Color.background.ignoresSafeArea())")

with open(screen_path, 'w') as f:
    f.write(screen_content)

# 2. PetProfileComponents.swift
with open(comp_path, 'r') as f:
    comp_content = f.read()

# TopBar
comp_content = comp_content.replace(".background(Color.cream)", ".background(\n            Color.surfaceContainerLowest.opacity(0.8)\n                .background(.ultraThinMaterial)\n        )")

# HeroCardView
old_hero_photo = """                .shadow(color: viewModel.wellnessScore >= 80 ? Color.primary.opacity(0.4) : Color.clear, radius: 10, x: 0, y: 0)"""
new_hero_photo = """                .shadow(color: viewModel.wellnessScore >= 80 ? Color.primary.opacity(0.4) : Color.clear, radius: 16, x: 0, y: 8)"""
comp_content = comp_content.replace(old_hero_photo, new_hero_photo)

old_hero_name = """                    Text(pet.name)
                        .font(.headlineMD)
                        .foregroundColor(.primaryText)"""
new_hero_name = """                    Text(pet.name)
                        .font(.title2.weight(.bold))
                        .foregroundColor(.primaryText)"""
comp_content = comp_content.replace(old_hero_name, new_hero_name)

old_ring = """                    Circle()
                        .trim(from: 0, to: CGFloat(viewModel.wellnessScore) / 100.0)
                        .stroke(ringColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))"""
new_ring = """                    Circle()
                        .trim(from: 0, to: CGFloat(viewModel.wellnessScore) / 100.0)
                        .stroke(LinearGradient(colors: [ringColor, ringColor.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing), style: StrokeStyle(lineWidth: 10, lineCap: .round))"""
comp_content = comp_content.replace(old_ring, new_ring)

old_ring_bg = """                    Circle()
                        .stroke(Color.warmSand, lineWidth: 8)"""
new_ring_bg = """                    Circle()
                        .stroke(Color.primary.opacity(0.05), lineWidth: 10)"""
comp_content = comp_content.replace(old_ring_bg, new_ring_bg)


# AICoachCardView
old_ai_coach_premium = """                    Text("Premium 🔒")
                        .font(.captionTabular)
                        .foregroundColor(.primary)"""
new_ai_coach_premium = """                    Text("Premium 🔒")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(LinearGradient(colors: [Color.primary, Color.primary.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .clipShape(Capsule())"""
comp_content = comp_content.replace(old_ai_coach_premium, new_ai_coach_premium)

old_ai_ask = """            Button(action: { showCoach = true }) {
                Text("Ask the Coach about \\(pet.name) →")
                    .font(.bodyS)
                    .foregroundColor(.primary)
            }"""
new_ai_ask = """            Button(action: { showCoach = true }) {
                HStack {
                    Text("Ask the Coach about \\(pet.name)")
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .font(.labelSemibold)
                .foregroundColor(.white)
                .padding()
                .background(Color.primary)
                .cornerRadius(16)
            }
            .buttonStyle(SquishyCardStyle())"""
comp_content = comp_content.replace(old_ai_ask, new_ai_ask)

old_ai_bg = """        .background(Color.cream)
        .cornerRadius(AppRadius.card)"""
new_ai_bg = """        .background(Color.surfaceContainerLowest)
        .cornerRadius(AppRadius.card)
        .overlay(RoundedRectangle(cornerRadius: AppRadius.card).stroke(LinearGradient(colors: [Color.primary.opacity(0.3), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1))
        .shadow(color: Color.primary.opacity(0.05), radius: 10, x: 0, y: 4)"""
comp_content = comp_content.replace(old_ai_bg, new_ai_bg)


# VetPDFCTACard
old_vet_card = """            .background(Color.cream)
            .cornerRadius(AppRadius.card)
        }
        .alert"""
new_vet_card = """            .background(Color.surfaceContainerLowest)
            .cornerRadius(AppRadius.card)
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(SquishyCardStyle())
        .alert"""
comp_content = comp_content.replace(old_vet_card, new_vet_card)

# MedicationsCard logged today pill
old_med_logged = """                                    Text("Logged today · \\(med.streakCount) day streak ✓")
                                        .font(.captionTabular)
                                        .foregroundColor(.primary)"""
new_med_logged = """                                    Text("Logged today · \\(med.streakCount) day streak ✓")
                                        .font(.caption.weight(.bold))
                                        .foregroundColor(.primary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.primary.opacity(0.1))
                                        .clipShape(Capsule())"""
comp_content = comp_content.replace(old_med_logged, new_med_logged)

# ArchiveButton
old_archive = """                .frame(height: 52)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.error, lineWidth: 1))
        }
        .disabled"""
new_archive = """                .frame(height: 52)
                .background(Color.error.opacity(0.1))
                .cornerRadius(16)
        }
        .buttonStyle(SquishyCardStyle())
        .disabled"""
comp_content = comp_content.replace(old_archive, new_archive)


with open(comp_path, 'w') as f:
    f.write(comp_content)

print("PetProfile components updated.")
