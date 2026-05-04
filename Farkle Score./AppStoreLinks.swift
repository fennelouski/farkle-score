//
//  AppStoreLinks.swift
//  Farkle Score.
//

import Foundation

/// URLs for Settings and alignment with App Store Connect. Set `FarklePrivacyPolicyURL` and
/// `FarkleSupportURL` in Info.plist (non-empty) before submission.
enum AppStoreLinks {
    static var privacyPolicyURL: URL? {
        url(forInfoKey: "FarklePrivacyPolicyURL")
    }

    static var supportURL: URL? {
        url(forInfoKey: "FarkleSupportURL")
    }

    private static func url(forInfoKey key: String) -> URL? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: key) as? String else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let url = URL(string: trimmed), url.scheme == "http" || url.scheme == "https" else {
            return nil
        }
        return url
    }
}
