import SwiftUI

struct StatCardView: View {
    let icon: String
    let label: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(LinearGradient.blazeFire)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(Color.blazeSubtext)
            }
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(Color.blazeSubtext)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.blazeCard)
        .clipShape(.rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.blazeBorder)
        }
    }
}
