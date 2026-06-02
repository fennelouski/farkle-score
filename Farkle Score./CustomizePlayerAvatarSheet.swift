//
//  CustomizePlayerAvatarSheet.swift
//  Farkle Score.
//

import SwiftUI
import PhotosUI
import WebImagePicker
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

struct CustomizePlayerAvatarSheet: View {
    @Binding var avatarEmoji: String?
    @Binding var avatarPhotoFileName: String?

    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.dismiss) private var dismiss

    @State private var photoPickerItem: PhotosPickerItem?
    @State private var showWebImagePicker = false
    @State private var showEmojiEntrySheet = false
    @State private var emojiDraft = ""
#if os(iOS)
    @State private var showCameraNotice = false
    @State private var showCameraPicker = false
    @State private var cameraImage: UIImage?
#endif

    private static let quickPickEmojis: [String] = [
        "🎲", "🎯", "⭐", "🏆", "🔥", "💎", "🍀", "🎪", "🦄", "🐉", "🦋", "🌙", "⚡️", "🎸", "🍕",
    ]

    private static let quickPicksRowInsets = EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20)
    private static let optionRowInsets = EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20)

    var body: some View {
        NavigationStack {
            avatarForm
                .navigationTitle("Customize avatar")
#if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
#endif
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
#if os(macOS)
        .frame(minWidth: 480, minHeight: 380)
#endif
        .sheet(isPresented: $showEmojiEntrySheet) {
            emojiEntrySheet
        }
        .webImagePicker(isPresented: $showWebImagePicker) { selections in
            guard let selection = selections.first else { return }
            saveWebImageSelection(selection)
        }
#if os(iOS)
        .alert("Open camera?", isPresented: $showCameraNotice) {
            Button("Cancel", role: .cancel) {}
            Button("Continue") {
                showCameraPicker = true
            }
        } message: {
            Text("The camera will open so you can take a picture for this player’s avatar.")
        }
        .fullScreenCover(isPresented: $showCameraPicker) {
            CameraImagePicker(pickedImage: $cameraImage)
        }
        .onChange(of: cameraImage) { _, img in
            guard let img else { return }
            Task {
                await saveCameraImage(img)
                await MainActor.run { cameraImage = nil }
            }
        }
#endif
    }

    private var avatarForm: some View {
        Form {
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Self.quickPickEmojis, id: \.self) { em in
                            Button {
                                selectEmoji(em)
                            } label: {
                                Text(em)
                                    .font(.system(size: 36))
                                    .frame(width: 52, height: 52)
                                    .farkleButtonHitArea(cornerRadius: 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(AppTheme.cardFill)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(
                                                        avatarEmoji == em
                                                            ? AppTheme.accentYellow(contrast)
                                                            : AppTheme.stroke(contrast),
                                                        lineWidth: avatarEmoji == em ? 2 : 1
                                                    )
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Emoji \(em)")
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 4)
                }
                .listRowInsets(Self.quickPicksRowInsets)
            } header: {
                Text("Quick picks")
            }

            Section {
                Button {
                    showEmojiEntrySheet = true
                } label: {
                    Label("Choose any emoji…", systemImage: "face.smiling")
                }
                .listRowInsets(Self.optionRowInsets)

                PhotosPicker(
                    selection: $photoPickerItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Label("Choose from photo library…", systemImage: "photo.on.rectangle.angled")
                }
                .onChange(of: photoPickerItem) { _, item in
                    Task { await loadPhoto(from: item) }
                }
                .listRowInsets(Self.optionRowInsets)

                Button {
                    showWebImagePicker = true
                } label: {
                    Label("Choose from website…", systemImage: "globe")
                }
                .listRowInsets(Self.optionRowInsets)

#if os(iOS)
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button {
                        showCameraNotice = true
                    } label: {
                        Label("Take a photo…", systemImage: "camera.fill")
                    }
                    .listRowInsets(Self.optionRowInsets)
                }
#endif

                Button {
                    resetToMonogram()
                } label: {
                    Label("Use initials instead", systemImage: "person.crop.circle")
                }
                .listRowInsets(Self.optionRowInsets)
            } header: {
                Text("More options")
            } footer: {
                Text("Photo library, camera, and website picker are only used when you choose them here.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted(contrast))
                    .padding(.top, 4)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
#if os(macOS)
        .formStyle(.grouped)
        .fixedSize(horizontal: false, vertical: true)
#else
        .listSectionSpacing(.compact)
#endif
    }

    private var emojiEntrySheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Tap the smiley key on your keyboard", text: $emojiDraft)
                        .font(.title)
#if os(iOS)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
#endif
                } footer: {
                    Text("We’ll use the first emoji you enter.")
                }
            }
            .navigationTitle("Any emoji")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        emojiDraft = ""
                        showEmojiEntrySheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Use") {
                        if let normalized = Player.normalizedEmoji(emojiDraft) {
                            selectEmoji(normalized)
                        }
                        emojiDraft = ""
                        showEmojiEntrySheet = false
                    }
                    .disabled(Player.normalizedEmoji(emojiDraft) == nil)
                }
            }
        }
#if os(iOS)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
#endif
    }

    private func selectEmoji(_ em: String) {
        if let old = avatarPhotoFileName {
            AvatarImageStore.deleteFile(named: old)
            avatarPhotoFileName = nil
        }
        avatarEmoji = em
    }

    private func resetToMonogram() {
        if let old = avatarPhotoFileName {
            AvatarImageStore.deleteFile(named: old)
        }
        avatarPhotoFileName = nil
        avatarEmoji = nil
    }

    private func saveWebImageSelection(_ selection: WebImageSelection) {
        let payload = Self.jpegPayload(from: selection.data) ?? selection.data
        do {
            if let old = avatarPhotoFileName {
                AvatarImageStore.deleteFile(named: old)
            }
            let name = try AvatarImageStore.saveImageData(payload)
            avatarEmoji = nil
            avatarPhotoFileName = name
        } catch {
            return
        }
    }

    private func loadPhoto(from item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else { return }
            let out = Self.jpegPayload(from: data) ?? data
            await MainActor.run {
                do {
                    if let old = avatarPhotoFileName {
                        AvatarImageStore.deleteFile(named: old)
                    }
                    let name = try AvatarImageStore.saveImageData(out)
                    avatarEmoji = nil
                    avatarPhotoFileName = name
                    photoPickerItem = nil
                } catch {
                    return
                }
            }
        } catch {
            return
        }
    }

    nonisolated private static func jpegPayload(from data: Data) -> Data? {
#if canImport(UIKit)
        if let ui = UIImage(data: data) {
            return ui.jpegData(compressionQuality: 0.85)
        }
#endif
#if canImport(AppKit)
        if let ns = NSImage(data: data),
           let tiff = ns.tiffRepresentation,
           let rep = NSBitmapImageRep(data: tiff) {
            return rep.representation(using: .jpeg, properties: [.compressionFactor: 0.85])
        }
#endif
        return nil
    }

#if os(iOS)
    private func saveCameraImage(_ image: UIImage) async {
        guard let data = image.jpegData(compressionQuality: 0.85) else {
            await MainActor.run { showCameraPicker = false }
            return
        }
        await MainActor.run {
            do {
                if let old = avatarPhotoFileName {
                    AvatarImageStore.deleteFile(named: old)
                }
                let name = try AvatarImageStore.saveImageData(data)
                avatarEmoji = nil
                avatarPhotoFileName = name
                showCameraPicker = false
            } catch {
                showCameraPicker = false
            }
        }
    }
#endif
}
