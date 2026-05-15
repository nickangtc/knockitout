import CoreTransferable
import Foundation

struct KnockItem: Identifiable, Codable, Equatable, Transferable {
    let id: UUID
    var title: String
    let createdAt: Date
    var isActive: Bool

    init(id: UUID = UUID(), title: String, createdAt: Date = Date(), isActive: Bool = false) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.isActive = isActive
    }

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .knockItem)
    }
}
