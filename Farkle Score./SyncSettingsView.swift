//
//  SyncSettingsView.swift
//  Farkle Score.
//

import SwiftUI

struct SyncSettingsView: View {
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle(
                        "Sync in-progress game",
                        isOn: Binding(
                            get: { AppSettings.syncCurrentSession },
                            set: { AppSettings.syncCurrentSession = $0 }
                        )
                    )
                    .tint(AppTheme.accentBlue(contrast))
                    Text(
                        "When off (default), player names and score history still sync via iCloud. Turn on to also save the active match so you can continue the same game on another device."
                    )
                    .font(.footnote)
                    .foregroundStyle(AppTheme.muted(contrast))
                } header: {
                    Text("iCloud")
                }

                Section {
                    Text(
                        "Sign in to iCloud on each device. Names and history merge automatically; deleted entries on one device are not removed from the archive on others."
                    )
                    .font(.footnote)
                    .foregroundStyle(AppTheme.muted(contrast))
                }
            }
            .navigationTitle("Sync")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
#if os(iOS)
        .presentationDetents([.medium, .large])
#endif
    }
}

#Preview {
    SyncSettingsView()
}
