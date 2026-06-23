import os

quick_log_path = "/Users/max_ladmin/Desktop/antigravity_pawmento/pawmento/PawMento/Views/Logging/QuickLogSheetView.swift"
category_path = "/Users/max_ladmin/Desktop/antigravity_pawmento/pawmento/PawMento/Views/Logging/Components/CategoryScrollerView.swift"
photo_note_path = "/Users/max_ladmin/Desktop/antigravity_pawmento/pawmento/PawMento/Views/Logging/Components/PhotoNoteRowView.swift"
severity_path = "/Users/max_ladmin/Desktop/antigravity_pawmento/pawmento/PawMento/Views/Logging/Components/SeveritySliderView.swift"

# 1. QuickLogSheetView.swift
with open(quick_log_path, 'r') as f:
    content = f.read()

# Replace header divider
content = content.replace("""                Divider()
                    .background(Color.warmSand.opacity(0.3))
                    .padding(.top, 16)
                    .padding(.bottom, 16)""", """                // Padding instead of harsh divider
                Color.clear.frame(height: 24)""")

# Replace Sticky CTA Footer
old_footer = """                // Sticky CTA Footer
                VStack(spacing: 12) {
                    Button(action: saveLog) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.trailing, 8)
                            } else if showSuccess {
                                Image(systemName: "checkmark")
                                    .font(.headlineSM)
                            } else {
                                Text(AppStrings.QuickLog.save)
                                    .font(.ctaOnboarding)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            selectedCategory == nil ? Color.primary.opacity(0.4) : Color.primary
                        )
                        .cornerRadius(AppRadius.input)
                        .shadow(color: Color.primary.opacity((selectedCategory == nil || !hasContent) ? 0 : 0.2), radius: 8, x: 0, y: 4)
                    }
                    .disabled(selectedCategory == nil || !hasContent || isSaving || showSuccess)
                    .offset(x: showErrorShake && !reduceMotion ? 10 : -10)
                    .animation(showErrorShake && !reduceMotion ? Animation.default.repeatCount(3).speed(4) : .default, value: showErrorShake)
                    
                    Button(AppStrings.QuickLog.moreDetails) {
                        TelemetryEngine.shared.track(event: .quick_log_more_details_tapped, properties: [
                            "carries_photo": photo != nil,
                            "has_note": !note.isEmpty
                        ])
                        showDetailedLog = true
                    }
                    .font(.labelMD)
                    .foregroundColor(.primary)
                    .padding(.bottom, 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 16)
                .background(Color.warmCream)
            }
            
        }"""

new_footer = """            }
            .safeAreaInset(edge: .bottom) {
                // Floating Glass Footer
                VStack(spacing: 12) {
                    Button(action: saveLog) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.trailing, 8)
                            } else if showSuccess {
                                Image(systemName: "checkmark")
                                    .font(.headlineSM)
                            } else {
                                Text(AppStrings.QuickLog.save)
                                    .font(.ctaOnboarding)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [Color.primary, Color.primary.opacity(0.8)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.input))
                        .shadow(color: Color.primary.opacity((selectedCategory == nil || !hasContent) ? 0 : 0.3), radius: 8, x: 0, y: 4)
                        .opacity(selectedCategory == nil || !hasContent ? 0.4 : 1.0)
                        .scaleEffect((selectedCategory == nil || !hasContent) ? 1.0 : (isSaving ? 0.95 : 1.0))
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedCategory == nil || !hasContent)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSaving)
                    }
                    .disabled(selectedCategory == nil || !hasContent || isSaving || showSuccess)
                    .offset(x: showErrorShake && !reduceMotion ? 10 : -10)
                    .animation(showErrorShake && !reduceMotion ? Animation.default.repeatCount(3).speed(4) : .default, value: showErrorShake)
                    
                    Button(AppStrings.QuickLog.moreDetails) {
                        TelemetryEngine.shared.track(event: .quick_log_more_details_tapped, properties: [
                            "carries_photo": photo != nil,
                            "has_note": !note.isEmpty
                        ])
                        showDetailedLog = true
                    }
                    .font(.labelMD)
                    .foregroundColor(.primary)
                    .padding(.bottom, 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 16)
                .background(
                    Color.surfaceContainerLowest.opacity(0.8)
                        .background(.ultraThinMaterial)
                )
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.primary.opacity(0.05)),
                    alignment: .top
                )
            }
        }"""
