import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject private var pairing: PairingStore
    @EnvironmentObject private var session: SpoofSession
    @Environment(\.dismiss) private var dismiss

    @State private var showImporter = false
    @State private var showPairOnDevice = false
    @State private var tunnelIP = TunnelConfig.targetIP
    @State private var localDevVPNInstalled = LocalDevVPN.isInstalled
    @Environment(\.scenePhase) private var scenePhase

    private var supportsOnDevicePairing: Bool {
        if #available(iOS 27.0, *) { return true }
        return false
    }

    private var appVersion: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        return build.isEmpty ? short : "\(short) (\(build))"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label {
                        Text(pairing.hasPairingFile ? "RPPairing-Datei installiert" : "Keine Pairing-Datei")
                    } icon: {
                        Image(systemName: pairing.hasPairingFile ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(pairing.hasPairingFile ? LocusTheme.statusGood : LocusTheme.statusWarn)
                    }

                    if supportsOnDevicePairing {
                        Button {
                            showPairOnDevice = true
                        } label: {
                            Label("Auf diesem iPhone koppeln", systemImage: "iphone.gen3.radiowaves.left.and.right")
                        }
                    }

                    Button("RPPairing-Datei importieren …") { showImporter = true }
                    Button("RPPairing aus Zwischenablage einfügen") {
                        do {
                            try pairing.importPairingFromClipboard()
                        } catch {
                            session.lastError = error.localizedDescription
                        }
                    }
                    if pairing.hasPairingFile {
                        Button("Pairing-Datei entfernen", role: .destructive) {
                            try? pairing.removePairing()
                        }
                    }
                } header: {
                    Text("Entwickler-Kopplung")
                } footer: {
                    Text(supportsOnDevicePairing
                         ? "Unter iOS 27 kannst du auf diesem iPhone koppeln — ohne Computer. SpoofIt! stellt einen koppelbaren Host bereit. Bestätige den 6-stelligen Code unter Einstellungen › Datenschutz & Sicherheit › Entwicklermodus › Mit Host koppeln. Unter älteren iOS-Versionen importierst du eine RPPairing-Datei von idevice_pair."
                         : "Importiere eine RPPairing-Datei von idevice_pair. Falls der Dateiauswahldialog nicht funktioniert, aktiviere Fix File Picker in der App, teile die Datei mit LiveContainer → SpoofIt! oder kopiere den Plist-Text und füge ihn ein.")
                }

                Section {
                    TextField("IP des Gerätetunnels", text: $tunnelIP)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onSubmit {
                            TunnelConfig.setTargetIP(tunnelIP)
                        }
                    LabeledContent("Status") {
                        Text(LocalDevVPN.isConnected ? "Verbunden" : "Nicht verbunden")
                            .foregroundStyle(LocalDevVPN.isConnected ? LocusTheme.statusGood : LocusTheme.statusWarn)
                    }
                    Button("Tunnel-IP speichern") {
                        TunnelConfig.setTargetIP(tunnelIP)
                    }
                    Button {
                        if localDevVPNInstalled {
                            LocalDevVPN.openInstalled()
                        } else {
                            LocalDevVPN.openAppStore()
                        }
                    } label: {
                        Label(
                            localDevVPNInstalled ? "LocalDevVPN öffnen" : "LocalDevVPN laden (App Store)",
                            systemImage: localDevVPNInstalled ? "lock.shield.fill" : "arrow.down.app.fill"
                        )
                    }
                } header: {
                    Text("Tunnel")
                } footer: {
                    Text("Verbinde LocalDevVPN vor dem Teleportieren. Die Standard-Tunnel-IP ist 10.7.0.1. Starte den ersten Spoof im WLAN; danach kann er auch über Mobilfunk weiterlaufen.")
                }

                Section("Datenschutz") {
                    Text("Alles bleibt auf dem Gerät. Favoriten und zuletzt verwendete Orte bleiben in UserDefaults. Keine Analyse, keine Konten, kein Upload.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Über") {
                    LabeledContent("Version", value: appVersion)
                    LabeledContent("Engine", value: "idevice-DVT-Ortssimulation")
                }

                Section {
                    Text("Gemacht von Emir, für leute wie Emir.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 8)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    
                    Text("Fenerbahçe ❤️")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 4)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

            }
            .navigationTitle("Einstellungen")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fertig") {
                        TunnelConfig.setTargetIP(tunnelIP)
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showImporter) {
            PairingDocumentPicker(
                onPick: { url in
                    showImporter = false
                    do {
                        try pairing.importPairing(from: url)
                    } catch {
                        session.lastError = error.localizedDescription
                    }
                },
                onCancel: { showImporter = false }
            )
            .ignoresSafeArea()
        }
            .sheet(isPresented: $showPairOnDevice) {
                PairOnDeviceView()
                    .environmentObject(pairing)
            }
            .onAppear {
                localDevVPNInstalled = LocalDevVPN.isInstalled
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    localDevVPNInstalled = LocalDevVPN.isInstalled
                }
            }
        }
    }
}

struct PlacesView: View {
    @EnvironmentObject private var session: SpoofSession
    @EnvironmentObject private var pairing: PairingStore
    @Environment(\.dismiss) private var dismiss

    @State private var placeToRename: SavedPlace?
    @State private var renameText = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Favoriten") {
                    if session.favorites.isEmpty {
                        Text("Markiere einen Pin auf der Karte, um ihn zu speichern.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(session.favorites) { place in
                        placeButton(place)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    session.removeFavorite(place)
                                } label: {
                                    Label("Löschen", systemImage: "trash.fill")
                                }
                                Button {
                                    placeToRename = place
                                    renameText = place.name
                                } label: {
                                    Label("Umbenennen", systemImage: "pencil")
                                }
                                .tint(.gray)
                            }
                    }
                }

                Section("Zuletzt verwendet") {
                    if session.recents.isEmpty {
                        Text("Teleportierte Orte erscheinen hier.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(session.recents) { place in
                        placeButton(place)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    session.removeRecent(place)
                                } label: {
                                    Label("Löschen", systemImage: "trash.fill")
                                }
                            }
                    }
                }
            }
            .navigationTitle("Orte")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
            .alert("Favorit umbenennen", isPresented: Binding(
                get: { placeToRename != nil },
                set: { if !$0 { placeToRename = nil } }
            )) {
                TextField("Name", text: $renameText)
                Button("Abbrechen", role: .cancel) {
                    placeToRename = nil
                }
                Button("Speichern") {
                    if let place = placeToRename {
                        session.renameFavorite(place, to: renameText)
                    }
                    placeToRename = nil
                }
            } message: {
                Text("Wähle einen Namen, den du später wiedererkennst.")
            }
        }
    }

    private func placeButton(_ place: SavedPlace) -> some View {
        Button {
            session.teleport(to: place.coordinate, pairing: pairing)
            dismiss()
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(place.name).foregroundStyle(.primary)
                Text(String(format: "%.5f, %.5f", place.latitude, place.longitude))
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
        }
    }
}
