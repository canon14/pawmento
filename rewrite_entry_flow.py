import os

base_dir = "/Users/max_ladmin/Desktop/antigravity_pawmento/pawmento/PawMento/"

# 1. Theme.swift (PrimaryButtonStyle)
theme_path = os.path.join(base_dir, "App/Theme.swift")
with open(theme_path, 'r') as f:
    theme_content = f.read()

old_primary_btn = """            .background(isEnabled ? Color.primary : Color.primary.opacity(0.4))
            .cornerRadius(AppRadius.input)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)"""
new_primary_btn = """            .background(
                isEnabled ? 
                LinearGradient(colors: [Color.primary, Color.primary.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing) 
                : LinearGradient(colors: [Color.primary.opacity(0.4), Color.primary.opacity(0.4)], startPoint: .top, endPoint: .bottom)
            )
            .cornerRadius(16)
            .shadow(color: isEnabled ? Color.primary.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)"""
theme_content = theme_content.replace(old_primary_btn, new_primary_btn)
with open(theme_path, 'w') as f:
    f.write(theme_content)


# Helper to replace basic inputs
def upgrade_input(path):
    with open(path, 'r') as f:
        content = f.read()
    content = content.replace(".cornerRadius(AppRadius.input)", ".cornerRadius(16)")
    content = content.replace(".stroke(isError ? Color.error : Color.warmSand, lineWidth: isError ? 2 : 1)", ".stroke(isError ? Color.error : Color.primary.opacity(0.05), lineWidth: isError ? 2 : 1)")
    content = content.replace(".stroke(isExpanded ? Color.primary : Color.warmSand, lineWidth: isExpanded ? 2 : 1)", ".stroke(isExpanded ? Color.primary : Color.primary.opacity(0.05), lineWidth: isExpanded ? 2 : 1)")
    content = content.replace(".stroke(Color.warmSand, lineWidth: 1)", ".stroke(Color.primary.opacity(0.05), lineWidth: 1)")
    # Replace overlay corner radius if hardcoded
    content = content.replace("RoundedRectangle(cornerRadius: 12)", "RoundedRectangle(cornerRadius: 16)")
    with open(path, 'w') as f:
        f.write(content)

upgrade_input(os.path.join(base_dir, "Views/Onboarding/FormTextField.swift"))
upgrade_input(os.path.join(base_dir, "Views/Onboarding/FormSecureField.swift"))
upgrade_input(os.path.join(base_dir, "Views/Onboarding/BirthdayPickerField.swift"))
upgrade_input(os.path.join(base_dir, "Views/Onboarding/WeightFieldView.swift"))

# 2. SpeciesSelectorView.swift
species_path = os.path.join(base_dir, "Views/Onboarding/SpeciesSelectorView.swift")
with open(species_path, 'r') as f:
    species_content = f.read()

old_pill = """            .background(isSelected ? Color.primary : Color.surface0)
            .foregroundColor(isSelected ? .white : .primaryText)
            .cornerRadius(AppRadius.input)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color.warmSand, lineWidth: 1)
            )
            .scaleEffect(isSelected ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.08), value: isSelected)
        }"""
new_pill = """            .background(
                isSelected ? 
                LinearGradient(colors: [Color.primary, Color.primary.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing) 
                : LinearGradient(colors: [Color.surface0, Color.surface0], startPoint: .top, endPoint: .bottom)
            )
            .foregroundColor(isSelected ? .white : .primaryText)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.clear : Color.primary.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: isSelected ? Color.primary.opacity(0.3) : Color.black.opacity(0.02), radius: isSelected ? 8 : 4, x: 0, y: isSelected ? 4 : 2)
        }
        .buttonStyle(SquishyCardStyle())"""
species_content = species_content.replace(old_pill, new_pill)
with open(species_path, 'w') as f:
    f.write(species_content)

# 3. LoginScreen.swift
login_path = os.path.join(base_dir, "Core/Authentication/LoginScreen.swift")
with open(login_path, 'r') as f:
    login_content = f.read()
login_content = login_content.replace(".background(Color.warmCream.ignoresSafeArea())", ".background(Color.background.ignoresSafeArea())")
with open(login_path, 'w') as f:
    f.write(login_content)

# 4. OnboardingCarouselView.swift
onboarding_path = os.path.join(base_dir, "Views/Onboarding/OnboardingCarouselView.swift")
with open(onboarding_path, 'r') as f:
    onboarding_content = f.read()
onboarding_content = onboarding_content.replace("Color.warmCream.ignoresSafeArea()", "Color.background.ignoresSafeArea()")
old_cta = """                        Text(currentIndex == 3 ? "Get started" : "Continue")
                            .font(.ctaOnboarding)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.primary)
                            .cornerRadius(AppRadius.input)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)"""
new_cta = """                        Text(currentIndex == 3 ? "Get started" : "Continue")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)"""
onboarding_content = onboarding_content.replace(old_cta, new_cta)
with open(onboarding_path, 'w') as f:
    f.write(onboarding_content)

print("Entry flow updated.")
