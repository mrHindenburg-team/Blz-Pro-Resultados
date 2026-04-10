import Foundation
import SwiftData

@Model
final class FavoriteSpot {
    var spotName: String
    var addedAt: Date

    init(spotName: String) {
        self.spotName = spotName
        self.addedAt = .now
    }
}
