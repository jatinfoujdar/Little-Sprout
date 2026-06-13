import Foundation

class StorageManager {
    static let shared = StorageManager()
    
    private init() {
        migrateOldStatsIfNecessary()
    }
    
    private let statsKey = "focus_stats_history"
    private let coinsKey = "user_coins_count"
    private let treeListKey = "cached_tree_list"
    
    func getCoins() -> Int {
        return UserDefaults.standard.integer(forKey: coinsKey)
    }
    
    func saveCoins(_ coins: Int) {
        UserDefaults.standard.set(coins, forKey: coinsKey)
    }
    
    func addCoins(_ amount: Int) {
        let current = getCoins()
        saveCoins(current + amount)
    }
    
    func removeCoins(_ amount: Int) {
        let current = getCoins()
        saveCoins(max(0, current - amount))
    }
    
    func getStats(for monthYear: String = getCurrentMonthYear()) -> [FocusStats] {
        let fileURL = getDocumentsDirectory().appendingPathComponent("\(monthYear).json")
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([FocusStats].self, from: data)
        } catch {
            print("Failed to decode stats for \(monthYear): \(error)")
            return []
        }
    }
    
    func saveStats(_ stats: [FocusStats], for monthYear: String) {
        let fileURL = getDocumentsDirectory().appendingPathComponent("\(monthYear).json")
        do {
            let data = try JSONEncoder().encode(stats)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to encode stats for \(monthYear): \(error)")
        }
    }
    
    func injectStat(_ stat: FocusStats) {
        let date = Date(timeIntervalSince1970: stat.completedOn / 1000.0)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let monthYear = formatter.string(from: date)
        
        var stats = getStats(for: monthYear)
        if let index = stats.firstIndex(where: { $0.id == stat.id }) {
            stats[index] = stat
        } else {
            stats.append(stat)
        }
        saveStats(stats, for: monthYear)
    }
    
    private func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private static func getCurrentMonthYear() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: Date())
    }
    
    func getCachedTrees() -> [TreeData] {
        guard let data = UserDefaults.standard.data(forKey: treeListKey) else {
            return []
        }
        do {
            return try JSONDecoder().decode([TreeData].self, from: data)
        } catch {
            return []
        }
    }
    
    func cacheTrees(_ trees: [TreeData]) {
        do {
            let data = try JSONEncoder().encode(trees)
            UserDefaults.standard.set(data, forKey: treeListKey)
        } catch {
            print("Failed to cache trees: \(error)")
        }
    }
    
    func getPurchasedTrees() -> [String] {
        guard let list = UserDefaults.standard.stringArray(forKey: "purchased_trees_list") else {
            return ["tree"] // Pre-owned default tree
        }
        return list
    }
    
    func purchaseTree(treeId: String) {
        var list = getPurchasedTrees()
        if !list.contains(treeId) {
            list.append(treeId)
            UserDefaults.standard.set(list, forKey: "purchased_trees_list")
        }
    }
    
    private func migrateOldStatsIfNecessary() {
        guard let data = UserDefaults.standard.data(forKey: statsKey) else {
            return
        }
        do {
            let oldStats = try JSONDecoder().decode([FocusStats].self, from: data)
            if !oldStats.isEmpty {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM"
                
                var grouped: [String: [FocusStats]] = [:]
                for stat in oldStats {
                    let date = Date(timeIntervalSince1970: stat.completedOn / 1000.0)
                    let monthYear = formatter.string(from: date)
                    grouped[monthYear, default: []].append(stat)
                }
                
                for (monthYear, stats) in grouped {
                    var currentMonthStats = getStats(for: monthYear)
                    for stat in stats {
                        if !currentMonthStats.contains(where: { $0.id == stat.id }) {
                            currentMonthStats.append(stat)
                        }
                    }
                    saveStats(currentMonthStats, for: monthYear)
                }
            }
            UserDefaults.standard.removeObject(forKey: statsKey)
        } catch {
            print("Failed to migrate old stats: \(error)")
        }
    }
}
