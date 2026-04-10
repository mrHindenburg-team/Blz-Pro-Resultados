import SwiftUI
import MapKit

struct BrazilMapView: View {
    @State private var cameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: -14.0, longitude: -51.0),
            span: MKCoordinateSpan(latitudeDelta: 35, longitudeDelta: 35)
        )
    )
    @State private var selectedSpot: HotSpot?
    @State private var detailSpot: HotSpot?

    private let spots = HotSpot.brazilHotSpots

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                mapLayer
                if let spot = selectedSpot {
                    SpotDetailCard(spot: spot, onViewDetails: { detailSpot = spot })
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding()
                }
            }
            .navigationTitle("Heat Zones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.blazeBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HeatLegendView()
                }
            }
            .sheet(item: $detailSpot) { SpotDetailView(spot: $0) }
        }
    }

    private var mapLayer: some View {
        Map(position: $cameraPosition) {
            ForEach(spots) { spot in
                Annotation(
                    spot.name,
                    coordinate: CLLocationCoordinate2D(
                        latitude: spot.latitude,
                        longitude: spot.longitude
                    )
                ) {
                    HotSpotAnnotationView(spot: spot)
                        .onTapGesture {
                            withAnimation(.spring(duration: 0.4)) {
                                selectedSpot = selectedSpot?.name == spot.name ? nil : spot
                            }
                        }
                }
            }
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
        .ignoresSafeArea()
        .onTapGesture {
            withAnimation(.spring(duration: 0.3)) {
                selectedSpot = nil
            }
        }
    }
}

struct SpotDetailCard: View {
    let spot: HotSpot
    let onViewDetails: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(spot.name)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("Intensity \(spot.intensity * 100, specifier: "%.1f")%")
                        .font(.caption)
                        .foregroundStyle(Color.blazeSubtext)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(spot.temperature, specifier: "%.1f")°C")
                        .font(.title2.bold())
                        .foregroundStyle(LinearGradient.blazeFire)
                    Text("\(spot.humidity, specifier: "%.1f")% humidity")
                        .font(.caption)
                        .foregroundStyle(Color.blazeSubtext)
                }
            }
            Button(action: onViewDetails) {
                HStack(spacing: 6) {
                    Text("View Details")
                    Image(systemName: "arrow.right")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(LinearGradient.blazeFire)
                .clipShape(.rect(cornerRadius: 10))
            }
        }
        .padding(16)
        .background(Color.blazeSurface)
        .clipShape(.rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.blazeBorder)
        }
    }
}

struct HeatLegendView: View {
    var body: some View {
        HStack(spacing: 4) {
            Text("Cold")
                .font(.caption2)
                .foregroundStyle(Color.blazeSubtext)
            LinearGradient(
                colors: [.blue, .yellow, .blazeOrange, .blazeRed],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 60, height: 8)
            .clipShape(.rect(cornerRadius: 4))
            Text("Hot")
                .font(.caption2)
                .foregroundStyle(Color.blazeSubtext)
        }
    }
}
