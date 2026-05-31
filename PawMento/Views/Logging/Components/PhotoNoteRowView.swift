import SwiftUI
import UIKit

struct PhotoNoteRowView: View {
    @Binding var note: String
    @Binding var photo: UIImage?
    @State private var showingImagePicker = false
    @State private var showingActionSheet = false
    @State private var pickerSourceType: UIImagePickerController.SourceType = .camera
    
    @FocusState private var isNoteFocused: Bool
    @State private var noteFocusStartTime: Date?
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Photo Well
            Button(action: {
                if photo == nil {
                    showingActionSheet = true
                }
            }) {
                ZStack {
                    if let image = photo {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 72, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.warmTan, lineWidth: 1)
                            )
                        
                        // Remove badge
                        VStack {
                            HStack {
                                Spacer()
                                Button(action: { photo = nil }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.warmCoral)
                                        .background(Color.white.clipShape(Circle()))
                                        .font(.system(size: 20))
                                }
                                .offset(x: 8, y: -8)
                            }
                            Spacer()
                        }
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.cream)
                            .frame(width: 72, height: 72)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(Color.warmTan, style: StrokeStyle(lineWidth: 1, dash: [4]))
                            )
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .foregroundColor(.warmTan)
                                    .font(.system(size: 24))
                            )
                    }
                }
                .frame(width: 72, height: 72)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Note Field
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isNoteFocused ? Color.warmTan : Color.warmSand, lineWidth: isNoteFocused ? 2 : 1)
                    .background(Color.clear)
                
                if note.isEmpty {
                    Text(AppStrings.QuickLog.tapToDescribe)
                        .font(.labelMD)
                        .italic()
                        .foregroundColor(.tertiaryText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .allowsHitTesting(false)
                }
                
                TextEditor(text: $note)
                    .font(.bodyMD)
                    .focused($isNoteFocused)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .frame(height: 72)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .onChange(of: isNoteFocused) { focused in
                        if focused {
                            noteFocusStartTime = Date()
                        } else if let start = noteFocusStartTime {
                            let tookMs = Date().timeIntervalSince(start) * 1000
                            TelemetryEngine.shared.track(event: .quick_log_note_typed, properties: [
                                "length": note.count,
                                "took_ms": Int(tookMs)
                            ])
                            noteFocusStartTime = nil
                        }
                    }
                    .onChange(of: note) { newValue in
                        if newValue.count > 280 {
                            note = String(newValue.prefix(280))
                        }
                    }
            }
            .frame(height: 72)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $photo, sourceType: pickerSourceType)
        }
        .confirmationDialog("Choose Photo", isPresented: $showingActionSheet, titleVisibility: .visible) {
            Button("Take Photo") {
                pickerSourceType = .camera
                showingImagePicker = true
            }
            Button("Choose from Library") {
                pickerSourceType = .photoLibrary
                showingImagePicker = true
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}
