import Foundation

struct TreeData: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var description: String
    var creator: String
    var donate: String
    var variants: Int
    var basePrice: Int
    var isGrowable: Bool? = true
}

struct FocusStats: Codable, Identifiable, Equatable {
    var id: String = UUID().uuidString
    var duration: Double // in seconds
    var treeId: String
    var isFailed: Bool
    var failureTree: String = "weathered_0"
    var completedOn: Double = Date().timeIntervalSince1970 * 1000 // ms
    var treeSeed: Int = 0
}

enum TimerStatus: String, Codable, Equatable {
    case idle
    case running
    case hasQuit = "has_quit"
    case hasWon = "has_won"
    case postQuit = "post_quit"
    case postWin = "post_win"
}
