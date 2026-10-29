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

    private var insideClass: ClassLocation? {
        classes.first {
            guard let id = $0.id?.uuidString else { return false }
            return location.isInside(id: id)
        }
    }

    var body: some View {
        NavigationStack {
            Map {
                UserAnnotation()
                ForEach(classes) { c in
                    let coord = CLLocationCoordinate2D(latitude: c.latitude, longitude: c.longitude)
                    Marker(c.subject ?? "Class", coordinate: coord)
                    MapCircle(center: coord, radius: c.radius)
                        .foregroundStyle(.blue.opacity(0.15))
                        .stroke(.blue, lineWidth: 1.5)
                }
            }
            .mapControls { MapUserLocationButton() }
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("Attendance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add class")
                }
            }
            .safeAreaInset(edge: .bottom) { bottomCard }
            .sheet(isPresented: $showingAdd) {
                AddClassLocationView().environment(\.managedObjectContext, context)
            }
            .sheet(isPresented: $showingCheckIn) {
                CheckInView().environment(\.managedObjectContext, context)
            }
            .sheet(item: $selectedClass) { c in ShowAttendanceCodeView(classLocation: c) }
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

    private var bottomCard: some View {
        VStack(spacing: 12) {
            if let inside = insideClass {
                HStack(spacing: 12) {
                    Image(systemName: "location.fill.viewfinder")
                        .font(.title2).foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("You're at \(inside.subject ?? "class")").font(.headline)
                        Text("Check in to mark your attendance")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                Button { showingCheckIn = true } label: {
                    Label("Check in", systemImage: "checkmark.circle.fill").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent).tint(.green).controlSize(.large)
            } else {
                HStack(spacing: 12) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.title2).foregroundStyle(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(classes.isEmpty ? "No class locations yet"
                             : "\(classes.count) class location\(classes.count == 1 ? "" : "s")")
                            .font(.headline)
                        Text(classes.isEmpty ? "Tap + to add one"
                             : "Scan a code or tap a tag at class")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                Button { showingCheckIn = true } label: {
                    Label("Check in", systemImage: "qrcode.viewfinder").frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered).controlSize(.large)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding()
    }
}
