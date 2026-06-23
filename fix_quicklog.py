import os

quick_log_path = "/Users/max_ladmin/Desktop/antigravity_pawmento/pawmento/PawMento/Views/Logging/QuickLogSheetView.swift"
category_path = "/Users/max_ladmin/Desktop/antigravity_pawmento/pawmento/PawMento/Views/Logging/Components/CategoryScrollerView.swift"
photo_note_path = "/Users/max_ladmin/Desktop/antigravity_pawmento/pawmento/PawMento/Views/Logging/Components/PhotoNoteRowView.swift"

# 1. QuickLogSheetView.swift
with open(quick_log_path, 'r') as f:
    content = f.read()

old_cancel = """                    Button(AppStrings.QuickLog.cancel) {
                        TelemetryEngine.shared.track(event: .quick_log_cancelled, properties: ["had_changes": !note.isEmpty || selectedCategory != nil])
                        dismiss()
                    }
                    .font(.bodyMD)
                    .foregroundColor(.tertiaryText)"""

new_cancel = """                    Button(action: {
                        TelemetryEngine.shared.track(event: .quick_log_cancelled, properties: ["had_changes": !note.isEmpty || selectedCategory != nil])
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.tertiaryText)
                            .frame(width: 32, height: 32)
                            .background(Color.surface0)
                            .clipShape(Circle())
                    }"""
content = content.replace(old_cancel, new_cancel)

old_med = """                                TextField("e.g. 16mg, 1 tablet", text: $dose)
                                    .padding()
                                    .background(Color.surface0)
                                    .cornerRadius(AppRadius.input)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.warmSand, lineWidth: 1))"""

new_med = """                                TextField("e.g. 16mg, 1 tablet", text: $dose)
                                    .padding()
                                    .background(Color.surface0)
                                    .cornerRadius(16)
                                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.05), lineWidth: 1))"""
content = content.replace(old_med, new_med)

old_footer_bg = """                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 16)
                .background("""

new_footer_bg = """                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 16)
                .background("""
content = content.replace(old_footer_bg, new_footer_bg)

with open(quick_log_path, 'w') as f:
    f.write(content)

# 2. CategoryScrollerView.swift
with open(category_path, 'r') as f:
    cat_content = f.read()

old_more = """                    // More button
                    Button(action: {
                        showingMoreCategories = true
                    }) {
                        VStack(spacing: 8) {
                            Text("···")
                                .font(.headlineLG)
                                .padding(.top, 8)
                            Text("More")
                                .font(.labelMD)
                        }
                        .frame(width: 64, height: 76)
                        .background(Color.surface0)
                        .cornerRadius(AppRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.warmSand, lineWidth: 1)
                        )
                        .foregroundColor(.primaryText)
                    }"""

new_more = """                    // More button
                    Button(action: {
                        showingMoreCategories = true
                    }) {
                        VStack(spacing: 8) {
                            Text("···")
                                .font(.headlineLG)
                                .padding(.top, 8)
                            Text("More")
                                .font(.labelMD)
                        }
                        .frame(width: 68, height: 80)
                        .background(
                            LinearGradient(colors: [Color.surface0, Color.surface0], startPoint: .top, endPoint: .bottom)
                        )
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
                        .foregroundColor(.primaryText)
                    }
                    .buttonStyle(SquishyCardStyle())"""
cat_content = cat_content.replace(old_more, new_more)

with open(category_path, 'w') as f:
    f.write(cat_content)

print("QuickLog design deep dive fixes applied.")
