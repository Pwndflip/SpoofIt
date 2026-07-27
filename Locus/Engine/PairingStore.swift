import Foundation
import UniformTypeIdentifiers

@MainActor
final class PairingStore: ObservableObject {
    @Published private(set) var hasPairingFile = false
    @Published var lastError: String?

    static let fileName = "rp_pairing_file.plist"
    static let supportedTypes: [UTType] = [
        .propertyList,
        UTType(filenameExtension: "mobiledevicepairing", conformingTo: .data)!,
        UTType(filenameExtension: "mobiledevicepair", conformingTo: .data)!
    ]

    private var directoryURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Pairing", isDirectory: true)
    }

    var pairingURL: URL {
        directoryURL.appendingPathComponent(Self.fileName)
    }

    var pairingPath: String { pairingURL.path }

    init() {
        refresh()
    }

    func refresh() {
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        hasPairingFile = FileManager.default.fileExists(atPath: pairingURL.path)
    }

    func importPairing(from sourceURL: URL) throws {
        let accessing = sourceURL.startAccessingSecurityScopedResource()
        defer { if accessing { sourceURL.stopAccessingSecurityScopedResource() } }

        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: pairingURL.path) {
            try FileManager.default.removeItem(at: pairingURL)
        }
        try FileManager.default.copyItem(at: sourceURL, to: pairingURL)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: pairingURL.path)
        hasPairingFile = true
        lastError = nil
    }

    func removePairing() throws {
        if FileManager.default.fileExists(atPath: pairingURL.path) {
            try FileManager.default.removeItem(at: pairingURL)
        }
        hasPairingFile = false
    }
}
