import Foundation
import Combine

class GardenViewModel: ObservableObject {
    @Published var pngTreeList: [String] = []
    @Published var stats: [FocusStats] = []
    @Published var streak: Int = 0
    @Published var totalFocus: Int = 0
    @Published var selectedMonthDate: Date = Date()
    
    init() {
        updateTreeStats()
    }
    
    func changeMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: selectedMonthDate) {
            selectedMonthDate = newDate
            updateTreeStats()
        }
    }
    
    var selectedMonthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: selectedMonthDate)
    }
    
    var selectedMonthYearLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM ''yy"
        return formatter.string(from: selectedMonthDate)
    }
    
    func updateTreeStats() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let monthStr = formatter.string(from: selectedMonthDate)
        
        let monthStats = StorageManager.shared.getStats(for: monthStr)
        self.stats = monthStats
        
        self.pngTreeList = monthStats.map { stat in
            if stat.isFailed {
                return "\(stat.failureTree)_grid.png"
            } else {
                return "\(stat.treeId)_\(stat.treeSeed)_grid.png"
            }
        }
        
        self.streak = calculateStreak(stats: monthStats)
        self.totalFocus = calculateTotalMinsFocused(statsLst: monthStats)
    }
    
    private func calculateStreak(stats: [FocusStats]) -> Int {
        let successfulStats = stats.filter { !$0.isFailed }
        if successfulStats.isEmpty { return 0 }
        
        let calendar = Calendar.current
        let dates = successfulStats.map {
            let date = Date(timeIntervalSince1970: $0.completedOn / 1000.0)
            return calendar.startOfDay(for: date)
        }
        
        let uniqueSortedDates = Array(Set(dates)).sorted(by: >)
        guard let latestDate = uniqueSortedDates.first else { return 0 }
        
        let today = calendar.startOfDay(for: Date())
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return 0 }
        
        if latestDate != today && latestDate != yesterday {
            return 0
        }
        
        var currentStreak = 1
        for i in 0..<(uniqueSortedDates.count - 1) {
            let current = uniqueSortedDates[i]
            let next = uniqueSortedDates[i + 1]
            
            if let expectedNext = calendar.date(byAdding: .day, value: -1, to: current), expectedNext == next {
                currentStreak += 1
            } else {
                break
            }
        }
        
        return currentStreak
    }
    
    private func calculateTotalMinsFocused(statsLst: [FocusStats]) -> Int {
        let totalSeconds = statsLst.filter { !$0.isFailed }.reduce(0.0) { $0 + $1.duration }
        return Int(round(totalSeconds / 60.0))
    }
}
