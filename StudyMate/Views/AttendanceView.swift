import SwiftUI
import MapKit
import CoreData

struct AttendanceView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var location = LocationService.shared
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ClassLocation.subject, ascending: true)],
        animation: .default
    ) private var classes: FetchedResults<ClassLocation>

    @State private var showingAdd = false
    @State private var showingCheckIn = false
    @State private var selectedClass: ClassLocation?

    var body: some View {
        NavigationStack {
            Map {
                UserAnnotation()
                ForEach(classes) { c in
                    let coord = CLLocationCoordinate2D(latitude: c.latitude, longitude: c.longitude)
                    Marker(c.subject ?? "Class", coordinate: coord)
                    MapCircle(center: coord, radius: c.radius)
                        .foregroundStyle(.blue.opacity(0.15))
                        .stroke(.blue, lineWidth: 1)
                }
            }
            .mapControls { MapUserLocationButton() }
            .navigationTitle("Attendance")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add class")
                }
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button { showingCheckIn = true } label: {
                            Label("Check in (scan)", systemImage: "qrcode.viewfinder")
                        }
                        if !classes.isEmpty {
                            Menu("Show code (leader)") {
                                ForEach(classes) { c in
                                    Button(c.subject ?? "Class") { selectedClass = c }
                                }
                            }
                        }
                    } label: { Image(systemName: "qrcode") }
                        .accessibilityLabel("Attendance actions")
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddClassLocationView().environment(\.managedObjectContext, context)
            }
            .sheet(isPresented: $showingCheckIn) {
                CheckInView().environment(\.managedObjectContext, context)
            }
            .sheet(item: $selectedClass) { c in
                ShowAttendanceCodeView(classLocation: c)
            }
            .safeAreaInset(edge: .bottom) {
                if let inside = classes.first(where: {
                    guard let id = $0.id?.uuidString else { return false }
                    return location.isInside(id: id)
                }) {
                    Text("You're at \(inside.subject ?? "class")")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.green.opacity(0.2))
                }
            }
            .task {
                location.requestAuthorization()
                location.startUpdating()
                for c in classes {
                    if let id = c.id?.uuidString {
                        location.startMonitoring(id: id, latitude: c.latitude,
                                                 longitude: c.longitude, radius: c.radius)
                    }
                }
            }
        }
    }
}