content = content.replace(old_footer, new_footer)

with open(quick_log_path, 'w') as f:
    f.write(content)

# 2. CategoryScrollerView.swift
with open(category_path, 'r') as f:
    cat_content = f.read()

old_chip = """        Button(action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                selectedCategory = category
            }
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
            TelemetryEngine.shared.track(event: .quick_log_category_selected, properties: [
                "category": category.rawValue,
                "was_preselected": false
            ])
        }) {
            VStack(spacing: 8) {
                Text(category.emoji)
                    .font(.headlineLG)
                    .padding(.top, 8)
                
                Text(category.rawValue)
                    .font(.labelMD)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
            }
            .frame(width: 64, height: 76)
            .background(isSelected ? Color.primary : Color.surface0)
            .cornerRadius(AppRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.primary : Color.warmSand, lineWidth: 1)
            )
            .foregroundColor(isSelected ? .white : .primaryText)
            .scaleEffect(isSelected ? 1.0 : 0.98)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(category.rawValue)
            .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        }"""

new_chip = """        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                selectedCategory = category
            }
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
            TelemetryEngine.shared.track(event: .quick_log_category_selected, properties: [
                "category": category.rawValue,
                "was_preselected": false
            ])
        }) {
            VStack(spacing: 8) {
                Text(category.emoji)
                    .font(.headlineLG)
                    .padding(.top, 8)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                
                Text(category.rawValue)
                    .font(isSelected ? .labelSemibold : .labelMD)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
            }
            .frame(width: 68, height: 80) // Slightly taller and wider for premium feel
            .background(
                isSelected ? 
                LinearGradient(colors: [Color.primary, Color.primary.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing) 
                : LinearGradient(colors: [Color.surface0, Color.surface0], startPoint: .top, endPoint: .bottom)
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.clear : Color.primary.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: isSelected ? Color.primary.opacity(0.3) : Color.black.opacity(0.02), radius: isSelected ? 8 : 4, x: 0, y: isSelected ? 4 : 2)
            .foregroundColor(isSelected ? .white : .primaryText)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(category.rawValue)
            .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        }
        .buttonStyle(SquishyCardStyle())"""

cat_content = cat_content.replace(old_chip, new_chip)

with open(category_path, 'w') as f:
    f.write(cat_content)


# 3. PhotoNoteRowView.swift
with open(photo_note_path, 'r') as f:
    photo_content = f.read()

old_photo_well = """                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.cream)
                            .frame(width: 72, height: 72)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(Color.primary, style: StrokeStyle(lineWidth: 1, dash: [4]))
                            )
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .foregroundColor(.primary)
                                    .font(.headlineLG)
                            )
                    }"""

new_photo_well = """                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.surfaceContainerLowest)
                            .frame(width: 72, height: 72)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
                            .overlay(
                                VStack(spacing: 4) {
                                    Image(systemName: "camera.fill")
                                        .foregroundColor(.primary)
                                        .font(.headlineLG)
                                    Text("Add")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.secondaryText)
                                }
                            )
                    }"""

old_note_field = """            // Note Field
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isNoteFocused ? Color.primary : Color.warmSand, lineWidth: isNoteFocused ? 2 : 1)
                    .background(Color.clear)"""

new_note_field = """            // Note Field
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.surface0)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isNoteFocused ? Color.primary : Color.primary.opacity(0.05), lineWidth: isNoteFocused ? 2 : 1)
                    )"""

photo_content = photo_content.replace(old_photo_well, new_photo_well).replace(old_note_field, new_note_field)

with open(photo_note_path, 'w') as f:
    f.write(photo_content)


# 4. SeveritySliderView.swift
with open(severity_path, 'r') as f:
    sev_content = f.read()

old_sev = """                Text(labels[severity - 1])
                    .font(.labelMD)
                    .foregroundColor(colorForSeverity(severity))"""

new_sev = """                Text(labels[severity - 1])
                    .font(.labelSemibold)
                    .foregroundColor(colorForSeverity(severity))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(colorForSeverity(severity).opacity(0.15))
                    .clipShape(Capsule())"""

sev_content = sev_content.replace(old_sev, new_sev)

with open(severity_path, 'w') as f:
    f.write(sev_content)

print("Rewritten 4 QuickLog components.")
