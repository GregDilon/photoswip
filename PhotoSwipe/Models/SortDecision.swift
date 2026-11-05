import Foundation
import SwiftData

/// Ce que l'utilisateur a décidé pour une photo.
enum Decision: String, Codable {
    case keep
    case trash
}

/// Une décision de tri enregistrée, liée à une photo par son `localIdentifier` PhotoKit.
/// On ne stocke que l'identifiant : la photo elle-même reste dans la photothèque.
@Model
final class SortDecision {
    @Attribute(.unique) var assetID: String
    /// Stocké en String pour pouvoir filtrer simplement dans les `#Predicate`.
    var decisionRaw: String
    var decidedAt: Date

    var decision: Decision {
        get { Decision(rawValue: decisionRaw) ?? .keep }
        set { decisionRaw = newValue.rawValue }
    }

    init(assetID: String, decision: Decision, decidedAt: Date = .now) {
        self.assetID = assetID
        self.decisionRaw = decision.rawValue
        self.decidedAt = decidedAt
    }
}
