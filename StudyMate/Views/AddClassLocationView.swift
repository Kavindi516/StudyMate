import SwiftUI
import MapKit
import CoreData

struct AddClassLocationView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @StateObject private var location = LocationService.shared

    @State private var subject = ""
    @State private var radius: Double = 100
    @State private var position: MapCameraPosition = .automatic
    @State private var center = CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612) // Colombo

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ZStack {
                    Map(position: $position)
                        .onMapCameraChange { ctx in center = ctx.region.center }
                    Image(systemName: "mappin")
                        .font(.title).foregroundStyle(.red).offset(y: -12)
                }
                .frame(height: 280)

                Form {
                    Section("Class") { TextField("Subject", text: $subject) }
                    Section("Geofence radius") {
                        Text("\(Int(radius)) m")
                        Slider(value: $radius, in: 50...300, step: 10)
                    }
                    Button("Center on my location") {
                        if let loc = location.currentLocation {
                            position = .region(MKCoordinateRegion(center: loc.coordinate,
                                latitudinalMeters: 500, longitudinalMeters: 500))
                        }
                    }
                }
            }
            .navigationTitle("Add Class")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(subject.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .task {
                location.requestAuthorization()
                location.startUpdating()
                if let loc = location.currentLocation {
                    position = .region(MKCoordinateRegion(center: loc.coordinate,
                        latitudinalMeters: 500, longitudinalMeters: 500))
                }
            }
        }
    }

    private func save() {
        let c = ClassLocation(context: context)
        let id = UUID()
        c.id = id
        c.subject = subject
        c.latitude = center.latitude
        c.longitude = center.longitude
        c.radius = radius
        try? context.save()
        LocationService.shared.startMonitoring(id: id.uuidString,
            latitude: center.latitude, longitude: center.longitude, radius: radius)
        dismiss()
    }
}
