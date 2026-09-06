import CoreLocation
import SwiftUI

struct RoutePlannerSheet: View {
    @Binding var start: CLLocationCoordinate2D?
    @Binding var end: CLLocationCoordinate2D?
    @Binding var isRouting: Bool
    var onBuild: () -> Void
    var onPlay: () -> Void
    var onUseDrawn: () -> Void

    @EnvironmentObject private var session: SpoofSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Straßenroute") {
                    Button("Aktuellen Pin / Spoof als Start verwenden") {
                        start = session.simulated ?? session.pin
                    }
                    Button("Aktuellen Pin als Ziel verwenden") {
                        end = session.pin
                    }
                    LabeledContent("Start") {
                        Text(coordText(start)).font(.caption.monospaced())
                    }
                    LabeledContent("Ziel") {
                        Text(coordText(end)).font(.caption.monospaced())
                    }
                    Button {
                        onBuild()
                    } label: {
                        if isRouting {
                            ProgressView()
                        } else {
                            Label("Fuß- oder Fahrroute auf Straßen erstellen", systemImage: "road.lanes")
                        }
                    }
                    .disabled(isRouting)
                }

                Section("Abspielen / Zeichnen") {
                    Button {
                        onUseDrawn()
                    } label: {
                        Label("Gezeichneten Kartenpfad verwenden", systemImage: "pencil.tip")
                    }
                    Button(action: onPlay) {
                        Label("Route abspielen", systemImage: "play.fill")
                    }
                }

                Section {
                    Text("Routen folgen für den gewählten Reisemodus den Straßen und Wegen aus Apple Karten. Die Geschwindigkeit variiert leicht zufällig, damit die Bewegung weniger robotisch wirkt.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Routen")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }

    private func coordText(_ c: CLLocationCoordinate2D?) -> String {
        guard let c else { return "—" }
        return String(format: "%.5f, %.5f", c.latitude, c.longitude)
    }
}
